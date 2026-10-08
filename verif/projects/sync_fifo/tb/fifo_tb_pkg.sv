// File:        fifo_tb_pkg.sv
// Author:      Isaac Hagedorn
// Date:        2026-10-08
// Description: Testbench package. Contains the Lab 0 hello test.
`include "uvm_macros.svh"

package fifo_tb_pkg;
  import uvm_pkg::*;

  // Lab 0 test: runs 200 ns and passes
  class fifo_hello_test extends uvm_test;
    `uvm_component_utils(fifo_hello_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      #200ns;
      `uvm_info("HELLO", "UVM is running and the DUT elaborated", UVM_LOW)
      phase.drop_objection(this);
    endtask

    // PASS/FAIL banner read by scripts/regress.py
    function void report_phase(uvm_phase phase);
      uvm_report_server rs = uvm_report_server::get_server();
      if (rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL) == 0)
        `uvm_info("RESULT", "*** TEST PASSED ***", UVM_NONE)
      else
        `uvm_info("RESULT", "*** TEST FAILED ***", UVM_NONE)
    endfunction
  endclass
endpackage
