// File:        q3_implication_signed_range.sv
// Author:      Isaac Hagedorn
// Date:        2025-11-15
// Description: Verilator quirk Q3: `cond -> x inside {[-4:4]}` is unsatisfiable for signed x.
class C; rand logic signed [7:0] x; int mode = 1; constraint c { (mode == 1) -> x inside {[-4:4]}; } endclass
module q3;
  initial begin
    C c = new;
    if (c.randomize()) $display("QUIRK-RESULT q3 FIXED");
    else $display("QUIRK-RESULT q3 PRESENT randomize() failed");
    $finish;
  end
endmodule
