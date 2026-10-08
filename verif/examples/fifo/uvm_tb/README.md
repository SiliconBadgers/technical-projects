# `socetlib_fifo` UVM testbench

- DUT: `../rtl/socetlib_fifo.sv`
- Test plan: `../fifo-test-plan.md`

## Run

```bash
micromamba activate sb-uvm
cd examples/fifo/uvm_tb
make run TEST=fifo_smoke_test CONFIG=C1 SEED=1
make regress SEEDS=20
make mutants
```

## Files

| File | Description |
|---|---|
| `tb/tb_top.sv` | Clock, interface, DUT, `run_test()` |
| `tb/fifo_if.sv` | Port interface with clocking blocks |
| `tb/fifo_sva.sv` | Assertions SVA01–SVA10 |
| `tb/fifo_item.svh` | One cycle of inputs |
| `tb/fifo_obs.svh` | One observation of the ports |
| `tb/fifo_driver.svh` | Drives inputs and resets |
| `tb/fifo_monitor.svh` | Samples every edge |
| `tb/fifo_predictor.svh` | Reference model |
| `tb/fifo_scoreboard.svh` | Compares every cycle |
| `tb/fifo_coverage.svh` | Covergroups |
| `tb/fifo_seqs.svh` | Sequences |
| `tb/fifo_tests.svh` | Tests |
| `scripts/regress.py` | Regression and mutant check |
| `mutants/M*.sed` | Planted RTL bugs |

## Results

`results/regress.txt`: 7 tests × 20 seeds × 5 configurations, all passing.

| Config | Runs passed | Functional coverage | Code coverage |
|---|---|---|---|
| C1 | 140/140 | 58/58 | 100% |
| C2 | 140/140 | 58/58 | 100% |
| C3 | 140/140 | 50/50 | 100% |
| C4 | 140/140 | 58/58 | 100% |
| C5 | 140/140 | 48/48 | 100% |

At `DEPTH` = 1 (C5), points that need a FIFO neither empty nor full do not apply.

`results/mutants.txt`: all 8 caught.

| Mutant | Requirement | Caught by |
|---|---|---|
| M1 | R08 | 2/7 tests |
| M2 | R11 | 4/7 |
| M3 | R12 | 4/7 |
| M4 | R05 | 7/7 |
| M5 | R09 | 2/7 |
| M6 | R16 | 7/7 |
| M7 | R13 | 2/7 |
| M8 | R15 | 6/7 |
