// File:        lec.do
// Author:      Isaac Hagedorn
// Date:        2026-10-09
// Description: Conformal LEC of the RTL (golden) against the Genus netlist (revised). Runs the dofile Genus wrote when it exists, else reads everything itself.
tclmode

# value of an environment variable, or a default when it is unset or empty
proc env_or {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} { return $::env($name) }
    return $default
}

set top      $::env(TOP)
set out      [env_or OUT_DIR .]
set genus_do $out/genus_lec.do

# --- 1. the dofile Genus wrote: it knows every renaming and datapath choice Genus made ---
if {[env_or LEC_MODE genus] eq "genus" && [file exists $genus_do]} {
    puts "SB: running the dofile Genus wrote: $genus_do"
    dofile $genus_do
} else {
    # --- 2. otherwise: our own setup (LEC_MODE=own) ---
    puts "SB: running flow/conformal/lec.do without the Genus dofile"
    if {[env_or RTL_PARAMS ""] ne ""} {
        puts "SB-WARNING: DESIGN_PARAMS are not applied here; use LEC_MODE=genus"
    }
    set_log_file $out/lec.log -replace

    # libraries: standard cells, tie cells and hard macros at the synthesis corner
    read_library -liberty -both {*}[concat $::env(LIB_SYNTH) [env_or LIB_EXTRA ""] [env_or MACRO_LIBS_SYNTH ""]]

    # golden: the RTL with the synthesis defines; `include files from the include directories
    foreach d [env_or RTL_INCDIRS ""] { add_search_path $d -design -golden }
    set_hdl_options -VERILOG_INCLUDE_DIR "sep:src"
    set define_args {}
    foreach d [env_or RTL_DEFINES ""] { lappend define_args -define $d }
    read_design -sv09 -golden -lastmod -noelab {*}$define_args {*}$::env(RTL_FILES)
    elaborate_design -golden -root $top

    # revised: the netlist
    read_design -verilog95 -revised -lastmod -noelab $out/netlist.v
    elaborate_design -revised -root $top

    report_design_data
    report_black_box

    # --- 3. map key points, then compare ---
    set_system_mode lec
    catch {analyze_datapath -module -verbose}
    catch {analyze_datapath -flowgraph -verbose}
    add_compared_points -all
    compare

    catch {report_compare_data -class nonequivalent}
    catch {report_compare_data -class abort}
    report_verification -verbose

    # same summary lines as the Genus dofile (make and check.py read them)
    puts "No of compare points = [get_compare_points -count]"
    puts "No of diff points    = [get_compare_points -NONequivalent -count]"
    puts "No of abort points   = [get_compare_points -abort -count]"
    puts "No of unknown points = [get_compare_points -unknown -count]"
}

# back to native mode to exit (as the Genus dofile does)
vpxmode
exit -force
