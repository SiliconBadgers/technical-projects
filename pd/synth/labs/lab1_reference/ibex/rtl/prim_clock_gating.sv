// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
// File:        prim_clock_gating.sv
// Author:      Isaac Hagedorn
// Date:        2026-10-09
// Description: Clock gate with a latch-based enable. Modified from lowRISC prim_clock_gating.

module prim_clock_gating (
  input  logic clk_i,
  input  logic en_i,
  input  logic test_en_i,
  output logic clk_o
);

`ifdef SYNTHESIS
  // Library clock-gating cell. Each track provides sb_icg for its library.
  sb_icg u_icg (
    .clk_i     (clk_i),
    .en_i      (en_i),
    .test_en_i (test_en_i),
    .clk_o     (clk_o)
  );
`else
  // RTL simulation model.
  logic en_latch;
  always_latch begin
    if (!clk_i) en_latch = en_i | test_en_i;
  end
  assign clk_o = en_latch & clk_i;
`endif

endmodule
