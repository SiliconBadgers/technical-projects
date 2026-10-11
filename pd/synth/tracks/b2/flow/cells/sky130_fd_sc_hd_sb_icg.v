// File:        sky130_fd_sc_hd_sb_icg.v
// Author:      Isaac Hagedorn
// Date:        2026-10-09
// Description: sb_icg clock-gate wrapper for sky130_fd_sc_hd: instantiates the library cell sky130_fd_sc_hd__sdlclkp_1. Read by synthesis and LEC when the RTL is compiled with SYNTHESIS.
module sb_icg (
  input  clk_i,
  input  en_i,
  input  test_en_i,
  output clk_o
);
  sky130_fd_sc_hd__sdlclkp_1 u_icg (.CLK(clk_i), .GATE(en_i), .SCE(test_en_i), .GCLK(clk_o));
endmodule
