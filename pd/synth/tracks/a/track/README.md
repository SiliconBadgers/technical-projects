# Track A: open-source tools

Track A runs every step of the course with free, open-source tools. No license and no special machine are needed: a laptop is enough.
You are on the `track-a` branch. The course itself (concepts, labs, designs) is the same on every track; this folder only says how to do each step here.

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
| Everything | IIC-OSIC-TOOLS | A container image that holds all of the above. |

Think of Yosys as the translator (RTL into gates) and ABC as the shopper who picks real parts from the library catalog.
Exact versions: [pins.md](pins.md). New words: [glossary](../docs/02_glossary.md).

## Setup

### Option 1: the container (recommended)

A container is a ready-made Linux box with every tool at the right version, so everyone gets the same results.

```
env/start.sh build      # once, and again whenever pdk.lock changes
env/start.sh shell      # opens a shell inside the container
cd /foss/designs/silicon-badgers-synth-onboarding
make env-check          # PDKs and tools match pdk.lock
```

- Needs Docker or Podman.
- The folder that holds your clone is mounted at `/foss/designs`.
- The container sets `PDK_ROOT` and `SCL_ROOT` for you.

### Option 2: tools on your own machine

1. Install the tool versions in [pins.md](pins.md).
2. `pip install -r requirements.txt` (in a virtual environment).
3. Install the PDKs (process design kits: the factory's files, including the cell libraries) with ciel, at the `open_pdks` hashes in [`pdk.lock`](../pdk.lock):
   ```
   ciel enable --pdk-root <dir> --pdk-family sky130   -l sky130_fd_sc_hd -l sky130_fd_sc_hs <sky130 hash>
   ciel enable --pdk-root <dir> --pdk-family gf180mcu -l gf180mcu_fd_sc_mcu7t5v0 -l gf180mcu_fd_sc_mcu9t5v0 <gf180mcu hash>
   ```
4. Point the flow at them, then check:
   ```
   export PDK_ROOT=<dir>                          # holds sky130A/ and gf180mcuD/
   export SCL_ROOT=<path>/sky130_scl_9T_0.1.2     # only for the sky130scl library
   make env-check
   ```

| Variable | Meaning | Default |
|---|---|---|
| `PDK_ROOT` | ciel install of `sky130A` and `gf180mcuD` | `~/.ciel` |
| `SCL_ROOT` | unpacked `sky130_scl_9T` 0.1.2 release (not redistributable: ask a mentor for the tarball) | `$PDK_ROOT/sky130_scl_9T_0.1.2` |

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
| [spec_deviations.md](spec_deviations.md) | where Track A differs from its build spec |
| [course_spec.md](course_spec.md) | the build spec |
| [maintainers.md](maintainers.md) | rules for people who change this branch |

Next: [docs/03_liberty.md](../docs/03_liberty.md), then Lab 0 with [track/lab0.md](lab0.md).
