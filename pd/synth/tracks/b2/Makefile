# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Track B2 (Synopsys) flow: lint, sim, synth, sta, lec, gls and qor for one DESIGN on sky130_fd_sc_hd. Run `make help` for usage.

SHELL         := /bin/bash
.SHELLFLAGS   := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
# keep generated files such as *.env
.SECONDARY:

ROOT    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
FLOW    := $(ROOT)/flow
DESIGN  ?= gcd
LIBRARY := sky130_fd_sc_hd

# --- library (SiliconBadgers sky130 PDK repo, cloned next to this repo) ---
SB_PDK ?= $(abspath $(ROOT)/../silicon-badgers-sky130-pdk)
VIEWS  := $(SB_PDK)/synopsys/views
CELLS  := $(SB_PDK)/synopsys/$(LIBRARY)
# Liberty corner names: <process>_<temperature>_<voltage>
CORNER_tt := tt_025C_1v80
CORNER_ss := ss_100C_1v60
CORNER_ff := ff_n40C_1v95
CORNERS      ?= tt ss ff
# corner synthesis optimizes for (slow cells: worst setup)
SYNTH_CORNER ?= ss
# $(call cell_db,<corner>): standard-cell .db, built once by $SB_PDK/synopsys/make_views.sh
cell_db = $(VIEWS)/$(LIBRARY)__$(CORNER_$(1)).db
# cell models for gate-level simulation
CELL_VERILOG := $(CELLS)/verilog/primitives.v $(CELLS)/verilog/$(LIBRARY).v
# cells synthesis must not use: power-gating, probe, clock and delay cells
DONT_USE := $(LIBRARY)__lpflow_* $(LIBRARY)__probe* $(LIBRARY)__clk* $(LIBRARY)__dlygate* $(LIBRARY)__dlymetal*

# --- design ---
DESIGN_DIR_gcd              := labs/lab1_reference/gcd
DESIGN_DIR_ibex             := labs/lab1_reference/ibex
DESIGN_DIR_sb_systolic_tile := labs/lab2_systolic
ifeq ($(DESIGN_DIR_$(DESIGN)),)
  $(error DESIGN=$(DESIGN) is unknown: use gcd, ibex or sb_systolic_tile)
endif
DESIGN_DIR := $(ROOT)/$(DESIGN_DIR_$(DESIGN))

# defaults for the optional design.mk settings
RTL_INCDIRS      :=
RTL_DEFINES      :=
# defines for synthesis and LEC only
SYNTH_DEFINES    :=
# defines for VCS only (lint, RTL sim)
SIM_DEFINES      :=
# wrapper cells from flow/cells/ that the RTL instantiates (e.g. sb_icg)
PLATFORM_CELLS   :=
# hard macros: <name> has macros/<name>_sky130_fd_sc_hd_<corner>.lib
MACROS           :=
MACRO_SIM_MODELS :=
# asynchronous reset input: STA counts the flip-flops hanging straight on it
ASYNC_RESET_PORT :=
include $(DESIGN_DIR)/design.mk

SYNTH_RTL := $(foreach c,$(PLATFORM_CELLS),$(FLOW)/cells/$(LIBRARY)_$(c).v) $(RTL_FILES)
SIM_RTL   := $(RTL_FILES) $(MACRO_SIM_MODELS)

# --- knobs (KNOB=value on the make line) ---
# top-level parameters, NAME=VALUE (the testbench reads SB_DESIGN_PARAMS)
DESIGN_PARAMS ?=
export SB_DESIGN_PARAMS := $(DESIGN_PARAMS)
# clock period override in ns (replaces the SDC's `set clk_period` line)
CLOCK_PERIOD  ?=
DC_COMPILE    ?= compile_ultra
SYNTH_RETIME  ?= 0
# your own Tcl file, sourced by dc_shell just before compile
DC_EXTRA      ?=
LINT_TOOL     ?= auto
WAVES         ?= 0

empty :=
space := $(empty) $(empty)
PARAMS_TAG := $(if $(strip $(DESIGN_PARAMS)),_$(subst =,,$(subst $(space),_,$(strip $(DESIGN_PARAMS)))))
BUILD      ?= $(ROOT)/build/$(DESIGN)/$(LIBRARY)$(PARAMS_TAG)$(if $(CLOCK_PERIOD),_p$(CLOCK_PERIOD))
# compiled macro libraries, shared by all builds of the design
MACRO_DB_DIR := $(ROOT)/build/$(DESIGN)/macros
macro_dbs     = $(foreach m,$(MACROS),$(MACRO_DB_DIR)/$(m)_$(LIBRARY)_$(1).db)
# the SDC the tools read (a copy, with the CLOCK_PERIOD override if given)
SDC := $(BUILD)/constraints.sdc

