# File:        Makefile
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Track B1 (Cadence) flow: lint, sim, synth, sta, lec, gls and qor for one DESIGN on sky130_scl_9T.
#              Run `make help` in this folder (tracks/b1) for usage.

SHELL         := /bin/bash
.SHELLFLAGS   := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

# TRACK_DIR: this track's folder (tracks/b1: flow, design.mk, SDCs, build/); SB_ROOT: the repo root (shared RTL, testbenches)
TRACK_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SB_ROOT   := $(abspath $(TRACK_DIR)/../..)
FLOW      := $(TRACK_DIR)/flow

# --- library: sky130_scl_9T from the SiliconBadgers PDK repo (cloned next to the course folder) ---
SB_PDK   ?= $(abspath $(SB_ROOT)/../silicon-badgers-sky130-pdk)
export SB_PDK
LIB_NAME := sky130_scl_9T
SCL      := $(SB_PDK)/cadence/sky130_scl_9T
# Liberty per corner: <process>_<voltage>_<temperature>
LIB_tt   := $(SCL)/lib/sky130_tt_1.8_25_nldm.lib.gz
LIB_ss   := $(SCL)/lib/sky130_ss_1.62_125_nldm.lib.gz
LIB_ff   := $(SCL)/lib/sky130_ff_1.98_0_nldm.lib.gz
# tie cells TIEHI/TIELO: a separate Liberty file with one typical corner, used at every corner
LIB_EXTRA    := $(SB_PDK)/cadence/sky130_scl_9T_tech/lib/sky130_scl_9T_phyCells.lib
# cell simulation models (gate-level simulation; the tie-cell models are in flow/cells/) and physical views (Lab 0)
CELL_VERILOG := $(SCL)/verilog/sky130_scl_9T.v $(FLOW)/cells/sky130_scl_9T_tiecells.v
TECH_LEF     := $(SB_PDK)/cadence/sky130_scl_9T_tech/lef/sky130_scl_9T.tlef
CELL_LEF     := $(SCL)/lef/sky130_scl_9T.lef
# cells synthesis must not use: clock, delay, clock-gate, tri-state and scan cells
DONT_USE    := CLK* DLY* ICG* TBUF* SDFF*
# latch cells, for the latch check
LATCH_CELLS := TLAT*

# --- tools (override on the command line, e.g. GENUS=/path/to/genus) ---
# TOOL_WRAP: prefix for every tool command, e.g. TOOL_WRAP=cadence-run where tools run in a wrapper
TOOL_WRAP    ?=
GENUS        ?= genus
GENUS_FLAGS  ?= -no_gui
TEMPUS       ?= tempus
TEMPUS_FLAGS ?= -stylus -no_gui
LEC          ?= lec
LEC_FLAGS    ?= -xl -nogui
XRUN         ?= xrun
# HAL rules that are off by default (style rules that bury real findings): flow/xcelium/hal_rules.f
HAL_ARGS     ?= -f $(FLOW)/xcelium/hal_rules.f

# --- design ---
DESIGN ?= gcd
DESIGN_DIR_gcd              := labs/lab1_reference/gcd
DESIGN_DIR_ibex             := labs/lab1_reference/ibex
DESIGN_DIR_sb_systolic_tile := labs/lab2_systolic
ifeq ($(DESIGN_DIR_$(DESIGN)),)
  $(error DESIGN=$(DESIGN) is unknown. Use gcd, ibex or sb_systolic_tile)
endif
# DESIGN_DIR: the lab folder at the repo root (RTL, testbench, macro models);
# TRACK_DESIGN_DIR: the same folder in this track (design.mk, SDCs, HAL waivers, macro Liberty)
DESIGN_DIR       := $(SB_ROOT)/$(DESIGN_DIR_$(DESIGN))
TRACK_DESIGN_DIR := $(TRACK_DIR)/$(DESIGN_DIR_$(DESIGN))
include $(TRACK_DESIGN_DIR)/design.mk

