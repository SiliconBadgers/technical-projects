`timescale 1ns/1ps

module apb_zero_strobe_tb;
  reg pclk = 0;
  always #5 pclk = ~pclk;
  reg presetn = 0, psel = 0, penable = 0, pwrite = 0;
  reg [7:0] paddr = 0;
  reg [31:0] pwdata = 0;
  reg [3:0] pstrb = 0;
  wire [31:0] prdata;
  wire pready, pslverr, irq;
  reg [31:0] before_write, stopped_value;

  sb_apb_regs dut (.*);

  task automatic reset_dut;
    @(posedge pclk); #1;
    presetn = 0; psel = 0; penable = 0;
    repeat (2) @(posedge pclk);
    #1 presetn = 1;
  endtask

  task automatic write_apb(input [7:0] addr, input [31:0] data, input [3:0] strb);
    @(posedge pclk); #1;
    psel = 1; penable = 0; pwrite = 1;
    paddr = addr; pwdata = data; pstrb = strb;
    @(posedge pclk); #1; penable = 1;
    @(negedge pclk);
    before_write = dut.tmr_value;
    if (!pready || pslverr) $fatal(1, "Unexpected APB write response");
    @(posedge pclk); #1; psel = 0; penable = 0;
  endtask

  initial begin
    // A disabled counter must keep its current value, even when it differs from LOAD.
    reset_dut();
    write_apb('h0c, 20, 'hf);
    write_apb('h04, 1, 1);
    repeat (3) @(posedge pclk);
    write_apb('h04, 0, 1);
    stopped_value = dut.tmr_value;
    if (stopped_value == 20) $fatal(1, "Timer did not count before stopping");
    write_apb('h0c, 'hffffffff, 0);
    if (dut.tmr_value !== stopped_value || dut.tmr_load !== 20)
      $fatal(1, "Zero-strobe write changed disabled timer");

    // An enabled timer must still decrement on the zero-strobe completion edge.
    write_apb('h0c, 100, 'hf);
    write_apb('h04, 1, 1);
    write_apb('h0c, 'hffffffff, 0);
    if (dut.tmr_value !== before_write - 1 || dut.tmr_load !== 100)
      $fatal(1, "Zero-strobe write interrupted countdown");

    // A zero-strobe write at expiry must preserve the interrupt and one-shot stop.
    reset_dut();
    write_apb('h0c, 2, 'hf);
    write_apb('h18, 1, 1);
    write_apb('h04, 1, 1);
    write_apb('h0c, 99, 0);
    if (before_write !== 0 || dut.tmr_value !== 2 || !irq || dut.ctrl_en !== 0)
      $fatal(1, "Zero-strobe write suppressed one-shot expiry");

    // Auto-reload also expires normally and keeps EN set.
    reset_dut();
    write_apb('h0c, 2, 'hf);
    write_apb('h18, 1, 1);
    write_apb('h04, 3, 1);
    write_apb('h0c, 99, 0);
    if (before_write !== 0 || dut.tmr_value !== 2 || !irq || dut.ctrl_en !== 1)
      $fatal(1, "Zero-strobe write suppressed auto-reload expiry");

    // Real strobed writes still reload the full counter using the merged byte lanes.
    reset_dut();
    write_apb('h0c, 'h12345678, 'hf);
    write_apb('h0c, 'haabbccdd, 'h4);
    if (dut.tmr_load !== 'h12bb5678 || dut.tmr_value !== 'h12bb5678)
      $fatal(1, "Partial-strobe load did not merge and reload");

    // A strobed write retains priority over expiry.
    reset_dut();
    write_apb('h0c, 2, 'hf);
    write_apb('h18, 1, 1);
    write_apb('h04, 1, 1);
    write_apb('h0c, 9, 1);
    if (before_write !== 0 || dut.tmr_value !== 9 || irq || dut.ctrl_en !== 1)
      $fatal(1, "Strobed write lost priority over expiry");

    $display("PASS: APB zero-strobe, countdown, expiry and partial-write checks");
    $finish;
  end

  initial begin
    #10000;
    $fatal(1, "APB probe timed out");
  end
endmodule
