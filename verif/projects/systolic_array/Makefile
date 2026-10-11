# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: sb_systolic_array project settings; the flow is ../../common/sim.mk. Run `make help`.

PROJECT_ROOT     := $(abspath .)
TOP              := tb_top
DUT_TOP          := sb_systolic_array
# test to run
TEST             ?= sa_smoke_test
# array size
N                ?= 4

RTL_F_golden     := $(PROJECT_ROOT)/rtl/sb_systolic_array.f
RTL_F_sanity     := $(PROJECT_ROOT)/rtl/sanity/sanity.f
RTL_F_broken      = $(MENTOR_DIR)/broken/broken.f
BUG_PREFIX       := SB_BUG_
ALL_BUGS         := B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11
PROJECT_DEFS     := +define+SA_N=$(N)
PROJECT_TAG      := $(if $(filter-out 4,$(N)),_n$(N))
PROJECT_PLUSARGS := +SA_VECTORS=$(PROJECT_ROOT)/model/golden_vectors.txt
LINT_ARGS        := -GN=$(N)
WAVES_DEFINE     := SA_WAVES

include ../../common/sim.mk
