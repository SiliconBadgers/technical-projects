# Lab 3: Tests and coverage (days 7–9)

**Goal:** implement every row of your test plan as stimulus, checking and coverage.

**Inputs:** your reviewed test plan and your Lab 1 environment.

## Deliverables

- Checks at every edge for `in_ready`, `out_valid`, `count`, `almost_full` and `almost_empty`, not only for the data.
- Tests for every test-plan row, at least: full and empty corners, a push and a pop at the same edge at every fill level, backpressure, flush, reset during traffic, and a random test.
- Covergroups that show those scenarios happened.
- `tb/regress.list` with all tests.
- The test plan with the Link and Status columns filled in.

```bash
make regress SEEDS=5
make cov
make regress DEPTH=8 SEEDS=2      # another depth: your bench must take DEPTH from FIFO_DEPTH
```

## Exit criteria

- [ ] Every test-plan row is Passing, or Waived with a reason.
- [ ] `make regress SEEDS=5` passes on the golden design, at the default `DEPTH` and at `DEPTH=8`.
- [ ] Functional coverage meets the agreed target.
- [ ] Your smoke test still fails with `DUT=sanity`.
- [ ] No test can hang.
