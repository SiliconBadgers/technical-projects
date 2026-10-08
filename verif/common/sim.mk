# File:        sim.mk
# Author:      Isaac Hagedorn
# Date:        2025-03-29
# Description: Build, run, regression and coverage flow shared by every project. A project Makefile sets the
#              project variables below and includes this file. Run `make help` in a project directory.
#
# Project variables (set before the include):
#   PROJECT_ROOT      project directory              TOP            testbench top module
#   DUT_TOP           design top module (lint)       TEST           default test
#   RTL_F_golden, RTL_F_sanity, RTL_F_broken         RTL file lists (paths relative to each list)
#   BUG_PREFIX        seeded-bug define prefix       ALL_BUGS       seeded-bug IDs for BUG=ALL
#   PROJECT_DEFS      extra +define+ flags           PROJECT_TAG    extra build-directory tag
#   PROJECT_PLUSARGS  plusargs for every run         LINT_ARGS      extra verilator --lint-only arguments
#   WAVES_DEFINE      define that turns on $dumpvars in the testbench

COURSE_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
PROJECT     := $(notdir $(PROJECT_ROOT))
# the private uvm-mentor checkout, if present (uvm-onboarding/mentor)
MENTOR_DIR  := $(COURSE_ROOT)/mentor/projects/$(PROJECT)

empty    :=
space    := $(empty) $(empty)
# verilator | questa | xcelium | vcs
SIM      ?= verilator
# testbench directory (contains tb.f and regress.list)
TB       ?= tb
# golden | sanity | broken
DUT      ?= golden
# seeded bug(s) for DUT=broken: B3, "B1 B4" or ALL
BUG      ?=
# random seed
SEED     ?= 1
# UVM verbosity
VERB     ?= UVM_MEDIUM
# collect covergroups (Verilator)
COV      ?= 1
# also line + toggle coverage (Verilator)
CODECOV  ?= 0
# FST waves (Verilator)
WAVES    ?= 0
# seeds per test in a regression
SEEDS    ?= 3
# parallel jobs
JOBS     ?= $(shell nproc 2>/dev/null || echo 4)
# regression list
LIST     ?= $(TB)/regress.list
# extra simulator plusargs
PLUSARGS ?=
SIM_ARGS := $(PROJECT_PLUSARGS) $(PLUSARGS)

UVM_HOME  ?= $(COURSE_ROOT)/third_party/uvm-1.2/src
VERILATOR ?= verilator
# not plain python3: mentor/suite puts a broken Calibre python3 first on PATH
PYTHON    ?= $(firstword $(wildcard $(CONDA_PREFIX)/bin/python3 /usr/bin/python3) python3)

TB_DIR := $(abspath $(TB))
TB_F   := $(TB_DIR)/tb.f
RTL_F  := $(RTL_F_$(DUT))
ifeq ($(RTL_F),)
  $(error DUT must be golden, sanity or broken)
endif
ifeq ($(DUT),broken)
  ifeq ($(BUG),)
    $(error DUT=broken needs BUG=<id>, e.g. BUG=B1)
  endif
  ifeq ($(wildcard $(RTL_F)),)
    $(error DUT=broken needs the mentor repository at $(COURSE_ROOT)/mentor)
  endif
endif

CFG_TAG := $(DUT)$(if $(BUG),_$(subst $(space),-,$(strip $(BUG))))$(PROJECT_TAG)$(if $(filter 1,$(CODECOV)),_cc)$(if $(filter 1,$(WAVES)),_waves)
# tb -> tb; a testbench outside the project -> its path from the course root
TB_TAG  := $(subst /,_,$(patsubst $(COURSE_ROOT)/%,%,$(patsubst $(PROJECT_ROOT)/%,%,$(TB_DIR))))
BUILD   := $(COURSE_ROOT)/build/$(PROJECT)/$(SIM)/$(TB_TAG)/$(CFG_TAG)
RUNDIR  := $(BUILD)/runs/$(TEST)_s$(SEED)

BUG_LIST := $(if $(filter ALL,$(BUG)),$(ALL_BUGS),$(BUG))
DEFS     := +define+UVM_NO_DPI $(PROJECT_DEFS) $(foreach b,$(BUG_LIST),+define+$(BUG_PREFIX)$(b))
INCS     := +incdir+$(UVM_HOME) +incdir+$(TB_DIR)
DEPS     := $(shell find $(PROJECT_ROOT)/rtl $(TB_DIR) $(if $(filter broken,$(DUT)),$(MENTOR_DIR)/broken) -type f 2>/dev/null)
# absolute paths of every source file, for the simulators without verilator's -F
FLIST     = $(shell $(PYTHON) $(COURSE_ROOT)/scripts/flist.py $(RTL_F) $(TB_F))

