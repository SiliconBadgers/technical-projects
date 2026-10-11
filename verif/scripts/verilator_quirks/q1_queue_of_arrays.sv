// File:        q1_queue_of_arrays.sv
// Author:      Isaac Hagedorn
// Date:        2025-11-15
// Description: Verilator quirk Q1: a queue of unpacked arrays loses data on push/pop.
module q1;
  int qa[$][4];
  initial begin
    int y[4], z[4];
    y = '{1, 2, 3, 4}; qa.push_back(y);
    y = '{5, 6, 7, 8}; qa.push_back(y);
    z = qa.pop_front();
    if (z == '{1, 2, 3, 4} && qa.size() == 1) $display("QUIRK-RESULT q1 FIXED");
    else $display("QUIRK-RESULT q1 PRESENT popped=%p size=%0d", z, qa.size());
    $finish;
  end
endmodule
