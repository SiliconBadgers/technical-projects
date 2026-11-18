# Track B1: Cadence tools

Track B1 runs every step of the course with Cadence's commercial tools. They need a license, so you work on a licensed Linux machine (ask your mentor which one).
Track B1 lives in the folder `tracks/b1`. The course itself (concepts, labs, designs) is the same on every track and sits in the course folder, two levels up (the folder with `docs/`, `labs/` and `tracks/`); this folder holds Track B1's flow, and these pages say how to do each step here.
Run every command on these pages from `tracks/b1`; paths are relative to it.

## The tools

| Step | Tool | What it does |
|---|---|---|
| Lint | Xcelium HAL (`xrun -hal`) | Reads the RTL and warns about code that is legal but risky. |
| Simulation | Xcelium (`xrun`) + cocotb | Runs the testbench (written in Python with cocotb) on the RTL. |
| Synthesis | Genus | Turns the RTL into a netlist of `sky130_scl_9T` cells, aiming at the clock period in the SDC. |
| Timing | Tempus | Static timing analysis at the tt, ss and ff corners in one run. |
| Equivalence | Conformal LEC | Proves the netlist does the same as the RTL. |
| Gate-level simulation | Xcelium + cocotb | The same testbench on the netlist, with the cell models. |

New words: [glossary](../../../docs/02_glossary.md).

### Library

