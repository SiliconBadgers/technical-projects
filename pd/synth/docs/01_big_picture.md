# 01 — The big picture

This course is about the middle of chip design: turning code into gates, and checking that the gates are right and fast enough.

## From code to gates

You describe hardware as [RTL](02_glossary.md#rtl): Verilog or SystemVerilog that says what happens on each clock edge.
A chip cannot run code. It is built from [standard cells](02_glossary.md#cell): small, pre-designed gates such as inverters, NAND gates and flip-flops.
[Synthesis](02_glossary.md#synthesis) turns your RTL into a [netlist](02_glossary.md#netlist): a list of those cells and the wires between them.

Analogy: the RTL is a recipe. The [standard-cell library](02_glossary.md#standard-cell-library) is the pantry.
Synthesis is the cook who makes the dish using only what is in the pantry.

## The steps

```
RTL ──► lint ──► simulation ──► synthesis ──► netlist
                                   ▲             │
                    constraints ───┘             ├──► timing analysis      (fast enough?)
                    (SDC)                        ├──► equivalence check    (same logic as the RTL?)
                                                 ├──► gate-level simulation (testbench still passes?)
                                                 └──► QoR                  (how big, how fast?)
```

| Step | Question it answers | Read |
|---|---|---|
| [Lint](02_glossary.md#lint) | Is the RTL written so that hardware tools read it the way you meant? | [04](04_synthesis.md) |
| Simulation | Does the RTL do what the spec says? | — |
| Synthesis | Which cells implement this RTL? | [04](04_synthesis.md) |
| Constraints ([SDC](02_glossary.md#sdc)) | How fast must it run, and what is connected around it? | [05](05_sdc.md) |
| [Static timing analysis](02_glossary.md#static-timing-analysis-sta) | Is every path fast enough, at every [corner](02_glossary.md#corner-pvt)? | [06](06_timing_reports.md) |
| [Equivalence checking](02_glossary.md#equivalence-checking-lec) | Does the netlist do exactly what the RTL does? | [07](07_equivalence.md) |
| [Gate-level simulation](02_glossary.md#gate-level-simulation-gls) | Does the testbench still pass on the netlist? | [08](08_gate_level_sim.md) |
| [QoR](02_glossary.md#qor) | How much area, speed and leakage did we get? | [06](06_timing_reports.md) |

## Why timing matters

A synchronous design moves data from [flip-flop](02_glossary.md#flip-flop) to flip-flop, one step per clock tick.
Between two flip-flops the data runs through a chain of gates. Each gate takes a little time.

Analogy: a relay race. On each clock tick a flip-flop hands the baton to the next runner (the logic).
The runner must reach the next flip-flop before the next tick ([setup](02_glossary.md#setup)).
The runner must also not arrive so early that it bumps into the previous baton handoff ([hold](02_glossary.md#hold)).

The slowest path sets the fastest clock you can use. That path is the [critical path](02_glossary.md#critical-path).

## What happens after synthesis

The netlist goes to [physical design](02_glossary.md#physical-design-pd): placing the cells, building the clock tree and routing the wires.
That is a separate course. [09](09_synthesis_vs_pd.md) explains which problems belong to synthesis and which to physical design.

## Tools

Every step above is done by a tool: your synthesis tool, your timing tool, your simulator, and so on.
Which tools you use depends on your track. The ideas in these docs are the same for every track.
The commands are in your track's folder: [tracks/README.md](../tracks/README.md).

Next: [02 — Glossary](02_glossary.md)
