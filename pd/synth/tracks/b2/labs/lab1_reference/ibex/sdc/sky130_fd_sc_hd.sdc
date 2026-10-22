# File:        sky130_fd_sc_hd.sdc
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: ibex timing constraints for sky130_fd_sc_hd (Track B2), adapted from OpenROAD-flow-scripts (BSD-3). The period is calibrated: the shortest period that passes setup at ss with DC/PT Y-2026.03 (11.0 ns), plus 5 %.

# clock period in ns (make CLOCK_PERIOD=<ns> replaces this line)
set clk_period 11.6
# share of the period spent outside this block, for inputs and outputs
set clk_io_pct 0.2

# the real clock on port clk_i, and a virtual clock (no port) for the I/O delays
create_clock -name core_clock -period $clk_period [get_ports clk_i]
create_clock -name vclk_core_clock -period $clk_period
set_clock_latency 1.095 [get_clocks {core_clock vclk_core_clock}]

# pre-layout margin: setup 10 % of the period, hold 0.05 ns
set_clock_uncertainty -setup [expr {0.10 * $clk_period}] [all_clocks]
set_clock_uncertainty -hold 0.05 [all_clocks]

# every input except the clock
set non_clock_inputs [remove_from_collection [all_inputs] [get_ports clk_i]]
set_input_delay  [expr {$clk_period * $clk_io_pct}] -clock vclk_core_clock $non_clock_inputs
set_output_delay [expr {$clk_period * $clk_io_pct}] -clock vclk_core_clock [all_outputs]

# inputs are driven by a library buffer, except rst_ni:
# an ideal net until physical design buffers it
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 -pin X [remove_from_collection $non_clock_inputs [get_ports rst_ni]]
set_input_transition 0 [get_ports rst_ni]
# outputs drive four buffer inputs: 4 x 0.0024 pF (sky130_fd_sc_hd__buf_4 pin A, tt Liberty)
set_load 0.0096 [all_outputs]
