# Project: APB register block

Verify an APB4 register block with a timer and an interrupt (`sb_apb_regs`) with UVM. You get an interface definition and a spec. You build the testbench and a register model, write a test plan, implement it, and hunt bugs in a hidden broken version of the design. This is the second project: it takes about two weeks.

## Quick start

From the repository root, on your own branch (see the repository README):

```bash
source env/setup.sh
cd projects/apb_regs
make run TEST=apb_hello_test
make help
```

Paths below are relative to this directory.

## Course

| Days | Lab | Deliverable |
|---|---|---|
| 1 | [Setup](docs/labs/lab0_setup.md) | Hello test passes; exercise |
| 2–4 | [Testbench and smoke test](docs/labs/lab1_tb_infrastructure.md) | Agent, reference model, scoreboard; smoke test |
| 5 | [Test plan](docs/labs/lab2_testplan.md) | Reviewed test plan |
| 6–9 | [Tests, register model and coverage](docs/labs/lab3_tests_ral_coverage.md) | Full regression and coverage |
| 10 | [Bug hunt](docs/labs/lab4_bug_hunt.md) | Scorecard and bug reports |

## Layout

| Path | Contents |
|---|---|
| `docs/spec/` | Spec and interface (with an example waveform) |
| `docs/labs/` | Lab guides |
| `docs/testplan/` | Your test plan |
| `tb/` | Your testbench |
| `rtl/` | The design (simulate it; don't read it) |
| `rtl/sanity/` | The design with one known bug |
| `scripts/` | Generator for `rtl/sanity/` (maintainers) |
| `../../docs/templates/` | Test-plan and bug-report templates |
| `../../docs/simulators.md` | Simulator notes |

## Running

```bash
make run TEST=<test> [SEED=<n>] [DUT=sanity]
make regress SEEDS=3 && make cov      # coverage needs Verilator
make waves TEST=<test>                # Verilator FST waves
make run SIM=questa TEST=<test>       # or xcelium, vcs; make gui SIM=questa for the Questa GUI
```

## Rules

1. Build your model from the spec, not the RTL.
2. Never edit the RTL. Report disagreements as bugs or spec questions.
3. Report every failed check with `uvm_error`.
