// File:        gf180_7t_sb_icg.v
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: sb_icg clock-gate wrapper for gf180_7t: instantiates gf180mcu_fd_sc_mcu7t5v0__icgtp_1. Used by the RTL when SYNTHESIS is defined.
module sb_icg (
  input  clk_i,
  input  en_i,
  input  test_en_i,
  output clk_o
);
  gf180mcu_fd_sc_mcu7t5v0__icgtp_1 u_icg (.CLK(clk_i), .E(en_i), .TE(test_en_i), .Q(clk_o));
endmodule
