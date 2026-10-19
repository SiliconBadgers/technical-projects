// File:        tb_top.sv
// Author:      Isaac Hagedorn
// Date:        2026-01-17
// Description: Testbench top: clock, reset, DUT and run_test. Starting point for Lab 1.
`include "uvm_macros.svh"

module tb_top;
  import uvm_pkg::*;
  import sa_tb_pkg::*;

  localparam int N = 4, DATA_W = 8, ACC_W = 32;

  logic clk = 1'b0;
  always #5ns clk = ~clk;               // 100 MHz

  logic rst_n;

  // DUT signals (TODO: replace with your interfaces)
  logic                       wr_valid = 1'b0, wr_ready;
  logic [$clog2(N+1)-1:0]     wr_addr  = '0;
  logic [N*DATA_W-1:0]        wr_data  = '0;
  logic                       a_valid  = 1'b0, a_ready;
  logic [N*DATA_W-1:0]        a_data   = '0;
  logic                       r_valid,  r_ready = 1'b1;
  logic [N*ACC_W-1:0]         r_data;
  logic                       busy;

  sb_systolic_array #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
    .clk, .rst_n,
    .wr_valid, .wr_ready, .wr_addr, .wr_data,
    .a_valid,  .a_ready,  .a_data,
    .r_valid,  .r_ready,  .r_data,
    .busy
  );

  // Placeholder reset (TODO)
  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    #1ns rst_n = 1'b1;
  end

  initial begin
`ifdef SA_WAVES
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
