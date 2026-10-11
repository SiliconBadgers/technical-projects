# Lab 1: Testbench and smoke test (days 2–5)

**Goal:** a UVM environment that drives both sides of the FIFO, predicts every pop, and fails when the DUT is wrong.

**Inputs:** `docs/spec/`, the skeleton in `tb/`, `../../docs/simulators.md`.

## Deliverables

1. A testbench architecture diagram, reviewed by a mentor before you write code.
2. In `tb/`:
   - SystemVerilog interfaces, with assertions for the handshake rules in `interface.md`
   - a write agent: a driver that offers entries with random gaps and holds them until `in_ready` (P2), and a monitor that reports every push
   - a read agent: a driver that drives `out_ready` with random delays, and a monitor that reports every pop
   - a way to drive `rst_n` and `flush`
   - a reference model written from the spec (a queue is enough)
   - a scoreboard that compares every pop with the model
   - an environment and a base test
   - a smoke test
3. Your smoke test passes on the golden design and fails on the sanity design:

```bash
make run TEST=<your_smoke_test>
make run TEST=<your_smoke_test> DUT=sanity
```

## Hints

- Drive at the falling edge and sample with clocking blocks (`../../docs/simulators.md`, Q7).
- A push, a pop and a flush can happen at the same edge. Section 7 of the spec says what happens; your model must agree.
- A scoreboard that compares nothing passes every test. Fail the test if it compared nothing.

## Exit criteria

- [ ] Architecture diagram reviewed.
- [ ] Smoke test passes with `DUT=golden` and fails with `DUT=sanity`.
- [ ] `tb/regress.list` lists your smoke test, and `make regress` passes.
