# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: sb_apb_regs project settings; the flow is ../../common/sim.mk. Run `make help`.

PROJECT_ROOT     := $(abspath .)
TOP              := tb_top
DUT_TOP          := sb_apb_regs
# test to run
TEST             ?= apb_smoke_test

RTL_F_golden     := $(PROJECT_ROOT)/rtl/sb_apb_regs.f
RTL_F_sanity     := $(PROJECT_ROOT)/rtl/sanity/sanity.f
RTL_F_broken      = $(MENTOR_DIR)/broken/broken.f
BUG_PREFIX       := APB_BUG_
ALL_BUGS         := B1 B2 B3 B4 B5 B6 B7 B8 B9 B10
PROJECT_DEFS     :=
PROJECT_TAG      :=
PROJECT_PLUSARGS :=
LINT_ARGS        :=
WAVES_DEFINE     := APB_WAVES

include ../../common/sim.mk
