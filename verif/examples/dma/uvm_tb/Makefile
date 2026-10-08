# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Builds and runs the dma_controller UVM bench. Targets: build, run, regress, mutants, clean.

ROOT     := $(abspath .)
CONFIG   ?= C1
TEST     ?= dma_smoke_test
SEED     ?= 1
VERB     ?= UVM_LOW
PLUSARGS ?=
MUTANT   ?=
CONFIGS  ?= C1 C2 C3 C4
SEEDS    ?= 3
JOBS     ?= $(shell nproc 2>/dev/null || echo 4)

DMA      ?= $(abspath $(ROOT)/../rtl)
UVM_HOME ?= $(abspath $(ROOT)/../../../third_party/uvm-1.2/src)

NCH_C1 := 8
FD_C1  := 16
NCH_C2 := 2
FD_C2  := 4
NCH_C3 := 32
FD_C3  := 16
NCH_C4 := 8
FD_C4  := 32
NCH := $(NCH_$(CONFIG))
FD  := $(FD_$(CONFIG))
ifeq ($(NCH),)
  $(error CONFIG must be one of C1..C4)
endif

TAG   := $(CONFIG)$(if $(MUTANT),_$(MUTANT))
BUILD := $(ROOT)/build/$(TAG)
BIN   := $(BUILD)/obj/Vtb_top

RTL_FILES := include/ahb_if.sv include/bus_protocol_if.sv include/socetlib_counter.sv \
             source/dma_fifo.sv source/channel_csr.sv source/channel_manager.sv \
             source/trigger_controller.sv source/dma_arbiter.sv source/address_generator.sv \
             source/ahb_subordinate.sv source/dma_engine.sv source/ahb_read_manager.sv \
             source/ahb_write_manager.sv source/dma_controller.sv
MUT_FILE  := $(if $(MUTANT),$(shell sed -n '2s/^# file: //p' mutants/$(MUTANT).sed))
DUT_SRC   := $(foreach f,$(RTL_FILES),$(if $(filter $(f),$(MUT_FILE)),$(BUILD)/mut/$(notdir $(f)),$(DMA)/$(f)))

VFLAGS := --binary --timing --assert -j $(JOBS) --timescale 1ns/1ps \
          -Wno-fatal -Wno-lint -Wno-style -Wno-MULTIDRIVEN -Werror-USERERROR \
          --coverage-user --coverage-line --coverage-toggle --coverage-expr \
          +define+UVM_NO_DPI +define+DMA_NCH=$(NCH) +define+DMA_FDEPTH=$(FD) \
          +incdir+$(UVM_HOME) +incdir+$(ROOT)/tb +incdir+$(DMA)/include \
          --top-module tb_top --Mdir $(BUILD)/obj -o Vtb_top

SRCS := $(UVM_HOME)/uvm_pkg.sv $(DUT_SRC) tb/dma_ahb_if.sv tb/dma_sva.sv tb/dma_tb_pkg.sv tb/tb_top.sv

.PHONY: help build run regress mutants clean
help:
	@echo 'make build|run|regress|mutants|clean  [CONFIG=C1..C4 TEST=<test> SEED=<n> SEEDS=<n> RAND_SEEDS=<n> PLUSARGS=...]'

$(BUILD)/mut/%.sv: mutants/$(MUTANT).sed
	@mkdir -p $(BUILD)/mut
	sed -f mutants/$(MUTANT).sed $(DMA)/$(MUT_FILE) > $@
	@! cmp -s $(DMA)/$(MUT_FILE) $@ || (echo "mutant $(MUTANT) did not change $(MUT_FILE)"; rm -f $@; exit 1)

$(BIN): $(DUT_SRC) $(wildcard tb/*) Makefile
	@mkdir -p $(BUILD)
	@echo "[build] $(TAG): NUM_CHANNELS=$(NCH) FIFO_DEPTH=$(FD)$(if $(MUTANT), mutant $(MUTANT))"
	verilator $(VFLAGS) $(SRCS) > $(BUILD)/build.log 2>&1 || (tail -40 $(BUILD)/build.log; exit 1)

build: $(BIN)

run: $(BIN)
	@mkdir -p $(BUILD)/runs/$(TEST)_s$(SEED)
	cd $(BUILD)/runs/$(TEST)_s$(SEED) && $(BIN) +UVM_TESTNAME=$(TEST) +verilator+seed+$(SEED) \
	  +UVM_VERBOSITY=$(VERB) +verilator+coverage+file+coverage.dat $(PLUSARGS) > sim.log 2>&1; \
	  rc=$$?; grep -E 'UVM_(ERROR|FATAL) [^:]|TEST (PASSED|FAILED)|\[SCB\] compares' sim.log | head -40; \
	  grep -q 'TEST PASSED' sim.log && [ $$rc -eq 0 ]

regress:
	python3 -I scripts/regress.py --configs $(CONFIGS) --seeds $(SEEDS) $(if $(RAND_SEEDS),--rand-seeds $(RAND_SEEDS)) --jobs $(JOBS)

mutants:
	python3 -I scripts/regress.py --mutants --configs C1 --seeds 1 --jobs $(JOBS)

clean:
	rm -rf $(ROOT)/build
