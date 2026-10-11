# Track B2: Synopsys tools

Track B2 runs every step of the course with Synopsys tools on the open SkyWater 130 nm library `sky130_fd_sc_hd`.
You are on the `track-b2` branch. The course itself (concepts, labs, designs) is the same on every track; this folder only says how to do each step here.

These are commercial tools: they need a **license** (a permission file served by a license server on your network).
Work on a machine where your group has the tools installed. Ask your mentor which one.

## The tools

| Step | Tool (command) | What it does |
|---|---|---|
| Lint | VC SpyGlass (`vc_static_shell`), or VCS (`vcs +lint=all`) if VC SpyGlass is not installed | Reads the RTL and warns about code that is legal but risky. |
| Simulation | VCS (`vcs`) + cocotb | VCS compiles and runs Verilog; cocotb lets the testbench be written in Python. |
| Synthesis | Design Compiler (`dc_shell`) | Turns the RTL into library cells, aiming at the clock period in the SDC. |
| Timing | PrimeTime (`pt_shell`) | Static timing analysis at the tt, ss and ff corners. |
| Equivalence | Formality (`fm_shell`) | Proves the netlist does the same as the RTL. |
| Library compile | Library Compiler (`lc_shell`) | Turns a text Liberty file (`.lib`) into the binary `.db` the other tools read. |

Think of Design Compiler as the translator (RTL into gates), PrimeTime as the inspector with a stopwatch, and Formality as the proofreader who checks the translation line by line.

Words used on these pages:

- **Shell**: each tool is a command prompt that understands Tcl (`dc_shell`, `pt_shell`, ...). The flow gives it a script with `-f <script>`.
- **`.db`**: a Liberty file compiled to binary. Same content as the `.lib`, but the Synopsys tools only read `.db`. Like a program and its source code.
- **SVF**: a file Design Compiler writes for Formality, listing what it changed (renamed, merged or moved). A change log for the proofreader.

### Versions

The scripts use standard commands of recent releases. Assumed:

| Tool | Version |
|---|---|
| Design Compiler, PrimeTime, Formality, VCS, Library Compiler | V-2023.12 or newer |
| VC SpyGlass (optional) | V-2023.12 or newer |
| Python | 3.9 or newer |
| cocotb | 2.1.0 |

## Setup (once)

1. **Get the PDK repo** (the library files) next to this repo, so the two folders sit side by side:
   ```
   cd <the folder that holds this repo>
   git clone <PDK repo URL> silicon-badgers-sky130-pdk     # ask a mentor for the URL; keep this folder name
   ```
   Somewhere else? Set `SB_PDK` to its path (`export SB_PDK=<path>`).
2. **Load the tools.** Every site does this differently, for example `module load synopsys` or sourcing a setup script. Ask your mentor. Then check:
   ```
   which dc_shell pt_shell fm_shell vcs lc_shell
   which vc_static_shell      # optional; without it, make lint uses vcs
   ```
3. **Build the library views** (the `.db` files):
   ```
   $SB_PDK/synopsys/make_views.sh            # or ../silicon-badgers-sky130-pdk/synopsys/make_views.sh
   ls $SB_PDK/synopsys/views/*.db            # three files: tt, ss, ff
   ```
   The script also builds files for the physical design course (it needs `grdgenxo` and `icc2_lm_shell` for those).
   If it stops there, the three `.db` files are already written, and they are all this course needs.
4. **Python packages**, in a virtual environment (`liberty-parser` brings `lark`):
   ```
   python3 -m venv ~/venvs/sb && source ~/venvs/sb/bin/activate
   pip install cocotb==2.1.0 pyyaml liberty-parser==0.0.29 numpy matplotlib pytest
   ```
   **UW CAE machines**, or anywhere the tools run inside a container (`synopsys-run`): `make sim` and `make gls` run `python3` inside the container. It has no Python of its own and cannot use a venv made from the host's Python, and your home folder is small. Build a conda-forge Python on a path the container mounts (local scratch) and put it first on `PATH`:
   ```
   mamba create -y -p /var/tmp/$USER/sb-py -c conda-forge python=3.10 pip     # or micromamba; /var/tmp belongs to one machine
   /var/tmp/$USER/sb-py/bin/pip install cocotb==2.1.0 pyyaml liberty-parser==0.0.29 numpy matplotlib pytest
   export PATH=/var/tmp/$USER/sb-py/bin:$PATH
   ```
