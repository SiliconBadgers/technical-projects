`timescale 1ns/1ps
// Completed examples for intro/README.md#stage-1-digital-logic.
module logic_basics (
    input  logic clk, rst, a, b, select_b, start,
    output logic both_high, selected, q, busy
);
    assign both_high = a & b;
    assign selected = select_b ? b : a;
    // Synchronous, active-high reset. q samples selected on a rising edge.
    always_ff @(posedge clk) begin
        if (rst) // we can omit the begin/end block if it is just one line
            q <= 1'b0;
        else
            q <= selected;
    end
    // busy stores the state: 0 means idle, 1 means busy.
    always_ff @(posedge clk) begin
        if (rst)
            busy <= 1'b0;
        else if (busy)
            busy <= 1'b0;
        else
            busy <= start;
    end
endmodule
