# File:        gf180_9t.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Platform settings for GF180MCU 9-track 5 V cells (gf180mcu_fd_sc_mcu9t5v0). Cell choices follow OpenROAD-flow-scripts.
# NOTE(spec-mismatch): corner voltages differ (5.00 / 4.50 / 5.50 V); see track/spec_deviations.md.

PLATFORM_PDK  := gf180mcuD
STD_CELL_LIB  := gf180mcu_fd_sc_mcu9t5v0
SC_DIR        := $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu9t5v0

LIB_tt := $(call sb_lib,$(SC_DIR)/lib/gf180mcu_fd_sc_mcu9t5v0__tt_025C_5v00)
LIB_ss := $(call sb_lib,$(SC_DIR)/lib/gf180mcu_fd_sc_mcu9t5v0__ss_125C_4v50)
LIB_ff := $(call sb_lib,$(SC_DIR)/lib/gf180mcu_fd_sc_mcu9t5v0__ff_n40C_5v50)
LIB_EXTRA_tt :=
LIB_EXTRA_ss :=
LIB_EXTRA_ff :=

# tie cells (outputs Z and ZN) and output buffer
TIEHI_CELL := gf180mcu_fd_sc_mcu9t5v0__tieh
TIEHI_PORT := Z
TIELO_CELL := gf180mcu_fd_sc_mcu9t5v0__tiel
TIELO_PORT := ZN
BUF_CELL   := gf180mcu_fd_sc_mcu9t5v0__buf_4
BUF_IN     := I
BUF_OUT    := Z

# cells synthesis must not use: drive-1, clock, delay and clock-gate cells
DONT_USE    := gf180mcu_fd_sc_mcu9t5v0__*_1 gf180mcu_fd_sc_mcu9t5v0__clk* gf180mcu_fd_sc_mcu9t5v0__dly* gf180mcu_fd_sc_mcu9t5v0__icg*
# latch cells, for the latch check
LATCH_CELLS := gf180mcu_fd_sc_mcu9t5v0__lat*

# clock-gating cell, used by cells/gf180_9t_sb_icg.v
ICG_CELL    := gf180mcu_fd_sc_mcu9t5v0__icgtp_1

# SDC helpers: input driver and output load cells
DRIVING_CELL := gf180mcu_fd_sc_mcu9t5v0__buf_2
DRIVING_PIN  := Z
LOAD_CELL    := gf180mcu_fd_sc_mcu9t5v0__buf_4
LOAD_PIN     := I

# gate-level simulation models and defines
CELL_VERILOG := $(SC_DIR)/verilog/primitives.v $(SC_DIR)/verilog/gf180mcu_fd_sc_mcu9t5v0.v
GLS_DEFINES  := FUNCTIONAL

# physical views (Lab 0)
TECH_LEF := $(SC_DIR)/techlef/gf180mcu_fd_sc_mcu9t5v0__nom.tlef
CELL_LEF := $(SC_DIR)/lef/gf180mcu_fd_sc_mcu9t5v0.lef