# On CAE machines the commercial simulators only run inside these container wrappers.
# The conda env's compilers (on PATH for Verilator) link against a newer glibc than the
# containers have, so the wrappers get PATH without the conda env.
CLEAN_PATH := $(if $(CONDA_PREFIX),$(subst $(CONDA_PREFIX)/bin:,,$(PATH)),$(PATH))
wrap = $(if $(shell command -v $(1) 2>/dev/null),env PATH=$(CLEAN_PATH) $(1))

# RUN_TMPL is one simulation; regress.py fills in {test} {seed} {verb} {cov}
ifeq ($(SIM),verilator)
  TOOL := $(VERILATOR)
  HINT := source env/setup.sh
  BIN  := $(BUILD)/obj/V$(TOP)
  VFLAGS := --binary --timing --assert -j $(JOBS) --timescale 1ns/1ps \
            -Wno-fatal -Wno-lint -Wno-style -Wno-MULTIDRIVEN -Werror-USERERROR $(DEFS) $(INCS) \
            --top-module $(TOP) --Mdir $(BUILD)/obj -o V$(TOP) \
            $(if $(filter 1,$(COV)),--coverage-user) \
            $(if $(filter 1,$(CODECOV)),--coverage-line --coverage-toggle) \
            $(if $(filter 1,$(WAVES)),--trace-fst +define+$(WAVES_DEFINE))
  BUILD_CMD = $(VERILATOR) $(VFLAGS) $(UVM_HOME)/uvm_pkg.sv -F $(RTL_F) -F $(TB_F)
  RUN_TMPL := $(BIN) +UVM_TESTNAME={test} +verilator+seed+{seed} +UVM_VERBOSITY={verb} \
              +verilator+coverage+file+{cov} $(SIM_ARGS)
else ifeq ($(SIM),questa)
  TOOL := vsim
  HINT := source env/setup.sh questa
  WRAP := $(call wrap,mentor-run)
  # vopt once at build time so parallel runs only read the library
  BUILD_CMD = $(WRAP) sh -c "vlib work && vlog -sv -timescale 1ns/1ps $(DEFS) $(INCS) $(UVM_HOME)/uvm_pkg.sv $(FLIST) \
              && vopt $(TOP) -o $(TOP)_opt"
  RUN_TMPL := $(WRAP) vsim -c -lib $(BUILD)/work $(TOP)_opt +UVM_TESTNAME={test} -sv_seed {seed} \
              +UVM_VERBOSITY={verb} $(SIM_ARGS) -do "run -all; quit -f"
else ifeq ($(SIM),xcelium)
  TOOL := xrun
  HINT := source env/setup.sh xcelium
  WRAP := $(call wrap,cadence-run)
  BUILD_CMD = $(WRAP) xrun -64bit -elaborate -sv -timescale 1ns/1ps -vtimescale 1ns/1ps -uvmhome $(abspath $(UVM_HOME)/..) -uvmnocdnsextra \
              $(DEFS) $(INCS) $(FLIST) -top $(TOP) -xmlibdirname $(BUILD)/xcelium.d
  RUN_TMPL := $(WRAP) xrun -64bit -R -xmlibdirname $(BUILD)/xcelium.d +UVM_TESTNAME={test} -svseed {seed} \
              +UVM_VERBOSITY={verb} $(SIM_ARGS)
else ifeq ($(SIM),vcs)
  TOOL := vcs
  HINT := source env/setup.sh vcs
  WRAP := $(call wrap,synopsys-run)
  BUILD_CMD = $(WRAP) vcs -full64 -sverilog -timescale=1ns/1ps $(DEFS) $(INCS) $(UVM_HOME)/uvm_pkg.sv $(FLIST) \
              -top $(TOP) -o $(BUILD)/simv
  RUN_TMPL := $(WRAP) $(BUILD)/simv +UVM_TESTNAME={test} +ntb_random_seed={seed} +UVM_VERBOSITY={verb} $(SIM_ARGS)
else
  $(error SIM must be verilator, questa, xcelium or vcs)
endif
# Verilator's target is its binary, so a build whose obj/ was deleted (bughunt.py) is rebuilt
STAMP   := $(if $(filter verilator,$(SIM)),$(BIN),$(BUILD)/.built)
RUN_CMD := $(subst {test},$(TEST),$(subst {seed},$(SEED),$(subst {verb},$(VERB),$(subst {cov},$(RUNDIR)/coverage.dat,$(RUN_TMPL)))))

