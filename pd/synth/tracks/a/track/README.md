# Track A: open-source tools

Track A runs every step of the course with free, open-source tools. No license and no special machine are needed: a laptop or a UW CAE machine is enough.
Track A lives in the folder `tracks/a`. The course itself (concepts, labs, designs) is the same on every track and sits in the course folder, two levels up (the folder with `docs/`, `labs/` and `tracks/`); this folder holds Track A's flow, and these pages say how to do each step here.
Run every command on these pages from `tracks/a`; paths are relative to it.

## The tools

| Step | Tool | What it does |
|---|---|---|
| Lint | Verilator (`--lint-only -Wall`) | Reads the RTL and warns about code that is legal but risky. |
| Lint | `flow/scripts/lint/sb_lint.py` | One team rule Verilator lacks (`SB-SENS`, hand-written sensitivity lists). |
| Lint | Verible | Style advice only; it never fails the build. |
| Simulation | cocotb | Testbenches written in Python. |
| Simulation | Icarus Verilog | Runs the Verilog simulation (RTL and gate level). |
| Simulation | Verilator | Simulator for SystemVerilog-heavy designs (ibex). |
| Synthesis | Yosys | Reads the RTL and turns it into generic gates. |
| Synthesis | ABC (inside Yosys) | Picks real library cells for those gates, aiming at the clock period. |
| Synthesis | `read_slang` (sv-elab, inside Yosys) | The SystemVerilog reader. |
| Timing | OpenSTA | Static timing analysis at the tt, ss and ff corners. |
| Equivalence | eqy | Proves the netlist does the same as the RTL. |
| PDK install | ciel | Downloads the open PDKs at the exact pinned version. |
| Install | conda-forge, `env/install.sh` | Puts all of the above in your home folder ([Setup](#setup), Option 1). |
| Install | IIC-OSIC-TOOLS | A container image that holds all of the above ([Setup](#setup), Option 2). |

Think of Yosys as the translator (RTL into gates) and ABC as the shopper who picks real parts from the library catalog.
Exact versions: [pins.md](pins.md). New words: [glossary](../../../docs/02_glossary.md).

## Setup

Track A needs no license and no sudo. Get the tools one of two ways.

### Option 1: the install script (no container)

`env/install.sh` puts every tool and both PDKs (process design kits: the factory's files, including the cell libraries) in your home folder, at the versions in [pins.md](pins.md).
It needs `git` and a conda-forge package manager (`mamba`, `micromamba` or `conda`).

```
env/install.sh          # once: about 6 GB; 25 minutes in a CAE home folder, 2 on a local disk
source env/setup.sh     # in every new terminal
make env-check          # PDKs and tools match pdk.lock
```

- **UW CAE:** run `module load conda-forge/26.3.2` before `env/install.sh` (it gives `mamba`). Run the flow on the CAE host; this track does not use `synopsys-run`.
- **Your own Linux machine:** install [Miniforge](https://conda-forge.org/download/) in your home folder first (no sudo needed).
- macOS and Windows are not tested with the script. Use Option 2 there.
- The tools go to `~/.conda/envs/sb-track-a` and the PDKs to `~/.ciel`. For other folders, set `SB_TRACK_A_ENV` and `PDK_ROOT` before both commands.
- The script builds eqy, sby and OpenSTA from source. If it stops, fix the problem it prints and run it again; it skips what is already installed.

### Option 2: the container

A container is a ready-made Linux box with every tool at the right version. It needs Docker or Podman.

```
env/start.sh build      # once, and again whenever pdk.lock changes
env/start.sh shell      # opens a shell inside the container and prints the cd line below
cd /foss/designs/<course folder>/tracks/a
make env-check          # PDKs and tools match pdk.lock
```

- The folder that holds the course folder (the folder with `docs/`, `labs/` and `tracks/`) is mounted at `/foss/designs`; `<course folder>` is that folder's name.
- The container sets `PDK_ROOT` and `SCL_ROOT` for you. `SCL_ROOT` is `/foss/designs/sky130_scl_9T_0.1.2`, so for the `sky130scl` library unpack its tarball next to the course folder.

Both options give the same slack and area: the synthesis, timing and equivalence tools and the PDKs are the same versions ([pins.md](pins.md)).

| Variable | Meaning | Default |
|---|---|---|
| `PDK_ROOT` | ciel install of `sky130A` and `gf180mcuD` | `~/.ciel` |
| `SCL_ROOT` | unpacked `sky130_scl_9T` 0.1.2 release (not redistributable: ask a mentor for the tarball) | `$PDK_ROOT/sky130_scl_9T_0.1.2` |
| `SB_TRACK_A_ENV` | the tools from `env/install.sh` | `~/.conda/envs/sb-track-a` |

## Running a step

```
make <step> PDK=<library> DESIGN=<design>
```

| Target | Does | Main output |
|---|---|---|
| `lint` | Verilator, sb_lint, Verible | `lint.log` |
| `sim` | cocotb testbench on the RTL | `results.xml` |
| `synth` | Yosys + ABC (`flow/scripts/yosys/synth.tcl`) | `netlist.v`, `synth.log`, `synth_stat.txt`, `synth_check.txt` |
| `sta` | OpenSTA at tt, ss and ff (`flow/scripts/sta/sta.tcl`) | `sta_<corner>.rpt`, `sta_<corner>.json` |
| `lec` | eqy, RTL against `netlist.v` | `lec.log`, `lec/` |
| `gls` | the same cocotb testbench on the netlist | `gls_results.xml` |
| `qor` | collects area, slack, power and runtimes | `qor.csv` |
| `all` | all of the above, in order | |
| `check` | the acceptance checks (`ci/checks.py`) | PASS/FAIL per check |

- Outputs go to `build/<design>/<library>/`, e.g. `build/gcd/sky130hd/`.
- Each step also writes `<step>.env` there, so you can rerun the tool by hand.
- A failing check prints the page to read.
- `PDK=`: `sky130hd`, `sky130hs`, `gf180_7t`, `gf180_9t`, `sky130scl` (settings in `flow/platforms/<library>.mk`; Liberty files in [libraries.yaml](libraries.yaml)).
- `DESIGN=`: `gcd`, `ibex`, `sb_systolic_tile` (see `labs/designs.mk`).
- Other targets: `make help`, `make info`, `make clean` (deletes one build folder), `make lec-mutation`.

### Knobs

Add `KNOB=value` to any `make` line.

| Knob | Meaning |
|---|---|
| `CLOCK_PERIOD=<ns>` | override the SDC clock period; output in `build/<design>/<library>_p<ns>/` |
| `DESIGN_PARAMS="A=1 B=2"` | top-level parameters; output in a folder named after them |
| `BUGS=1` | Lab 2 Task 1: build the copy with the seeded bugs (`rtl_bugs/`); output in `build/<design>/<library>_bugs/` |
| `SYNTH_CORNER` | Liberty corner synthesis maps to (default `ss`) |
| `SYNTH_FLATTEN` | 1 = flatten the hierarchy (default), 0 = keep modules |
| `SYNTH_RETIME` | 1 = let ABC move registers (LEC gets harder) |
| `SYNTH_FSM` | 1 = let Yosys re-encode state machines (LEC gets harder) |
| `SYNTH_ADDER` | `kogge-stone` (default), `sklansky`, `han-carlson` or `ripple` |
| `SYNTH_OUTBUF` | 1 = a buffer on every output bit (default) |
| `ABC_CONSTR` | 1 = tell ABC the input driver and output load (default) |
| `ABC_DELAY_FRAC` | ABC's delay target as a fraction of the period (default 0.6) |
| `ABC_SCRIPT` | your own ABC script |
| `LEC_JOBS` | parallel eqy jobs (default: one per CPU core) |
| `WAVES=1` | write a `.fst` waveform in `sim_rtl/` or `sim_gls/` (open it with GTKWave) |

## Clock targets

### Lab 1 (period in each SDC, `labs/lab1_reference/<design>/sdc/<library>.sdc`)

| Library | gcd | ibex |
|---|---|---|
| sky130hd | 9 ns | 24 ns |
| sky130hs | 6 ns | 16 ns |
| gf180_7t | 17 ns | 44 ns |
| gf180_9t | 14 ns | 40 ns |
| sky130scl | 6 ns | 17 ns |

### Lab 2 (from `labs/lab2_systolic/targets.yaml`)

| Library | Bronze clock | Bronze period | Silver period (at `ss`) |
|---|---|---|---|
| sky130hd | 57 MHz | 17.544 ns | 12.25 ns |
| sky130hs | 97 MHz | 10.309 ns | 7.21 ns |
| gf180_7t | 33 MHz | 30.303 ns | 21.0 ns |
| gf180_9t | 38 MHz | 26.316 ns | 18.2 ns |
| sky130scl | 90 MHz | 11.111 ns | 7.7 ns |

## SDC helpers

`flow/scripts/sta/sta.tcl` defines these before it reads your SDC:

| Name | What |
|---|---|
| `$sb_driving_cell`, `$sb_driving_pin` | the library's `buf_2` and its output pin |
| `$sb_load_cell`, `$sb_load_pin` | the library's `buf_4` and its input pin |
| `[sb_pin_cap <cell> <pin>]` | that pin's input capacitance (library units, pF) |
| `[sb_clock_period <ns>]` | returns `<ns>`, or `<x>` when you run `make ... CLOCK_PERIOD=<x>` |

Write the period as `set clk_period [sb_clock_period <ns>]`; otherwise `CLOCK_PERIOD=` overrides are refused.

## Pages in this track

| Page | What |
|---|---|
| [lab0.md](lab0.md), [lab1.md](lab1.md), [lab2.md](lab2.md) | commands for each lab |
| [reading_logs.md](reading_logs.md) | reading this track's logs and reports |
| [pins.md](pins.md) | pinned tool and PDK versions |

Next: [docs/03_liberty.md](../../../docs/03_liberty.md), then Lab 0 with [track/lab0.md](lab0.md).
