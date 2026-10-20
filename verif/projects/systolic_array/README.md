# Project: systolic array

Verify a 4 × 4 int8 systolic array (`sb_systolic_array`) with UVM. You get a block diagram, an interface definition and a spec. You build the testbench, write a test plan, implement it, and hunt bugs in a hidden broken version of the design.

## Quick start

From `verif/`, on your own branch, after the [verification setup](../../../intro/SETUP.md#verification-track):

```bash
module load synopsys/suite
cd projects/systolic_array
make run TEST=sa_hello_test
make help
```

Paths below are relative to this directory.

## Course

| Week | Lab | Deliverable |
|---|---|---|
| 0 | [Setup](docs/labs/lab0_setup.md) | Hello test passes; exercise |
| 1–2 | [Testbench infrastructure](docs/labs/lab1_tb_infrastructure.md) | Environment and smoke test |
| 3 | [Test plan](docs/labs/lab2_testplan.md) | Reviewed test plan |
| 4–5 | [Sequences and tests](docs/labs/lab3_sequences_and_tests.md) | Full regression and coverage |
| 6 | [Bug hunt](docs/labs/lab4_bug_hunt.md) | Scorecard and bug reports |

## Layout

| Path | Contents |
|---|---|
| `docs/spec/` | Spec, interface, block diagram, cycle tables |
| `docs/labs/` | Lab guides |
| `docs/testplan/` | Your test plan |
| `tb/` | Your testbench |
| `rtl/` | The design (simulate it; don't read it) |
| `rtl/sanity/` | The design with one known bug |
| `model/` | Python reference model and golden vectors |
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
