# File:        synth.tcl
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Genus synthesis of one design at one Liberty corner. Inputs are environment variables from flow.env, written by make.

# value of an environment variable, or a default when it is unset or empty
proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} { return $::env($name) }
    return $default
}
# set a root attribute; warn (do not stop) if this Genus version does not know it
proc try_db {attr value} {
    if {[catch {set_db $attr $value} err]} { puts "SB-WARNING: could not set $attr: $err" }
}

set top    $::env(TOP)                    ;# top module
set out    [env_or OUT_DIR .]             ;# output directory (the build directory)
set effort [env_or SYNTH_EFFORT medium]   ;# low, medium or high
set adder  [env_or SYNTH_ADDER auto]      ;# auto or ripple
set retime [env_or SYNTH_RETIME 0]        ;# 1 = move registers across logic
puts "SB: top=$top  lib=[file tail $::env(LIB_SYNTH)]  effort=$effort  adder=$adder  retime=$retime"

# --- 1. settings ---
try_db hdl_error_on_blackbox true         ;# a missing module is an error, not an empty box
try_db hdl_error_on_latch true            ;# an inferred latch is an error
try_db hdl_track_filename_row_col true    ;# messages give file and line
set_db syn_generic_effort $effort
set_db syn_map_effort $effort
set_db syn_opt_effort $effort

# --- 2. libraries: standard cells, tie cells and hard macros at the synthesis corner ---
read_libs [concat $::env(LIB_SYNTH) [env_or LIB_EXTRA ""] [env_or MACRO_LIBS_SYNTH ""]]
foreach pattern [env_or DONT_USE ""] {
    set cells [get_db base_cells $pattern]
    if {[llength $cells] > 0} { set_db $cells .dont_use true }
}

# --- 3. read and elaborate the RTL ---
set_db init_hdl_search_path [env_or RTL_INCDIRS ""]   ;# `include directories
set define_args {}
foreach d [env_or RTL_DEFINES ""] { lappend define_args -define $d }
read_hdl -language sv {*}$define_args $::env(RTL_FILES)

set params {}
foreach p [env_or RTL_PARAMS ""] { lappend params [split $p =] }
if {[llength $params] > 0} {
    elaborate -parameters $params $top
} else {
    elaborate $top
}
# parameter values can be added to the design name; keep the plain top name
set design [get_db designs]
if {[get_db $design .name] ne $top} { rename_obj $design $top }
check_design -unresolved

# ripple-carry adders: set the architecture of every adder and subtractor Genus created from the RTL
if {$adder eq "ripple"} {
    set n 0
    foreach h [get_db hinsts] {
        if {[string match *add_* [get_db $h .name]] || [string match *sub_* [get_db $h .name]]} {
            if {![catch {set_db $h .user_sub_arch ripple}]} { incr n }
        }
    }
    puts "SB: SYNTH_ADDER=ripple set on $n adder instances"
    if {$n == 0} { puts "SB-WARNING: no adder took SYNTH_ADDER=ripple (see track/README.md, First run checklist)" }
}
if {$retime} {
    if {[catch {set_db [get_db designs] .retime true} err]} { puts "SB-WARNING: retiming not enabled: $err" }
}

# --- 4. constraints ---
read_sdc $::env(SDC_FILE)

# --- 5. synthesis: generic gates, then library cells, then optimization ---
syn_generic
syn_map
syn_opt

# constant 0 and 1 from tie cells instead of direct connections to the supply
set tiehi [env_or TIEHI_CELL ""]
set tielo [env_or TIELO_CELL ""]
if {$tiehi ne "" && $tielo ne ""} {
    if {[catch {add_tieoffs -high $tiehi -low $tielo} err]} {
        puts "SB-WARNING: no tie cells added ($err); constants stay 1'b0/1'b1 in the netlist"
    }
}

# --- 6. checks and reports ---
check_design -all            > $out/check_design.rpt
check_timing_intent -verbose > $out/check_timing.rpt
report_timing -max_paths 10 -nworst 1 > $out/timing.rpt
report_area                  > $out/area.rpt
report_gates                 > $out/gates.rpt
report_qor                   > $out/qor.rpt
report_dp                    > $out/datapath.rpt
report_power                 > $out/power.rpt

# --- 7. netlist, constraints as Genus applied them, and the Conformal dofile ---
write_hdl > $out/netlist.v
write_sdc > $out/netlist.sdc
write_do_lec -golden_design rtl -revised_design $out/netlist.v -logfile $out/lec.log > $out/genus_lec.do

puts "SB: synthesis done, wrote $out/netlist.v"
exit
