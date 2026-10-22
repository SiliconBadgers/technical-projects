// File:        q4_longint_negative_bins.sv
// Author:      Isaac Hagedorn
// Date:        2025-11-15
// Description: Verilator quirk Q4: negative bins on a longint coverpoint never hit.
module q4;
  longint v;
  covergroup cg; cp: coverpoint v { bins neg = {[-100:-1]}; bins pos = {[1:100]}; } endgroup
  cg g = new;
  initial begin
    v = -5; g.sample(); v = 5; g.sample();
    $display("QUIRK-RESULT q4 CHECK-COVERAGE");   // result is read from coverage.dat
    $finish;
  end
endmodule
