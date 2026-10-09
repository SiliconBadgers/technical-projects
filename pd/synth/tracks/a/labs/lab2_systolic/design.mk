# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Lab 2 design config for sb_systolic_tile, the int8 systolic MAC array.
TOP          := sb_systolic_tile
RTL_FILES    := $(addprefix $(DESIGN_DIR)/rtl/,reset_sync.sv pe.sv pe_ctrl.sv readout.sv tile_top.sv)
RTL_INCDIRS  := $(DESIGN_DIR)/rtl
RTL_DEFINES  :=
# Multiplier is a (* keep_hierarchy *) module; it gets 35 % of ABC's delay target.
SLANG_HIERARCHY := 1
ABC_SUBMODULE_DELAY_FRAC := 0.35

# Weight-buffer SRAM macro: black box, simulation model, fake Liberty per corner.
MACRO_VERILOG    := $(DESIGN_DIR)/macros/sb_sram_256x8.v
MACRO_SIM_MODELS := $(DESIGN_DIR)/macros/sb_sram_256x8_model.v
MACRO_LIBS_tt    := $(DESIGN_DIR)/macros/sb_sram_256x8_$(PDK)_tt.lib
MACRO_LIBS_ss    := $(DESIGN_DIR)/macros/sb_sram_256x8_$(PDK)_ss.lib
MACRO_LIBS_ff    := $(DESIGN_DIR)/macros/sb_sram_256x8_$(PDK)_ff.lib

# Asynchronous reset input (only the reset synchronizer may use it).
ASYNC_RESET_PORT := rst_n

# You write this SDC from spec.md.
SDC_FILE     := $(DESIGN_DIR)/sdc/$(PDK).sdc

SIM_RTL      := icarus
TB_DIR       := $(DESIGN_DIR)/tb
TB_MODULE    := test_tile
TB_SOURCES   :=
