# Verification track

[Home](../README.md) · [Shared introduction](../intro/README.md#shared-introduction) · [CAE setup](../intro/SETUP.md) · [RTL](../rtl/README.md#rtl-track)

The verification track is a UVM onboarding course: after the shared introduction
you verify designs you have not seen. Each project gives you a specification and a
design. You write the test plan and the UVM testbench, run them against the design,
and find the bugs in broken versions your instructors keep hidden.

## On this page

- [Projects](#projects)
- [Getting started with verification](#getting-started-with-verification)
- [Debug in the waveform](#debug-in-the-waveform)
- [Coverage](#coverage)
- [Layout](#layout)
- [Rules](#rules)
- [Testbench completion](#testbench-completion)

## Projects

Do them in this order:

| # | Project | Design | You build | Time |
|---|---|---|---|---|
| 1 | [`sync_fifo`](projects/sync_fifo/README.md) | Synchronous FIFO with valid/ready on both sides, flags and flush | Write and read agents, a queue model, scoreboard, coverage, a test plan | 1–2 weeks |
| 2 | [`apb_regs`](projects/apb_regs/README.md) | APB4 register block with a timer and an interrupt | An APB agent, a UVM register model, a timer model, coverage, a test plan | ~2 weeks |
| 3 | [`systolic_array`](projects/systolic_array/README.md) | 4 × 4 int8 systolic array with valid/ready channels | Three agents, a reference model, scoreboard, coverage, a test plan | 6 weeks |

Each project has its own labs under `projects/<project>/docs/labs/` and a hidden
set of seeded bugs for the final bug hunt, which your instructors score against.

## Getting started with verification

Set up CAE and the UVM library as described in [CAE setup](../intro/SETUP.md#verification-track).
All your work lives on your own branch. `main` is the course.

```bash
cd ~/technical-projects
git switch -c <your-netid>
module load synopsys/suite
cd verif/projects/sync_fifo
make run TEST=fifo_hello_test
```

The test prints `*** TEST PASSED ***`. VCS is the default simulator. Add `SIM=verilator`,
`SIM=questa`, or `SIM=xcelium` to a `make` command to use another one;
[Simulators](docs/simulators.md) covers their setup and differences.

| You edit | Course material (do not edit) |
|---|---|
| `projects/<project>/tb/` (testbench, `tb.f`, `regress.list`) | `projects/<project>/rtl/`, `docs/`, `model/` |
| `projects/<project>/docs/testplan/` | `common/`, `scripts/`, `third_party/`, `env/` |

Push your branch for review (`git push -u origin <your-netid>`). To pick up course
updates, merge `main` into your branch (`git fetch && git merge origin/main`);
since you only edit `tb/` and `docs/testplan/`, the merge is clean.

## Debug in the waveform

When a check fails, the log tells you which check failed and when. The waveform shows
why. `make waves TEST=<test> SEED=<seed>` reruns the test with waves on and prints the
file to open: `waves.vcd`, or `waves.fst` with Verilator. Open it with
`gtkwave <file>` in a CAE desktop host terminal.

1. Before you open the viewer, write a short table from the spec: a few clock edges
   around the failure and the values you expect at each one.
2. Show the clock, reset, and the DUT's inputs and outputs, then zoom to the failure
   time from the log.
3. Read every signal at one clock edge. A registered output changes just after the
   edge, so compare the values just before and just after it.
4. Step back edge by edge to the first time the waveform disagrees with your table.
   Write down that time and signal.
5. Open the code that drives or samples that signal: your driver, monitor, or model in
   `tb/`, or the DUT port it comes from. It's a design bug only if your testbench
   followed the spec at that edge.

To compare with a passing run, run `make waves` for the passing seed or design too and
look at both at the same time.

## Coverage

`make regress` collects functional coverage from your covergroups, and `make cov` lists
each covergroup and coverpoint with its percentage and the bins no test hit.

Code coverage of the design is separate: run `make regress CODECOV=1`, then
`make cov-code CODECOV=1`. With VCS it prints line, condition, toggle, and branch
coverage of `tb_top.dut`, and `modinfo.txt` in the report directory it names lists
each line, condition, toggle, and branch that no test reached.

Report coverage with its scope and metric, for example "`tb_top.dut` branch 100%". A
report's total score also counts your testbench's own modules and interfaces, so it
doesn't describe the design. Coverage counts only where a check looks at the behavior.

## Layout

All paths below are under `verif/`.

| Path | Contents |
|---|---|
| `projects/<project>/` | Spec, labs, design, model, and your `tb/` and test plan |
| `common/sim.mk` | Build, run, regression and coverage flow every project uses (`SIM=vcs\|verilator\|questa\|xcelium`) |
| `scripts/` | Regression runner, coverage report, Verilator quirk checks |
| `docs/simulators.md` | Simulator notes and known Verilator issues |
| `docs/templates/` | Test-plan and bug-report templates |
| `env/` | Optional simulators: `setup.sh` and the Verilator conda env |
| `third_party/uvm-1.2/` | `SiliconBadgers/UVM_Library` submodule (UVM 1.2) |

## Rules

1. Build your model from the spec, not the RTL.
2. Never edit the RTL. Report disagreements as bugs or spec questions.
3. Report every failed check with `uvm_error`.

## Testbench completion

Complete the project test plan and UVM testbench, then run the project regression.
The checkpoint is complete when the testbench checks the specification and detects
design errors.