This track uses one library: `sky130_scl_9T`, a 9-track standard-cell library for SkyWater 130 nm (a "track" here is one routing wire's width plus spacing; Lab 0 explains it).
Its files are in the SiliconBadgers PDK repo (PDK, process design kit: the factory's files, including the cell libraries), folder `cadence/`.
[libraries.yaml](libraries.yaml) also lists `sky130_fd_sc_hd` for comparisons in Lab 0. The flow does not use it, so for Labs 1 and 2 this track has one library.

The tie cells `TIEHI` and `TIELO` are in a separate small Liberty file, `$SB_PDK/cadence/sky130_scl_9T_tech/lib/sky130_scl_9T_phyCells.lib`, with one typical corner that the flow uses at every corner.
A tie cell is a cell whose output is always 1 (`TIEHI`) or always 0 (`TIELO`). Genus connects every constant input to one, so no gate input is wired straight to the power or ground rail.

## Setup

### 1. Tools

The flow was written for these versions or newer:

| Tool | Version | Started as |
|---|---|---|
| Genus | 21.1 (Stylus common user interface, the default) | `genus -no_gui` |
| Tempus | 21.1, Stylus mode | `tempus -stylus -no_gui` |
| Conformal LEC | 21.1 (the dofile Genus writes needs 19.10-p100 or newer) | `lec -xl -nogui` |
| Xcelium | 23.09 (with HAL) | `xrun` |
| Python | 3.10 | `python3` |
| cocotb | 2.1.0 | used by `flow/xcelium/run_cocotb.py` |

Most licensed machines load tools with environment modules. A module is a small script that puts one tool on your `PATH`.

```
module avail cadence              # what is installed; names differ between machines
module load cadence/xcelium/2509  # example from the UW CAE machines (the default Xcelium there is newer than the license)
```

Load Genus, Tempus and Conformal the same way, or add their `bin/` folders to `PATH` yourself.
If your machine runs Cadence tools inside a wrapper command (for example `cadence-run`), add `TOOL_WRAP=cadence-run` to every `make` line.

### 2. Python packages

In a virtual environment (a private folder of Python packages; `liberty-parser` brings `lark`):

```
python3 -m venv ~/sb-venv && source ~/sb-venv/bin/activate
pip install cocotb==2.1.0 pyyaml liberty-parser==0.0.29 numpy matplotlib pytest
```

**UW CAE machines**, or anywhere the tools run inside a container (`TOOL_WRAP=cadence-run`): `make sim` and `make gls` run `python3` inside the container. It has no Python of its own and cannot use a venv made from the host's Python.
Build a conda-forge Python in your home folder instead (the container sees it) and put it first on `PATH`. On the CAE host, once:

```
module load conda-forge/26.3.2                        # gives mamba
export CONDA_PKGS_DIRS=/var/tmp/$USER/conda-pkgs      # download cache on local scratch, not in your home folder
mamba create -y -p ~/.conda/envs/sb-py -c conda-forge python=3.10 pip      # about 750 MB, a few minutes
~/.conda/envs/sb-py/bin/pip install --no-cache-dir cocotb==2.1.0 pyyaml liberty-parser==0.0.29 numpy matplotlib pytest
```

Then in every new terminal, after the `module load` lines: `export PATH=$HOME/.conda/envs/sb-py/bin:$PATH`.

### 3. The PDK repo

Clone the PDK repo next to the course folder (the folder with `docs/`, `labs/` and `tracks/`), three folders up from `tracks/b1`, under exactly this folder name:

```
cd ../../..
git clone <PDK repo URL> silicon-badgers-sky130-pdk     # ask a mentor for the URL
cd -
```

Somewhere else? `export SB_PDK=<path to silicon-badgers-sky130-pdk>`.

### 4. Check

```
make env-check
```

Every tool prints a path (not `MISSING`), every library file says `OK`, and cocotb prints its version.
`make env-check` looks on your shell's `PATH`, not inside `TOOL_WRAP`'s container. With a wrapper, also check there: `cadence-run which genus tempus lec xrun python3`.

## Running a step

```
make <step> DESIGN=<design>
```

| Target | Does | Main output |
|---|---|---|
| `lint` | Xcelium HAL on the RTL | `lint.log` |
| `sim` | cocotb testbench on the RTL (Xcelium) | `results.xml`, `sim_rtl/` |
| `synth` | Genus (`flow/genus/synth.tcl`) | `netlist.v`, `synth.log`, reports `*.rpt` |
| `sta` | Tempus at tt, ss and ff (`flow/tempus/sta.tcl`) | `sta_<corner>_setup.rpt`, `sta_<corner>_hold.rpt`, `sta_summary.txt` |
| `lec` | Conformal, RTL against `netlist.v` (`flow/conformal/lec.do`) | `lec_run.log`, `lec.log` |
| `gls` | the same cocotb testbench on the netlist | `gls_results.xml`, `sim_gls/` |
| `qor` | collects period, slack, area, cells, leakage and runtimes | `qor.csv` |
| `all` | all of the above, in order | |
| `check` | the course's checks (`flow/scripts/check.py`) | PASS/FAIL per check |

- `DESIGN=`: `gcd`, `ibex`, `sb_systolic_tile`. Each has a `design.mk` in its lab folder here (top module, SDC, and the RTL files and testbench from the lab folder in the course folder).
- Outputs go to `build/<design>/sky130_scl_9T/`, e.g. `build/gcd/sky130_scl_9T/`.
- `flow.env` there holds every input of the Tcl scripts. To rerun a tool by hand: `cd build/gcd/sky130_scl_9T && source flow.env && genus -files $FLOW_DIR/genus/synth.tcl`.
- A failing step prints the file to read. A failing check prints the page to read.
- Other targets: `make help`, `make info`, `make env-check`, `make clean` (deletes one build folder), `make -s print-<VAR>` (one setting, e.g. `print-LIB_tt`).

### Outputs of one run

| File | From | What |
|---|---|---|
| `lint.log` | HAL | lint messages |
| `results.xml`, `gls_results.xml` | cocotb | test results (RTL, netlist) |
| `sim_rtl/`, `sim_gls/` | Xcelium | `xrun_*.log`, and waves with `WAVES=1` |
| `constraints.sdc` | make | your SDC as the tools read it (period replaced if you set `CLOCK_PERIOD`) |
| `synth.log` | Genus | the whole synthesis session |
| `check_design.rpt` | Genus | structural check: missing modules, multiple drivers, undriven pins |
| `check_timing.rpt` | Genus | constraint check: unclocked flip-flops, ports without delays, loops |
| `timing.rpt`, `area.rpt`, `gates.rpt`, `qor.rpt`, `datapath.rpt`, `power.rpt` | Genus | worst paths, area, cells used, summary, adder choices, power |
| `netlist.v`, `netlist.sdc` | Genus | the netlist, and the constraints as Genus applied them |
| `genus_lec.do`, `fv/` | Genus | the Conformal script Genus wrote, and its notes for Conformal |
| `sta.log`, `sta_check_timing.rpt`, `sta_drv.rpt` | Tempus | session log, constraint check, design-rule violators |
| `sta_<corner>_setup.rpt`, `sta_<corner>_hold.rpt` | Tempus | the 10 worst paths per corner |
| `sta_summary.txt` | Tempus | WNS and TNS per corner, for `qor` and `check` |
| `lec_run.log`, `lec.log` | Conformal | session output and log |
| `qor.csv`, `runtimes.txt` | make | one row per corner; seconds per step |

## Knobs

Add `KNOB=value` to any `make` line. The synthesis knobs match the rows of [09 — What synthesis can fix](../../../docs/09_synthesis_vs_pd.md#synthesis-can-fix).

| Knob | Meaning |
|---|---|
| `CLOCK_PERIOD=<ns>` | replace the `set clk_period` line of the SDC; output in `build/<design>/sky130_scl_9T_p<ns>/`. A tighter period makes Genus restructure and size harder |
| `SYNTH_EFFORT` | Genus effort for all three synthesis steps: `low`, `medium` (default) or `high` |
| `SYNTH_ADDER` | `auto` (default: Genus picks an adder structure per path) or `ripple` (ripple-carry adders everywhere) |
| `SYNTH_RETIME` | `1` = let Genus move registers across logic ([retiming](../../../docs/02_glossary.md#retiming)); LEC gets harder |
| `SYNTH_CORNER` | Liberty corner Genus maps to (default `ss`) |
| `DESIGN_PARAMS="A=1 B=2"` | top-level parameters for synthesis and simulation; output in a folder named after them |
| `BUGS=1` | Lab 2 Task 1: build the copy with the seeded bugs (`rtl_bugs/`); output in `build/sb_systolic_tile/sky130_scl_9T_bugs/` |
| `WAVES=1` | save waveforms in `sim_rtl/` or `sim_gls/` (`cocotb_waves.shm`; open it with `simvision`) |
| `SIM_TIMEOUT=<s>` | wall-clock limit of one `sim` or `gls` run (default 900 s); a run that hits it is killed and fails |
| `LEC_MODE` | `genus` (default: run the script Genus wrote) or `own` (only `flow/conformal/lec.do`) |
| `BUILD=<dir>` | use another build folder, e.g. to keep two runs side by side |
| `TOOL_WRAP`, `GENUS`, `TEMPUS`, `LEC`, `XRUN` | wrapper command, and each tool's command name |
| `HAL_ARGS` | extra HAL options for `make lint` (default `-f flow/xcelium/hal_rules.f`: the style rules that are off) |

Give `make check` and `make qor` the same `DESIGN_PARAMS`, `CLOCK_PERIOD` and `BUILD` as the run, so they read the same folder.

Stronger cells and buffers: Genus adds them by itself while mapping; there is no knob.

## Gate-level simulation

[GLS](../../../docs/08_gate_level_sim.md#gls) runs the RTL testbench on `netlist.v`:

```
make gls DESIGN=gcd            # runs synth first if the netlist is missing
```

- Xcelium reads the netlist, the cell models `$SB_PDK/cadence/sky130_scl_9T/verilog/sky130_scl_9T.v`, the tie-cell models `flow/cells/sky130_scl_9T_tiecells.v` (the library ships none), and for Lab 2 the SRAM model `../../labs/lab2_systolic/macros/sb_sram_256x8_model.v`.
- The cell models have zero delay: GLS checks behaviour, not timing.
- ibex's clock gate: under `SYNTHESIS`, the RTL uses the wrapper `flow/cells/sky130_scl_9T_sb_icg.v`, which instantiates the library's clock-gating cell `ICGPRECX1`. Genus keeps it in `netlist.v`; GLS uses its model from the cell file.
- Results: `gls_results.xml`; logs in `sim_gls/`. With `WAVES=1`: `sim_gls/cocotb_waves.shm`.

## Clock targets

All periods are a starting point taken from Track A's numbers for the same library. Genus gives different results than Track A's tools, so they are recalibrated after the first runs on a licensed machine.

### Lab 1 (the period is the `set clk_period` line of each SDC)

| Design | SDC | Period |
|---|---|---|
| gcd | `labs/lab1_reference/gcd/sdc/sky130_scl_9T.sdc` | 6 ns |
| ibex | `labs/lab1_reference/ibex/sdc/sky130_scl_9T.sdc` | 17 ns |

### Lab 2

| Tier | Clock | Period at `ss` | Area |
|---|---|---|---|
| Bronze | 90 MHz | 11.111 ns | |
| Silver | 0.70 × T0 (11 ns) | 7.7 ns | ≤ 1.25 × your Bronze area |
| Gold | Silver, plus `N_ROWS = N_COLS = 8` closed at the Bronze period | | |

This track has one library, so Gold is the 8 × 8 part. `make check` prints your tier and leaderboard score (`BRONZE_PERIOD_NS` and `SILVER_PERIOD_NS` in `labs/lab2_systolic/design.mk`).

## SDC files

This track's SDCs are plain SDC, read by both Genus and Tempus: `labs/lab1_reference/<design>/sdc/sky130_scl_9T.sdc`, and for Lab 2 `labs/lab2_systolic/sdc/sky130_scl_9T.sdc` (you write that one).

- Start with `set clk_period <ns>` and use `$clk_period` after it; `CLOCK_PERIOD=` replaces that one line.
- Input driver: `set_driving_cell -lib_cell BUFX2 -pin Y ...` (the library's `buf_2`).
- Output load: 4 × the input capacitance of `BUFX4` pin `A` (the library's `buf_4`), in pF. Look it up in the Liberty file at your synthesis corner.

## Pages in this track

| Page | What |
|---|---|
| [lab0.md](lab0.md), [lab1.md](lab1.md), [lab2.md](lab2.md) | commands for each lab |
| [reading_logs.md](reading_logs.md) | reading this track's logs and reports |
| [libraries.yaml](libraries.yaml) | Liberty files for the Lab 0 scripts |

Next: [docs/03_liberty.md](../../../docs/03_liberty.md)
