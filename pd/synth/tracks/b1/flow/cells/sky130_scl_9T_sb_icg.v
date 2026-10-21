// File:        sky130_scl_9T_sb_icg.v
// Author:      Isaac Hagedorn
// Date:        2026-10-09
// Description: sb_icg clock-gate wrapper for sky130_scl_9T: instantiates the library's integrated clock-gating cell ICGPRECX1.
//              Read by synthesis and LEC; ibex's prim_clock_gating.sv uses it when SYNTHESIS is defined.
module sb_icg (
  input  clk_i,
  input  en_i,
  input  test_en_i,
  output clk_o
);
  // ECK = CK gated by a latch that holds (E | TE) while CK is high
  ICGPRECX1 u_icg (.CK(clk_i), .E(en_i), .TE(test_en_i), .ECK(clk_o));
endmodule
