# 02 — Glossary

Words used in this course, in alphabetical order. Skim it once now; come back when a word is new.

## Area
The chip area the cells take, in µm². Before layout it is the sum of the cell areas; wires are not counted.

## Asynchronous reset
A reset that acts the moment it changes, without waiting for a clock edge. Releasing it safely needs a [reset synchronizer](#reset-synchronizer).

## Black box
A module that the tools know only by its ports, not its contents. A [macro](#macro) is used as a black box on purpose; a missing module becomes one by mistake.

## Capacitance
How much electric charge a pin or wire stores. More capacitance on a cell's output means more [load](#load), so the cell is slower. Usually in pF.

## Cell
One pre-designed gate in a [standard-cell library](#standard-cell-library): an inverter, a NAND gate, a flip-flop. Also called a standard cell.

## Clock period
The time between two rising clock edges, in ns. Period (ns) = 1000 / frequency (MHz).

## Clock skew
The clock reaching different flip-flops at slightly different times. It does not exist before the clock tree is built.

## Clock tree synthesis (CTS)
The physical-design step that builds a tree of buffers to deliver the clock to every flip-flop at nearly the same time.

## Clock uncertainty
A safety margin taken off the clock period in timing checks. It stands in for jitter and for skew that is not known yet.

## Clock-to-Q
The delay from the clock edge at a flip-flop to its new value appearing on the output Q.

## Combinational logic
Logic whose output depends only on its current inputs, with no memory: AND, OR, adders, multiplexers.

## Combinational loop
A path from a gate's output back to its own input with no flip-flop in between. It can oscillate and cannot be timed.

## Corner (PVT)
One combination of process, voltage and temperature at which cells are characterized. `ss` (slow) is used for [setup](#setup), `ff` (fast) for [hold](#hold), `tt` (typical) for comparison.

## Critical path
The path with the worst (smallest) [slack](#slack). It limits how fast the clock can be.

## Drive strength
How much current a cell can push. A bigger number in the name (`inv_4` vs. `inv_1`) means a stronger, bigger cell.

## Driving cell
The cell assumed to drive your block's inputs from outside. Set in the [SDC](#sdc).

## Endpoint
Where a timing path ends: a flip-flop's data pin or an output port.

## Equivalence checking (LEC)
A proof that two designs (usually RTL and netlist) give the same outputs for every input sequence. Also called logic equivalence checking.

## Extraction
Measuring the resistance and capacitance of the real wires after routing, so that timing analysis can include wire delay.

## False path
A path the timing tool is told to ignore, because it can never carry data that matters in time. A [timing exception](#timing-exception).

## Fanout
How many cell inputs one net drives. High fanout means high [load](#load) and a slow signal.

## Flip-flop
A cell that stores one bit and updates it on a clock edge. The basic building block of synchronous design.

## Gate-level simulation (GLS)
Running the testbench on the synthesized netlist instead of the RTL.

## Handshake
Two signals that move data only when both sides agree: `valid` (I have data) and `ready` (I can take it). A transfer happens when both are 1 at a clock edge.

## Hold
The check that new data does not reach a flip-flop too soon after a clock edge, while the flip-flop is still capturing the old data.

## Ideal clock
A clock that reaches every flip-flop at the same instant with no delay. Timing before layout assumes it.

## Input delay
How long after the clock edge an input arrives at your block, set in the SDC. It is the time used up outside your block.

## Interpolation
Estimating a value between table entries from the entries around it. Timing tools use bilinear interpolation on [NLDM](#nldm) tables.

## Key point
A point that equivalence checking matches between the two designs: a port, a register, or a black-box pin.

## Latch
A storage cell that is transparent while its enable is active. Usually created by mistake in RTL; hard to time.

## Leakage
Power a cell uses even when nothing switches. Reported per cell in the [Liberty](#liberty) file.

## LEF
A text file with physical shapes. The technology LEF describes the metal layers; the cell LEF describes each cell's outline and pins.

## Liberty
The `.lib` file format for a cell library's timing, power and function at one [corner](#corner-pvt).

## Lint
A check of the RTL for code that is legal but risky: widths that do not match, missing assignments, multiple drivers.

## Load
The [capacitance](#capacitance) a cell output has to drive: the pins and wires connected to it.

## Macro
A large pre-built block, such as an SRAM, used as one piece. It comes with its own timing model.

## Mismatch (simulation vs. synthesis)
RTL that simulates one way but synthesizes to logic that behaves another way.

## Multicycle path
A path that is allowed more than one clock cycle. A [timing exception](#timing-exception).

## Multiple drivers
One signal driven from two places. Real hardware would short-circuit.

## Netlist
The output of synthesis: a list of cell instances and the nets (wires) that connect them. Usually written as Verilog.

## NLDM
Non-Linear Delay Model: delay and [slew](#slew-transition) stored as 2-D tables over input slew and output load.

## Output delay
How much of the clock period the outside world needs after your output, set in the SDC. Your output must be ready that long before the next clock edge.

## Physical design (PD)
Turning the netlist into a layout: placement, clock tree, routing. Comes after synthesis.

## Pipeline register
A flip-flop added in the middle of a long path. It splits the path into shorter ones, at the cost of one more cycle of latency.

## QoR
Quality of results: the numbers that describe a run, such as slack, area, cell count and leakage.

## Quasi-static
A signal that changes only rarely, while the design is idle, and is stable long before it is used.

## Recovery and removal
The setup-like and hold-like checks on an [asynchronous reset](#asynchronous-reset) pin when the reset is released.

## Reset synchronizer
Two flip-flops that let a reset start at any time but end only on a clock edge.

## Retiming
Moving flip-flops across logic to balance path delays. It changes register names and positions.

## RTL
Register-transfer level: hardware described as registers and the logic between them, in Verilog or SystemVerilog.

## SDC
The constraint file format: clocks, input and output delays, drive, load and exceptions. Timing tools check only what the SDC asks for.

## Sensitivity list
The list of signals after `@` in an `always` block. In combinational logic, a hand-written list that misses a signal makes simulation wrong.

## Setup
The check that data reaches a flip-flop early enough before the next clock edge.

## Sign-off
The final check that a design meets its targets. Here: setup at `ss`, hold at `ff`, nothing unconstrained.

## Slack
Required time minus arrival time (for hold, the other way round). Positive: met. Negative: violated.

## Slew (transition)
How long a signal takes to rise or fall. A slow slew makes the next cell slower.

## Standard-cell library
The set of cells synthesis may use, all the same height so they line up in rows. Comes with [Liberty](#liberty) and [LEF](#lef) files.

## Start point
Where a timing path starts: an input port or a flip-flop's clock pin.

## Static timing analysis (STA)
Checking timing by adding up delays along every path, without simulating. It covers every path at once.

## Synthesis
Turning RTL into a [netlist](#netlist) of cells from a library, while trying to meet the constraints.

## Systolic array
A grid of identical processing elements that pass data to their neighbours each clock cycle. Lab 2's tile is one.

## Technology mapping
The synthesis step that replaces generic logic with real cells from the library.

## Testbench
Code that drives a design's inputs and checks its outputs in simulation.

## Timing arc
One input-to-output delay of a cell, for example A to Y of an inverter. The Liberty file has a table for each.

## Timing exception
An SDC command that changes the default one-cycle check: a [false path](#false-path) or a [multicycle path](#multicycle-path).

## TNS
Total negative slack: the sum of the negative slacks of all failing endpoints. Shows how much is failing, not just the worst case.

## Waiver
A note that tells the lint tool to accept one specific warning. Each one needs a comment saying why it is harmless.

## Wire delay
Delay caused by the resistance and capacitance of wires. Not known until physical design.

## WNS
Worst negative slack: the slack of the worst path. Negative means the design fails timing.

## X (unknown value)
A simulation value meaning "could be 0 or 1". It shows up from flip-flops that were never reset and from undriven nets.

Next: [Pick and set up your track](../track/README.md)
