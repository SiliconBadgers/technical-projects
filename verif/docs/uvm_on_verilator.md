# UVM on Verilator

The course uses Accellera UVM 1.2 (`third_party/uvm-1.2`) on Verilator 5.052 with the z3 constraint solver.

## Basics

- UVM is compiled with `+define+UVM_NO_DPI`. Only `+UVM_TESTNAME` is read by UVM; parse other plusargs yourself.
- Seeds: `make run SEED=<n>` (passes `+verilator+seed+<n>`).
- Verilator is 2-state: there is no X or Z.
- Waves: `make waves TEST=<t> SEED=<s>` writes `waves.fst`.
- Coverage: `make cov` after `make regress`. `get_coverage()` returns 0 during simulation.

## Known issues

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
