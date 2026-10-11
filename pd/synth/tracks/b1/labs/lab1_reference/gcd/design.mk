# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Lab 1a design settings for the ORFS gcd unit (16-bit Euclid GCD), Track B1.
TOP         := gcd
RTL_FILES   := $(DESIGN_DIR)/rtl/gcd.v
RTL_INCDIRS :=

# constraints for sky130_scl_9T
SDC_FILE    := $(DESIGN_DIR)/sdc/sky130_scl_9T.sdc

# cocotb testbench
TB_DIR      := $(DESIGN_DIR)/tb
TB_MODULE   := test_gcd
