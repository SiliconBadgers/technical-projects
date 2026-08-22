# SiliconBadgers UVM Onboarding

Verify a 4 × 4 int8 systolic array (`sb_systolic_array`) with UVM. You get a block diagram, an interface definition and a spec. You build the testbench, write a test plan, implement it, and hunt bugs in a hidden broken version of the design.

## Quick start

```bash
micromamba create -f env/environment.yml && micromamba activate sb-uvm
make run TEST=sa_hello_test
make help
```

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
| `docs/templates/` | Test-plan and bug-report templates |
| `docs/uvm_on_verilator.md` | Simulator notes |
| `tb/` | Your testbench |
| `rtl/` | The design (simulate it; don't read it) |
| `rtl/sanity/` | The design with one known bug |
| `model/` | Python reference model |
| `scripts/` | Regression and coverage scripts |
| `third_party/uvm-1.2/` | UVM library |

## Rules

1. Build your model from the spec, not the RTL.
2. Never edit the RTL. Report disagreements as bugs or spec questions.
3. Report every failed check with `uvm_error`.
