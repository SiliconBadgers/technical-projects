# Lab 2 commands (Track B2)

The tasks and questions are in [labs/lab2_systolic/README.md](../labs/lab2_systolic/README.md); the contract is [spec.md](../labs/lab2_systolic/spec.md).
This page only shows how to run them here. Your clock target: [README.md](README.md#clock-targets) (Bronze: 57 MHz).

## Your SDC

Your SDC goes in **`labs/lab2_systolic/sdc/sky130_fd_sc_hd.sdc`**. Until it exists, `make synth` stops and says so.

- Write plain SDC: Design Compiler and PrimeTime both read it with `read_sdc`. There are no helper procedures in this track.
- Put the period on its own line, `set clk_period <ns>`, and compute the rest from it. `make ... CLOCK_PERIOD=<ns>` replaces that line.
- Input driver: `set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 -pin X <ports>`.
- Output load: `set_load <pF> <ports>`. Look up the input capacitance of `sky130_fd_sc_hd__buf_4` pin `A` in the Liberty file (Lab 0 tools) and write it in a comment.
- To leave some ports out of a list: `remove_from_collection [all_inputs] [get_ports {<ports>}]`.
- Example of the style: [the gcd SDC](../labs/lab1_reference/gcd/sdc/sky130_fd_sc_hd.sdc). Rules and conventions: [docs/05_sdc.md](../docs/05_sdc.md).

Check it with `make sta DESIGN=sb_systolic_tile`, then read the first sections of `sta_ss.rpt` (`check_timing` and the coverage) before any path ([reading_logs.md](reading_logs.md#timing)).

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

Or `make all DESIGN=sb_systolic_tile`. Outputs: `build/sb_systolic_tile/sky130_fd_sc_hd/`.

- The weight-buffer SRAM is a **macro**: a ready-made block that synthesis does not build. Its fake timing models are `labs/lab2_systolic/macros/sb_sram_256x8_sky130_fd_sc_hd_<corner>.lib`.
  `make synth` and `make sta` compile them to `.db` first (`make macros`; output in `build/sb_systolic_tile/macros/`).

## Trying changes

| Change | Command |
|---|---|
| Parameters | `make all DESIGN=sb_systolic_tile DESIGN_PARAMS="<NAME>=<value> ..."` (own build folder) |
| Clock period | add `CLOCK_PERIOD=<ns>` (own build folder, `..._p<ns>`) |
| Period sweep | `for p in <ns> <ns> <ns>; do make synth sta qor DESIGN=sb_systolic_tile CLOCK_PERIOD=$p; done` |
| Retiming | add `SYNTH_RETIME=1` |
| Waveforms | add `WAVES=1` to `make sim` or `make gls`; open `sim_rtl/waves.vcd` or `sim_gls/waves.vcd` |
| 8 × 8 array | `DESIGN_PARAMS="N_ROWS=8 N_COLS=8"` |

The testbench reads the same `DESIGN_PARAMS` (as `SB_DESIGN_PARAMS`), so it checks the array you built.

## Bronze, Silver, Gold

- Bronze: every row of [this track's checks](README.md#this-tracks-checks) passes at the Bronze clock target.
- This track has one library, so Gold is the 8 × 8 part.
- Leaderboard score: `area_um2` × `period_ns` from the `ss` row of `qor.csv`.

## Where to look

| Task | Look at |
|---|---|
| 1. Make it correct | `lint.log`, `sim.log` and `results.xml`, `synth.log` and `synth_check_design.rpt`, `synth_latches.rpt`, `lec_run.log` and `lec_failing.rpt`, `gls.log` |
| 2. SDC | `sta_<corner>.rpt`: the `check_timing` and coverage sections, the reset section, and the hold paths at `ff` |
| 3. Bronze | [this track's checks](README.md#this-tracks-checks) |
| 4. Silver | `sta_ss.rpt` setup paths, `qor.csv`, `synth_cells.rpt` |
| 5. Gold | the same, for the 8 × 8 build |
| 6. High fanout | `sta_ss.rpt`, section "All violators" (max fanout needs `set_max_fanout` in your SDC) |

How to read each file: [reading_logs.md](reading_logs.md).

Next: answer the questions in [labs/lab2_systolic/README.md](../labs/lab2_systolic/README.md), then follow its Next link.