.PHONY: help lint build run regress cov cov-code waves gui clean print-build print-run print-bugs

help:
	@echo "make lint | build | run | regress | cov | cov-code | waves | gui | clean"
	@echo "knobs: SIM=verilator|questa|xcelium|vcs TB DUT BUG TEST SEED VERB COV CODECOV WAVES SEEDS JOBS LIST PLUSARGS"
	@echo "e.g.   make run TEST=<test> SEED=3   make regress SEEDS=2   make run SIM=questa"

lint:
	$(VERILATOR) --lint-only -Wall $(LINT_ARGS) -F $(RTL_F) --top-module $(DUT_TOP)

$(STAMP): $(DEPS)
	@# /usr/local/cae/bin holds warning stubs, not simulators
	@case "$$(command -v $(TOOL))" in ""|/usr/local/cae/bin/*) echo "$(TOOL) not found. Run: $(HINT)"; exit 1;; esac
	$(if $(filter verilator,$(SIM)),@v=$$($(VERILATOR) --version | awk '{print $$2}'); \
	  [ "$$(printf '%s\n' 5.052 $$v | sort -V | head -1)" = 5.052 ] || { echo "verilator $$v is older than 5.052 (the version this course is tested with). Run: $(HINT)"; exit 1; })
	@mkdir -p $(BUILD)
	@echo "[build] $(SIM): $(TB) + $(DUT)$(if $(BUG), $(BUG)) -> $(BUILD)"
	@cd $(BUILD) && $(BUILD_CMD) > $(BUILD)/build.log 2>&1 || { tail -40 $(BUILD)/build.log; exit 1; }
	$(if $(filter verilator,$(SIM)),@grep -E '^%Warning-(WIDTH|CASE|LATCH|UNOPT)' $(BUILD)/build.log | grep -v third_party | head -20 || true)
	@touch $@

build: $(STAMP)

run: $(STAMP)
	@mkdir -p $(RUNDIR)
	cd $(RUNDIR) && $(RUN_CMD) 2>&1 | tee sim.log | \
	  grep -E 'UVM_(ERROR|FATAL) [^:]|\*\*\* TEST|Assertion|%Error|\*\* (Error|Fatal)|\*E,|\*F,|^Error-' | head -40 ; \
	  grep -q '\*\*\* TEST PASSED' sim.log

regress: $(STAMP)
	$(PYTHON) $(COURSE_ROOT)/scripts/regress.py --run '$(RUN_TMPL)' --list $(LIST) --seeds $(SEEDS) \
	  --out $(BUILD)/regress --jobs $(JOBS)

cov:
	@test "$(SIM)" = verilator || { echo "coverage reports need SIM=verilator"; exit 1; }
	$(PYTHON) $(COURSE_ROOT)/scripts/cov_report.py $(BUILD)/regress/merged.dat

cov-code:
	@test "$(SIM)" = verilator || { echo "coverage reports need SIM=verilator"; exit 1; }
	$(PYTHON) $(COURSE_ROOT)/scripts/cov_report.py $(BUILD)/regress/merged.dat --code

waves:
	@test "$(SIM)" = verilator || { echo "waves needs SIM=verilator; with Questa use make gui SIM=questa"; exit 1; }
	$(MAKE) --no-print-directory run WAVES=1 TEST=$(TEST) SEED=$(SEED)
	@echo "waves: $(subst $(CFG_TAG),$(subst _waves,,$(CFG_TAG))_waves,$(BUILD))/runs/$(TEST)_s$(SEED)/waves.fst"

# Questa only: interactive GUI with every top-level signal in the wave window
gui: $(STAMP)
	@test "$(SIM)" = questa || { echo "gui needs SIM=questa"; exit 1; }
	@mkdir -p $(RUNDIR)
	cd $(RUNDIR) && $(WRAP) vsim -lib $(BUILD)/work -voptargs=+acc $(TOP) +UVM_TESTNAME=$(TEST) -sv_seed $(SEED) \
	  +UVM_VERBOSITY=$(VERB) $(SIM_ARGS) -do "add wave -r /$(TOP)/*; run -all"

clean:
	rm -rf $(COURSE_ROOT)/build/$(PROJECT)

# for scripts (mentor/ci/bughunt.py)
print-build:
	@echo $(BUILD)
print-run:
	@echo '$(RUN_TMPL)'
print-bugs:
	@echo $(ALL_BUGS)
