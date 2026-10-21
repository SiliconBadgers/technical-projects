# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Lab 1 design settings for the lowRISC ibex core (RV32IMC, 2-stage pipeline), Track B2. Read by the top-level Makefile.
TOP         := ibex_core
# package first, then the rest of the RTL
RTL_FILES   := $(DESIGN_DIR)/rtl/ibex_pkg.sv \
               $(filter-out %/ibex_pkg.sv,$(sort $(wildcard $(DESIGN_DIR)/rtl/*.sv)))
# prim_assert.sv is `include`d, not compiled
RTL_INCDIRS := $(DESIGN_DIR)/rtl/vendor/lowrisc_ip/prim/rtl
RTL_DEFINES :=

# synthesis and LEC: empty assertion macros and the library clock-gating cell (flow/cells/)
SYNTH_DEFINES  := SYNTHESIS
PLATFORM_CELLS := sb_icg
# VCS (lint, RTL sim): VERILATOR selects the empty assertion macros in prim_assert.sv
SIM_DEFINES    := VERILATOR

# constraints for this library
SDC_FILE    := $(TRACK_DESIGN_DIR)/sdc/sky130_fd_sc_hd.sdc

# cocotb testbench: tb/test_ibex.py
TB_DIR      := $(DESIGN_DIR)/tb
TB_MODULE   := test_ibex
