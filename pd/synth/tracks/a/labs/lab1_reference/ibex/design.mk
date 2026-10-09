# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Lab 1b design config for the lowRISC ibex core (RV32IMC, 2-stage pipeline).
TOP          := ibex_core
# Package first, then the rest of the RTL.
RTL_FILES    := $(DESIGN_DIR)/rtl/ibex_pkg.sv \
                $(filter-out %/ibex_pkg.sv,$(sort $(wildcard $(DESIGN_DIR)/rtl/*.sv)))
# prim_assert.sv is `include`d, not compiled.
RTL_INCDIRS  := $(DESIGN_DIR)/rtl/vendor/lowrisc_ip/prim/rtl
RTL_DEFINES  :=
# SYNTHESIS: dummy assertion macros and the library clock-gating cell.
SYNTH_DEFINES  := SYNTHESIS
PLATFORM_CELLS := sb_icg
# Register file is a (* keep_hierarchy *) module; its read mux gets 15 % of ABC's delay target.
SLANG_HIERARCHY := 1
ABC_SUBMODULE_DELAY_FRAC := 0.15

# One SDC per platform.
SDC_FILE     := $(DESIGN_DIR)/sdc/$(PDK).sdc

# Icarus cannot elaborate ibex, so RTL sim and GLS use Verilator.
SIM_RTL      := verilator
GLS_SIM      := verilator
SIM_ARGS     := $(DESIGN_DIR)/lint_waivers.vlt
TB_DIR       := $(DESIGN_DIR)/tb
TB_MODULE    := test_ibex
TB_SOURCES   :=
