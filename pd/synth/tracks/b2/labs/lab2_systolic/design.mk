# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Lab 2 design settings for sb_systolic_tile, the int8 systolic MAC array, Track B2. Read by the top-level Makefile.
TOP         := sb_systolic_tile
# BUGS=1: the copy with the seeded bugs (rtl_bugs/), for Task 1
RTL_DIR     := $(DESIGN_DIR)/$(if $(filter 1,$(BUGS)),rtl_bugs,rtl)
RTL_FILES   := $(addprefix $(RTL_DIR)/,reset_sync.sv pe.sv pe_ctrl.sv readout.sv tile_top.sv)
RTL_INCDIRS := $(RTL_DIR)
RTL_DEFINES :=

# weight-buffer SRAM: fake timing model per corner (macros/sb_sram_256x8_sky130_fd_sc_hd_<corner>.lib,
# compiled to .db by `make macros`) and a simulation model
MACROS           := sb_sram_256x8
MACRO_SIM_MODELS := $(DESIGN_DIR)/macros/sb_sram_256x8_model.v

# asynchronous reset input (only the reset synchronizer may hang on it)
ASYNC_RESET_PORT := rst_n

# you write this SDC from spec.md (see sdc/README.md)
SDC_FILE    := $(TRACK_DESIGN_DIR)/sdc/sky130_fd_sc_hd.sdc

# cocotb testbench: tb/test_tile.py
TB_DIR      := $(DESIGN_DIR)/tb
TB_MODULE   := test_tile
