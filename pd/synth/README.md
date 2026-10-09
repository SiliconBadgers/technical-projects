# SiliconBadgers synthesis onboarding

Learn how RTL becomes gates, and how to check that those gates are correct and fast enough: lint, synthesis, constraints, timing analysis, equivalence checking and gate-level simulation.
For new SiliconBadgers members who know some Verilog but have not run synthesis or timing analysis. Three labs, about six weeks.

**Start here:** [01 — The big picture](docs/01_big_picture.md)

## Learning path

Every page ends with a **Next:** link, so you can also just follow those.

1. [ ] Read [01 — The big picture](docs/01_big_picture.md).
2. [ ] Skim [02 — Glossary](docs/02_glossary.md). Come back to it whenever a word is new.
3. [ ] Pick a track and set it up: [track/README.md](track/README.md).
4. [ ] Read [03 — Reading a Liberty file](docs/03_liberty.md).
5. [ ] Do [Lab 0 — Library literacy](labs/lab0_libraries/README.md) (week 1).
6. [ ] Read [04 — Synthesis and its common problems](docs/04_synthesis.md).
7. [ ] Read [05 — Writing constraints (SDC)](docs/05_sdc.md).
8. [ ] Read [06 — Reading timing reports](docs/06_timing_reports.md).
9. [ ] Read [07 — Equivalence checking](docs/07_equivalence.md).
10. [ ] Read [08 — Gate-level simulation](docs/08_gate_level_sim.md).
11. [ ] Do [Lab 1 — Reference designs](labs/lab1_reference/README.md) (weeks 2–3).
12. [ ] Read [09 — What synthesis can fix](docs/09_synthesis_vs_pd.md).
13. [ ] Do [Lab 2 — Accelerator tile](labs/lab2_systolic/README.md) (weeks 4–6). Keep docs 04–09 open while you work.

## Tracks

The `main` branch holds the course: concepts, tasks and designs, with no tool commands.
Each track branch adds the commands and flow scripts for one set of tools, mostly in `track/`.

| Track | Tools | Branch |
|---|---|---|
| A | Open-source: Yosys, OpenSTA, eqy, Verilator, Icarus Verilog, cocotb | `track-a` |
| B1 | Cadence: Genus, Tempus, Conformal, Xcelium | `track-b1` |
| B2 | Synopsys: Design Compiler, PrimeTime, Formality, VCS | `track-b2` |

Track A runs on your own computer. Track B needs a machine with the vendor's licenses. Ask your mentor which one to use.

## Switching tracks

```
git checkout track-a       # or track-b1, track-b2
git checkout main          # back to the course without tool commands
```

Commit your own work before you switch.

## Layout

| Path | What |
|---|---|
| `docs/` | the concepts, numbered in reading order |
| `labs/` | the three labs: tasks, RTL, testbenches |
| `libs/lab0/` | Lab 0 Python scripts |
| `track/` | the commands for your track (on `main`: how to pick one) |
