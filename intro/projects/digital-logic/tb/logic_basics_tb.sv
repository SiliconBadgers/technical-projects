`timescale 1ns/1ps
module logic_basics_tb;
    logic clk = 0;
    logic rst = 1, a = 0, b = 0, select_b = 0, start = 0;
    wire both_high, selected, q, busy;
    logic_basics dut (.*);
    always #5 clk = ~clk;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, logic_basics_tb);
        @(posedge clk); #1;
        if (q !== 0 || busy !== 0) $fatal(1, "reset failed");
        @(negedge clk); rst = 0;
        // Exhaust every combination of a, b, and select_b.
        for (int i = 0; i < 8; i++) begin
            {a, b, select_b} = i[2:0];
            #1;
            if (both_high !== (a & b)) $fatal(1, "AND failed");
            if (selected !== (select_b ? b : a)) $fatal(1, "mux failed");
            @(posedge clk); #1;
            if (q !== selected) $fatal(1, "register failed");
            @(negedge clk);
        end
        start = 1;
        @(posedge clk); #1;
        if (busy !== 1) $fatal(1, "IDLE -> BUSY failed");
        @(negedge clk); start = 0;
        @(posedge clk); #1;
        if (busy !== 0) $fatal(1, "BUSY -> IDLE failed");
        $display("PASS: digital logic smoke");
        $finish;
    end
    initial begin
        #1000;
        $fatal(1, "timeout");
    end
endmodule