5. **Smoke test** (from the repo root):
   ```
   make all DESIGN=gcd
   ```
   It ends with a `qor.csv` table and no `FAILED` line.

| Variable | Meaning | Default |
|---|---|---|
| `SB_PDK` | the SiliconBadgers sky130 PDK repo | `../silicon-badgers-sky130-pdk` (next to this repo) |

## Running a step

```
make <step> DESIGN=<design>          # from the repo root; make help lists everything
```

| Target | Tool | Main output |
|---|---|---|
| `lint` | VC SpyGlass, or `vcs +lint=all` | `lint.log` (details: `lint_vc.rpt` or `lint/vcs.log`) |
| `sim` | cocotb + VCS on the RTL | `results.xml`, `sim.log` |
| `synth` | `dc_shell`, [flow/dc/synth.tcl](../flow/dc/synth.tcl) | `netlist.v`, `synth.log`, `synth_*.rpt`, `synth.svf` |
| `sta` | `pt_shell` at tt, ss and ff, [flow/pt/sta.tcl](../flow/pt/sta.tcl) | `sta_<corner>.rpt`, `sta_<corner>.txt` |
| `lec` | `fm_shell`, [flow/fm/lec.tcl](../flow/fm/lec.tcl) | `lec.log` (on a pass), `lec_run.log`, `lec_failing.rpt` |
| `gls` | cocotb + VCS on the netlist | `gls_results.xml`, `gls.log` |
| `qor` | [flow/qor/collect_qor.py](../flow/qor/collect_qor.py) | `qor.csv` |
| `all` | all of the above, in order | |
| `macros` | `lc_shell`, [flow/lc/compile_lib.tcl](../flow/lc/compile_lib.tcl): macro `.lib` to `.db` (Lab 2; `synth` and `sta` run it for you) | `build/<design>/macros/*.db` |
| `clean` | deletes one build folder | |

- `DESIGN=`: `gcd`, `ibex` or `sb_systolic_tile`. Each design's settings are in its `design.mk`.
- Outputs go to `build/<design>/sky130_fd_sc_hd/`, for example `build/gcd/sky130_fd_sc_hd/`.
- A step that fails says which log to read. How to read each one: [reading_logs.md](reading_logs.md).

### Running a tool by hand

Each tool step writes `<step>.env` (its inputs) next to its outputs. To rerun one and stay at the tool's prompt:

```
cd build/gcd/sky130_fd_sc_hd
source sta_ss.env
SB_STAY=1 pt_shell -f ../../../flow/pt/sta.tcl
pt_shell> report_timing -through <a pin or net> -input_pins
pt_shell> exit
```

The same works with `synth.env` + `dc_shell -f ../../../flow/dc/synth.tcl` and `lec.env` + `fm_shell -f ../../../flow/fm/lec.tcl`.

### GLS

Gate-level simulation runs the RTL's cocotb testbench on `netlist.v`:

```
make gls DESIGN=gcd               # runs synth first if needed
```

- VCS reads `netlist.v`, the cell models in `$SB_PDK/synopsys/sky130_fd_sc_hd/verilog/` and, for Lab 2, the SRAM simulation model.
- The cell models are functional (`FUNCTIONAL`, one time unit per cell, `UNIT_DELAY=#1`): GLS checks behaviour, not timing.
- Result: `gls_results.xml` and `gls.log` (the cocotb summary is at the end). Waveforms: add `WAVES=1`.

### Knobs

