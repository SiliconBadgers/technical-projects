# Simulators

The course uses Accellera UVM 1.2 (`third_party/uvm-1.2`) on VCS by default. The same testbench also runs on Verilator, Questa, and Xcelium with `SIM=`.

| `SIM=` | Simulator | Setup on the CAE host | Coverage | Waves |
|---|---|---|---|---|
| `vcs` (default) | VCS 2026.03 | `module load synopsys/suite` | `make cov`, `make cov-code` | `waves.vcd` |
| `verilator` | Verilator 5.052 | `source env/setup.sh` | `make cov`, `make cov-code` | `waves.fst` |
| `questa` | Questa 2025.1 | `source env/setup.sh questa` | — | `waves.vcd`, `make gui SIM=questa` |
| `xcelium` | Xcelium 25.09 | `source env/setup.sh xcelium` | — | `waves.vcd` |

## All simulators

- UVM is compiled from `third_party/uvm-1.2` with `+define+UVM_NO_DPI`. Only `+UVM_TESTNAME` is read by UVM; parse other plusargs yourself.
- Seeds: `make run SEED=<n>`. Each simulator turns a seed into different random values, so a failing seed on one simulator does not reproduce on another.
- A run passes with exit status 0, the PASS banner, and 0 UVM errors and fatals. `make run` and `make regress` use the same rule.
- `make waves TEST=<t> SEED=<s>` reruns one test with waves on and prints the file. Open it with `gtkwave` in a CAE desktop host terminal.
- VCS, Questa, and Xcelium are 4-state: an undriven or uninitialized signal is X, which Verilator shows as 0. A test that passes on Verilator and fails on a 4-state simulator usually has an X problem.

## VCS

- Load it with `module load synopsys/suite` on the CAE host. VCS runs inside the Synopsys container: run `make` at the `synopsys>` prompt, or on the host, where the Makefile adds `synopsys-run` to each VCS command.
- The Makefile builds with `-full64`. Without it, VCS runs 32-bit and fails to find `libelf.so.1`.
- Each run writes its coverage to `cov.vdb` in its run directory. `make cov` and `make cov-code` merge the last regression's databases with URG and print a summary; URG's full text report is in the `regress/urg/` directory they name.
- `simv` exits with status 0 even after `$fatal`. That is why a run also needs the PASS banner and a clean UVM error count.

## Verilator

- Set it up with `source env/setup.sh` on the CAE host, not at the `synopsys>` prompt. The first run builds a conda environment in your home directory (about 1.5 GB).
- Seeds: `make run SEED=<n>` passes `+verilator+seed+<n>`.
- Waves: `make waves TEST=<t> SEED=<s>` writes `waves.fst`.
- Coverage: `make cov` after `make regress`. `get_coverage()` returns 0 during simulation. `CODECOV=1` collects line and toggle coverage.

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


## Questa and Xcelium

These are optional. On CAE Linux:

- Load them through `source env/setup.sh questa` (or `xcelium`, or both). Use `cadence/xcelium/2509`: the default `cadence/xcelium` (2603) is newer than the campus license and fails at simulation with `NOLICN`.
- They run inside the CAE containers (`mentor-run`, `cadence-run`); the Makefile adds the wrapper.
- `make gui SIM=questa` opens Questa with every top-level signal in the wave window.
- `make cov` and `make cov-code` support VCS and Verilator.
- Loading `mentor/suite/2026` puts a Calibre `python3` first on `PATH` that cannot run scripts. `env/setup.sh` puts the course's Python back in front; if you load modules by hand, load them before `source env/setup.sh`.
