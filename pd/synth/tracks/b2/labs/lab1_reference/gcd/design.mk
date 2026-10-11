# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Lab 1 design settings for the gcd unit (16-bit Euclid GCD), Track B2. Read by the top-level Makefile.
TOP         := gcd
RTL_FILES   := $(DESIGN_DIR)/rtl/gcd.v
RTL_INCDIRS :=
RTL_DEFINES :=

# constraints for this library
SDC_FILE    := $(DESIGN_DIR)/sdc/sky130_fd_sc_hd.sdc

# cocotb testbench: tb/test_gcd.py
TB_DIR      := $(DESIGN_DIR)/tb
TB_MODULE   := test_gcd
