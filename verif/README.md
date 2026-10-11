# Verification track

[Home](../README.md) · [Shared introduction](../intro/README.md#shared-introduction) · [CAE setup](../intro/SETUP.md) · [RTL](../rtl/README.md#rtl-track)

The verification track is a UVM onboarding course: after the shared introduction
you verify designs you have not seen. Each project gives you a specification and a
design. You write the test plan and the UVM testbench, run them against the design,
and find the bugs in broken versions your instructors keep hidden.

## On this page

- [Projects](#projects)
- [Your branch](#your-branch)
- [Layout](#layout)
- [Rules](#rules)

## Projects

Do them in this order:

| # | Project | Design | You build | Time |
|---|---|---|---|---|
| 1 | [`sync_fifo`](projects/sync_fifo/README.md) | Synchronous FIFO with valid/ready on both sides, flags and flush | Write and read agents, a queue model, scoreboard, coverage, a test plan | 1–2 weeks |
| 2 | [`apb_regs`](projects/apb_regs/README.md) | APB4 register block with a timer and an interrupt | An APB agent, a UVM register model, a timer model, coverage, a test plan | ~2 weeks |
| 3 | [`systolic_array`](projects/systolic_array/README.md) | 4 × 4 int8 systolic array with valid/ready channels | Three agents, a reference model, scoreboard, coverage, a test plan | 6 weeks |

Each project has its own labs under `projects/<project>/docs/labs/` and a hidden
set of seeded bugs for the final bug hunt, which your instructors score against.

## Your branch

All your work lives on your own branch. `main` is the course.

```bash
git clone --recurse-submodules git@github.com:SiliconBadgers/technical-projects.git
cd technical-projects/verif
git switch -c <your-netid>
source env/setup.sh                 # Verilator (default); add questa, xcelium or vcs
cd projects/sync_fifo && make run TEST=fifo_hello_test
```

The UVM 1.2 library is the [`SiliconBadgers/UVM_Library`](third_party/uvm-1.2)
submodule at `verif/third_party/uvm-1.2`. If you cloned without
`--recurse-submodules`, fetch it with `git submodule update --init
verif/third_party/uvm-1.2` from the repository root.

| You edit | Course material (do not edit) |
|---|---|
| `projects/<project>/tb/` (testbench, `tb.f`, `regress.list`) | `projects/<project>/rtl/`, `docs/`, `model/` |
| `projects/<project>/docs/testplan/` | `common/`, `scripts/`, `third_party/`, `env/` |

Push your branch for review (`git push -u origin <your-netid>`). To pick up course
updates, merge `main` into your branch (`git fetch && git merge origin/main`);
since you only edit `tb/` and `docs/testplan/`, the merge is clean.

## Layout

All paths below are under `verif/`.

| Path | Contents |
|---|---|
| `projects/<project>/` | Spec, labs, design, model, and your `tb/` and test plan |
| `common/sim.mk` | Build, run, regression and coverage flow every project uses (`SIM=verilator\|questa\|xcelium\|vcs`) |
| `scripts/` | Regression runner, coverage report, Verilator quirk checks |
| `docs/simulators.md` | Simulator notes and known Verilator issues |
| `docs/templates/` | Test-plan and bug-report templates |
| `env/` | Toolchain: `setup.sh` and the Verilator conda env |
| `third_party/uvm-1.2/` | `SiliconBadgers/UVM_Library` submodule (UVM 1.2) |

## Rules

1. Build your model from the spec, not the RTL.
2. Never edit the RTL. Report disagreements as bugs or spec questions.
3. Report every failed check with `uvm_error`.
