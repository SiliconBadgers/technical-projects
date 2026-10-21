# File:        sta.tcl
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Tempus static timing analysis of the Genus netlist at tt, ss and ff in one run. Inputs are environment variables from flow.env.

# value of an environment variable, or a default when it is unset or empty
proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} { return $::env($name) }
    return $default
}

set top     $::env(TOP)              ;# top module
set out     [env_or OUT_DIR .]       ;# output directory (the build directory)
set corners {tt ss ff}

# --- 1. views, netlist ---
read_mmmc $::env(FLOW_DIR)/tempus/mmmc.tcl
read_netlist $out/netlist.v -top $top
init_design

# --- 2. constraint problems: unclocked flip-flops, missing I/O delays, loops ---
if {[catch {check_timing -verbose > $out/sta_check_timing.rpt}]} {
    check_timing_intent -verbose > $out/sta_check_timing.rpt
}

# --- 3. the 10 worst paths per corner: setup (late) and hold (early) ---
foreach c $corners {
    report_timing -late  -view view_$c -max_paths 10 -nworst 1 -path_type full_clock > $out/sta_${c}_setup.rpt
    report_timing -early -view view_$c -max_paths 10 -nworst 1 -path_type full_clock > $out/sta_${c}_hold.rpt
}

# design rules (max transition, capacitance, fanout): reported, not signed off
if {[catch {report_constraint -all_violators > $out/sta_drv.rpt} err]} {
    puts "SB-WARNING: no design-rule report ($err); read qor.rpt from Genus instead"
}

# --- 4. summary for make, qor.py and check.py ---
# worst slack (WNS) and total negative slack (TNS) over one path per endpoint
proc sb_slack_summary {args} {
    set wns ""
    set tns 0.0
    foreach_in_collection p [report_timing -collection -max_paths 100000 -nworst 1 {*}$args] {
        set s [get_db $p .slack]
        if {![string is double -strict $s]} { continue }
        if {$wns eq "" || $s < $wns} { set wns $s }
        if {$s < 0} { set tns [expr {$tns + $s}] }
    }
    if {$wns eq ""} { return {INF 0.0} }
    return [list $wns $tns]
}

set f [open $out/sta_summary.txt.tmp w]
puts $f "# corner check wns_ns tns_ns (from flow/tempus/sta.tcl)"
foreach c $corners {
    foreach {check side} {setup -late hold -early} {
        if {[catch {set r [sb_slack_summary $side -view view_$c]} err]} {
            puts "SB-WARNING: slack summary failed ($err); qor.py reads sta_${c}_${check}.rpt instead"
            set r {NA NA}
        }
        puts $f "$c $check [lindex $r 0] [lindex $r 1]"
    }
}

# clock period of the first clock (ns)
if {[catch {set period [get_db [lindex [get_db clocks] 0] .period]}] || $period eq ""} { set period NA }
puts $f "period_ns $period"

# flip-flop reset/set pins reached from the asynchronous reset port (-1 = could not count)
set rst [env_or ASYNC_RESET_PORT ""]
if {$rst ne ""} {
    set n -1
    catch {
        set async {}
        foreach_in_collection p [all_registers -async_pins] { dict set async [get_object_name $p] 1 }
        set count 0
        foreach_in_collection p [all_fanout -from [get_ports $rst] -endpoints_only] {
            if {[dict exists $async [get_object_name $p]]} { incr count }
        }
        set n $count
    }
    puts $f "reset_port_async_pins $n"
}
close $f
file rename -force $out/sta_summary.txt.tmp $out/sta_summary.txt
puts "SB: STA done, summary in $out/sta_summary.txt"
exit
