# Lab 2 commands (Track A)

The tasks and questions are in [labs/lab2_systolic/README.md](../../../labs/lab2_systolic/README.md); the contract is [spec.md](../../../labs/lab2_systolic/spec.md).
This page only shows how to run them here. Your clock target: [README.md](README.md#clock-targets).

## Task 1: the seeded bugs

The bugs are in the copy `labs/lab2_systolic/rtl_bugs/` (in the course folder). Add `BUGS=1` to every `make` line, `make check` included, to build that copy:

```
make lint  PDK=sky130hd DESIGN=sb_systolic_tile BUGS=1
make sim   PDK=sky130hd DESIGN=sb_systolic_tile BUGS=1
make synth PDK=sky130hd DESIGN=sb_systolic_tile BUGS=1
```

Its outputs go to `build/sb_systolic_tile/<library>_bugs/`. Fix the bugs in `rtl_bugs/`.
Without `BUGS=1` the flow builds `rtl/`, the working RTL that tasks 2 to 6 start from.

## Run the steps one at a time

```
make lint  PDK=sky130hd DESIGN=sb_systolic_tile
make sim   PDK=sky130hd DESIGN=sb_systolic_tile
make synth PDK=sky130hd DESIGN=sb_systolic_tile
make sta   PDK=sky130hd DESIGN=sb_systolic_tile
make lec   PDK=sky130hd DESIGN=sb_systolic_tile
make gls   PDK=sky130hd DESIGN=sb_systolic_tile
make qor   PDK=sky130hd DESIGN=sb_systolic_tile
```

Or all at once, then the acceptance checks:

```
make all   PDK=sky130hd DESIGN=sb_systolic_tile
make check PDK=sky130hd DESIGN=sb_systolic_tile
```

Outputs: `build/sb_systolic_tile/sky130hd/`.

## Your SDC

- Write `tracks/a/labs/lab2_systolic/sdc/<library>.sdc` (e.g. `sky130hd.sdc`; this track's lab folder, not the one in the course's `labs/`). The flow reads `sdc/$(PDK).sdc`.
- Use the [SDC helpers](README.md#sdc-helpers): `set clk_period [sb_clock_period <ns>]`, `$sb_driving_cell`, `[sb_pin_cap ...]`.
- Check it: `make sta ...`, then read the first sections of `sta_ss.rpt` ([reading_logs.md](reading_logs.md#timing)).

## Trying changes

| Change | Command |
|---|---|
| Parameters | `make all PDK=sky130hd DESIGN=sb_systolic_tile DESIGN_PARAMS="<NAME>=<value> ..."` (own build folder) |
| Clock period | add `CLOCK_PERIOD=<ns>` (own build folder, `..._p<ns>`) |
| Period sweep | `python3 flow/scripts/qor/sweep.py --pdk sky130hd --design sb_systolic_tile --periods <ns> <ns>` |
| Retiming | add `SYNTH_RETIME=1` |
| Waveforms | add `WAVES=1` to `make sim` or `make gls` |
| Second library | `PDK=gf180_7t` (or any library in [README.md](README.md#clock-targets)) |
| 8 x 8 array | `DESIGN_PARAMS="N_ROWS=8 N_COLS=8"` |

Give `make check` the same `DESIGN_PARAMS` and `CLOCK_PERIOD`, so it reads the same build folder.

## Where to look

| Task | Look at |
|---|---|
| 1. Make it correct (`..._bugs/`) | `lint.log`, `make sim` output and `results.xml`, `synth.log`, `synth_check.txt`, `lec_run.log`, `gls_results.xml` |
| 2. SDC | `sta_<corner>.rpt`: the sections before the paths, and the hold paths at `ff` |
| 3. Bronze | `make check` |
| 4. Silver | `sta_ss.rpt` setup paths, `qor.csv`, `synth_stat.txt` |
| 5. Gold | the same, for the second library and the 8 x 8 run |
| 6. High fanout | `sta_ss.rpt`, section "Design rule violators" |

How to read each file: [reading_logs.md](reading_logs.md). `make check` also prints your tier and leaderboard score.

Next: answer the questions in [labs/lab2_systolic/README.md](../../../labs/lab2_systolic/README.md), then follow its Next link.
