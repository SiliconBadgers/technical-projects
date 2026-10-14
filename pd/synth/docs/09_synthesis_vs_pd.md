# 09 — What synthesis can fix, and what has to wait for physical design

Synthesis turns RTL into gates. [Physical design](02_glossary.md#physical-design-pd) (PD) turns gates into a layout: placement, [clock tree](02_glossary.md#clock-tree-synthesis-cts), routing, and repair.
Some problems belong to synthesis, some to PD, and some only to the RTL.

Analogy: synthesis decides which buildings a town needs and how big they are. PD places them and lays the roads.
Traffic jams caused by long roads only show up once the roads exist.

## Synthesis can fix

| Problem | What synthesis can do |
|---|---|
| A long chain of logic | restructure and size it harder when the clock period in the SDC is tighter |
| A slow adder or comparator | pick a different adder or comparator structure |
| A weak gate driving a moderate load | use a stronger cell or add a buffer while mapping |
| Registers in the wrong place in a pipeline | [retiming](02_glossary.md#retiming): move them (equivalence checking gets harder) |

Your track's knobs for these: its `track/README.md` ([tracks/README.md](../tracks/README.md)).

## Only the RTL can fix

- Too much logic between two registers for the target period. Add a [pipeline register](02_glossary.md#pipeline-register) or change the algorithm.
- A [latch](02_glossary.md#latch), a [multi-driven](02_glossary.md#multiple-drivers) net, a [combinational loop](02_glossary.md#combinational-loop).
- A reset released asynchronously to the clock.
- An overflow, a wrong width.

## Has to wait for physical design

| Problem | What PD does |
|---|---|
| [Wire delay](02_glossary.md#wire-delay) | [extraction](02_glossary.md#extraction) after routing measures it |
| [Clock skew](02_glossary.md#clock-skew) | clock tree synthesis balances it |
| High-[fanout](02_glossary.md#fanout) nets | buffer trees after placement |
| Max slew / max capacitance | sizing and buffering after placement |
| [Hold](02_glossary.md#hold) violations | delay cells, added after the clock tree is built |

Next: [Lab 2 — Accelerator tile](../labs/lab2_systolic/README.md)
