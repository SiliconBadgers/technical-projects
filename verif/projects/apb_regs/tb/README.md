# `tb/`: your testbench

Everything you build goes in this directory.

## Rules (the Makefile and mentor CI depend on them)

1. The top module is `tb_top`, the file list is `tb/tb.f`, and the regression list is `tb/regress.list`.
2. Every test is registered with `` `uvm_component_utils ``. Tests are selected with `+UVM_TESTNAME`.
3. Every test prints `*** TEST PASSED ***` only when there are 0 `UVM_ERROR` and 0 `UVM_FATAL` (see `apb_hello_test`).
4. Checks fail with `uvm_error`.
5. No test can hang: set a timeout.

## Run

```bash
make run TEST=apb_hello_test
make regress SEEDS=3
make cov
```
