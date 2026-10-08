# Lab 3: Tests, register model and coverage (days 6–9)

**Goal:** implement every row of your test plan as stimulus, checking and coverage, using a UVM register model for register access.

**Inputs:** your reviewed test plan and your Lab 1 environment.

## Deliverables

- A register model of spec Section 6: a `uvm_reg_block` with one `uvm_reg` per register, an adapter for your APB item, and a `uvm_reg_predictor` connected to your monitor. Sequences access registers through it (`write()`, `read()`, `mirror()`).
- Sequences and tests for every test-plan row; `tb/regress.list` with all tests.
- Functional coverage: every register × read/write, byte strobes, error responses, wait states, both timer modes, and `INT_STATUS` × `INT_ENABLE`.
- The test plan with the Link and Status columns filled in.

```bash
make regress SEEDS=5
make cov
```

## Hints

- UVM is compiled with `UVM_NO_DPI`: there is no backdoor access. Use the frontdoor only.
- Mark fields that the hardware changes as volatile, or the mirror will disagree with the DUT.
- The predictor applies `pstrb` per field: a field is updated only if the byte lane of its lowest bit is enabled. Decide what that means for 32-bit registers written with partial strobes.
- Look up `uvm_reg_map::set_check_on_read()` and `uvm_reg_hw_reset_seq`.
- Some corner cases need a write to complete at an exact edge. Count edges from the spec's timer table.

## Exit criteria

- [ ] Every test-plan row is Passing, or Waived with a reason.
- [ ] `make regress SEEDS=5` passes on the golden design.
- [ ] Functional coverage meets the agreed target.
- [ ] Your smoke test still fails with `DUT=sanity`.
- [ ] No test can hang.
