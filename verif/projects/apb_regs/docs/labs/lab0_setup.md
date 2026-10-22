# Lab 0: Setup (day 1)

**Goal:** a working toolchain and a first read of the design documents.

## Steps

1. Follow the [verification setup](../../../../../intro/SETUP.md#verification-track). Then, from `verif/`, run `module load synopsys/suite` and `cd projects/apb_regs`.
2. Run `make run TEST=apb_hello_test`. It must print `*** TEST PASSED ***`.
3. Read `docs/spec/`: `interface.md` (with the example waveform) and the spec.
4. Re-read `../../docs/simulators.md`, in particular the Verilator issues Q1–Q7.

Do not read `rtl/`. Verify the design against the spec.

## Exercise

1. `TIMER_LOAD` = 3 was written earlier. A write of `CTRL` = `0x1` completes at edge 50. At which edge does the timer expire? What do `CTRL`, `TIMER_VALUE` and `INT_STATUS` read afterwards? Repeat with `CTRL` = `0x3` and list the first three expiry edges.
2. Draw a cycle table (like the one in `interface.md`) for, back to back: a write of `0x0000_FF00` to `SCRATCH` with `pstrb` = `0b0010`, a read of `TIMER_VALUE`, and a write to `ID`. Give `prdata`, `pready` and `pslverr` at every edge, and `SCRATCH` and `INT_STATUS` at the end.
3. Write one question about the spec that you could not answer from the documents.

## Exit criteria

- [ ] The hello test passes.
- [ ] A mentor has reviewed the exercise.
