# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Track A flow: lint, sim, synth, sta, lec, gls and qor for one DESIGN on one PDK. Run `make help` for usage.

SHELL       := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
# keep generated files such as *.env
.SECONDARY:

SB_ROOT  := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
FLOW     := $(SB_ROOT)/flow
SCRIPTS  := $(FLOW)/scripts

PDK      ?= sky130hd
DESIGN   ?= gcd
CORNERS  ?= tt ss ff
# Liberty corner used for mapping
SYNTH_CORNER ?= ss
CORNER   ?= ss

SYNTH_FLATTEN ?= 1
SYNTH_RETIME  ?= 0
SYNTH_FSM     ?= 0
SYNTH_ADDER   ?= kogge-stone
SYNTH_OUTBUF  ?= 1
# 1 = give ABC the input driving cell and output load
ABC_CONSTR    ?= 1
# ABC delay target as a fraction of the clock period
ABC_DELAY_FRAC ?= 0.6
# share of the ABC target for (* keep_hierarchy *) modules
ABC_SUBMODULE_DELAY_FRAC ?= 1.0
# gate-level simulator: icarus or verilator
GLS_SIM ?= icarus
ABC_SCRIPT    ?=
RTL_FRONTEND  ?= slang
WAVES         ?= 0

# PDK_ROOT: ciel install of sky130A / gf180mcuD. SCL_ROOT: unpacked sky130_scl_9T release.
PDK_ROOT ?= $(HOME)/.ciel
SCL_ROOT ?= $(PDK_ROOT)/sky130_scl_9T_0.1.2

# $(call sb_lib,<path without extension>): the Liberty file, plain or gzipped
sb_lib = $(firstword $(wildcard $(1).lib $(1).lib.gz) $(1).lib)

