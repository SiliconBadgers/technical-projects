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
        if (rst) q <= 1'b0;
        else     q <= selected;
    end
    typedef enum logic {IDLE, BUSY} state_t;
    state_t state, next_state;
    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = BUSY;
            BUSY: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    always_ff @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end
    assign busy = (state == BUSY);
endmodule
