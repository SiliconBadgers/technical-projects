# File:        sky130_scl_9T.sdc
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: gcd timing constraints for sky130_scl_9T (plain SDC). Adapted from the OpenROAD-flow-scripts gcd SDC (BSD-3).

# clock period in ns: starting point (Track A's sky130_scl_9T number); recalibrate on first run.
# make CLOCK_PERIOD=<ns> replaces this line.
set clk_period 6.0
# input and output delay: 20 % of the period
set clk_io_pct 0.2

# core clock on port clk, and a virtual clock for the I/O delays
create_clock -name core_clock -period $clk_period [get_ports clk]
create_clock -name vclk_core_clock -period $clk_period
set_clock_latency 0.290 [get_clocks {core_clock vclk_core_clock}]

# every input except the clock, and every output
set data_inputs [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay  [expr {$clk_period * $clk_io_pct}] -clock vclk_core_clock $data_inputs
set_output_delay [expr {$clk_period * $clk_io_pct}] -clock vclk_core_clock [all_outputs]

# pre-layout margin: setup 10 % of the period, hold 0.05 ns
set_clock_uncertainty -setup [expr {0.10 * $clk_period}] [all_clocks]
set_clock_uncertainty -hold 0.05 [all_clocks]

# inputs driven by a BUFX2 output
set_driving_cell -lib_cell BUFX2 -pin Y $data_inputs
# output load: four BUFX4 inputs, 4 x 0.00317 pF (BUFX4/A at ss)
set_load 0.0127 [all_outputs]
