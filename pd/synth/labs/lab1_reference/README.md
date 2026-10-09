# Lab 1 — Reference designs, end to end (weeks 2–3)

**Goal:** run a known-good design through every step, read every report, and see how the library changes the result.
Nothing here is broken on purpose.

Read docs [04](../../docs/04_synthesis.md) to [08](../../docs/08_gate_level_sim.md) before or while you do the tasks.

Commands for your track: [track/lab1.md](../../track/lab1.md)

| Part | Design |
|---|---|
| 1a — smoke test | `gcd` (16-bit GCD, ~250 cells) |
| 1b — reference | `ibex` (lowRISC RISC-V core, ~30 k cells) |

- Where the sources come from: `gcd/rtl/README.orfs.md` and `ibex/UPSTREAM.md`.
- The clock periods in your track's constraint files are calibrated by the team.

## Tasks

1. **Run as shipped.** Run every step (lint, simulation, synthesis, timing, equivalence, gate-level simulation, QoR) and your track's checks for `gcd` in every library of your track, then for `ibex`.
   Note each step's wall time: which step dominates, and how does that change from gcd to ibex?
2. **Read the critical path** of ibex at `ss` ([06](../../docs/06_timing_reports.md#setup)): start point and endpoint, RTL module, which cells dominate. About half a page.
   Then synthesize with ripple-carry adders instead of your track's default and compare: what changed, and why?
3. **Clock sweep.** For each library, run at 1.3×, 1.2×, 1.1×, 1.0×, 0.9×, 0.8× and 0.7× the constraint file's clock period.
   Record WNS, TNS and area; find the shortest passing period. Why does area change with the period?
4. **Library comparison.** At each library's shortest passing period: area, cell count, the 10 most used cells (synthesis area report), leakage.
   Explain why the libraries differ (for example hs vs. hd, or gf180 7t vs. 9t). With one library, explain which cells dominate and why.
5. **Corner comparison.** One netlist, one library: setup WNS at `tt` vs. `ss`, hold WNS at `ff`. Explain the spread.
6. **Equivalence and GLS.** Both pass for ibex. Read [07](../../docs/07_equivalence.md) and [08](../../docs/08_gate_level_sim.md); in two sentences, what did equivalence checking prove that GLS could not, and the other way round?

## Exit

The QoR of all runs committed, plus the critical-path, library and corner write-ups (≤ 2 pages), reviewed by a mentor.

Next: [09 — What synthesis can fix](../../docs/09_synthesis_vs_pd.md)
