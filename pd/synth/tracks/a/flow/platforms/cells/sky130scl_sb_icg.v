// File:        sky130scl_sb_icg.v
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: sb_icg clock-gate wrapper for sky130scl: instantiates ICGPRECX1. Used by the RTL when SYNTHESIS is defined.
module sb_icg (
  input  clk_i,
  input  en_i,
  input  test_en_i,
  output clk_o
);
  ICGPRECX1 u_icg (.CK(clk_i), .E(en_i), .TE(test_en_i), .ECK(clk_o));
endmodule