# optional design.mk settings
RTL_INCDIRS      ?=
SYNTH_DEFINES    ?=
SIM_DEFINES      ?=
# extra Verilog for synthesis and LEC only (e.g. the clock-gate wrapper)
SYNTH_EXTRA      ?=
# black box of a hard macro, for lint (synthesis and LEC take the macro from its Liberty)
MACRO_VERILOG    ?=
MACRO_SIM_MODELS ?=
MACRO_LIBS_tt    ?=
MACRO_LIBS_ss    ?=
MACRO_LIBS_ff    ?=
# asynchronous reset input, and how many flip-flops may hang on it directly
ASYNC_RESET_PORT ?=
RESET_SYNC_FLOPS ?= 2
BRONZE_PERIOD_NS ?=
SILVER_PERIOD_NS ?=
# lint waivers: one line per waived HAL message, `<code> [<file pattern> [<signal>]]  # why`
LINT_WAIVERS     ?= $(wildcard $(TRACK_DESIGN_DIR)/hal_waivers.txt)

# --- run knobs ---
CORNERS      := tt ss ff
# Liberty corner synthesis maps to
SYNTH_CORNER ?= ss
# Genus effort for syn_generic, syn_map and syn_opt: low, medium or high
SYNTH_EFFORT ?= medium
# adder architecture: auto (Genus picks per path) or ripple (ripple-carry everywhere)
SYNTH_ADDER  ?= auto
# 1 = let Genus move registers across logic (retiming)
SYNTH_RETIME ?= 0
# top-level parameters, NAME=VALUE (e.g. DESIGN_PARAMS="MUL_PIPE=1")
DESIGN_PARAMS ?=
# clock period override in ns: replaces the `set clk_period` line of the SDC
CLOCK_PERIOD  ?=
# 1 = save waveforms in sim and gls
WAVES         ?= 0
# wall-clock limit of one simulation run (sim, gls) in seconds; a normal run takes well under a minute
SIM_TIMEOUT   ?= 900
# Conformal: genus = run the dofile Genus wrote (default), own = flow/conformal/lec.do only
LEC_MODE      ?= genus
export SB_DESIGN_PARAMS := $(DESIGN_PARAMS)

PARAMS_TAG := $(if $(filter command line,$(origin DESIGN_PARAMS)),_$(subst =,,$(subst $(eval) ,_,$(strip $(DESIGN_PARAMS)))))
BUILD      ?= $(TRACK_DIR)/build/$(DESIGN)/$(LIB_NAME)$(PARAMS_TAG)$(if $(CLOCK_PERIOD),_p$(CLOCK_PERIOD))
SYNTH_RTL  := $(SYNTH_EXTRA) $(RTL_FILES)
COCOTB     := $(TOOL_WRAP) python3 $(FLOW)/xcelium/run_cocotb.py --timeout $(SIM_TIMEOUT)
FLOW_DEPS  := $(TRACK_DESIGN_DIR)/design.mk

# --- targets ---
.PHONY: help info env-check all lint sim synth sta lec gls qor check clean FORCE
FORCE:

help:
	@echo "usage: make <step> DESIGN=<design> [CLOCK_PERIOD=<ns>] [DESIGN_PARAMS=\"N=V ...\"]"
	@echo "  steps:   lint sim synth sta lec gls qor | all | check | clean | info | env-check"
	@echo "  DESIGN:  gcd ibex sb_systolic_tile"
	@echo "  knobs:   SYNTH_EFFORT=low|medium|high  SYNTH_ADDER=auto|ripple  SYNTH_RETIME=0|1  SYNTH_CORNER=ss"
	@echo "           WAVES=1  SIM_TIMEOUT=<s>  LEC_MODE=genus|own  TOOL_WRAP=<cmd>  BUILD=<dir>"
	@echo "  library: $(LIB_NAME) from SB_PDK=$(SB_PDK)"
	@echo "outputs: build/<DESIGN>/$(LIB_NAME)/ (see track/README.md)"

info:
	@echo "DESIGN=$(DESIGN) TOP=$(TOP) library=$(LIB_NAME)"
	@echo "SDC=$(SDC_FILE)$(if $(CLOCK_PERIOD), (period overridden: $(CLOCK_PERIOD) ns))"
	@echo "synth corner=$(SYNTH_CORNER): $(LIB_$(SYNTH_CORNER))"
	@echo "tie cells (every corner): $(LIB_EXTRA)"
	@$(foreach c,$(CORNERS),echo "  $(c): $(LIB_$(c)) $(MACRO_LIBS_$(c))";)
	@echo "BUILD=$(BUILD)"

