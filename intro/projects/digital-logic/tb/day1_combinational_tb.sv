`timescale 1ns/1ps
module day1_combinational_tb;
    logic a = 0, b = 0, c = 0, sel = 0;
    wire gate_and, gate_or, gate_xor, gate_nand, gate_nor, gate_xnor;
    wire sum, carry, mux_out, out1, out2;
    logic [1:0] expected_total;
    day1_combinational dut (.*);

    task automatic interval(input logic [2:0] abc);
        {a, b, c} = abc;
        #10;
    endtask
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, day1_combinational_tb);
        // First 80 ns: the eight input intervals drawn on slide 21.
        // The slide has no numeric timescale; 10 ns per interval is for this demo.
        interval(3'b000);
        interval(3'b101);
        interval(3'b011);
        interval(3'b110);
        interval(3'b001);
        interval(3'b111);
        interval(3'b010);
        interval(3'b100);
        // After 80 ns, check all 16 combinations of {a, b, c, sel}.
        // Arithmetic and comparisons provide expectations independent of the RTL equations.
        for (int i = 0; i < 16; i++) begin
            {a, b, c, sel} = i[3:0];
            #1;
            expected_total = {1'b0, a} + {1'b0, b} + {1'b0, c};
            if ({carry, sum} !== expected_total)
                $fatal(1, "full adder failed at input %b", {a,b,c});
            if (gate_and !== (a == 1 && b == 1) ||
                gate_or !== (a == 1 || b == 1) || gate_xor !== (a != b) ||
                gate_nand !== (a == 0 || b == 0) ||
                gate_nor !== (a == 0 && b == 0) || gate_xnor !== (a == b))
                $fatal(1, "gate truth table failed at input %b", {a,b});
            if ((sel == 1 && mux_out !== a) || (sel == 0 && mux_out !== b))
                $fatal(1, "mux failed at input %b", {a,b,sel});
            if (out1 !== (expected_total >= 2 || c == 1) ||
                out2 !== (a != c && b == 1))
                $fatal(1, "waveform expression failed at input %b", {a,b,c});
            #9;
        end
        $display("PASS: Day 1 gates, full adder, mux, and waveform exercise (16 combinations)");
        $finish;
    end
endmodule
