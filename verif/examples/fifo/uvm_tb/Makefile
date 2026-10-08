# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Builds and runs the socetlib_fifo UVM bench. Targets: build, run, regress, mutants, clean.

ROOT     := $(abspath .)
CONFIG   ?= C1
TEST     ?= fifo_smoke_test
SEED     ?= 1
VERB     ?= UVM_LOW
PLUSARGS ?=
MUTANT   ?=
CONFIGS  ?= C1 C2 C3 C4 C5
SEEDS    ?= 5
JOBS     ?= $(shell nproc 2>/dev/null || echo 4)

RTL      ?= $(abspath $(ROOT)/../rtl/socetlib_fifo.sv)
UVM_HOME ?= $(abspath $(ROOT)/../../../third_party/uvm-1.2/src)

SIZE_C1 := 8
DEPTH_C1 := 8
SIZE_C2 := 32
DEPTH_C2 := 32
SIZE_C3 := 1
DEPTH_C3 := 2
SIZE_C4 := 8
DEPTH_C4 := 16
SIZE_C5 := 8
DEPTH_C5 := 1
SIZE  := $(SIZE_$(CONFIG))
DEPTH := $(DEPTH_$(CONFIG))
ifeq ($(SIZE),)
  $(error CONFIG must be one of C1..C5)
endif

TAG   := $(CONFIG)$(if $(MUTANT),_$(MUTANT))
BUILD := $(ROOT)/build/$(TAG)
BIN   := $(BUILD)/obj/Vtb_top
DUT_SRC := $(if $(MUTANT),$(BUILD)/socetlib_fifo_$(MUTANT).sv,$(RTL))

VFLAGS := --binary --timing --assert -j $(JOBS) --timescale 1ns/1ps \
          -Wno-fatal -Wno-lint -Wno-style -Wno-MULTIDRIVEN -Werror-USERERROR \
          --coverage-user --coverage-line --coverage-toggle --coverage-expr \
          +define+UVM_NO_DPI +define+FIFO_SIZE=$(SIZE) +define+FIFO_DEPTH=$(DEPTH) \
          +incdir+$(UVM_HOME) +incdir+$(ROOT)/tb \
          --top-module tb_top --Mdir $(BUILD)/obj -o Vtb_top

SRCS := $(UVM_HOME)/uvm_pkg.sv $(DUT_SRC) tb/fifo_if.sv tb/fifo_sva.sv tb/fifo_tb_pkg.sv tb/tb_top.sv

.PHONY: help build run regress mutants clean
help:
	@echo 'make build|run|regress|mutants|clean  [CONFIG=C1..C5 TEST=<test> SEED=<n> SEEDS=<n> PLUSARGS=...]'

$(BUILD)/socetlib_fifo_$(MUTANT).sv: $(RTL) mutants/$(MUTANT).sed
	@mkdir -p $(BUILD)
	sed -f mutants/$(MUTANT).sed $(RTL) > $@
	@! cmp -s $(RTL) $@ || (echo "mutant $(MUTANT) did not change the RTL"; rm -f $@; exit 1)

$(BIN): $(DUT_SRC) $(wildcard tb/*) Makefile
	@mkdir -p $(BUILD)
	@echo "[build] $(TAG): SIZE=$(SIZE) DEPTH=$(DEPTH)$(if $(MUTANT), mutant $(MUTANT))"
	verilator $(VFLAGS) $(SRCS) > $(BUILD)/build.log 2>&1 || (tail -30 $(BUILD)/build.log; exit 1)

build: $(BIN)

run: $(BIN)
	@mkdir -p $(BUILD)/runs/$(TEST)_s$(SEED)
	cd $(BUILD)/runs/$(TEST)_s$(SEED) && $(BIN) +UVM_TESTNAME=$(TEST) +verilator+seed+$(SEED) \
	  +UVM_VERBOSITY=$(VERB) +verilator+coverage+file+coverage.dat $(PLUSARGS) > sim.log 2>&1; \
	  grep -E 'UVM_(ERROR|FATAL) [^:]|TEST (PASSED|FAILED)|SCB.*compares' sim.log | head -30; \
	  grep -q 'TEST PASSED' sim.log

regress:
	python3 -I scripts/regress.py --configs $(CONFIGS) --seeds $(SEEDS) --jobs $(JOBS)

mutants:
	python3 -I scripts/regress.py --mutants --configs C1 --seeds 2 --jobs $(JOBS)

clean:
	rm -rf $(ROOT)/build
