# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2025-03-29
# Description: Verilator + UVM 1.2 build, run, regression and coverage targets. Run `make help` for usage.

ROOT     := $(abspath .)
empty    :=
space    := $(empty) $(empty)
# testbench directory (contains tb.f)
TB       ?= tb
# golden | sanity | broken
DUT      ?= golden
# seeded bug(s) for DUT=broken: B3, "B1 B4" or ALL
BUG      ?=
# test to run
TEST     ?= sa_smoke_test
# random seed
SEED     ?= 1
# UVM verbosity
VERB     ?= UVM_MEDIUM
# collect covergroups
COV      ?= 1
# also line + toggle coverage
CODECOV  ?= 0
# FST waves
WAVES    ?= 0
# array size
N        ?= 4
# seeds per test in a regression
SEEDS    ?= 3
# parallel jobs
JOBS     ?= $(shell nproc 2>/dev/null || echo 4)
# regression list
LIST     ?= $(TB)/regress.list
# extra simulator plusargs
PLUSARGS ?=
SIM_ARGS := +SA_VECTORS=$(abspath model/golden_vectors.txt) $(PLUSARGS)

UVM_HOME ?= $(ROOT)/third_party/uvm-1.2/src
VERILATOR ?= verilator

RTL_F_golden := $(ROOT)/rtl/sb_systolic_array.f
RTL_F_sanity := $(ROOT)/rtl/sanity/sanity.f
RTL_F_broken := $(ROOT)/mentor/broken/broken.f
RTL_F := $(RTL_F_$(DUT))
ifeq ($(RTL_F),)
  $(error DUT must be golden, sanity or broken)
endif
ifeq ($(DUT),broken)
  ifeq ($(BUG),)
    $(error DUT=broken needs BUG=<id>, e.g. BUG=B1)
  endif
endif

CFG_TAG  := $(DUT)$(if $(BUG),_$(subst $(space),-,$(strip $(BUG))))$(if $(filter-out 4,$(N)),_n$(N))$(if $(filter 1,$(CODECOV)),_cc)$(if $(filter 1,$(WAVES)),_waves)
BUILD    := $(ROOT)/build/$(subst /,_,$(TB))/$(CFG_TAG)
BIN      := $(BUILD)/obj/Vtb_top
RUNDIR   := $(BUILD)/runs/$(TEST)_s$(SEED)

VFLAGS := --binary --timing --assert -j $(JOBS) --timescale 1ns/1ps \
          -Wno-fatal -Wno-lint -Wno-style -Wno-MULTIDRIVEN -Werror-USERERROR \
          +define+UVM_NO_DPI +define+SA_N=$(N) \
          +incdir+$(UVM_HOME) +incdir+$(abspath $(TB)) \
          --top-module tb_top --Mdir $(BUILD)/obj -o Vtb_top
ALL_BUGS := B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11
BUG_LIST := $(if $(filter ALL,$(BUG)),$(ALL_BUGS),$(BUG))
VFLAGS += $(foreach b,$(BUG_LIST),+define+SB_BUG_$(b))
ifeq ($(COV),1)
  VFLAGS += --coverage-user
endif
ifeq ($(CODECOV),1)
  VFLAGS += --coverage-line --coverage-toggle
endif
ifeq ($(WAVES),1)
  VFLAGS += --trace-fst +define+SA_WAVES
endif

SRCS := $(UVM_HOME)/uvm_pkg.sv -F $(RTL_F) -F $(abspath $(TB))/tb.f
DEPS := $(shell find $(ROOT)/rtl $(abspath $(TB)) $(if $(filter broken,$(DUT)),$(ROOT)/mentor/broken) -type f 2>/dev/null)

.PHONY: help lint build run regress cov cov-code waves clean

help:
	@echo "make lint | build | run | regress | cov | cov-code | waves | clean"
	@echo "knobs: TB DUT BUG TEST SEED VERB COV CODECOV WAVES N SEEDS JOBS LIST PLUSARGS"

lint:
	$(VERILATOR) --lint-only -Wall -GN=$(N) -F $(RTL_F) --top-module sb_systolic_array

$(BIN): $(DEPS)
	@mkdir -p $(BUILD)
	@echo "[build] $(TB) + $(DUT)$(if $(BUG), $(BUG)) -> $(BUILD)"
	$(VERILATOR) $(VFLAGS) $(SRCS) > $(BUILD)/build.log 2>&1 || (tail -40 $(BUILD)/build.log; exit 1)
	@grep -E '^%Warning-(WIDTH|CASE|LATCH|UNOPT)' $(BUILD)/build.log | grep -v third_party | head -20 || true

build: $(BIN)

run: $(BIN)
	@mkdir -p $(RUNDIR)
	cd $(RUNDIR) && $(BIN) +UVM_TESTNAME=$(TEST) +verilator+seed+$(SEED) +UVM_VERBOSITY=$(VERB) \
	  +verilator+coverage+file+$(RUNDIR)/coverage.dat $(SIM_ARGS) 2>&1 | tee sim.log | \
	  grep -E 'UVM_(ERROR|FATAL) [^:]|\*\*\* TEST|Assertion|%Error' | head -40 ; \
	  grep -q '\*\*\* TEST PASSED' sim.log

waves:
	$(MAKE) run WAVES=1 TEST=$(TEST) SEED=$(SEED)
	@echo "waves: $(ROOT)/build/$(subst /,_,$(TB))/$(subst _waves,,$(CFG_TAG))_waves/runs/$(TEST)_s$(SEED)/waves.fst"

regress: $(BIN)
	python3 $(ROOT)/scripts/regress.py --bin $(BIN) --list $(LIST) --seeds $(SEEDS) \
	  --out $(BUILD)/regress --jobs $(JOBS) --plusargs "$(SIM_ARGS)"

cov:
	python3 $(ROOT)/scripts/cov_report.py $(BUILD)/regress/merged.dat

cov-code:
	python3 $(ROOT)/scripts/cov_report.py $(BUILD)/regress/merged.dat --code

clean:
	rm -rf $(ROOT)/build
