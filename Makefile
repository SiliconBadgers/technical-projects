# CAE/Synopsys is the recommended environment. For local use: export SIM=iverilog
SIM ?= vcs
VCS ?= vcs
IVERILOG ?= iverilog
VVP ?= vvp
PYTHON ?= python3
SIM_ARGS ?=

# Keep the same output paths and exercise commands with either simulator.
# Compile VCS in the build directory so generated files stay out of source folders.
ifeq ($(SIM),vcs)
define run_sim
	@command -v $(VCS) >/dev/null || { echo "VCS is unavailable. On CAE: module load synopsys/suite, then synopsys-run. For local simulation: export SIM=iverilog"; exit 1; }
	mkdir -p build/$(1)
	cd build/$(1) && $(VCS) -full64 -sverilog -top $(2) $(addprefix ../../,$(3)) -o simv
	cd build/$(1) && $(PYTHON) ../../scripts/run_vcs.py $(SIM_ARGS)
endef
else ifeq ($(SIM),iverilog)
define run_sim
	mkdir -p build/$(1)
	$(IVERILOG) -g2012 -Wall -s $(2) -o build/$(1)/simv $(3)
	cd build/$(1) && $(VVP) simv $(SIM_ARGS)
endef
else
$(error Unsupported SIM=$(SIM). Use vcs or iverilog)
endif

.PHONY: help check day1 smoke pe
help:
	@echo "Simulator: $(SIM) (default: vcs on CAE; local alternative: export SIM=iverilog)"
	@echo "make check  - validate local documentation links and code regions"
	@echo "make day1   - simulate Day 1 circuits, check outputs, and generate waves.vcd"
	@echo "make smoke  - simulate the completed digital logic examples"
	@echo "make pe     - run the supplied PE acceptance suite (fails until implemented)"

check:
	$(PYTHON) scripts/check_docs.py

day1:
	$(call run_sim,day1,day1_combinational_tb,intro/projects/digital-logic/rtl/day1_combinational.v intro/projects/digital-logic/tb/day1_combinational_tb.sv)

smoke: day1
	$(call run_sim,digital-logic,logic_basics_tb,intro/projects/digital-logic/rtl/logic_basics.sv intro/projects/digital-logic/tb/logic_basics_tb.sv)

pe:
	$(call run_sim,pe,pe_tb,intro/projects/processing-element/rtl/pe.sv intro/projects/processing-element/tb/pe_tb.sv)