# print one variable, e.g. make -s print-LIB_tt
print-%:
	@echo '$($*)'

# tools on PATH, PDK files present, cocotb importable
env-check:
	@for t in $(GENUS) $(TEMPUS) $(LEC) $(XRUN) python3; do printf '%-8s ' $$t; command -v $$t || echo MISSING; done
	@for f in $(LIB_tt) $(LIB_ss) $(LIB_ff) $(LIB_EXTRA) $(CELL_VERILOG) $(TECH_LEF) $(CELL_LEF); do \
	  test -f $$f && echo "OK      $$f" || echo "MISSING $$f (set SB_PDK, see track/README.md)"; done
	@python3 -c 'import cocotb; print("cocotb", cocotb.__version__)' || echo "cocotb MISSING (pip install cocotb)"

all: lint sim synth sta lec gls qor

lint:  $(BUILD)/lint.done
sim:   $(BUILD)/sim.done
synth: $(BUILD)/netlist.v
sta:   $(BUILD)/sta.done
lec:   $(BUILD)/lec.done
gls:   $(BUILD)/gls.done
qor:   $(BUILD)/qor.csv

check:
	python3 $(FLOW)/scripts/check.py --build $(BUILD) --top $(TOP) --latch-cells "$(LATCH_CELLS)" \
	  --lint-waivers "$(LINT_WAIVERS)" \
	  --async-reset-port "$(ASYNC_RESET_PORT)" --reset-sync-flops $(RESET_SYNC_FLOPS) \
	  --bronze-ns "$(BRONZE_PERIOD_NS)" --silver-ns "$(SILVER_PERIOD_NS)"

clean:
	rm -rf $(BUILD)

$(BUILD):
	mkdir -p $@

# --- inputs for the Tcl scripts; the file is replaced only when its content changes ---
$(BUILD)/flow.env: FORCE | $(BUILD)
	@{ \
	  echo "# Inputs for flow/genus, flow/tempus and flow/conformal (written by make; source it to rerun a tool by hand)"; \
	  echo "export FLOW_DIR='$(FLOW)' OUT_DIR='$(BUILD)' TOP='$(TOP)'"; \
	  echo "export RTL_FILES='$(SYNTH_RTL)'"; \
	  echo "export RTL_INCDIRS='$(RTL_INCDIRS)'"; \
	  echo "export RTL_DEFINES='$(SYNTH_DEFINES)'"; \
	  echo "export RTL_PARAMS='$(DESIGN_PARAMS)'"; \
	  echo "export SDC_FILE='$(BUILD)/constraints.sdc'"; \
	  echo "export LIB_SYNTH='$(LIB_$(SYNTH_CORNER))' MACRO_LIBS_SYNTH='$(MACRO_LIBS_$(SYNTH_CORNER))'"; \
	  echo "export LIB_EXTRA='$(LIB_EXTRA)' TIEHI_CELL='TIEHI' TIELO_CELL='TIELO'"; \
	  $(foreach c,$(CORNERS),echo "export LIB_$(c)='$(LIB_$(c))' MACRO_LIBS_$(c)='$(MACRO_LIBS_$(c))'";) \
	  echo "export DONT_USE='$(DONT_USE)' SYNTH_EFFORT='$(SYNTH_EFFORT)'"; \
	  echo "export SYNTH_ADDER='$(SYNTH_ADDER)' SYNTH_RETIME='$(SYNTH_RETIME)'"; \
	  echo "export ASYNC_RESET_PORT='$(ASYNC_RESET_PORT)' LEC_MODE='$(LEC_MODE)'"; \
	} > $@.tmp
	@cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

