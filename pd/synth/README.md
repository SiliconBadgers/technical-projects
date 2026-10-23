# SiliconBadgers synthesis onboarding

Learn how RTL becomes gates, and how to check that those gates are correct and fast enough: lint, synthesis, constraints, timing analysis, equivalence checking and gate-level simulation.
For new SiliconBadgers members who know some Verilog but have not run synthesis or timing analysis. Three labs, about six weeks.

**Start here:** [01 — The big picture](docs/01_big_picture.md)

## Learning path

Every page ends with a **Next:** link, so you can also just follow those.

1. [ ] Read [01 — The big picture](docs/01_big_picture.md).
2. [ ] Skim [02 — Glossary](docs/02_glossary.md). Come back to it whenever a word is new.
3. [ ] Pick a track and set it up: [tracks/README.md](tracks/README.md).
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

The course (`docs/`, `labs/`, `libs/`) is the same for every track. Each track has a folder under `tracks/` with the commands and flow scripts for one set of tools; its pages are in that folder's `track/`.

| Track | Tools | Folder |
|---|---|---|
| A | Open-source: Yosys, OpenSTA, eqy, Verilator, Icarus Verilog, cocotb | [`tracks/a`](tracks/a/track/README.md) |
| B1 | Cadence: Genus, Tempus, Conformal, Xcelium | [`tracks/b1`](tracks/b1/track/README.md) |
| B2 | Synopsys: Design Compiler, PrimeTime, Formality, VCS | [`tracks/b2`](tracks/b2/track/README.md) |

Track A runs on your own computer or on UW CAE. Track B needs a machine with the vendor's licenses. Ask your mentor which one to use.

## Working in a track

Run every command from your track's folder; build output goes to its `build/` folder.

```
cd tracks/b2               # or tracks/a, tracks/b1
make all DESIGN=gcd
```

## Layout

| Path | What |
|---|---|
| `docs/` | the concepts, numbered in reading order |
| `labs/` | the three labs: tasks, RTL, testbenches |
| `libs/lab0/` | Lab 0 Python scripts |
| `tracks/` | one folder per track: its flow, constraints and commands (`track/`); [tracks/README.md](tracks/README.md) helps you pick one |
