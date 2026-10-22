# Lab 1: Testbench infrastructure (weeks 1–2)

**Goal:** a UVM environment that can drive and observe every channel, predict every result, and fail when the DUT is wrong.

**Inputs:** `docs/spec/`, the skeleton in `tb/`, `../../docs/simulators.md`.

## Deliverables

1. A testbench architecture diagram, reviewed by a mentor before you write code.
2. In `tb/`:
   - SystemVerilog interfaces, with assertions for the handshake rules in `interface.md`
   - an agent for each channel
   - a reference model written from the spec
   - a scoreboard
   - an environment and a base test
   - a smoke test
3. Your smoke test passes on the golden design and fails on the sanity design:

```bash
make run TEST=<your_smoke_test>
make run TEST=<your_smoke_test> DUT=sanity
```

## Hints

- When a check fails, find the first edge where the waveform disagrees with the spec: [Debug in the waveform](../../../../README.md#debug-in-the-waveform).
- Keep the logs of the golden and the sanity run. The sanity run should fail with a `uvm_error` from your scoreboard or an assertion that names the broken requirement, not with a compile error or a timeout.

## Exit criteria

- [ ] Architecture diagram reviewed.
- [ ] Smoke test passes with `DUT=golden` and fails with `DUT=sanity`.
- [ ] `tb/regress.list` lists your smoke test, and `make regress` passes.
