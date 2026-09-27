`timescale 1ns/1ps
// Companion to Day 1 slides 10-21. See intro/README.md#stage-1-digital-logic.
module day1_combinational (
    input wire a, b, c, sel,
    output wire gate_and, gate_or, gate_xor,
    output wire gate_nand, gate_nor, gate_xnor,
    output wire sum, carry, mux_out, out1, out2
);
    assign gate_and = a & b;
    assign gate_or = a | b;
    assign gate_xor = a ^ b;
    assign gate_nand = ~(a & b);
    assign gate_nor = ~(a | b);
    assign gate_xnor = ~(a ^ b);
    // Slide 15: draw this circuit before looking at the slide 16 diagram.
    assign sum = a ^ b ^ c;
    assign carry = (a & b) | (b & c) | (a & c);
    // Slide 17: a is selected when sel is 1; b is selected when sel is 0.
    assign mux_out = sel ? a : b;
    // Slide 21: predict these outputs for the given input waveform.
    assign out1 = (a & b) | c;
    assign out2 = (a ^ c) & b;
endmodule
