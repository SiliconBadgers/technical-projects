# SiliconBadgers UVM Onboarding

Step 3 of the [UVM training](https://github.com/ihagedo/uvm-training): after the worked examples, verify designs you have not seen. Each project gives you a spec and a design. You write the test plan and the UVM testbench, run them against the design, and find the bugs in versions of it that mentors keep hidden.

## Projects

| Project | Design | You build |
|---|---|---|
| [`systolic_array`](projects/systolic_array/README.md) | 4 × 4 int8 systolic array with valid/ready channels | Three agents, a reference model, scoreboard, coverage, and a test plan |

Each project has its own labs under `projects/<project>/docs/labs/`.

## Your branch

All your work lives on your own branch. `main` is the course; mentors update it.

```bash
git clone git@github.com:ihagedo/uvm-onboarding.git
cd uvm-onboarding
git switch -c <your-netid>
source env/setup.sh                 # Verilator (default); add questa, xcelium or vcs
cd projects/systolic_array && make run TEST=sa_hello_test
```

| You edit | Course material (do not edit) |
|---|---|
| `projects/<project>/tb/` (testbench, `tb.f`, `regress.list`) | `projects/<project>/rtl/`, `docs/`, `model/` |
| `projects/<project>/docs/testplan/` | `common/`, `scripts/`, `third_party/`, `env/` |

Push your branch for review (`git push -u origin <your-netid>`). To pick up course updates, merge `main` into your branch (`git fetch && git merge origin/main`); since you only edit `tb/` and `docs/testplan/`, the merge is clean.

## Layout

| Path | Contents |
|---|---|
| `projects/<project>/` | Spec, labs, design, model, and your `tb/` and test plan |
| `common/sim.mk` | Build, run, regression and coverage flow every project uses (`SIM=verilator\|questa\|xcelium\|vcs`) |
| `scripts/` | Regression runner, coverage report, Verilator quirk checks |
| `docs/simulators.md` | Simulator notes and known Verilator issues |
| `docs/templates/` | Test-plan and bug-report templates |
| `env/` | Toolchain: `setup.sh` and the Verilator conda env |
| `third_party/uvm-1.2/` | Accellera UVM 1.2 |

## Rules

1. Build your model from the spec, not the RTL.
2. Never edit the RTL. Report disagreements as bugs or spec questions.
3. Report every failed check with `uvm_error`.

## Mentors

Answer keys, the broken designs and the scoring scripts are in the private `ihagedo/uvm-mentor` repository. Clone it as `mentor/` here (it is git-ignored); see its README.