Add `KNOB=value` to any `make` line.

| Knob | Meaning |
|---|---|
| `CLOCK_PERIOD=<ns>` | replaces the `set clk_period` line of the SDC; output in `build/<design>/sky130_fd_sc_hd_p<ns>/` |
| `DESIGN_PARAMS="A=1 B=2"` | top-level parameters for synthesis, LEC and simulation; output in a folder named after them |
| `SYNTH_CORNER` | corner Design Compiler optimizes for (default `ss`) |
| `DC_COMPILE` | `compile_ultra` (default; strongest optimization) or `compile` (simpler) |
| `SYNTH_RETIME=1` | `compile_ultra -retime`: Design Compiler may move registers across logic |
| `DC_EXTRA=<file.tcl>` | your own `dc_shell` commands, run just before compile (Lab 1 uses it for the adder experiment) |
| `LINT_TOOL` | `auto` (default: VC SpyGlass if installed), `vc` or `vcs` |
| `WAVES=1` | VCS writes `waves.vcd` in `sim_rtl/` or `sim_gls/` (open it with Verdi or GTKWave) |
| `SIM_TIMEOUT=<s>` | wall-clock limit of one `sim` or `gls` run (default 900 s); a run that hits it is killed and fails |

Design Compiler picks adder and multiplier structures itself, from its **DesignWare** library of ready-made arithmetic blocks; `synth_resources.rpt` lists what it picked.

## Clock targets

These were calibrated on the first licensed run, with Design Compiler and PrimeTime Y-2026.03 (checklist item 15): Lab 1 = the shortest period that passes setup at `ss`, plus 5 %; Lab 2 (all `*_PIPE = 0`) Bronze = the shortest passing period (7.5 ns) rounded up to a whole MHz, Silver = 0.70 × that period.
Design Compiler and PrimeTime estimate wire delay before layout from the library's wire-load table, so the numbers belong to these tools; after a tool upgrade the team recalibrates them.

| Design | Clock target | Constraint file |
|---|---|---|
| gcd (Lab 1) | 3.8 ns | `labs/lab1_reference/gcd/sdc/sky130_fd_sc_hd.sdc` |
| ibex (Lab 1) | 11.6 ns | `labs/lab1_reference/ibex/sdc/sky130_fd_sc_hd.sdc` |
| sb_systolic_tile (Lab 2), **Bronze** | **133 MHz** (7.519 ns) | you write `labs/lab2_systolic/sdc/sky130_fd_sc_hd.sdc` |
| sb_systolic_tile (Lab 2), Silver | 5.25 ns at `ss` | the same file |

## This track's checks

The labs ask that "your track's checks" pass. Here they are, with where to look (all in `build/<design>/sky130_fd_sc_hd/`):