# $(call check_run,<log>,<output>,<step>): fail when <output> is missing or <log> has errors
check_run = cd $(BUILD) && if [ ! -s $(2) ] || grep -qE '^(Error|SB-ERROR)' $(1); then \
	grep -m5 -E '^(Error|SB-ERROR)' $(1) || true; \
	echo "$(3) FAILED -- read $(BUILD)/$(1) (search for Error)"; rm -f $(2); exit 1; fi

# --- targets ---
.PHONY: help all lint sim synth sta lec gls qor macros clean FORCE
FORCE:

help:
	@echo "usage: make <target> DESIGN=<design> [KNOB=value ...]"
	@echo "  targets: lint sim synth sta lec gls qor | all | macros | clean"
	@echo "  DESIGN:  gcd ibex sb_systolic_tile"
	@echo "  knobs:   CLOCK_PERIOD=<ns>  DESIGN_PARAMS=\"A=1 B=2\"  DC_COMPILE=compile_ultra|compile"
	@echo "           SYNTH_RETIME=1  DC_EXTRA=<file.tcl>  LINT_TOOL=auto|vc|vcs  WAVES=1  SB_PDK=<dir>"
	@echo "outputs: build/<design>/$(LIBRARY)/ (see track/README.md)"

# print one variable, e.g. make -s print-CELL_VERILOG
print-%:
	@echo '$($*)'

all: lint sim synth sta lec gls qor

lint:  $(BUILD)/lint.log
sim:   $(BUILD)/results.xml
synth: $(BUILD)/netlist.v
sta:   $(foreach c,$(CORNERS),$(BUILD)/sta_$(c).rpt)
	@echo "sign-off: setup at ss, hold at ff (track/reading_logs.md)"
lec:   $(BUILD)/lec.log
gls:   $(BUILD)/gls_results.xml
qor:   $(BUILD)/qor.csv
macros: $(foreach c,$(CORNERS),$(call macro_dbs,$(c)))
	@echo "macro libraries: $(if $(MACROS),$(MACRO_DB_DIR),none for $(DESIGN))"

clean:
	rm -rf $(BUILD)

$(BUILD):
	mkdir -p $@

# --- libraries ---
# standard-cell .db files come from the PDK repo
$(VIEWS)/%.db:
	@echo "missing $@"
	@echo "build the Synopsys library views once: $(SB_PDK)/synopsys/make_views.sh (track/README.md)"
	@exit 1

# macro Liberty (.lib) -> .db with lc_shell
$(MACRO_DB_DIR)/%.db: $(DESIGN_DIR)/macros/%.lib $(FLOW)/lc/compile_lib.tcl
	@mkdir -p $(@D)
	cd $(@D) && LIB_FILE=$< DB_FILE=$@ lc_shell -no_init -f $(FLOW)/lc/compile_lib.tcl < /dev/null > $*.log 2>&1 || true
	@test -s $@ || { echo "lc_shell could not compile $< -- read $(@D)/$*.log"; exit 1; }

# --- constraints ---
# the SDC is hand-written: report it if missing
$(DESIGN_DIR)/sdc/%.sdc:
	@echo "no SDC: write $@ (Lab 2: see track/lab2.md)"; exit 1

$(SDC): $(SDC_FILE) | $(BUILD)
ifeq ($(CLOCK_PERIOD),)
	cp $< $@
else
	@grep -q '^set clk_period ' $< || { echo "CLOCK_PERIOD needs a 'set clk_period <ns>' line in $<"; exit 1; }
	sed -E 's/^set clk_period .*/set clk_period $(CLOCK_PERIOD)/' $< > $@
endif

