# Lab 3: Sequences and tests (weeks 4–5)

**Goal:** implement every row of your test plan as stimulus, checking and coverage.

**Inputs:** your reviewed test plan and your Lab 1 environment.

## Deliverables

- Sequences, virtual sequences and tests for every test-plan row.
- `tb/regress.list` with all tests.
- The test plan with the Link and Status columns filled in.

```bash
make regress SEEDS=5
make cov
```

## Exit criteria

- [ ] Every test-plan row is Passing, or Waived with a reason.
- [ ] `make regress SEEDS=5` passes on the golden design.
- [ ] Functional coverage meets the agreed target.
- [ ] Your smoke test still fails with `DUT=sanity`.
- [ ] No test can hang.