| Check | Passes when |
|---|---|
| Lint | `make lint` finishes; every message in `lint.log` is fixed or explained to your mentor |
| RTL simulation | `make sim`: every cocotb test passes (`sim.log`, `results.xml`) |
| No latches | `synth_latches.rpt` says 0 (ibex's clock-gating cell `sdlclkp` holds a latch on purpose and is not counted), and `synth.log` has no `Latch` in its inferred-memory tables |
| Synthesis is clean | `make synth` passes: no `Error`, every instance linked (no `LINK-5` in `synth.log`) |
| Setup | worst setup slack at `ss` is ≥ 0 (`sta_ss.txt`, `qor.csv`) |
| Hold | worst hold slack at `ff` is ≥ 0 (`sta_ff.txt`, `qor.csv`) |
| No unconstrained endpoints | in every `sta_<corner>.rpt`: `check_timing` lists no unconstrained endpoints and no input without an input delay except `rst_n` (Lab 2: asynchronous, by the spec), and the coverage of the SDC checks shows nothing untested except (a) recovery/removal of the reset synchronizer's two flip-flops, which only `rst_n` reaches (`no_startpoint_clock`, or `false_paths` if you gave `rst_n` an input delay; comment your false path) and (b) pins driven by a constant (`constant_disabled`, `no_paths`: the synchronizer's first `D` input, ibex's constant outputs) |
| Reset synchronizer (Lab 2) | `reset_port_async_pins` in `sta_ss.txt` is at most 2 (the synchronizer's own flip-flops) |
| Equivalence | `make lec`: `Verification SUCCEEDED` |
| GLS | `make gls`: the same tests as `make sim`, all passing |
| QoR | `make qor` writes `qor.csv` |

## First run checklist

For the mentor who runs this track first on a new machine or after a tool upgrade. The scripts were written against the tool documentation; confirm each item once.

1. `ls $SB_PDK/synopsys/views/*.db` shows the tt, ss and ff files.
2. `make synth DESIGN=gcd`: `dc_shell` exits by itself; `synth.log` has no `Error`. The `analyze -define` list form works (`make synth DESIGN=ibex`, which defines `SYNTHESIS`).
3. ibex: `sb_icg` links to `sky130_fd_sc_hd__sdlclkp_1` (no `LINK-5`), and `dw_foundation.sldb` is found.
4. `read_sdc` in Design Compiler and PrimeTime accepts the Lab 1 SDCs, which use `remove_from_collection`. If it does not, read them with `source` in `synth.tcl` and `sta.tcl`.
5. `make sta DESIGN=gcd`: three reports, numbers in `sta_<corner>.txt`, no unconstrained endpoints. `report_analysis_coverage -status_details untested` is accepted.
6. `report_power` either writes `synth_power.rpt` or prints the `SB:` note; in both cases `synth.log` has no `Error` line from it.
7. `make lec DESIGN=gcd`, then `DESIGN=ibex`: `Verification SUCCEEDED`. Formality accepts `read_sverilog -vcs "+incdir+... +define+..."` (ibex uses both).
8. `make sim gls DESIGN=gcd`, then `DESIGN=ibex`: cocotb finds VCS, the cell models compile, every test passes. `WAVES=1` writes `waves.vcd` (`+vcs+dumpvars`).
9. `make lint DESIGN=gcd LINT_TOOL=vc` (if VC SpyGlass is installed: `configure_lint_setup -goal lint_rtl`, `report_lint -file`) and `LINT_TOOL=vcs`.
10. Lab 2, with a mentor solution SDC: `make macros DESIGN=sb_systolic_tile` writes three `.db` files (read `build/sb_systolic_tile/macros/*.log`). `make all` passes, and with `DESIGN_PARAMS="N_ROWS=8 N_COLS=8"` the netlist's top module is still `sb_systolic_tile` and LEC passes (`set_top -parameter`).
11. Lab 2 reset check: on a correct tile, `reset_port_async_pins` in `sta_ss.txt` is 2, and the check fails on anything larger.
12. The Lab 1 ripple-adder snippet in [lab1.md](lab1.md) works with your DesignWare version (`report_synlib dw_foundation.sldb` lists the implementation names).
13. The message IDs in [reading_logs.md](reading_logs.md) match your version (`man LINK-5` at the `dc_shell` prompt).
14. Each Lab 2 seeded bug shows up in this track's logs.
15. Recalibrate the clock targets: sweep `CLOCK_PERIOD` for gcd, ibex and the tile, take the shortest period that passes setup at `ss` plus 5 %, and update the SDCs and the table above.
    For Lab 2 (all `*_PIPE = 0`): Bronze = the shortest passing period, rounded up to a whole MHz; Silver = 0.70 × the shortest passing period.

## Pages in this track

| Page | What |
|---|---|
| [lab0.md](lab0.md), [lab1.md](lab1.md), [lab2.md](lab2.md) | commands for each lab |
| [reading_logs.md](reading_logs.md) | reading this track's logs and reports |
| [libraries.yaml](libraries.yaml) | the Liberty files the Lab 0 scripts read |

Next: [docs/03_liberty.md](../docs/03_liberty.md)
