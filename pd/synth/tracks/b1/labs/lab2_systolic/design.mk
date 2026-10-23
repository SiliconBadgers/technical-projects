# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Lab 2 design settings for sb_systolic_tile, the int8 systolic MAC array, Track B1.
TOP         := sb_systolic_tile
# BUGS=1: the copy with the seeded bugs (rtl_bugs/), for Task 1
RTL_DIR     := $(DESIGN_DIR)/$(if $(filter 1,$(BUGS)),rtl_bugs,rtl)
RTL_FILES   := $(addprefix $(RTL_DIR)/,reset_sync.sv pe.sv pe_ctrl.sv readout.sv tile_top.sv)
RTL_INCDIRS := $(RTL_DIR)

# weight-buffer SRAM: black box (lint), simulation model, fake Liberty per corner (synthesis, STA, LEC)
MACRO_VERILOG    := $(DESIGN_DIR)/macros/sb_sram_256x8.v
MACRO_SIM_MODELS := $(DESIGN_DIR)/macros/sb_sram_256x8_model.v
MACRO_LIBS_tt    := $(TRACK_DESIGN_DIR)/macros/sb_sram_256x8_sky130_scl_9T_tt.lib
MACRO_LIBS_ss    := $(TRACK_DESIGN_DIR)/macros/sb_sram_256x8_sky130_scl_9T_ss.lib
MACRO_LIBS_ff    := $(TRACK_DESIGN_DIR)/macros/sb_sram_256x8_sky130_scl_9T_ff.lib

# asynchronous reset input: only the reset synchronizer's flip-flops may use it directly
ASYNC_RESET_PORT := rst_n

# you write this SDC from spec.md (see track/lab2.md)
SDC_FILE    := $(TRACK_DESIGN_DIR)/sdc/sky130_scl_9T.sdc

# targets for make check (starting point from Track A's sky130_scl_9T numbers; recalibrate on first run)
BRONZE_PERIOD_NS := 11.111
SILVER_PERIOD_NS := 7.778

# cocotb testbench
TB_DIR      := $(DESIGN_DIR)/tb
TB_MODULE   := test_tile
