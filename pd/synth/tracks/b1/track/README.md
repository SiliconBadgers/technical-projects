# Track B1: Cadence tools

Track B1 runs every step of the course with Cadence's commercial tools. They need a license, so you work on a licensed Linux machine (ask your mentor which one).
Track B1 lives in the folder `tracks/b1`. The course itself (concepts, labs, designs) is the same on every track and sits at the repo root; this folder holds Track B1's flow, and these pages say how to do each step here.
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

Think of Genus as the translator (RTL into gates) that also shops for real parts in the library catalog, Tempus as the person checking the train timetable, and Conformal as the proofreader who compares the translation with the original.
New words: [glossary](../../../docs/02_glossary.md).

### Library

This track uses one library: **`sky130_scl_9T`**, a 9-track standard-cell library for SkyWater 130 nm (a "track" here is one routing wire's width plus spacing; Lab 0 explains it).
Its files are in the SiliconBadgers PDK repo (PDK, process design kit: the factory's files, including the cell libraries), folder `cadence/`.
[libraries.yaml](libraries.yaml) also lists `sky130_fd_sc_hd` for comparisons in Lab 0. The flow does not use it, so for Labs 1 and 2 this track has one library.

The **tie cells** `TIEHI` and `TIELO` are in a separate small Liberty file, `$SB_PDK/cadence/sky130_scl_9T_tech/lib/sky130_scl_9T_phyCells.lib`, with one typical corner that the flow uses at every corner.
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

**UW CAE machines**, or anywhere the tools run inside a container (`TOOL_WRAP=cadence-run`): `make sim` and `make gls` run `python3` inside the container. It has no Python of its own and cannot use a venv made from the host's Python, and your home folder is small. Build a conda-forge Python on a path the container mounts (local scratch) and put it first on `PATH`:

```
mamba create -y -p /var/tmp/$USER/sb-py -c conda-forge python=3.10 pip     # or micromamba; /var/tmp belongs to one machine
/var/tmp/$USER/sb-py/bin/pip install cocotb==2.1.0 pyyaml liberty-parser==0.0.29 numpy matplotlib pytest
export PATH=/var/tmp/$USER/sb-py/bin:$PATH
```

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

- `DESIGN=`: `gcd`, `ibex`, `sb_systolic_tile`. Each has a `design.mk` in its lab folder here (top module, SDC, and the RTL files and testbench from the lab folder at the repo root).
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

All periods are a **starting point** taken from Track A's numbers for the same library. Genus gives different results than Track A's tools, so they are recalibrated after the first runs on a licensed machine.

### Lab 1 (the period is the `set clk_period` line of each SDC)

| Design | SDC | Period |
|---|---|---|
| gcd | `labs/lab1_reference/gcd/sdc/sky130_scl_9T.sdc` | 6 ns |
| ibex | `labs/lab1_reference/ibex/sdc/sky130_scl_9T.sdc` | 17 ns |

### Lab 2

| Tier | Clock | Period at `ss` | Area |
|---|---|---|---|
| Bronze | 90 MHz | 11.111 ns | |
| Silver | 0.70 × Bronze | 7.778 ns | ≤ 1.25 × your Bronze area |
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

## First run checklist

For the maintainer, on the first run on a licensed machine (and after a tool upgrade). The flow was written against the tool documentation; these are the places to confirm.

1. `make env-check`: every tool found. If a tool cannot start without a wrapper, set `TOOL_WRAP` (cocotb then needs Python inside that wrapper too).
2. Start-up flags: `GENUS_FLAGS=-no_gui`, `TEMPUS_FLAGS="-stylus -no_gui"` (older Tempus: `-nowin`), `LEC_FLAGS="-xl -nogui"`. Each tool must exit by itself at the end (the scripts end with `exit`; stdin is `/dev/null`).
3. Gzipped Liberty (`.lib.gz`): Genus, Tempus and Conformal read it. If one does not, unzip a copy and pass `LIB_ss=<file> LIB_tt=... LIB_ff=...`.
4. `make synth DESIGN=gcd`: `synth.log` has no `SB-WARNING` about `hdl_error_on_latch`, `hdl_error_on_blackbox` or `hdl_track_filename_row_col`; if one is unknown, find the equivalent attribute (`get_db -category hdl`) and update `flow/genus/synth.tcl`.
5. `check_design.rpt` and `check_timing.rpt` contain the summary rows that `flow/scripts/check.py` reads (`Unresolved References`, `Multidriven ...`, `Undriven ...`, `Sequential clock pins without clock waveform`, `Inputs/Outputs without clocked external delays`, `Loop-breaking cells ...`). If the wording differs, update the labels in `check.py`.
6. Tie cells: `grep -cE '^ *TIE(HI|LO) ' build/gcd/sky130_scl_9T/netlist.v` is not 0 and `synth.log` has no `SB-WARNING: no tie cells added` (else check the options of `add_tieoffs` in `flow/genus/synth.tcl`). Warnings that the phyCells library has other operating conditions than the ss/ff libraries are expected (it has one typical corner).
7. `make synth DESIGN=ibex`: `grep -c ICGPRECX1 build/ibex/sky130_scl_9T/netlist.v` is not 0 (Genus kept the instantiated clock gate although the library marks it `dont_use`).
8. `make synth DESIGN=sb_systolic_tile DESIGN_PARAMS="N_ROWS=8 N_COLS=8"` (with a Lab 2 SDC): the netlist's top module is still `sb_systolic_tile` (`rename_obj` in `synth.tcl`), and the SRAM is an instance of the Liberty cell `sb_sram_256x8`.
9. `SYNTH_ADDER=ripple`: `synth.log` says `set on N adder instances` with N > 0 and `datapath.rpt` changes. If N is 0, find Genus's attribute for a datapath instance's architecture and update `synth.tcl`.
10. `SYNTH_RETIME=1`: no `SB-WARNING`, and LEC still passes.
11. `make sta DESIGN=gcd`: `sta.log` builds three views; `sta_summary.txt` has numbers, not `NA`, and `period_ns` is the SDC period in ns (`NA` means `report_timing -collection` or `get_db <path> .slack` did not work; `qor.py` then reads the first path of each report and leaves TNS empty). `sta_check_timing.rpt` and `sta_drv.rpt` exist.
12. Reset check: for a correct Lab 2 tile, `sta_summary.txt` says `reset_port_async_pins 2`. A much larger number on a correct tile means `all_fanout` went through the flip-flops' reset-to-output arcs; fix the count in `flow/tempus/sta.tcl`.
13. `make lec` for gcd and ibex: `lec_run.log` says it ran the Genus dofile and ends with `No of diff points = 0`. Also try `LEC_MODE=own` on gcd. Break the netlist on purpose (swap two cell types in a copy) and see LEC fail.
14. `make lint`: HAL messages look like `*W,<CODE> (<file>,<line>|<col>): ...`. Add the harmless warnings in third-party code (gcd, ibex) to `labs/lab1_reference/<design>/hal_waivers.txt`, each with a reason, until `make lint` passes.
15. `make sim gls` for all three designs pass. Lab 2 `DESIGN_PARAMS` reach the simulation (cocotb passes them as `-gpg`); GLS with the Liberate cell models gives no X on the outputs.
16. Recovery/removal in Genus, before calibrating. Tempus times them by default (`timing_analysis_async_checks`, `auto` in 23.14); Genus must too, or it builds the tile's reset tree (about 810 reset pins) without regard to them. (On Track B2, Design Compiler skips them by default: the tile failed at `ss` by 1.36 ns on recovery, its reset tree a chain of seven `buf_1`, until `enable_recovery_removal_arcs true`.) Check, with a mentor's Lab 2 SDC, after `make synth sta DESIGN=sb_systolic_tile`: in Genus, `report_timing -from u_reset_sync/rst_n_o_reg/CK` ends at a flip-flop's `RN` as a recovery check with a slack, not as an unconstrained path without a capture clock; `sta_ss_setup.rpt` has no failing `Recovery Check`. If Genus does not time them, find its attribute for asynchronous checks (`get_db -category timing`; try Tempus's name first), set it in `flow/genus/synth.tcl`, and rerun.
17. Calibrate: find each design's shortest passing period at `ss`, then update the SDC periods, the tables above, and `BRONZE_PERIOD_NS`/`SILVER_PERIOD_NS`.
18. Note the run times and disk use of an ibex build in [lab1.md](lab1.md).

Next: [docs/03_liberty.md](../../../docs/03_liberty.md)
