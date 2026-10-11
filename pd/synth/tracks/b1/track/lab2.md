# Lab 2 commands (Track B1)

The tasks and questions are in [labs/lab2_systolic/README.md](../labs/lab2_systolic/README.md); the contract is [spec.md](../labs/lab2_systolic/spec.md).
This page only shows how to run them here. Your clock target: [README.md](README.md#lab-2).

## Your SDC

Your SDC goes in **`labs/lab2_systolic/sdc/sky130_scl_9T.sdc`**. Until it exists, `make synth` stops and says so.

- Plain SDC: Genus (synthesis) and Tempus (timing) both read it.
- First clock line: `set clk_period <ns>`, then use `$clk_period`. `CLOCK_PERIOD=<ns>` replaces that line for one run.
- Library cells for drive and load: `BUFX2` (pin `Y`) and `BUFX4` (pin `A`); the capacitance is in the Liberty file ([lab0.md](lab0.md#finding-the-library-files)).
- The Lab 1 SDCs show the syntax: `labs/lab1_reference/*/sdc/sky130_scl_9T.sdc`.
- Check it: `make sta DESIGN=sb_systolic_tile`, then read `check_timing.rpt` and `sta_check_timing.rpt` before any path ([reading_logs.md](reading_logs.md#constraint-checks)).

## Run the steps one at a time

```
make lint  DESIGN=sb_systolic_tile
make sim   DESIGN=sb_systolic_tile
make synth DESIGN=sb_systolic_tile
make sta   DESIGN=sb_systolic_tile
make lec   DESIGN=sb_systolic_tile
make gls   DESIGN=sb_systolic_tile
make qor   DESIGN=sb_systolic_tile
```

Or all at once, then the checks:

```
make -k all DESIGN=sb_systolic_tile     # -k: keep going after a failing step
make check  DESIGN=sb_systolic_tile
```

Outputs: `build/sb_systolic_tile/sky130_scl_9T/`.

## Lint waivers

A lint warning fails `make lint`. If a warning is checked and harmless, waive it in `labs/lab2_systolic/hal_waivers.txt`: one line per message, `<code> [<file pattern>]  # why`.
A mentor reviews every waiver.

## Trying changes

| Change | Command |
|---|---|
| Parameters | `make all DESIGN=sb_systolic_tile DESIGN_PARAMS="<NAME>=<value> ..."` (own build folder) |
| Clock period | add `CLOCK_PERIOD=<ns>` (own build folder, `..._p<ns>`) |
| Period sweep | `for p in <ns> <ns> <ns>; do make synth sta qor DESIGN=sb_systolic_tile CLOCK_PERIOD=$p; done` |
| Retiming | add `SYNTH_RETIME=1` |
| More synthesis effort | add `SYNTH_EFFORT=high` |
| Waveforms | add `WAVES=1` to `make sim` or `make gls` (open `sim_rtl/cocotb_waves.shm` with `simvision`) |
| 8 × 8 array | `DESIGN_PARAMS="N_ROWS=8 N_COLS=8"` |

Give `make check` the same `DESIGN_PARAMS` and `CLOCK_PERIOD`, so it reads the same build folder.

## Where to look

| Task | Look at |
|---|---|
| 1. Make it correct | `lint.log`, the `make sim` output and `results.xml`, `synth.log`, `check_design.rpt`, `lec_run.log`, `gls_results.xml` |
| 2. SDC | `check_timing.rpt`, `sta_check_timing.rpt`, then `sta_ss_setup.rpt` and `sta_ff_hold.rpt` |
| 3. Bronze | `make check` |
| 4. Silver | `sta_ss_setup.rpt`, `qor.csv`, `gates.rpt` |
| 5. Gold | the same, for the 8 × 8 run |
| 6. High fanout | `sta_drv.rpt` (Tempus design-rule violators) and the fanout lines of `qor.rpt` (Genus) |

How to read each file: [reading_logs.md](reading_logs.md). `make check` also prints your tier and leaderboard score.

Next: answer the questions in [labs/lab2_systolic/README.md](../labs/lab2_systolic/README.md), then follow its Next link.
