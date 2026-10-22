# Project: synchronous FIFO

Verify a synchronous FIFO (`sb_fifo`) with UVM. This is the first onboarding project, sized for one to two weeks. You get a spec and an interface definition. You build the testbench, write a test plan, implement it, and hunt bugs in a hidden broken version of the design.

## Quick start

From `verif/`, on your own branch, after the [verification setup](../../../intro/SETUP.md#verification-track):

```bash
module load synopsys/suite
cd projects/sync_fifo
make run TEST=fifo_hello_test
make help
```

Paths below are relative to this directory.

## Course

| Days | Lab | Deliverable |
|---|---|---|
| 1 | [Setup](docs/labs/lab0_setup.md) | Hello test passes; exercise |
| 2–5 | [Testbench and smoke test](docs/labs/lab1_testbench.md) | Environment and smoke test |
| 6 | [Test plan](docs/labs/lab2_testplan.md) | Reviewed test plan |
| 7–9 | [Tests and coverage](docs/labs/lab3_tests_and_coverage.md) | Full regression and coverage |
| 10 | [Bug hunt](docs/labs/lab4_bug_hunt.md) | Scorecard and bug reports |

## Layout

| Path | Contents |
|---|---|
| `docs/spec/` | Spec, interface and example waveforms |
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
make regress SEEDS=3 && make cov      # functional coverage
make regress CODECOV=1 && make cov-code CODECOV=1   # code coverage of the design
make regress DEPTH=8                  # another FIFO depth (default 6); WIDTH= works the same way
make waves TEST=<test>                # waves.vcd for GTKWave
make run SIM=verilator TEST=<test>    # or questa, xcelium (../../docs/simulators.md); make gui SIM=questa
```

## Rules

1. Build your model from the spec, not the RTL.
2. Never edit the RTL. Report disagreements as bugs or spec questions.
3. Report every failed check with `uvm_error`.
