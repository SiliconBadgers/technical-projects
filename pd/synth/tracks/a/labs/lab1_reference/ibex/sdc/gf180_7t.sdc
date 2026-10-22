# File:        gf180_7t.sdc
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: ibex timing constraints for gf180_7t, from the ORFS gf180 ibex SDC. Adapted from OpenROAD-flow-scripts (BSD-3).

current_design ibex_core

set clk_name core_clock
set clk_port_name clk_i
# NOTE(spec-mismatch): team period, not ORFS's 8.0 ns (min passing at ss +5 %, 2026-10-08).
set clk_period [sb_clock_period 44]
set clk_io_pct 0.2

set clk_port [get_ports $clk_port_name]

create_clock -name $clk_name -period $clk_period $clk_port
set clk_io_name vclk_$clk_name
create_clock -name $clk_io_name -period $clk_period
set_clock_latency 1.120 [get_clocks $clk_name]
set_clock_latency 1.120 [get_clocks $clk_io_name]

set non_clock_inputs [all_inputs -no_clocks]

set_input_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name [all_outputs]
set_false_path -from [get_ports {rst_ni}]

# --- team defaults (added to ORFS) ---
# Pre-layout margin: setup 10 % of the period, hold 0.05 ns.
set_clock_uncertainty -setup [expr {0.10 * $clk_period}] [all_clocks]
set_clock_uncertainty -hold 0.05 [all_clocks]

# Inputs driven by a library buffer (cell from the platform file).
# Except rst_ni: an ideal net until physical design buffers it.
set data_inputs {}
foreach port [all_inputs -no_clocks] {
    if {[get_name $port] ne "rst_ni"} { lappend data_inputs $port }
}
set_driving_cell -lib_cell $sb_driving_cell -pin $sb_driving_pin $data_inputs
set_input_transition 0 [get_ports rst_ni]

# Output load: four buffer inputs.
set_load [expr {4 * [sb_pin_cap $sb_load_cell $sb_load_pin]}] [all_outputs]
