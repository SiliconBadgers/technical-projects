# File:        sta.tcl
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: PrimeTime timing analysis of the pre-layout netlist at one corner. Inputs are environment variables from sta_<corner>.env (written by make); run it from the build folder.

# value of an environment variable, or a default when it is unset or empty
proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} { return $::env($name) }
    return $default
}

set top    $::env(TOP)              ;# top module
set corner $::env(CORNER)           ;# tt, ss or ff
set rpt    sta_${corner}.rpt        ;# text report

# --- 1. libraries, netlist, constraints ---
set_app_var search_path [list .]
set_app_var link_path   [concat * $::env(CELL_DB) [env_or MACRO_DBS ""]]   ;# .db files for this corner
read_verilog $::env(NETLIST)
current_design $top
link_design $top                    ;# bind every instance to a library cell
# source, not read_sdc: read_sdc's SDC interpreter has no remove_from_collection (CMD-005)
source -echo $::env(SDC_FILE)
update_timing -full

# --- 2. report ---
# append a section title to the report
proc section {file title} {
    set fh [open $file a]
    puts $fh "\n[string repeat = 78]\n$title\n[string repeat = 78]"
    close $fh
}
close [open $rpt w]

section $rpt "check_timing: unconstrained endpoints, missing input delays, loops"
redirect -append $rpt { check_timing -verbose }
section $rpt "Analysis coverage: timing checks met, violated, untested (untested = not timed)"
redirect -append $rpt { report_analysis_coverage }
redirect -append $rpt { report_analysis_coverage -status_details untested }
section $rpt "Setup (max delay): 10 worst paths"
# with -max_paths, PrimeTime lists only violating paths unless -slack_lesser_than is given
redirect -append $rpt { report_timing -delay_type max -max_paths 10 -slack_lesser_than infinity -input_pins -nets -transition_time -capacitance -significant_digits 3 }
section $rpt "Hold (min delay): 10 worst paths"
redirect -append $rpt { report_timing -delay_type min -max_paths 10 -slack_lesser_than infinity -input_pins -nets -transition_time -capacitance -significant_digits 3 }
section $rpt "Slack summary (WNS, TNS, number of violating paths)"
redirect -append $rpt { report_global_timing }
section $rpt "All violators (setup, hold, max transition, max capacitance, max fanout)"
redirect -append $rpt { report_constraint -all_violators }

# flip-flop reset/set pins the asynchronous reset port reaches through buffers only
# (a reset synchronizer leaves just its own flip-flops here)
set reset_port [env_or ASYNC_RESET_PORT ""]
set reset_pins ""
if {$reset_port ne ""} {
    set reached [all_fanout -from [get_ports $reset_port] -flat -endpoints_only]
    set direct  [remove_from_collection -intersect $reached [all_registers -async_pins]]
    set reset_pins [sizeof_collection $direct]
    section $rpt "Flip-flop reset/set pins driven straight from port $reset_port: $reset_pins"
    set fh [open $rpt a]
    foreach_in_collection pin $direct { puts $fh "  [get_object_name $pin]" }
    close $fh
}

# --- 3. summary for make qor ---
# worst slack of one check type (max = setup, min = hold); empty if nothing is timed
proc worst_slack {type} {
    set path [get_timing_paths -delay_type $type -max_paths 1]
    if {[sizeof_collection $path] == 0} { return "" }
    return [get_attribute $path slack]
}
# sum of the negative slacks, worst path per endpoint
proc total_negative_slack {type} {
    set tns 0.0
    foreach_in_collection path [get_timing_paths -delay_type $type -max_paths 100000 -slack_lesser_than 0] {
        set tns [expr {$tns + [get_attribute $path slack]}]
    }
    return $tns
}

set period ""
foreach_in_collection clk [all_clocks] { set period [get_attribute $clk period]; break }
set setup_ws [worst_slack max]
set hold_ws  [worst_slack min]

set fh [open sta_${corner}.txt w]
puts $fh "corner $corner"
puts $fh "period_ns $period"
puts $fh "setup_wns_ns $setup_ws"
puts $fh "setup_tns_ns [total_negative_slack max]"
puts $fh "hold_wns_ns $hold_ws"
puts $fh "hold_tns_ns [total_negative_slack min]"
if {$reset_port ne ""} { puts $fh "reset_port_async_pins $reset_pins" }
close $fh

puts "SB: corner=$corner period=${period}ns setup_slack=$setup_ws hold_slack=$hold_ws -> $rpt"
# leave the shell, unless you ran the script by hand with SB_STAY=1
if {[env_or SB_STAY 0] ne "1"} { exit }
