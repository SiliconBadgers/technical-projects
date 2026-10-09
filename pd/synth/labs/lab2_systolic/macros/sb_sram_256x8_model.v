// File:        sb_sram_256x8_model.v
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: Behavioural model of the fake sb_sram_256x8 for RTL and gate-level simulation.
module sb_sram_256x8 (
  input            clk,
  input            ce_in,
  input            we_in,
  input      [7:0] addr_in,
  input      [7:0] wd_in,
  output reg [7:0] rd_out
);
  reg [7:0] mem [0:255];
  integer i;
  initial begin
    // Power-up contents unknown.
    for (i = 0; i < 256; i = i + 1) mem[i] = 8'bx;
    rd_out = 8'bx;
  end
  always @(posedge clk) begin
    if (ce_in) begin
      if (we_in) mem[addr_in] <= wd_in;
      else       rd_out <= mem[addr_in];
    end
  end
endmodule
