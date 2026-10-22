# File:        design.mk
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Lab 1a design config for the ORFS gcd unit (16-bit Euclid GCD).
TOP          := gcd
RTL_FILES    := $(DESIGN_DIR)/rtl/gcd.v
RTL_INCDIRS  :=
RTL_DEFINES  :=

# One SDC per platform.
SDC_FILE     := $(TRACK_DESIGN_DIR)/sdc/$(PDK).sdc

TB_DIR       := $(DESIGN_DIR)/tb
TB_MODULE    := test_gcd
TB_SOURCES   :=
