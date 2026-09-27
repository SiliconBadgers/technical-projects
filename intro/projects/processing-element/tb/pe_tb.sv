`timescale 1ns/1ps

// Supplied acceptance tests: implement pe.sv, not this file, for the PE checkpoint.
// Each instance owns a DUT, an independent model, and a reproducible stimulus stream.
module pe_test_case #(
    parameter int DATA_W = 8,
    parameter int ACC_W = 32,
    parameter int CASE_ID = 0
) (output bit done = 0);
    logic clk = 0;
    logic rst = 0, clear = 0, valid_in = 0;
    logic signed [DATA_W-1:0] a_in = 0, b_in = 0;
    wire valid_out;
    wire signed [DATA_W-1:0] a_out, b_out;
    wire signed [ACC_W-1:0] acc_out;
    pe #(.DATA_W(DATA_W), .ACC_W(ACC_W)) dut (.*);
    always #5 clk = ~clk;

    localparam logic signed [DATA_W-1:0] MIN_VALUE = {1'b1, {(DATA_W-1){1'b0}}};
    localparam logic signed [DATA_W-1:0] MAX_VALUE = {1'b0, {(DATA_W-1){1'b1}}};
    logic signed [DATA_W-1:0] expected_a = 0, expected_b = 0;
    logic signed [ACC_W-1:0] expected_acc = 0;
    logic expected_valid = 0;
    bit initialized = 0;
    int cycles = 0;
    int operand_pairs = 0;
    int positive_wraps = 0, negative_wraps = 0;
    bit [63:0] control_transitions = 0;
    int previous_control = 0;
    string phase = "startup";
    bit [31:0] rng, seed;
    // Reference arithmetic deliberately avoids the DUT's likely signed '*' expression.
    // Convert to positive magnitudes with an extra bit (so abs(MIN_VALUE) fits),
    // multiply by shift/add, apply the sign, then explicitly extend to ACC_W.
    function automatic logic signed [ACC_W-1:0] reference_product(
        input logic signed [DATA_W-1:0] a, b
    );
        logic [DATA_W:0] magnitude_a, magnitude_b;
        logic signed [2*DATA_W:0] product;
        magnitude_a = a[DATA_W-1] ? -$signed({a[DATA_W-1], a}) : {1'b0, a};
        magnitude_b = b[DATA_W-1] ? -$signed({b[DATA_W-1], b}) : {1'b0, b};
        product = '0;
        for (int bit_index = 0; bit_index <= DATA_W; bit_index++)
            if (magnitude_b[bit_index])
                product = product + ({{DATA_W{1'b0}}, magnitude_a} << bit_index);
        if (a[DATA_W-1] != b[DATA_W-1]) product = -product;
        reference_product = product; // Signed extension, or discard the redundant sign bit.
    endfunction

    task automatic update_model;
        logic signed [ACC_W-1:0] product;
        logic signed [ACC_W:0] full_sum;
        if (rst || clear) begin
            expected_acc = '0;
            expected_a = '0;
            expected_b = '0;
            expected_valid = 0;
        end else begin
            expected_valid = valid_in;
            if (valid_in) begin
                product = reference_product(a_in, b_in);
                full_sum = {expected_acc[ACC_W-1], expected_acc} +
                           {product[ACC_W-1], product};
                // Count signed overflow in both directions before modulo truncation.
                if (!expected_acc[ACC_W-1] && !product[ACC_W-1] && full_sum[ACC_W-1])
                    positive_wraps++;
                if (expected_acc[ACC_W-1] && product[ACC_W-1] && !full_sum[ACC_W-1])
                    negative_wraps++;
                expected_acc = full_sum[ACC_W-1:0];
                expected_a = a_in;
                expected_b = b_in;
            end
        end
    endtask
    task automatic check_outputs(input string sample_point);
        // Case inequality rejects X/Z outputs too. Report every expected output,
        // plus the configuration, phase, cycle, seed, and applied inputs.
        if (acc_out !== expected_acc || valid_out !== expected_valid ||
            a_out !== expected_a || b_out !== expected_b)
            $fatal(1, {"PE mismatch D=%0d A=%0d seed=%08h phase=%s cycle=%0d (%s)\n",
                       "  inputs: rst=%b clear=%b valid=%b a=%0d b=%0d\n",
                       "  actual: acc=%0d (0x%h) valid=%b a=%0d b=%0d\n",
                       "  expect: acc=%0d (0x%h) valid=%b a=%0d b=%0d"},
                   DATA_W, ACC_W, seed, phase, cycles, sample_point,
                   rst, clear, valid_in, a_in, b_in,
                   acc_out, acc_out, valid_out, a_out, b_out,
                   expected_acc, expected_acc, expected_valid, expected_a, expected_b);
    endtask

    task automatic step(
        input logic r, c, v,
        input logic signed [DATA_W-1:0] a, b
    );
        @(negedge clk);
        rst = r; clear = c; valid_in = v; a_in = a; b_in = b;
        cycles++;
        control_transitions[previous_control * 8 + int'({r, c, v})] = 1;
        previous_control = int'({r, c, v});
        // Inputs (including reset/clear) must not change registered outputs early.
        #1;
        if (initialized) check_outputs("before rising edge / must hold");
        @(posedge clk);
        update_model();
        #1; // Wait for nonblocking assignments; do not race the DUT.
        check_outputs("after rising edge");
        initialized = 1;
    endtask

    // A private xorshift32 stream avoids simulator-specific random sequences and
    // interference between parallel configurations. PE_SEED is an unsigned decimal.
    function automatic bit [31:0] random_word();
        rng = rng ^ (rng << 13);
        rng = rng ^ (rng >> 17);
        rng = rng ^ (rng << 5);
        return rng;
    endfunction

    function automatic logic signed [DATA_W-1:0] random_operand();
        bit [31:0] word_bits;
        for (int bit_index = 0; bit_index < DATA_W; bit_index++) begin
            if (bit_index % 32 == 0) word_bits = random_word();
            random_operand[bit_index] = word_bits[bit_index % 32];
        end
    endfunction

    function automatic logic signed [DATA_W-1:0] boundary(input int index);
        case (index)
            0: return MIN_VALUE;
            1: return MIN_VALUE + 1'b1;
            2: return -1;
            3: return 0;
            4: return 1;
            5: return MAX_VALUE - 1'b1;
            default: return MAX_VALUE;
        endcase
    endfunction
    initial begin : run_tests
        int seed_argument;
        int wrap_steps;
        bit [2:0] controls;
        logic signed [DATA_W-1:0] random_a, random_b;
        // These selected configurations keep the full overflow walks practical.
        if (DATA_W < 1 || ACC_W < 2*DATA_W || ACC_W - 2*DATA_W > 16)
            $fatal(1, "Unsupported test configuration D=%0d A=%0d", DATA_W, ACC_W);
        seed = 32'h51b00b1e;
        if ($value$plusargs("PE_SEED=%d", seed_argument)) seed = seed_argument;
        rng = seed ^ (32'h9e3779b9 * (CASE_ID + 1));
        if (rng == 0) rng = 1;

        phase = "reset and readable dot product";
        step(1, 0, 0, 0, 0);
        if (DATA_W >= 4) begin
            step(0, 0, 1, 2, 3);   // acc = 6; forward 2, 3.
            if (expected_acc !== 6) $fatal(1, "Reference model sanity check: 2*3");
            step(0, 0, 0, 7, 7);   // acc = 6; hold operands, valid_out = 0.
            step(0, 0, 1, -1, 4);  // acc = 2; forward -1, 4.
            if (expected_acc !== 2) $fatal(1, "Reference model sanity check: 6-4");
            step(0, 0, 1, -3, -2); // acc = 8; consecutive valid, negative * negative.
            if (expected_acc !== 8) $fatal(1, "Reference model sanity check: 2+6");
        end
        step(0, 1, 1, MIN_VALUE, MIN_VALUE); // Clear must discard this product.
        step(0, 0, 1, MIN_VALUE, MIN_VALUE);
        step(1, 1, 1, MAX_VALUE, MAX_VALUE); // Reset from nonzero state.

        phase = "all control transitions";
        // All 8 {reset,clear,valid} settings followed by all 8 settings.
        // Reload nonzero state so clearing/holding zero cannot hide a mistake.
        for (int before_control = 0; before_control < 8; before_control++)
            for (int after_control = 0; after_control < 8; after_control++) begin
                step(0, 0, 1, MIN_VALUE, MIN_VALUE);
                step((before_control >> 2) & 1, (before_control >> 1) & 1,
                     before_control & 1, MIN_VALUE, MAX_VALUE);
                step((after_control >> 2) & 1, (after_control >> 1) & 1,
                     after_control & 1, MAX_VALUE, MIN_VALUE);
            end

        phase = "boundary operands and repeated bubbles";
        for (int a_index = 0; a_index < 7; a_index++)
            for (int b_index = 0; b_index < 7; b_index++) begin
                step(0, 1, 0, 0, 0);
                step(0, 0, 1, boundary(a_index), boundary(b_index));
                repeat (3) step(0, 0, 0, MIN_VALUE, MAX_VALUE);
                step(0, 0, 1, boundary(b_index), boundary(a_index));
            end

        phase = "every operand pair in isolation";
        // Exhaust all bit patterns through 8 bits. Clear before each product so
        // correlated accumulation errors cannot cancel across adjacent products.
        if (DATA_W <= 8)
            for (int a_bits = 0; a_bits < (1 << DATA_W); a_bits++)
                for (int b_bits = 0; b_bits < (1 << DATA_W); b_bits++) begin
                    step(0, 1, 0, 0, 0);
                    step(0, 0, 1, a_bits, b_bits);
                    operand_pairs++;
                end

        phase = "every operand pair back to back";
        step(1, 0, 0, 0, 0);
        if (DATA_W <= 8)
            for (int a_bits = 0; a_bits < (1 << DATA_W); a_bits++)
                for (int b_bits = 0; b_bits < (1 << DATA_W); b_bits++)
                    step(0, 0, 1, a_bits, b_bits);

        phase = "positive accumulator wraparound";
        step(0, 1, 0, 0, 0);
        // MIN*MIN = 2**(2*DATA_W-2). Walk through an entire accumulator modulus
        // and beyond without forcing internal state, including the default 32-bit acc.
        wrap_steps = (1 << (ACC_W - 2*DATA_W + 2));
        repeat (wrap_steps + 2) step(0, 0, 1, MIN_VALUE, MIN_VALUE);
        phase = "negative accumulator wraparound";
        step(0, 1, 0, 0, 0);
        // With 1-bit signed operands {-1,0}, no negative product is possible.
        if (DATA_W > 1)
            repeat (2*wrap_steps + 2) step(0, 0, 1, MIN_VALUE, MAX_VALUE);

        phase = "deterministic random sequences";
        for (int index = 0; index < 4000; index++) begin
            // Mostly valid traffic and bubbles, with occasional reset/clear.
            controls = 0;
            controls[0] = (random_word() % 4 != 0);
            controls[1] = (random_word() % 31 == 0);
            controls[2] = (random_word() % 47 == 0);
            random_a = random_operand();
            random_b = random_operand();
            step(controls[2], controls[1], controls[0], random_a, random_b);
        end
        phase = "final reset, idle, and restart";
        step(1, 0, 1, MIN_VALUE, MIN_VALUE);
        repeat (5) step(0, 0, 0, MAX_VALUE, MIN_VALUE);
        step(0, 0, 1, MIN_VALUE, MIN_VALUE);
        step(0, 1, 0, 0, 0);
        step(0, 0, 1, MAX_VALUE, MIN_VALUE);

        // Guard against accidentally deleting or bypassing whole test phases.
        if (control_transitions !== {64{1'b1}} || positive_wraps == 0 ||
            (DATA_W > 1 && negative_wraps == 0) ||
            (DATA_W <= 8 && operand_pairs != (1 << (2*DATA_W))))
            $fatal(1, "Test coverage incomplete D=%0d A=%0d", DATA_W, ACC_W);
        $display("CHECKED: PE D=%0d A=%0d seed=%08h cycles=%0d pairs=%0d controls=64/64 signed wraps=+%0d/-%0d",
                 DATA_W, ACC_W, seed, cycles, operand_pairs, positive_wraps, negative_wraps);
        done = 1;
    end
endmodule
module pe_tb;
    wire [6:0] done;
    pe_test_case #(.DATA_W(1),  .ACC_W(2),  .CASE_ID(0)) one_bit      (done[0]);
    pe_test_case #(.DATA_W(2),  .ACC_W(4),  .CASE_ID(1)) two_bit      (done[1]);
    pe_test_case #(.DATA_W(4),  .ACC_W(11), .CASE_ID(2)) odd_width    (done[2]);
    pe_test_case #(.DATA_W(8),  .ACC_W(16), .CASE_ID(3)) tight_acc    (done[3]);
    pe_test_case #(.DATA_W(8),  .ACC_W(32), .CASE_ID(4)) default_width(done[4]);
    pe_test_case #(.DATA_W(17), .ACC_W(40), .CASE_ID(5)) wide         (done[5]);
    pe_test_case #(.DATA_W(33), .ACC_W(72), .CASE_ID(6)) wider_than_64(done[6]);

    initial begin
        // Default trace covers the readable cases, control transitions and boundaries.
        // PE_WAVES records the entire run for debugging a later failure (large file).
        $dumpfile("waves.vcd");
        $dumpvars(0, one_bit.dut, two_bit.dut, odd_width.dut, tight_acc.dut,
                     default_width.dut, wide.dut, wider_than_64.dut);
        #10000;
        if (!$test$plusargs("PE_WAVES")) $dumpoff;
    end
    initial begin
        wait (&done);
        $display("PASS: PE acceptance suite (7 configurations; all checks complete)");
        $finish;
    end
    initial begin
        #20000000;
        $fatal(1, "PE testbench timeout: completed configurations=%b", done);
    end
endmodule