# --- lint (VC SpyGlass if installed, else vcs +lint=all) ---
$(BUILD)/lint.log: $(SIM_RTL) $(FLOW)/lint/run_lint.sh $(FLOW)/lint/vc_lint.tcl | $(BUILD)
	@echo "lint: $(TOP) -> $(BUILD)/lint_run.log"
	cd $(BUILD) && TOP='$(TOP)' RTL_FILES='$(SIM_RTL)' RTL_INCDIRS='$(RTL_INCDIRS)' \
	  RTL_DEFINES='$(strip $(RTL_DEFINES) $(SIM_DEFINES))' LINT_TOOL='$(LINT_TOOL)' \
	  $(FLOW)/lint/run_lint.sh > lint_run.log 2>&1 || \
	  { tail -20 lint_run.log; echo "lint FAILED -- read $(BUILD)/lint_run.log"; exit 1; }
	@cp $(BUILD)/lint_run.log $@
	@grep '^SB:' $@ || true

# --- sim / gls (the same cocotb testbench on the RTL and on the netlist, VCS) ---
COCOTB := python3 $(FLOW)/sim/run_cocotb.py

$(BUILD)/results.xml: $(SIM_RTL) $(wildcard $(TB_DIR)/*.py) $(DESIGN_DIR)/design.mk $(FLOW)/sim/run_cocotb.py | $(BUILD)
	$(COCOTB) --toplevel $(TOP) --test-module $(TB_MODULE) --test-dir $(TB_DIR) \
	  --build-dir $(BUILD)/sim_rtl --results $@ --waves $(WAVES) \
	  $(addprefix --incdir ,$(RTL_INCDIRS)) $(addprefix --define ,$(RTL_DEFINES) $(SIM_DEFINES)) \
	  $(addprefix --param ,$(DESIGN_PARAMS)) \
	  --sources $(SIM_RTL) 2>&1 | tee $(BUILD)/sim.log

# VCS rejects the UDP port declarations of primitives.v under `default_nettype none`
# (Error-[IND] Identifier not declared): GLS compiles a copy with `default_nettype wire`
GLS_CELL_VERILOG := $(BUILD)/primitives_vcs.v $(filter-out %/primitives.v,$(CELL_VERILOG))
$(BUILD)/primitives_vcs.v: $(CELLS)/verilog/primitives.v | $(BUILD)
	sed 's/^`default_nettype none/`default_nettype wire/' $< > $@

$(BUILD)/gls_results.xml: $(BUILD)/netlist.v $(GLS_CELL_VERILOG) $(MACRO_SIM_MODELS) $(wildcard $(TB_DIR)/*.py) $(FLOW)/sim/run_cocotb.py
	$(COCOTB) --toplevel $(TOP) --test-module $(TB_MODULE) --test-dir $(TB_DIR) \
	  --build-dir $(BUILD)/sim_gls --results $@ --waves $(WAVES) \
	  --define FUNCTIONAL --define 'UNIT_DELAY=#1' \
	  --sources $(BUILD)/netlist.v $(GLS_CELL_VERILOG) $(MACRO_SIM_MODELS) 2>&1 | tee $(BUILD)/gls.log

# --- synth (Design Compiler) ---
# inputs for synth.tcl; the file is replaced only when its content changes
$(BUILD)/synth.env: FORCE | $(BUILD)
	@{ \
	  echo "# Inputs for flow/dc/synth.tcl (written by make)"; \
	  echo "export TOP='$(TOP)'"; \
	  echo "export RTL_FILES='$(SYNTH_RTL)'"; \
	  echo "export RTL_INCDIRS='$(RTL_INCDIRS)'"; \
	  echo "export RTL_DEFINES='$(strip $(RTL_DEFINES) $(SYNTH_DEFINES))'"; \
	  echo "export RTL_PARAMS='$(DESIGN_PARAMS)'"; \
	  echo "export SDC_FILE='$(SDC)'"; \
	  echo "export CELL_DB='$(call cell_db,$(SYNTH_CORNER))'"; \
	  echo "export MACRO_DBS='$(call macro_dbs,$(SYNTH_CORNER))'"; \
	  echo "export DONT_USE='$(DONT_USE)'"; \
	  echo "export DC_COMPILE='$(DC_COMPILE)' SYNTH_RETIME='$(SYNTH_RETIME)'"; \
	  echo "export DC_EXTRA='$(if $(DC_EXTRA),$(abspath $(DC_EXTRA)))'"; \
	} > $@.tmp
	@cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

$(BUILD)/netlist.v: $(BUILD)/synth.env $(SYNTH_RTL) $(SDC) $(call cell_db,$(SYNTH_CORNER)) \
                    $(call macro_dbs,$(SYNTH_CORNER)) $(FLOW)/dc/synth.tcl $(DESIGN_DIR)/design.mk
	@echo "synth: dc_shell, $(TOP) at $(SYNTH_CORNER) -> $(BUILD)/synth.log"
	cd $(BUILD) && rm -f netlist.v && source synth.env && \
	  dc_shell -f $(FLOW)/dc/synth.tcl < /dev/null > synth.log 2>&1 || true
	@$(call check_run,synth.log,netlist.v,synthesis)
	@grep '^SB:' $(BUILD)/synth.log || true

# --- sta (PrimeTime, one run per corner) ---
$(BUILD)/sta_%.env: FORCE | $(BUILD)
	@{ \
	  echo "# Inputs for flow/pt/sta.tcl, corner $* (written by make)"; \
	  echo "export TOP='$(TOP)' CORNER='$*'"; \
	  echo "export NETLIST='$(BUILD)/netlist.v'"; \
	  echo "export SDC_FILE='$(SDC)'"; \
	  echo "export CELL_DB='$(call cell_db,$*)'"; \
	  echo "export MACRO_DBS='$(call macro_dbs,$*)'"; \
	  echo "export ASYNC_RESET_PORT='$(ASYNC_RESET_PORT)'"; \
	} > $@.tmp
	@cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

STA_DBS := $(foreach c,$(CORNERS),$(call cell_db,$(c)) $(call macro_dbs,$(c)))
$(BUILD)/sta_%.rpt: $(BUILD)/sta_%.env $(BUILD)/netlist.v $(SDC) $(STA_DBS) $(FLOW)/pt/sta.tcl
	cd $(BUILD) && rm -f sta_$*.rpt && source sta_$*.env && \
	  pt_shell -f $(FLOW)/pt/sta.tcl < /dev/null > sta_$*.log 2>&1 || true
	@$(call check_run,sta_$*.log,sta_$*.rpt,STA at $*)
	@grep '^SB:' $(BUILD)/sta_$*.log || true

# --- lec (Formality: RTL against the netlist, guided by synth.svf) ---
$(BUILD)/lec.env: FORCE | $(BUILD)
	@{ \
	  echo "# Inputs for flow/fm/lec.tcl (written by make)"; \
	  echo "export TOP='$(TOP)'"; \
	  echo "export RTL_FILES='$(SYNTH_RTL)'"; \
	  echo "export RTL_INCDIRS='$(RTL_INCDIRS)'"; \
	  echo "export RTL_DEFINES='$(strip $(RTL_DEFINES) $(SYNTH_DEFINES))'"; \
	  echo "export RTL_PARAMS='$(DESIGN_PARAMS)'"; \
	  echo "export NETLIST='$(BUILD)/netlist.v' SVF='$(BUILD)/synth.svf'"; \
	  echo "export CELL_DB='$(call cell_db,$(SYNTH_CORNER))'"; \
	  echo "export MACRO_DBS='$(call macro_dbs,$(SYNTH_CORNER))'"; \
	} > $@.tmp
	@cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

$(BUILD)/lec.log: $(BUILD)/lec.env $(BUILD)/netlist.v $(SYNTH_RTL) $(FLOW)/fm/lec.tcl
	@echo "lec: fm_shell -> $(BUILD)/lec_run.log"
	cd $(BUILD) && source lec.env && fm_shell -f $(FLOW)/fm/lec.tcl < /dev/null > lec_run.log 2>&1 || true
	@if grep -q 'Verification SUCCEEDED' $(BUILD)/lec_run.log; then \
	  cp $(BUILD)/lec_run.log $@; echo "lec: Verification SUCCEEDED"; \
	else \
	  grep -m5 -E '^Error|Verification (FAILED|INCONCLUSIVE)' $(BUILD)/lec_run.log || true; \
	  echo "LEC FAILED -- read $(BUILD)/lec_run.log and lec_failing.rpt (track/reading_logs.md)"; exit 1; \
	fi

# --- qor ---
$(BUILD)/qor.csv: $(BUILD)/netlist.v $(foreach c,$(CORNERS),$(BUILD)/sta_$(c).rpt) $(FLOW)/qor/collect_qor.py
	python3 $(FLOW)/qor/collect_qor.py --build $(BUILD) --design $(DESIGN) --library $(LIBRARY) \
	  --corners $(CORNERS) --out $@
	@column -s, -t < $@