PLATFORM_MK := $(FLOW)/platforms/$(PDK).mk
ifeq ($(wildcard $(PLATFORM_MK)),)
  $(error PDK=$(PDK) is not a platform. Choose one of: $(basename $(notdir $(wildcard $(FLOW)/platforms/*.mk))))
endif
include $(PLATFORM_MK)

include $(SB_ROOT)/labs/designs.mk
DESIGN_DIR := $(SB_ROOT)/$(DESIGN_DIR_$(DESIGN))
ifeq ($(DESIGN_DIR_$(DESIGN)),)
  $(error DESIGN=$(DESIGN) is not registered in labs/designs.mk)
endif
include $(DESIGN_DIR)/design.mk

# --- optional design.mk settings (MACRO_LIBS_<corner>: macro Liberty per corner) ---
# macros for synthesis and LEC only
SYNTH_DEFINES  ?=
# platform wrapper cells the RTL instantiates (e.g. sb_icg)
PLATFORM_CELLS ?=
# RTL simulator: icarus or verilator
SIM_RTL        ?= icarus
SIM_ARGS       ?=
# top-level parameters, NAME=VALUE
DESIGN_PARAMS  ?=
# black-box Verilog of hard macros
MACRO_VERILOG  ?=
# 1 = keep modules while reading, for (* keep_hierarchy *)
SLANG_HIERARCHY ?= 0
# async reset input, and how many flip-flops may hang on it directly
ASYNC_RESET_PORT ?=
RESET_SYNC_FLOPS ?= 2
# simulation models of hard macros
MACRO_SIM_MODELS ?=
export SB_DESIGN_PARAMS := $(DESIGN_PARAMS)
SYNTH_RTL      := $(foreach c,$(PLATFORM_CELLS),$(FLOW)/platforms/cells/$(PDK)_$(c).v) $(RTL_FILES) $(MACRO_VERILOG)

# clock period override in ns (needs [sb_clock_period <ns>] in the SDC)
CLOCK_PERIOD ?=
PARAMS_TAG := $(if $(filter command line,$(origin DESIGN_PARAMS)),_$(subst =,,$(subst $(eval) ,_,$(strip $(DESIGN_PARAMS)))))
BUILD    ?= $(SB_ROOT)/build/$(DESIGN)/$(PDK)$(PARAMS_TAG)$(if $(CLOCK_PERIOD),_p$(CLOCK_PERIOD))
TIMES    := $(BUILD)/runtimes.txt
TIMED    := $(SCRIPTS)/util/timed.sh $(TIMES)

LIB_SYNTH      := $(LIB_$(SYNTH_CORNER))
LIB_EXTRA_SYNTH := $(LIB_EXTRA_$(SYNTH_CORNER))
MACRO_LIBS_SYNTH := $(MACRO_LIBS_$(SYNTH_CORNER))

# clock period from the SDC (ns), and in ps for ABC
CLOCK_PERIOD_NS := $(if $(wildcard $(SDC_FILE)),$(shell tclsh $(SCRIPTS)/util/clock_period.tcl $(SDC_FILE) $(CLOCK_PERIOD)))
CLOCK_PERIOD_PS := $(if $(CLOCK_PERIOD_NS),$(shell awk 'BEGIN{printf "%d", $(CLOCK_PERIOD_NS)*1000 + 0.5}'))
ABC_DELAY_PS    := $(if $(CLOCK_PERIOD_NS),$(shell awk 'BEGIN{printf "%d", $(CLOCK_PERIOD_NS)*1000*$(ABC_DELAY_FRAC) + 0.5}'))

FLOW_DEPS := $(PLATFORM_MK) $(DESIGN_DIR)/design.mk

# --- targets ---
.PHONY: help info env-check all lint sim synth sta lec gls qor check lec-mutation clean FORCE
FORCE:
help:
	@echo "usage: make <stage> PDK=<platform> DESIGN=<design> [CORNER=<corner>] [CLOCK_PERIOD=<ns>]"
	@echo "  stages:       lint sim synth sta lec gls qor | all | check | lec-mutation | clean | info | env-check"
	@echo "  PDK:          sky130hd sky130hs gf180_7t gf180_9t sky130scl (flow/platforms/*.mk)"
	@echo "  DESIGN:       see labs/designs.mk"
	@echo "  CLOCK_PERIOD: override the SDC clock period (ns); output in build/<DESIGN>/<PDK>_p<ns>/"
	@echo "outputs: build/<DESIGN>/<PDK>/ (each step writes <stage>.env to rerun it by hand)"

info:
	@echo "DESIGN=$(DESIGN) TOP=$(TOP) PDK=$(PDK) ($(STD_CELL_LIB))"
	@echo "SDC=$(SDC_FILE)  period=$(CLOCK_PERIOD_NS) ns"
	@echo "synth corner=$(SYNTH_CORNER): $(LIB_SYNTH)"
	@$(foreach c,$(CORNERS),echo "  $(c): $(LIB_$(c)) $(LIB_EXTRA_$(c))";)
	@echo "BUILD=$(BUILD)"

# print one variable, e.g. make print-LIB_tt
print-%:
	@echo '$($*)'

# check installed PDKs and tools against pdk.lock
env-check:
	python3 $(SCRIPTS)/util/lock.py check --pdk-root $(PDK_ROOT)
	@for t in yosys eqy sta verilator iverilog; do printf '%-10s ' $$t; command -v $$t || { echo MISSING; exit 1; }; done
	@yosys -q -p 'help read_slang' >/dev/null && echo "read_slang OK"

all: lint sim synth sta lec gls qor

lint:  $(BUILD)/lint.log
sim:   $(BUILD)/results.xml
synth: $(BUILD)/netlist.v
sta:   $(foreach c,$(CORNERS),$(BUILD)/sta_$(c).rpt)
lec:   $(BUILD)/lec.log
gls:   $(BUILD)/gls_results.xml
qor:   $(BUILD)/qor.csv

check:
	python3 $(SB_ROOT)/ci/checks.py --build $(BUILD) --design-dir $(DESIGN_DIR) --latch-cells "$(LATCH_CELLS)" \
	  --reset-sync-flops $(RESET_SYNC_FLOPS)

# break the netlist on purpose; LEC must FAIL. LEC_MUTATIONS: number of mutants
LEC_MUTATIONS ?= 2
lec-mutation: $(BUILD)/lec.log
	python3 $(SB_ROOT)/ci/lec_mutation_test.py --build $(BUILD) --count $(LEC_MUTATIONS) --jobs $(LEC_JOBS)

clean:
	rm -rf $(BUILD)

$(BUILD):
	mkdir -p $@

# --- lint (Verilator and sb_lint gate, Verible is advisory) ---
LINT_WAIVERS ?= $(wildcard $(DESIGN_DIR)/lint_waivers.vlt)
$(BUILD)/lint.log: $(RTL_FILES) $(MACRO_VERILOG) $(LINT_WAIVERS) $(FLOW_DEPS) $(SCRIPTS)/lint/sb_lint.py | $(BUILD)
	@echo "== lint: verilator --lint-only -Wall" | tee $@
	verilator --lint-only -Wall --top-module $(TOP) $(addprefix -I,$(RTL_INCDIRS)) \
	  $(addprefix -D,$(RTL_DEFINES)) $(addprefix -G,$(DESIGN_PARAMS)) $(LINT_WAIVERS) $(RTL_FILES) $(MACRO_VERILOG) 2>&1 | tee -a $@
	@echo "== lint: sb_lint (team rules, flow/scripts/lint/sb_lint.py)" | tee -a $@
	python3 $(SCRIPTS)/lint/sb_lint.py $(RTL_FILES) 2>&1 | tee -a $@
	@echo "== lint: verible-verilog-lint (advisory, does not fail the build)" | tee -a $@
	-verible-verilog-lint $(VERIBLE_FLAGS) $(RTL_FILES) 2>&1 | tee -a $@
	@echo "LINT_STATUS: verilator+sb_lint PASS" | tee -a $@

# --- sim / gls (same cocotb testbench on RTL and netlist) ---
COCOTB := python3 $(SCRIPTS)/sim/run_cocotb.py

$(BUILD)/results.xml: $(RTL_FILES) $(MACRO_SIM_MODELS) $(TB_SOURCES) $(wildcard $(TB_DIR)/*.py) $(FLOW_DEPS) | $(BUILD)
	$(TIMED) sim $(COCOTB) --sim $(SIM_RTL) $(addprefix --sim-arg=,$(SIM_ARGS)) \
	  --toplevel $(TOP) --test-module $(TB_MODULE) --test-dir $(TB_DIR) \
	  --build-dir $(BUILD)/sim_rtl --results $@ --waves $(WAVES) \
	  $(addprefix --incdir ,$(RTL_INCDIRS)) $(addprefix --define ,$(RTL_DEFINES)) \
	  $(addprefix --param ,$(DESIGN_PARAMS)) \
	  --sources $(RTL_FILES) $(MACRO_SIM_MODELS) $(TB_SOURCES)

$(BUILD)/gls_results.xml: $(BUILD)/netlist.v $(TB_SOURCES) $(wildcard $(TB_DIR)/*.py) $(FLOW_DEPS) | $(BUILD)
	GLS_SIM=$(GLS_SIM) $(TIMED) gls $(SCRIPTS)/gls/run_gls.sh $(BUILD) $(TOP) $(TB_MODULE) $(TB_DIR) $(WAVES) \
	  "$(GLS_DEFINES)" $(CELL_VERILOG) $(MACRO_SIM_MODELS) $(TB_SOURCES)

# --- synth ---
# inputs for synth.tcl; the file is replaced only when its content changes
$(BUILD)/synth.env: FORCE | $(BUILD)
	@{ \
	  echo "# Inputs for flow/scripts/yosys/synth.tcl (generated by make)"; \
	  echo "export SB_ROOT='$(SB_ROOT)'"; \
	  echo "export TOP='$(TOP)'"; \
	  echo "export RTL_FILES='$(SYNTH_RTL)'"; \
	  echo "export RTL_INCDIRS='$(RTL_INCDIRS)'"; \
	  echo "export RTL_DEFINES='$(RTL_DEFINES) $(SYNTH_DEFINES)'"; \
	  echo "export RTL_PARAMS='$(DESIGN_PARAMS)'"; \
	  echo "export RTL_FRONTEND='$(RTL_FRONTEND)' SLANG_HIERARCHY='$(SLANG_HIERARCHY)'"; \
	  echo "export LIB_MAP='$(LIB_SYNTH)'"; \
	  echo "export LIB_EXTRA='$(LIB_EXTRA_SYNTH)'"; \
	  echo "export MACRO_LIBS='$(MACRO_LIBS_SYNTH)'"; \
	  echo "export CLOCK_PERIOD_PS='$(CLOCK_PERIOD_PS)' ABC_DELAY_PS='$(ABC_DELAY_PS)'"; \
	  echo "export TIEHI_CELL='$(TIEHI_CELL)' TIEHI_PORT='$(TIEHI_PORT)'"; \
	  echo "export TIELO_CELL='$(TIELO_CELL)' TIELO_PORT='$(TIELO_PORT)'"; \
	  echo "export BUF_CELL='$(BUF_CELL)' BUF_IN='$(BUF_IN)' BUF_OUT='$(BUF_OUT)'"; \
	  echo "export DONT_USE='$(DONT_USE)'"; \
	  echo "export LATCH_CELLS='$(LATCH_CELLS)'"; \
	  echo "export SYNTH_FLATTEN='$(SYNTH_FLATTEN)' SYNTH_RETIME='$(SYNTH_RETIME)' SYNTH_FSM='$(SYNTH_FSM)'"; \
	  echo "export SYNTH_ADDER='$(SYNTH_ADDER)' SYNTH_OUTBUF='$(SYNTH_OUTBUF)'"; \
	  echo "export ABC_SCRIPT='$(ABC_SCRIPT)' ABC_SUBMODULE_DELAY_FRAC='$(ABC_SUBMODULE_DELAY_FRAC)'"; \
	  echo "export ABC_CONSTR_FILE='$(if $(filter 1,$(ABC_CONSTR)),$(BUILD)/abc.constr)'"; \
	  echo "export OUT_DIR='$(BUILD)'"; \
	} > $@.tmp
	@cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

# the SDC is hand-written: report it if missing
$(SDC_FILE):
	@echo "no SDC: write $@ (see docs/05_sdc.md and track/README.md#sdc-helpers; for Lab 2, from spec.md)"; exit 1

# ABC constraints: input driving cell and output load (4 x LOAD_CELL pin, fF)
$(BUILD)/abc.constr: $(LIB_SYNTH) $(FLOW_DEPS) $(SCRIPTS)/util/liberty_pin_cap.py | $(BUILD)
	@cap=$$(python3 $(SCRIPTS)/util/liberty_pin_cap.py $(LIB_SYNTH) $(LOAD_CELL) $(LOAD_PIN)) && \
	{ echo "set_driving_cell $(DRIVING_CELL)"; \
	  awk -v c=$$cap 'BEGIN { printf "set_load %.2f\n", 4 * c * 1000 }'; } > $@
	@echo "abc.constr: $$(tr '\n' ' ' < $@)(fF; 4 x $(LOAD_CELL)/$(LOAD_PIN))"

$(BUILD)/netlist.v: $(BUILD)/synth.env $(SYNTH_RTL) $(SDC_FILE) $(FLOW_DEPS) $(SCRIPTS)/yosys/synth.tcl \
                    $(if $(filter 1,$(ABC_CONSTR)),$(BUILD)/abc.constr)
	@test -f "$(SDC_FILE)" || { echo "no SDC: write $(SDC_FILE) (see docs/05_sdc.md and track/README.md#sdc-helpers)"; exit 1; }
	@test -n "$(CLOCK_PERIOD_PS)" || { echo "could not read the clock period from $(SDC_FILE)"; exit 1; }
	@echo "synth: $(TOP) on $(PDK), period $(CLOCK_PERIOD_NS) ns -> ABC -D $(ABC_DELAY_PS) ps ($(ABC_DELAY_FRAC) x period)"
	cd $(BUILD) && source synth.env && \
	  $(TIMED) synth yosys -q -l synth.log -c $(SCRIPTS)/yosys/synth.tcl || \
	  { echo "synthesis FAILED -- read $(BUILD)/synth.log (search for ERROR / SB-ERROR)"; exit 1; }
	@grep -E 'Chip area|cells$$' $(BUILD)/synth_stat.txt | head -3 || true

# --- sta (one OpenSTA run per corner) ---
$(BUILD)/sta_%.env: FORCE | $(BUILD)
	@{ \
	  echo "# Inputs for flow/scripts/sta/sta.tcl, corner $* (generated by make)"; \
	  echo "export SB_ROOT='$(SB_ROOT)'"; \
	  echo "export TOP='$(TOP)' CORNER='$*'"; \
	  echo "export NETLIST='$(BUILD)/netlist.v'"; \
	  echo "export SDC_FILE='$(SDC_FILE)'"; \
	  echo "export LIBS='$(LIB_$*) $(LIB_EXTRA_$*)'"; \
	  echo "export MACRO_LIBS='$(MACRO_LIBS_$*)'"; \
	  echo "export DRIVING_CELL='$(DRIVING_CELL)' DRIVING_PIN='$(DRIVING_PIN)'"; \
	  echo "export LOAD_CELL='$(LOAD_CELL)' LOAD_PIN='$(LOAD_PIN)'"; \
	  echo "export CLOCK_PERIOD='$(CLOCK_PERIOD)'"; \
	  echo "export ASYNC_RESET_PORT='$(ASYNC_RESET_PORT)'"; \
	  echo "export OUT_DIR='$(BUILD)'"; \
	} > $@.tmp
	@cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

$(BUILD)/sta_%.rpt: $(BUILD)/sta_%.env $(BUILD)/netlist.v $(SDC_FILE) $(SCRIPTS)/sta/sta.tcl
	cd $(BUILD) && source sta_$*.env && \
	  $(TIMED) sta_$* sta -no_init -no_splash -exit $(SCRIPTS)/sta/sta.tcl 2>&1 | tee sta_$*.log | grep '^SB:'

# --- lec (eqy: RTL vs netlist) ---
# parallel LEC proofs
LEC_JOBS ?= $(shell nproc 2>/dev/null || echo 4)
$(BUILD)/lec.eqy: $(SCRIPTS)/lec/eqy.template $(SCRIPTS)/lec/make_eqy.py $(BUILD)/netlist.v $(SYNTH_RTL) $(FLOW_DEPS)
	python3 $(SCRIPTS)/lec/make_eqy.py --template $< --out $@ --top $(TOP) \
	  --frontend $(RTL_FRONTEND) --netlist $(BUILD)/netlist.v \
	  --cell-libs $(LIB_SYNTH) $(LIB_EXTRA_SYNTH) --macro-libs $(MACRO_LIBS_SYNTH) \
	  --blackbox-cells $(if $(filter sb_icg,$(PLATFORM_CELLS)),$(ICG_CELL)) $(if $(filter 1,$(SLANG_HIERARCHY)),--slang-hierarchy) \
	  --adder $(SYNTH_ADDER) \
	  --incdirs $(RTL_INCDIRS) --defines $(RTL_DEFINES) $(SYNTH_DEFINES) --params $(DESIGN_PARAMS) \
	  --rtl $(SYNTH_RTL)

$(BUILD)/lec.log: $(BUILD)/lec.eqy
	cd $(BUILD) && rm -rf lec && \
	  $(TIMED) lec eqy -j $(LEC_JOBS) -f -d lec lec.eqy > lec_run.log 2>&1 || \
	  { grep -E 'Failed to prove|DONE' lec_run.log; echo "LEC FAILED -- see $(BUILD)/lec_run.log and track/reading_logs.md#lec"; exit 1; }
	@cp $(BUILD)/lec_run.log $@
	@grep -E 'DONE' $@ | tail -1

# --- qor ---
$(BUILD)/qor.csv: $(BUILD)/netlist.v $(foreach c,$(CORNERS),$(BUILD)/sta_$(c).rpt) $(SCRIPTS)/qor/collect_qor.py
	python3 $(SCRIPTS)/qor/collect_qor.py --build $(BUILD) --design $(DESIGN) --platform $(PDK) \
	  --corners $(CORNERS) --out $@
	@column -s, -t < $@
