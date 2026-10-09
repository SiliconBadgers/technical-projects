# 08 — Gate-level simulation

## GLS

[Gate-level simulation](02_glossary.md#gate-level-simulation-gls) (GLS) runs the same [testbench](02_glossary.md#testbench) you used on the RTL, but on the synthesized netlist.
The simulator reads the netlist plus a simulation model of every library cell.

Analogy: a dress rehearsal. The script (testbench) is the same; now the real cast (the gates) plays it.

GLS can catch what the other checks miss:

- **Simulation/synthesis [mismatches](02_glossary.md#mismatch-simulation-vs-synthesis)**: RTL that simulates one way but is built another way. [Equivalence checking](07_equivalence.md) compares against the RTL as the synthesis tool reads it, so it cannot see these.
- **[X](02_glossary.md#x-unknown-value) propagation**: in RTL simulation an unknown value is often hidden; in gates it spreads, for example from a register that is never reset.
- **Reset problems**: a reset that does not reach every register that needs it, or is released in the wrong order.

## Limits

- The cell models are functional, without delays. GLS checks behaviour, not timing; [timing analysis](06_timing_reports.md) checks timing.
- It runs much slower than RTL simulation on big designs.

## When GLS fails but RTL simulation passes

1. Find the first cycle where the outputs differ, or where an X appears.
2. Trace that signal back through the netlist toward its source. Net names keep their RTL names.
3. Ask: does the RTL describe the same thing to the simulator and to the synthesis tool?

If the testbench seems to need a change to pass GLS, talk to a mentor first. The testbench is the reference.

How to run GLS on your track: [track/README.md](../track/README.md).

Next: [Lab 1 — Reference designs](../labs/lab1_reference/README.md)
