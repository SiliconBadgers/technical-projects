// File:        q2_dist_with_bound.sv
// Author:      Isaac Hagedorn
// Date:        2025-11-15
// Description: Verilator quirk Q2: dist combined with another constraint on the same variable fails.
class C; rand int unsigned d; int unsigned mx = 4; constraint c { d <= mx; d dist {0 := 8, [1:16] :/ 2}; } endclass
module q2;
  initial begin
    C c = new; int fails = 0;
    repeat (200) if (!c.randomize()) fails++;
    if (fails == 0) $display("QUIRK-RESULT q2 FIXED");
    else $display("QUIRK-RESULT q2 PRESENT %0d/200 randomize() calls failed", fails);
    $finish;
  end
endmodule