# --- lint: Xcelium HAL; warnings fail unless waived in hal_waivers.txt ---
# HAL writes its messages only to the xrun log file (-logfile), not to stdout
$(BUILD)/lint.done: $(RTL_FILES) $(MACRO_VERILOG) $(LINT_WAIVERS) $(FLOW)/xcelium/hal_rules.f $(FLOW_DEPS) | $(BUILD)
	@mkdir -p $(BUILD)/lint
	cd $(BUILD)/lint && rc=0 && \
	  { $(TOOL_WRAP) $(XRUN) -hal -sv -top $(TOP) $(addprefix -incdir ,$(RTL_INCDIRS)) \
	    $(addprefix -define ,$(SIM_DEFINES)) $(foreach p,$(DESIGN_PARAMS),-defparam $(TOP).$(p)) $(HAL_ARGS) \
	    $(RTL_FILES) $(MACRO_VERILOG) -logfile $(BUILD)/lint.log > xrun_stdout.log 2>&1 || rc=$$?; } && \
	  echo "SB: xrun exit status $$rc" >> $(BUILD)/lint.log
	python3 $(FLOW)/scripts/check.py --build $(BUILD) --top $(TOP) --lint-waivers "$(LINT_WAIVERS)" --only lint_clean || \
	  { echo "lint FAILED -- read $(BUILD)/lint.log"; exit 1; }
	@touch $@

