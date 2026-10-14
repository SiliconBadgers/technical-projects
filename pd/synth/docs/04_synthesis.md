# 04 — Synthesis and its common problems

[Synthesis](02_glossary.md#synthesis) turns [RTL](02_glossary.md#rtl) into a [netlist](02_glossary.md#netlist) of library cells.
It works like a compiler: it reads your code, builds generic logic, simplifies it, then maps it onto real cells.

## What synthesis does

1. **Read and elaborate**: parse the RTL, fill in parameters, connect the module hierarchy.
2. **Build generic logic**: registers become flip-flops; `always` blocks and `assign`s become gates and multiplexers; arrays may become flip-flops too.
3. **Optimize**: remove logic that does nothing, share common terms, pick adder and comparator structures.
4. **[Technology mapping](02_glossary.md#technology-mapping)**: replace the generic gates with cells from the [Liberty](02_glossary.md#liberty) file, sized to meet the clock period in the [SDC](02_glossary.md#sdc).
5. **Write** the netlist and an area report (cells and area per cell type).

Synthesis can only build what the RTL describes. If the RTL describes a [latch](02_glossary.md#latch) or a short circuit, synthesis builds it faithfully.
The sections below are the problems to look for in the logs, roughly in the order you meet them.
Your track explains the exact log messages in its `track/reading_logs.md` ([tracks/README.md](../tracks/README.md)).

## Lint

[Lint](02_glossary.md#lint) reads the RTL before synthesis and warns about code that is legal but risky.
A lint warning fails the lint step. Fix the code, or [waive](02_glossary.md#waiver) a harmless warning with a comment saying why.

| Warning is about | Meaning |
|---|---|
| a latch | a combinational block does not assign a signal on every path |
| multiple drivers | two `always` blocks drive the same signal |
| width | an expression is cut short or padded to fit |
| a combinational loop | a signal depends on itself without a flip-flop (lint sometimes reports loops that are not real) |
| an incomplete case | a `case` without `default` in combinational logic |
| a hand-written sensitivity list | team rule: combinational blocks use `always_comb` or `always @*`, never a hand-written [sensitivity list](02_glossary.md#sensitivity-list) |

The last row is a team rule. A missing signal in a hand-written list makes simulation disagree with the hardware, and most lint tools do not warn about it.

## Latches

A latch appears when a combinational block does not assign a signal on every path through it.
The hardware must then "remember" the old value, and the only way to remember without a clock edge is a latch.

Analogy: a form with a box you forgot to fill in. The clerk keeps whatever was written there last time.

- Latches are hard to time, and the team's checks fail if the netlist has any.
- The synthesis log lists the latches it made. The team's checks also scan the netlist for latch cells.
- A missed assignment in `always_comb` does not always give a latch or a warning.

## Combinational loops

A [combinational loop](02_glossary.md#combinational-loop) is a gate whose output feeds back into its own input with no flip-flop in between.

Analogy: a microphone held next to its own speaker.

- The value may oscillate or depend on gate delays.
- The timing tool cannot time a loop. It cuts it somewhere, and the paths through the cut go unchecked.
- The synthesis check (below) reports it. Lint may also report it, but lint sometimes flags loops that are not real (for example, two different bits of one bus).

## Multiple drivers

[Multiple drivers](02_glossary.md#multiple-drivers): one net driven from two places, for example two `always` blocks assigning the same signal.

Analogy: two people talking into the same phone line at once.

- In silicon, one driver pulls high while the other pulls low: a short circuit.
- Simulation may hide it (the last assignment wins). Lint and the synthesis check report it.

## Black boxes

A [black box](02_glossary.md#black-box) is a module synthesis knows only by its ports.

- On purpose: a [macro](02_glossary.md#macro) such as Lab 2's SRAM (`labs/lab2_systolic/macros/sb_sram_256x8.v`). Its timing comes from the macro's own Liberty model.
- By mistake: a module whose file was not read. It becomes an empty box with no logic.
- A black box with no timing model is dangerous: the timing tool cannot time paths into or out of it, and may not list them as [unconstrained](05_sdc.md#unconstrained).

## Check

After synthesis, the flow runs a structural check on the netlist. Any problem stops the run.

| Problem | Meaning |
|---|---|
| multiple conflicting drivers | one net driven from two places |
| logic loop | a combinational loop |
| used but not driven | a missing connection: the wire floats |

## Other things in the synthesis log

- Memories turned into flip-flops: a big array in RTL can become thousands of flip-flops.
- The technology-mapping step and how long it took.
- The area report: number of cells and area per cell type. Lab 1 uses it to find the most used cells.

Next: [05 — Writing constraints (SDC)](05_sdc.md)
