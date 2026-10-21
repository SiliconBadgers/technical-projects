// File:        sky130scl_phycells.v
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: Functional models of the sky130_scl_9T TIEHI and TIELO cells for gate-level simulation. The release ships no Verilog for them.
`timescale 1ns/10ps
`celldefine
module TIEHI (output Y);
  assign Y = 1'b1;
endmodule
`endcelldefine

`celldefine
module TIELO (output Y);
  assign Y = 1'b0;
endmodule
`endcelldefine