# --- sim / gls: the same cocotb testbench on the RTL and on the netlist ---
$(BUILD)/sim.done: $(RTL_FILES) $(MACRO_SIM_MODELS) $(wildcard $(TB_DIR)/*.py) $(FLOW_DEPS) | $(BUILD)
	t0=$$SECONDS; \
	$(COCOTB) --toplevel $(TOP) --test-module $(TB_MODULE) --test-dir $(TB_DIR) \
	  --build-dir $(BUILD)/sim_rtl --results $(BUILD)/results.xml --waves $(WAVES) \
	  $(addprefix --incdir ,$(RTL_INCDIRS)) $(addprefix --define ,$(SIM_DEFINES)) \
	  $(addprefix --param ,$(DESIGN_PARAMS)) --sources $(RTL_FILES) $(MACRO_SIM_MODELS); \
	echo "sim $$((SECONDS - t0))" >> $(BUILD)/runtimes.txt
	@touch $@

$(BUILD)/gls.done: $(BUILD)/netlist.v $(MACRO_SIM_MODELS) $(wildcard $(TB_DIR)/*.py) $(FLOW_DEPS)
	t0=$$SECONDS; \
	$(COCOTB) --toplevel $(TOP) --test-module $(TB_MODULE) --test-dir $(TB_DIR) \
	  --build-dir $(BUILD)/sim_gls --results $(BUILD)/gls_results.xml --waves $(WAVES) \
	  --sources $(BUILD)/netlist.v $(CELL_VERILOG) $(MACRO_SIM_MODELS); \
	echo "gls $$((SECONDS - t0))" >> $(BUILD)/runtimes.txt
	@touch $@

# --- constraints: your SDC, with the period replaced when CLOCK_PERIOD is set ---
$(SDC_FILE):
	@echo "no SDC: write $@ (see ../../docs/05_sdc.md; for Lab 2, from spec.md)"; exit 1

$(BUILD)/constraints.sdc: $(SDC_FILE) | $(BUILD)
ifeq ($(CLOCK_PERIOD),)
	cp $< $@
else
	sed -E 's/^([[:space:]]*set[[:space:]]+clk_period[[:space:]]+)[^;#]*/\1$(CLOCK_PERIOD) /' $< > $@
	@grep -qE '^[[:space:]]*set[[:space:]]+clk_period[[:space:]]+$(CLOCK_PERIOD) ' $@ || \
	  { rm -f $@; echo "CLOCK_PERIOD needs a line 'set clk_period <ns>' in $<"; exit 1; }
endif

# $(call tool_errors,<log>): fail when a Genus, Tempus or Conformal log has an error line (**ERROR:, Error :, // Error:)
# that flow/scripts/tool_error_waivers.txt does not waive; these tools can print an error and still exit 0
tool_errors = python3 $(FLOW)/scripts/tool_errors.py $(1) --waivers $(FLOW)/scripts/tool_error_waivers.txt

# --- synth: Genus ---
$(BUILD)/netlist.v: $(BUILD)/flow.env $(SYNTH_RTL) $(BUILD)/constraints.sdc $(FLOW)/genus/synth.tcl \
                    $(MACRO_LIBS_$(SYNTH_CORNER))
	@echo "synth: $(TOP) on $(LIB_NAME) at $(SYNTH_CORNER), log $(BUILD)/synth.log"
	cd $(BUILD) && source flow.env && rm -f netlist.v && t0=$$SECONDS && \
	  { $(TOOL_WRAP) $(GENUS) $(GENUS_FLAGS) -files $(FLOW)/genus/synth.tcl < /dev/null > synth.log 2>&1 || true; } && \
	  echo "synth $$((SECONDS - t0))" >> runtimes.txt
	@grep -q '^SB: synthesis done' $(BUILD)/synth.log || { rm -f $@; grep -E '^(Error|SB-)' $(BUILD)/synth.log | head -5; \
	  echo "synthesis FAILED -- read $(BUILD)/synth.log (search for Error)"; exit 1; }
	@grep -E '^SB' $(BUILD)/synth.log || true
	@$(call tool_errors,$(BUILD)/synth.log) || { rm -f $@; echo "synthesis FAILED -- read $(BUILD)/synth.log (search for Error)"; exit 1; }
	@python3 $(FLOW)/scripts/check.py --build $(BUILD) --top $(TOP) --latch-cells "$(LATCH_CELLS)" \
	  --only no_latches design_check --quiet --gate || \
	  { rm -f $@; echo "synthesis check FAILED -- read $(BUILD)/check_design.rpt and synth.log"; exit 1; }

# --- sta: Tempus, one run with the tt, ss and ff views ---
$(BUILD)/sta.done: $(BUILD)/netlist.v $(BUILD)/constraints.sdc $(FLOW)/tempus/sta.tcl $(FLOW)/tempus/mmmc.tcl \
                   $(foreach c,$(CORNERS),$(MACRO_LIBS_$(c)))
	cd $(BUILD) && source flow.env && rm -f sta_summary.txt && t0=$$SECONDS && \
	  { $(TOOL_WRAP) $(TEMPUS) $(TEMPUS_FLAGS) -files $(FLOW)/tempus/sta.tcl < /dev/null > sta.log 2>&1 || true; } && \
	  echo "sta $$((SECONDS - t0))" >> runtimes.txt
	@test -s $(BUILD)/sta_summary.txt || { grep -E '^\*\*ERROR' $(BUILD)/sta.log | head -5; \
	  echo "STA FAILED -- read $(BUILD)/sta.log (search for **ERROR)"; exit 1; }
	@$(call tool_errors,$(BUILD)/sta.log) || { echo "STA FAILED -- read $(BUILD)/sta.log (search for **ERROR)"; exit 1; }
	@cat $(BUILD)/sta_summary.txt
	@touch $@

# --- lec: Conformal, RTL (golden) vs. netlist (revised) ---
$(BUILD)/lec.done: $(BUILD)/netlist.v $(FLOW)/conformal/lec.do
	cd $(BUILD) && source flow.env && rm -f lec.log && t0=$$SECONDS && \
	  { $(TOOL_WRAP) $(LEC) $(LEC_FLAGS) -dofile $(FLOW)/conformal/lec.do < /dev/null > lec_run.log 2>&1 || true; } && \
	  echo "lec $$((SECONDS - t0))" >> runtimes.txt
	@grep -hE 'No of (compare|diff|abort|unknown) points' $(BUILD)/lec_run.log > $(BUILD)/lec_summary.txt || true
	@cat $(BUILD)/lec_summary.txt
	@$(call tool_errors,$(BUILD)/lec_run.log) || { echo "LEC FAILED -- read $(BUILD)/lec_run.log (search for // Error)"; exit 1; }
	@python3 $(FLOW)/scripts/check.py --build $(BUILD) --top $(TOP) --only lec --quiet || \
	  { echo "LEC FAILED -- read $(BUILD)/lec_run.log and $(BUILD)/lec.log"; exit 1; }
	@touch $@

# --- qor: one row per corner ---
$(BUILD)/qor.csv: $(BUILD)/sta.done $(FLOW)/scripts/qor.py
	python3 $(FLOW)/scripts/qor.py --build $(BUILD) --design $(DESIGN) --top $(TOP) --library $(LIB_NAME) \
	  --corners $(CORNERS) --synth-corner $(SYNTH_CORNER) --out $@
	@column -s, -t < $@
