// File:        tb_top.sv
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: Testbench top: clock, reset, DUT and run_test. Starting point for Lab 1.
`include "uvm_macros.svh"

module tb_top;
  import uvm_pkg::*;
  import apb_tb_pkg::*;

  localparam int ADDR_W = 8, DATA_W = 32;

  logic pclk = 1'b0;
  always #5ns pclk = ~pclk;             // 100 MHz

  logic presetn;

  // DUT signals (TODO: replace with your APB interface)
  logic                psel    = 1'b0;
  logic                penable = 1'b0;
  logic                pwrite  = 1'b0;
  logic [ADDR_W-1:0]   paddr   = '0;
  logic [DATA_W-1:0]   pwdata  = '0;
  logic [DATA_W/8-1:0] pstrb   = '0;
  logic [DATA_W-1:0]   prdata;
  logic                pready, pslverr;
  logic                irq;

  sb_apb_regs #(.ADDR_W(ADDR_W), .DATA_W(DATA_W)) dut (
    .pclk, .presetn,
    .psel, .penable, .pwrite, .paddr, .pwdata, .pstrb,
    .prdata, .pready, .pslverr,
    .irq
  );

  // Placeholder reset (TODO)
  initial begin
    presetn = 1'b0;
    repeat (5) @(posedge pclk);
    #1ns presetn = 1'b1;
  end

  initial begin
`ifdef APB_WAVES
`ifdef VERILATOR
    $dumpfile("waves.fst");             // FST for Verilator
`else
    $dumpfile("waves.vcd");
`endif
    $dumpvars(0, tb_top);
`endif
    run_test();
  end
endmodule
