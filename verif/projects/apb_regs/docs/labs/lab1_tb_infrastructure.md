# Lab 1: Testbench and smoke test (days 2–4)

**Goal:** a UVM environment that can drive any APB transfer, predict every response and the `irq` output from the spec, and fail when the DUT is wrong.

**Inputs:** `docs/spec/`, the skeleton in `tb/`, `../../docs/simulators.md`.

## Deliverables

1. A testbench architecture diagram, reviewed by a mentor before you write code.
2. In `tb/`:
   - an APB interface, with assertions for the APB4 rules in `interface.md` (both the host and the DUT side)
   - an APB agent: a driver that runs the setup and access phases and waits for `pready`, and a monitor that reports each completed transfer with its wait states
   - a reference model of the registers, the timer and `irq`, written from the spec
   - a scoreboard that checks `prdata`, `pslverr`, the wait states and `irq`
   - an environment and a base test
   - a smoke test
3. Your smoke test passes on the golden design and fails on the sanity design:

```bash
make run TEST=<your_smoke_test>
make run TEST=<your_smoke_test> DUT=sanity
```

## Hints

- The timer and `irq` are exact to the edge. Your model needs to know the edge at which each transfer completed, and it has to advance the timer on edges with no transfer too.
- The driver must not assume a fixed transfer length: some reads have a wait state.
- Drive at the falling edge and sample with a clocking block (Verilator issue Q7).
- When a check fails, find the first edge where the waveform disagrees with the spec: [Debug in the waveform](../../../../README.md#debug-in-the-waveform).
- Keep the logs of the golden and the sanity run. The sanity run should fail with a `uvm_error` from your scoreboard or an assertion that names the broken requirement, not with a compile error or a timeout.

## Exit criteria

- [ ] Architecture diagram reviewed.
- [ ] Smoke test passes with `DUT=golden` and fails with `DUT=sanity`.
- [ ] `tb/regress.list` lists your smoke test, and `make regress` passes.
