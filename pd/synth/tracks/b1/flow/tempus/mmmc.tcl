# File:        mmmc.tcl
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Tempus multi-mode multi-corner (MMMC) setup: one analysis view per Liberty corner (tt, ss, ff). Read by sta.tcl with read_mmmc.

set corners {tt ss ff}

# library set (Liberty files) and timing condition per corner; the tie-cell library (LIB_EXTRA) is the same at every corner
foreach c $corners {
    set libs [concat $::env(LIB_$c) $::env(LIB_EXTRA) $::env(MACRO_LIBS_$c)]
    create_library_set -name libs_$c -timing $libs
    create_timing_condition -name cond_$c -library_sets [list libs_$c]
}

# no parasitics before layout: wires have no resistance or capacitance of their own
create_rc_corner -name rc_none

# delay corner = timing condition + RC corner
foreach c $corners {
    create_delay_corner -name delay_$c -timing_condition cond_$c -rc_corner rc_none
}

# one constraint mode: your SDC
create_constraint_mode -name func -sdc_files [list $::env(SDC_FILE)]

# analysis view = constraint mode + delay corner
foreach c $corners {
    create_analysis_view -name view_$c -constraint_mode func -delay_corner delay_$c
}

# every view checks setup and hold; sign-off reads setup at ss and hold at ff
set_analysis_view -setup {view_ss view_tt view_ff} -hold {view_ff view_tt view_ss}
