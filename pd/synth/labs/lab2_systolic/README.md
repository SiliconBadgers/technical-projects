# Lab 2 — Accelerator tile with seeded bugs (weeks 4–6)

**Goal:** fix a broken design using tool output. `sb_systolic_tile` is an int8 [systolic](../../docs/02_glossary.md#systolic-array) multiply-accumulate array. Read [spec.md](spec.md) first.

- `rtl_bugs/` is a copy of the RTL with several bugs.
- There is no SDC.
- The timing target is not reachable without design changes.

Find each problem from tool output, not by reading the RTL line by line. For every fix, point at the log line that told you.

Commands for your track: its `track/lab2.md` ([tracks/README.md](../../tracks/README.md))

## What you have

| Path | What |
|---|---|
| [spec.md](spec.md) | interface and timing contract |
| `rtl/` | the working RTL: `tile_top.sv` (top: `sb_systolic_tile`), `pe.sv`, `pe_ctrl.sv`, `readout.sv`, `reset_sync.sv`, `params.svh`. Tasks 2–6 start from it |
| `rtl_bugs/` | the same files with the seeded bugs, for Task 1. Add `BUGS=1` to a `make` line to build this copy |
| `macros/` | weight-buffer SRAM: black box for synthesis (`sb_sram_256x8.v`) and simulation model (`sb_sram_256x8_model.v`); your track adds its fake timing models |
| `tb/test_tile.py` | the testbench. Do not change it to make something pass |
| your SDC | you write it; your track's `track/lab2.md` says where it goes |

## Tasks

1. **Make it correct.** Fix the bugs in `rtl_bugs/`, with `BUGS=1` on every `make` line. Start with lint, then simulation, then synthesis. Equivalence checking and GLS also have something to tell you.
   Do not compare the files with `rtl/`: find each bug from tool output. You are done when your track's checks give the same results with `BUGS=1` as without it.
   See [04](../../docs/04_synthesis.md), [07](../../docs/07_equivalence.md), [08](../../docs/08_gate_level_sim.md).
2. **Write the SDC** from [spec.md](spec.md): every port constrained, right units, drive and load, uncertainty, and a decision (with a comment) for `cfg_k_len` and `rst_n`.
   See [05](../../docs/05_sdc.md). Check hold at `ff` after every change to timing exceptions.
3. **Bronze:** every check of your track passes at the clock target for your library (your track's `track/README.md`).
4. **Silver:** 0.70 × the Bronze period at `ss`, hold clean at `ff`, area ≤ 1.25 × your Bronze area.
   Read the critical path first ([06](../../docs/06_timing_reports.md)). Options: `MUL_PIPE`, `ACC_PIPE`, `OUT_PIPE`, retiming, RTL changes.
   Your track shows how to set parameters and sweep clock periods.
5. **Gold:** Silver in a second library, and `N_ROWS = N_COLS = 8` closed at the Bronze period. If your track has only one library, Gold is the 8 × 8 part.
6. **High fanout.** In the timing tool's design-rule report: which net has the largest fanout, why does synthesis alone not fix it well, and what will physical design do ([09](../../docs/09_synthesis_vs_pd.md))? For the report; a change is optional.

## Deliverables

1. A PR with your fixes in `rtl_bugs/`, your SDCs, updated parameters, and passing checks.
2. `lab2_report.md` (≤ 3 pages): per bug, symptom → tool output → fix; critical path before and after; QoR table; the high-fanout discussion.
3. A mentor review of your SDC: every multicycle or false path needs a comment saying why it is safe.

Leaderboard: area (µm²) × clock period (ns) at `ss`, per library. Lower is better; ties go to fewer pipeline registers.

Next: you have finished the course. Go back to the [course README](../../README.md) and tick the last box.
