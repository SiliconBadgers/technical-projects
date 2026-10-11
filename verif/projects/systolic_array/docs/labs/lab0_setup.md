# Lab 0: Setup (week 0)

**Goal:** a working toolchain and a first read of the design documents.

## Steps

1. From the repository root, run `source env/setup.sh` (the first run builds the Verilator environment). Then `cd projects/systolic_array`.
2. Run `make run TEST=sa_hello_test`. It must print `*** TEST PASSED ***`.
3. Read `docs/spec/`: the block diagram, `interface.md`, the spec and `cycle_tables.md`.
4. Read `../../docs/simulators.md`.

Do not read `rtl/`. Verify the design against the spec.

## Exercise

1. Pick a weight matrix and an activation vector. Compute `y`, and write the `wr_data`, `a_data` and `r_data` values in hex.
2. An activation transfers at edge 100 and `r_ready` is always 1. When can its result transfer? When can the next write transfer?
3. Write one question about the spec that you could not answer from the documents.

## Exit criteria

- [ ] The hello test passes.
- [ ] A mentor has reviewed the exercise.
