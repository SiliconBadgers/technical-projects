# 07 — Equivalence checking

[Equivalence checking](02_glossary.md#equivalence-checking-lec) (LEC) proves that the netlist does the same as the RTL, for **every** input sequence.
Simulation tries the inputs a testbench happens to give. LEC covers all of them, with math instead of test cases.

Analogy: checking a translation of a book. Simulation reads a few chapters in both languages and compares.
LEC proves, sentence by sentence, that the two books say the same thing.

## What it proves, and what it does not

- It proves: synthesis did not change the logic. No optimization or mapping step broke anything.
- It does not prove the RTL is right. If the RTL has a bug, the netlist has the same bug, and LEC passes.
- It compares against the RTL **as the synthesis tool reads it**. If simulation reads the RTL differently ([mismatch](02_glossary.md#mismatch-simulation-vs-synthesis)), LEC cannot see it. That is a job for [gate-level simulation](08_gate_level_sim.md).

## How it works

1. Read the RTL (the reference, often called "gold") and the netlist (the implementation, often called "gate" or "revised").
2. Match [key points](02_glossary.md#key-point) by name: ports, register outputs, black-box pins.
3. Cut both designs at the matched points into small pieces of combinational logic.
4. Prove each pair of pieces equal. Easy pieces are proven quickly; hard ones get a stronger, slower method.

Matching is the fragile part:

- Optimizations that rename or move registers ([retiming](02_glossary.md#retiming), re-encoding a state machine) break the name match. LEC then has to work much harder, or fails to finish.
- Big pieces (a multiplier merged with the logic around it) are slow to prove. Keeping such a block as its own module gives LEC a cut point at its ports.

## Reading the result

- Only the final verdict counts: pass, fail, or inconclusive.
- Messages such as "could not prove with method X: timeout" along the way are normal. A later, stronger method may finish the job.
- A run that is still busy after a long time usually has one huge piece. Find the biggest one and tell a mentor which it is.

## Reading a failure

A failing point is named after a key point (a register or an output) in the design. Start there.

- **Real difference**: the tool gives a counterexample, a set of input values (and maybe a few clock cycles) where the RTL and the netlist give different outputs.
  Apply those values in simulation to both and compare.
- **Inconclusive**: no difference was found, but the proof did not close. Check whether a stronger method ran, and whether the piece is just too big.

Where your track's tool writes these details: its `track/reading_logs.md`.

Next: [08 — Gate-level simulation](08_gate_level_sim.md)
