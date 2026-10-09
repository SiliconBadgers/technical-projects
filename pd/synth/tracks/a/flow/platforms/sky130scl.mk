# File:        sky130scl.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Platform settings for the sky130_scl_9T 9-track library (SKY130, release 0.1.2). Unpacked at $(SCL_ROOT), not installed by ciel.
# NOTE(spec-mismatch): fifth platform, not in track/course_spec.md §0; see track/spec_deviations.md.

PLATFORM_PDK  := sky130A
STD_CELL_LIB  := sky130_scl_9T
SCL_LIBDIR    := $(SCL_ROOT)/sky130_scl_9T/lib
SCL_TECHDIR   := $(SCL_ROOT)/sky130_scl_9T_tech

# Liberty per corner (<process>_<voltage>_<temperature>)
LIB_tt := $(SCL_LIBDIR)/sky130_tt_1.8_25_nldm.lib.gz
LIB_ss := $(SCL_LIBDIR)/sky130_ss_1.62_125_nldm.lib.gz
LIB_ff := $(SCL_LIBDIR)/sky130_ff_1.98_0_nldm.lib.gz

# tie cells are in a separate single-corner phyCells library
PHY_LIB       := $(SCL_TECHDIR)/lib/sky130_scl_9T_phyCells.lib
LIB_EXTRA_tt  := $(PHY_LIB)
LIB_EXTRA_ss  := $(PHY_LIB)
LIB_EXTRA_ff  := $(PHY_LIB)

# tie cells and output buffer
TIEHI_CELL := TIEHI
TIEHI_PORT := Y
TIELO_CELL := TIELO
TIELO_PORT := Y
BUF_CELL   := BUFX2
BUF_IN     := A
BUF_OUT    := Y

# cells synthesis must not use: clock, delay, clock-gate, tri-state and scan cells
DONT_USE    := CLK* DLY* ICG* TBUF* SDFF*
# latch cells, for the latch check
LATCH_CELLS := TLAT*

# clock-gating cell, used by cells/sky130scl_sb_icg.v
ICG_CELL    := ICGPRECX1

# SDC helpers: input driver and output load cells
DRIVING_CELL := BUFX2
DRIVING_PIN  := Y
LOAD_CELL    := BUFX4
LOAD_PIN     := A

# gate-level simulation models (TIEHI/TIELO models from flow/platforms/models/)
CELL_VERILOG := $(SCL_ROOT)/sky130_scl_9T/verilog/sky130_scl_9T.v \
                $(FLOW)/platforms/models/sky130scl_phycells.v
GLS_DEFINES  :=

# physical views (Lab 0)
TECH_LEF := $(SCL_TECHDIR)/lef/sky130_scl_9T.tlef
CELL_LEF := $(SCL_ROOT)/sky130_scl_9T/lef/sky130_scl_9T.lef
