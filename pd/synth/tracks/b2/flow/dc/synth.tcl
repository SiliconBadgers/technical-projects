# File:        synth.tcl
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Design Compiler synthesis of one design at one corner. Inputs are environment variables from synth.env (written by make); run it from the build folder.

# value of an environment variable, or a default when it is unset or empty
proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} { return $::env($name) }
    return $default
}

set top       $::env(TOP)                      ;# top module
set rtl_files $::env(RTL_FILES)                ;# RTL files, packages first
set incdirs   [env_or RTL_INCDIRS ""]          ;# folders searched by `include
set defines   [env_or RTL_DEFINES ""]          ;# macros, NAME or NAME=VALUE
set params    [env_or RTL_PARAMS ""]           ;# top-level parameters, NAME=VALUE
set sdc       $::env(SDC_FILE)                 ;# constraints
set cell_db   $::env(CELL_DB)                  ;# standard cells (.db) at the synthesis corner
set macro_dbs [env_or MACRO_DBS ""]            ;# hard macros (.db)
set dont_use  [env_or DONT_USE ""]             ;# cell name patterns synthesis must not use
set compile   [env_or DC_COMPILE compile_ultra] ;# compile_ultra or compile
set retime    [env_or SYNTH_RETIME 0]          ;# 1 = compile_ultra -retime
set extra     [env_or DC_EXTRA ""]             ;# your own Tcl, sourced just before compile

# --- 1. libraries ---
# target_library: cells DC may pick. link_library: where DC looks up every instance.
set_app_var search_path       [concat . $incdirs [get_app_var search_path]]
set_app_var target_library    $cell_db
set_app_var synthetic_library dw_foundation.sldb   ;# DesignWare (adders, multipliers)
set_app_var link_library      [concat * $cell_db $macro_dbs dw_foundation.sldb]

# Formality setup file: DC records here every change it makes
set_svf synth.svf
# time recovery/removal (reset pins) as PrimeTime does; DC skips them by default and leaves the reset tree slow
set_app_var enable_recovery_removal_arcs true

# --- 2. read the RTL ---
define_design_lib WORK -path ./WORK
set_app_var hdlin_check_no_latch true   ;# warn for every inferred latch
set analyze_args [list -format sverilog]
if {[llength $defines]} { lappend analyze_args -define $defines }
analyze {*}$analyze_args $rtl_files

set elab_args {}
if {[llength $params]} { lappend elab_args -parameters [join $params ,] }
elaborate $top {*}$elab_args
# with parameters DC names the design <top>_<params>: give it back its name
if {[get_object_name [current_design]] ne $top} {
    rename_design [get_object_name [current_design]] $top
}
current_design $top
# bind every instance to a module or a library cell
if {![link]} {
    puts "SB-ERROR: link could not resolve every instance (see the LINK warnings above)"
}

# --- 3. constraints and checks before compile ---
# source, not read_sdc: read_sdc's SDC interpreter has no remove_from_collection (CMD-005)
source -echo $sdc
redirect synth_check_design.rpt { check_design }
redirect synth_check_timing.rpt { check_timing }
# nets with more than 16 loads as the RTL wrote them (Lab 2 task 6); compile then buffers or duplicates them
redirect synth_fanout.rpt { report_net_fanout -threshold 16 -nosplit [get_nets *] }   ;# top-level nets; loads counted through the hierarchy

# --- 4. compile ---
foreach pattern $dont_use {
    set cells [get_lib_cells -quiet */$pattern]
    if {[sizeof_collection $cells] > 0} { set_dont_use $cells }
}
set_fix_multiple_port_nets -all -buffer_constants   ;# no assign statements in the netlist
if {$extra ne ""} { source $extra }
set compile_cmd [list $compile]
if {$retime && $compile eq "compile_ultra"} { lappend compile_cmd -retime }
{*}$compile_cmd

# --- 5. reports ---
change_names -rules verilog -hierarchy   ;# legal Verilog names, used in reports and netlist
redirect synth_timing.rpt     { report_timing -delay_type max -max_paths 10 -input_pins -nets -transition_time -capacitance -significant_digits 3 }
redirect synth_area.rpt       { report_area -nosplit }
redirect synth_cells.rpt      { report_reference -nosplit }
redirect synth_qor.rpt        { report_qor }
redirect synth_violators.rpt  { report_constraint -all_violators }
redirect synth_resources.rpt  { report_resources }   ;# DesignWare parts (adders, multipliers) and their structure
# the same nets after compile: -tree counts the loads behind the buffers compile added
# (one tree in detail: report_buffer_tree -net <net> at the dc_shell prompt, SB_STAY=1)
redirect -append synth_fanout.rpt { report_net_fanout -tree -threshold 16 -nosplit }
# leakage and an activity-free power estimate (needs a Power Compiler license)
if {[catch { redirect synth_power.rpt { report_power } }]} {
    puts "SB: report_power not available here (license?): no synth_power.rpt"
}

# latches (level-sensitive registers) left in the netlist
set latches [all_registers -level_sensitive]
set fh [open synth_latches.rpt w]
puts $fh "Latches in the netlist: [sizeof_collection $latches]"
foreach_in_collection cell $latches {
    puts $fh "  [get_object_name $cell]  ([get_attribute $cell ref_name])"
}
close $fh

# --- 6. outputs ---
set_app_var verilogout_no_tri true
write -format verilog -hierarchy -output netlist.v
write -format ddc -hierarchy -output synth.ddc
write_sdc synth.sdc
set_svf -off

puts "SB: $top: [sizeof_collection $latches] latch(es); wrote netlist.v, synth.svf, synth_*.rpt"
# leave the shell, unless you ran the script by hand with SB_STAY=1
if {[env_or SB_STAY 0] ne "1"} { exit }
