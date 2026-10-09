# File:        sky130hd.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Platform settings for SkyWater 130 nm high-density cells (sky130_fd_sc_hd). Cell choices follow OpenROAD-flow-scripts.

PLATFORM_PDK  := sky130A
STD_CELL_LIB  := sky130_fd_sc_hd
SC_DIR        := $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd

# Liberty per corner (<process>_<temperature>_<voltage>)
LIB_tt := $(call sb_lib,$(SC_DIR)/lib/sky130_fd_sc_hd__tt_025C_1v80)
LIB_ss := $(call sb_lib,$(SC_DIR)/lib/sky130_fd_sc_hd__ss_100C_1v60)
LIB_ff := $(call sb_lib,$(SC_DIR)/lib/sky130_fd_sc_hd__ff_n40C_1v95)
LIB_EXTRA_tt :=
LIB_EXTRA_ss :=
LIB_EXTRA_ff :=

# tie cells (conb_1 has both HI and LO outputs) and output buffer
TIEHI_CELL := sky130_fd_sc_hd__conb_1
TIEHI_PORT := HI
TIELO_CELL := sky130_fd_sc_hd__conb_1
TIELO_PORT := LO
BUF_CELL   := sky130_fd_sc_hd__buf_4
BUF_IN     := A
BUF_OUT    := X

# cells synthesis must not use: power-gating, probe, clock and delay cells
DONT_USE    := sky130_fd_sc_hd__lpflow_* sky130_fd_sc_hd__probe* \
               sky130_fd_sc_hd__clk* sky130_fd_sc_hd__dlygate* sky130_fd_sc_hd__dlymetal*
# latch cells, for the latch check
LATCH_CELLS := sky130_fd_sc_hd__dlx* sky130_fd_sc_hd__dlr*

# clock-gating cell, used by cells/sky130hd_sb_icg.v
ICG_CELL    := sky130_fd_sc_hd__sdlclkp_1

# SDC helpers: input driver and output load cells
DRIVING_CELL := sky130_fd_sc_hd__buf_2
DRIVING_PIN  := X
LOAD_CELL    := sky130_fd_sc_hd__buf_4
LOAD_PIN     := A

# gate-level simulation models and defines
CELL_VERILOG := $(SC_DIR)/verilog/primitives.v $(SC_DIR)/verilog/sky130_fd_sc_hd.v
GLS_DEFINES  := FUNCTIONAL UNIT_DELAY=\#1

# physical views (Lab 0)
TECH_LEF := $(SC_DIR)/techlef/sky130_fd_sc_hd__nom.tlef
CELL_LEF := $(SC_DIR)/lef/sky130_fd_sc_hd.lef
