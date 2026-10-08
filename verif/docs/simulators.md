# Simulators

The course uses Accellera UVM 1.2 (`third_party/uvm-1.2`) on Verilator 5.052 with the z3 constraint solver. The same testbench also runs on Questa, Xcelium and VCS with `SIM=`.

| `SIM=` | Simulator | `source env/setup.sh …` | Coverage, waves |
|---|---|---|---|
| `verilator` (default) | Verilator 5.052 | (nothing) | `make cov`, `make waves` |
| `questa` | Questa 2025.1 | `questa` | `make gui SIM=questa` |
| `xcelium` | Xcelium 25.09 | `xcelium` | — |
| `vcs` | VCS 2026.03 | `vcs` | — |

## All simulators

- UVM is compiled from `third_party/uvm-1.2` with `+define+UVM_NO_DPI`. Only `+UVM_TESTNAME` is read by UVM; parse other plusargs yourself.
- Seeds: `make run SEED=<n>`. Each simulator turns a seed into different random values, so a failing seed on one simulator does not reproduce on another.
- `make regress` runs on every simulator; the PASS/FAIL rule is the same (the PASS banner and 0 UVM errors and fatals).

## Verilator

- Seeds: `make run SEED=<n>` passes `+verilator+seed+<n>`.
- Verilator is 2-state: there is no X or Z.
- Waves: `make waves TEST=<t> SEED=<s>` writes `waves.fst`.
- Coverage: `make cov` after `make regress`. `get_coverage()` returns 0 during simulation.

### Known issues

| # | Issue | Workaround |
|---|---|---|
| Q1 | A queue of unpacked arrays (`int q[$][4]`) loses data. | Queue class objects or packed vectors. |
| Q2 | `dist` on a variable that has other constraints fails or skews. | Put `dist` on a separate selector bit. |
| Q3 | `cond -> x inside {[-4:4]}` fails for signed `x`. | Write `if (cond) x inside {[-4:4]};`. |
| Q4 | Negative bins on a `longint` coverpoint never hit. | Use an `int` coverpoint. |
| Q5 | `binsof` in cross bins is not supported. | Shape the cross with coverpoint bins. |
| Q6 | A comment that starts with the word "verilator" is read as a directive. | Start the comment with another word. |
| Q7 | A clocking-block drive issued after a blocking call (`get_next_item`, `try_next_item`) can take effect one edge late. | Drive with non-blocking assignments right after the clock edge (or at the falling edge). |
| Q8 | `dist` inside `randomize() with {}` is ignored. | Put `dist` in a class constraint. |
| Q9 | `$error` in a generate block is only a warning. | Build with `-Werror-USERERROR` (the Makefile does). |
| Q10 | A variable with an initializer inside an `always` block is static. | Declare it `automatic`. |
| Q11 | `program`, `edge` and `until` are keywords. | Use other names. |
| Q12 | Line coverage skips statements inside functions. | Check function logic with assertions or directed tests. |

`scripts/verilator_quirks/run.sh` checks whether Q1–Q4 are still present.

## Questa, Xcelium and VCS

These are optional. On CAE Linux:

- Load them through `source env/setup.sh questa` (or `xcelium`, `vcs`, or several). Use `cadence/xcelium/2509`: the default `cadence/xcelium` (2603) is newer than the campus license and fails at simulation with `NOLICN`.
- They run inside the CAE containers (`mentor-run`, `cadence-run`, `synopsys-run`); the Makefile adds the wrapper. VCS runs 64-bit (`-full64`).
- They are 4-state: an undriven or uninitialized signal is X, which Verilator would show as 0. A test that passes on Verilator and fails on a 4-state simulator usually has an X problem.
- `make gui SIM=questa` opens Questa with every top-level signal in the wave window.
- Coverage reports (`make cov`) and `make waves` are Verilator-only in this flow.
- Loading `mentor/suite/2026` puts a Calibre `python3` first on `PATH` that cannot run scripts. `env/setup.sh` puts the course's Python back in front; if you load modules by hand, load them before `source env/setup.sh`.

