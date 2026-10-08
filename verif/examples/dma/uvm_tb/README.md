# `dma_controller` UVM testbench

- DUT: `../rtl/source/dma_controller.sv`
- Test plan: `../dma-test-plan.md`

## Run

```bash
micromamba activate sb-uvm
cd examples/dma/uvm_tb
make run TEST=dma_smoke_test CONFIG=C1 SEED=1
make regress SEEDS=5 RAND_SEEDS=50
make mutants
```

## Files

| File | Description |
|---|---|
| `tb/tb_top.sv` | Clock, interfaces, DUT, assertions, `run_test()` |
| `tb/dma_ahb_if.sv` | Bench-side AHB and system interfaces |
| `tb/dma_sva.sv` | Assertions SVA01–SVA12 |
| `tb/dma_item.svh` | Transactions |
| `tb/dma_drivers.svh` | Register-port manager, memory responders, trigger/reset driver |
| `tb/dma_mem.svh` | Shared memory and responder settings |
| `tb/dma_monitors.svh` | Port monitors |
| `tb/dma_regs.svh` | Register model |
| `tb/dma_model.svh` | Reference-model building blocks |
| `tb/dma_scoreboard.svh` | Reference model and checks |
| `tb/dma_coverage.svh` | Covergroups |
| `tb/dma_seqs.svh` | Virtual sequences |
| `tb/dma_tests.svh` | Tests |
| `scripts/regress.py` | Regression, coverage and mutant check |
| `mutants/M*.sed` | Planted RTL bugs |

## Results

`results/regress.txt`: 1 060 runs over C1–C4, all passing.

| Config | Runs passed | Functional coverage | Code coverage (line · branch) |
|---|---|---|---|
| C1 | 265/265 | 267/267 | 84.8% · 92.4% |
| C2 | 265/265 | 220/220 | 84.0% · 91.2% |
| C3 | 265/265 | 315/315 | 84.8% · 92.4% |
| C4 | 265/265 | 267/267 | 84.8% · 92.0% |

Code coverage holes:

| Where | Why |
|---|---|
| `ahb_read_manager.sv` `RD_FIFO_PUSH`, `tdata_fifo_full` paths | Unreachable: reads wait for room |
| `ahb_write_manager.sv` `WR_FIFO_PULL`, `tdata_fifo_empty` paths | Unreachable: writes wait for data |
| `ahb_write_manager.sv` `WR_FIRST_ADDR` with `HREADY` = 0 | No data phase is pending in a first address phase |
| `ahb_subordinate.sv` `request_stall` paths | `request_stall` tied to 0 |
| `channel_manager.sv` `default` items | Unaligned offsets rejected earlier |
| Other `default` branches | Fully decoded |
| Function bodies | Not counted by Verilator |

`results/mutants.txt`: all 16 caught.

| Mutant | Requirement | Caught by |
|---|---|---|
| M1 | R12 | 6/17 tests |
| M2 | R07 | 15/17 |
| M3 | R13 | 3/17 |
| M4 | R05 | 3/17 |
| M5 | R02 | 2/17 |
| M6 | R15 | 4/17 |
| M7 | R20 | 1/17 |
| M8 | R09 | 6/17 |
| M9 | R10 | 10/17 |
| M10 | R13 | 3/17 |
| M11 | R11 | 6/17 |
| M12 | R04 | 1/17 |
| M13 | R19 | 6/17 |
| M14 | R03 | 8/17 |
| M15 | R08 | 11/17 |
| M16 | R10 | 9/17 |
