`timescale 1ns/1ps
// Student starter. Contract: ../spec/pe.md. This is NOT a completed PE.
module pe #(
    parameter int DATA_W = 8,
    parameter int ACC_W = 32
) (
    input  logic clk, rst, clear, valid_in,
    input  logic signed [DATA_W-1:0] a_in, b_in,
    output logic valid_out,
    output logic signed [DATA_W-1:0] a_out, b_out,
    output logic signed [ACC_W-1:0] acc_out
);
    // TODO: Replace the placeholder with clocked state per spec/pe.md.
    // 1. Synchronous reset > clear > valid input > hold.
    // 2. Compute a signed full-width product and extend it before accumulation.
    // 3. Register forwarded operands and the valid flag.
    // Constant outputs only keep this starter compilable; make pe must fail.
    assign valid_out = 1'b0;
    assign a_out = '0;
    assign b_out = '0;
    assign acc_out = '0;
endmodule
