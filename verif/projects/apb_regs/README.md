# Project: APB register block

Verify an APB4 register block with a timer and an interrupt (`sb_apb_regs`) with UVM. You get an interface definition and a spec. You build the testbench and a register model, write a test plan, implement it, and hunt bugs in a hidden broken version of the design. This is the second project: it takes about two weeks.

## Quick start

From `verif/`, on your own branch, after the [verification setup](../../../intro/SETUP.md#verification-track):

```bash
module load synopsys/suite
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
make regress SEEDS=3 && make cov      # functional coverage
make regress CODECOV=1 && make cov-code CODECOV=1   # code coverage of the design
make waves TEST=<test>                # waves.vcd for GTKWave
make run SIM=verilator TEST=<test>    # or questa, xcelium (../../docs/simulators.md); make gui SIM=questa
```

## Rules

1. Build your model from the spec, not the RTL.
2. Never edit the RTL. Report disagreements as bugs or spec questions.
3. Report every failed check with `uvm_error`.
