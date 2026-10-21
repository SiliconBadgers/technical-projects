// File:        sb_sram_256x8.v
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: Black box of the 256x8 single-port weight SRAM, for synthesis and LEC. Fake macro for training only.
(* blackbox *)
module sb_sram_256x8 (
  input        clk,
  input        ce_in,     // chip enable (acts on the rising clk edge)
  input        we_in,     // 1 = write, 0 = read
  input  [7:0] addr_in,
  input  [7:0] wd_in,     // write data
  output [7:0] rd_out     // read data, held until the next read
);
endmodule
