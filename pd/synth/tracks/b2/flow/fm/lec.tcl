# File:        lec.tcl
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Formality equivalence check of the RTL (reference) against the synthesized netlist (implementation). Inputs are environment variables from lec.env (written by make); run it from the build folder.

# value of an environment variable, or a default when it is unset or empty
proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} { return $::env($name) }
    return $default
}

set top       $::env(TOP)              ;# top module
set rtl_files $::env(RTL_FILES)        ;# same RTL files synthesis read
set incdirs   [env_or RTL_INCDIRS ""]
set defines   [env_or RTL_DEFINES ""]
set params    [env_or RTL_PARAMS ""]   ;# top-level parameters, NAME=VALUE

# read the RTL the way Design Compiler did; the SVF lists what synthesis changed
set_app_var synopsys_auto_setup true
set_svf $::env(SVF)

# library cells (.db), shared by both designs
read_db [concat $::env(CELL_DB) [env_or MACRO_DBS ""]]

# --- 1. reference: the RTL ---
set vcs_opts {}
foreach d $incdirs { lappend vcs_opts +incdir+$d }
foreach d $defines { lappend vcs_opts +define+$d }
set read_args [list -r]
if {[llength $vcs_opts]} { lappend read_args -vcs [join $vcs_opts " "] }
read_sverilog {*}$read_args $rtl_files
set top_args {}
if {[llength $params]} { lappend top_args -parameters [join $params ,] }
set_top {*}$top_args r:/WORK/$top

# --- 2. implementation: the netlist ---
read_verilog -i $::env(NETLIST)
set_top i:/WORK/$top

# --- 3. compare ---
match                                              ;# pair up compare points by name
redirect lec_unmatched.rpt { report_unmatched_points }
verify                                             ;# prove each pair equal
redirect lec_failing.rpt   { report_failing_points }
redirect lec_analyze.rpt   { analyze_points -failing }

puts "SB: lec done (lec_failing.rpt, lec_unmatched.rpt, lec_analyze.rpt)"
# leave the shell, unless you ran the script by hand with SB_STAY=1
if {[env_or SB_STAY 0] ne "1"} { exit }
