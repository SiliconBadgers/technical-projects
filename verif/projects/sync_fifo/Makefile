# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: sb_fifo project settings; the flow is ../../common/sim.mk. Run `make help`.

PROJECT_ROOT     := $(abspath .)
TOP              := tb_top
DUT_TOP          := sb_fifo
# test to run
TEST             ?= fifo_smoke_test
# FIFO depth (entries) and entry width
DEPTH            ?= 6
WIDTH            ?= 8

RTL_F_golden     := $(PROJECT_ROOT)/rtl/sb_fifo.f
RTL_F_sanity     := $(PROJECT_ROOT)/rtl/sanity/sanity.f
RTL_F_broken      = $(MENTOR_DIR)/broken/broken.f
BUG_PREFIX       := FIFO_BUG_
ALL_BUGS         := B1 B2 B3 B4 B5 B6 B7 B8
PROJECT_DEFS     := +define+FIFO_DEPTH=$(DEPTH) +define+FIFO_WIDTH=$(WIDTH)
PROJECT_TAG      := $(if $(filter-out 6,$(DEPTH)),_d$(DEPTH))$(if $(filter-out 8,$(WIDTH)),_w$(WIDTH))
PROJECT_PLUSARGS :=
LINT_ARGS        := -GDEPTH=$(DEPTH) -GWIDTH=$(WIDTH)
WAVES_DEFINE     := FIFO_WAVES

include ../../common/sim.mk
