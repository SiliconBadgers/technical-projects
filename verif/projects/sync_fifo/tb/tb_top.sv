// File:        tb_top.sv
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: Testbench top: clock, reset, DUT and run_test. Starting point for Lab 1.
`include "uvm_macros.svh"

module tb_top;
  import uvm_pkg::*;
  import fifo_tb_pkg::*;

  // make DEPTH=<n> WIDTH=<w> pass +define+FIFO_DEPTH / FIFO_WIDTH
`ifdef FIFO_DEPTH
  localparam int DEPTH = `FIFO_DEPTH;
`else
  localparam int DEPTH = 6;
`endif
`ifdef FIFO_WIDTH
  localparam int WIDTH = `FIFO_WIDTH;
`else
  localparam int WIDTH = 8;
`endif

  logic clk = 1'b0;
  always #5ns clk = ~clk;               // 100 MHz

  logic rst_n;

  // DUT signals (TODO: replace with your interfaces)
  logic                       flush     = 1'b0;
  logic                       in_valid  = 1'b0, in_ready;
  logic [WIDTH-1:0]           in_data   = '0;
  logic                       out_valid, out_ready = 1'b0;
  logic [WIDTH-1:0]           out_data;
  logic [$clog2(DEPTH+1)-1:0] count;
  logic                       almost_full, almost_empty;

  sb_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk, .rst_n, .flush,
    .in_valid,  .in_ready,  .in_data,
    .out_valid, .out_ready, .out_data,
    .count, .almost_full, .almost_empty
  );

  // Placeholder reset (TODO)
  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    #1ns rst_n = 1'b1;
  end

  initial begin
`ifdef FIFO_WAVES
    $dumpfile("waves.fst");
    $dumpvars(0, tb_top);
`endif
    run_test();
  end
endmodule
