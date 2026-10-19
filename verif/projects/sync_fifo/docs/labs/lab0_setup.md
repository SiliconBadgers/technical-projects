# Lab 0: Setup (day 1)

**Goal:** a working toolchain and a first read of the design documents.

## Steps

1. Follow the [verification setup](../../../../../intro/SETUP.md#verification-track). Then, from `verif/`, run `module load synopsys/suite` and `cd projects/sync_fifo`.
2. Run `make run TEST=fifo_hello_test`. It must print `*** TEST PASSED ***`.
3. Read `docs/spec/`: the spec and `interface.md` with its examples.
4. Read `../../docs/simulators.md`.

Do not read `rtl/`. Verify the design against the spec.

## Exercise

Use the defaults (`DEPTH` = 6, `AF_LEVEL` = 5, `AE_LEVEL` = 1).

1. The FIFO is empty at edge 1. The producer holds `in_valid` at 1 from edge 1 to edge 10 with a new entry after every push. The consumer holds `out_ready` at 0 until edge 7 and at 1 from edge 8. At which edges do pushes and pops happen? Write `count`, `almost_full` and `almost_empty` for edges 1–12.
2. At edge 20, `count` is 3, `flush` is 1, and a push of `X` and a pop happen. Which entries does the consumer receive, and what is `count` at edge 21?
3. Write one question about the spec that you could not answer from the documents.

## Exit criteria

- [ ] The hello test passes.
- [ ] A mentor has reviewed the exercise.
