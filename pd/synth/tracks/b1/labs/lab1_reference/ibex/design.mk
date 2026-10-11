# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Lab 1b design settings for the lowRISC ibex core (RV32IMC, 2-stage pipeline), Track B1.
TOP         := ibex_core
# package first, then the rest of the RTL
RTL_FILES   := $(DESIGN_DIR)/rtl/ibex_pkg.sv \
               $(filter-out %/ibex_pkg.sv,$(sort $(wildcard $(DESIGN_DIR)/rtl/*.sv)))
# prim_assert.sv is `include`d, not compiled
RTL_INCDIRS := $(DESIGN_DIR)/rtl/vendor/lowrisc_ip/prim/rtl

# synthesis and LEC: SYNTHESIS selects the dummy assertion macros and the library clock gate (sb_icg)
SYNTH_DEFINES := SYNTHESIS
SYNTH_EXTRA   := $(FLOW)/cells/sky130_scl_9T_sb_icg.v
# simulation and lint: this copy has no full assertion macro file; VERILATOR selects the dummy macros
SIM_DEFINES   := VERILATOR

# constraints for sky130_scl_9T
SDC_FILE    := $(DESIGN_DIR)/sdc/sky130_scl_9T.sdc

# cocotb testbench
TB_DIR      := $(DESIGN_DIR)/tb
TB_MODULE   := test_ibex
