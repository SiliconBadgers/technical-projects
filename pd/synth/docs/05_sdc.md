# 05 — Writing constraints (SDC)

An [SDC](02_glossary.md#sdc) file tells synthesis and timing analysis about the world around your block:
the clock, when inputs arrive, when outputs are needed, what drives the inputs and what the outputs drive.

Analogy: a delivery contract. It says when the parcel leaves the warehouse, when the customer must have it, and how heavy it is.
Without the contract, nobody can say whether the courier is late.

The timing tool checks only what the SDC asks for. A path the SDC does not describe is not checked at all.

- SDC is Tcl: `set`, `expr` and loops work.
- Units come from the library (see [03](03_liberty.md#the-header)): usually ns and pF.
- The SDC commands below are standard; every track's tools read them. Your track's pages say where the file goes.

## A whole example

```tcl
set clk_period 10.0                                   ;# ns (100 MHz)

# clock
create_clock -name core_clock -period $clk_period [get_ports clk]

# input and output delays: 30 % of the period (team convention)
set_input_delay  [expr {0.3 * $clk_period}] -clock core_clock [get_ports {a b start}]
set_output_delay [expr {0.3 * $clk_period}] -clock core_clock [get_ports {y done}]

# drive and load
set_driving_cell -lib_cell <the library's buf_2> -pin <its output pin> [get_ports {a b start}]
set_load 0.02 [get_ports {y done}]                    ;# pF; write where the number comes from

# margin
set_clock_uncertainty -setup [expr {0.10 * $clk_period}] [get_clocks core_clock]
set_clock_uncertainty -hold  0.05                     [get_clocks core_clock]
```

Write the period once, in a variable, and compute everything else from it. Then changing the clock is a one-line edit.

## Clocks

`create_clock` names a clock, gives its [period](02_glossary.md#clock-period) and says which port it enters on.

- `-period` is in ns. Convert a frequency first: period (ns) = 1000 / frequency (MHz). 250 MHz → 4 ns.
- Before layout the clock is [ideal](02_glossary.md#ideal-clock): it reaches every flip-flop at once.
- [Clock uncertainty](02_glossary.md#clock-uncertainty) is a safety margin for jitter and for the skew the clock tree will add later. Team convention: setup 10 % of the period; hold a fixed 0.05 ns (hold does not depend on the period).

## Input and output delays

Your block is one piece of a bigger chip. The logic outside it uses part of each clock period.

- `set_input_delay 3 -clock core_clock [get_ports a]`: input `a` arrives 3 ns after the clock edge. Your logic gets the rest of the period.
- `set_output_delay 3 -clock core_clock [get_ports y]`: output `y` must be ready 3 ns before the next clock edge.
- Team convention: 30 % of the period for both, on every input except the clock (and reset, see below) and every output.
- Do not apply an input delay to the clock port itself.

## Drive and load

- `set_driving_cell`: the input is driven by this library cell (team convention: the library's `buf_2`). This sets the input [slew](02_glossary.md#slew-transition).
- `set_load`: the output drives this much [capacitance](02_glossary.md#capacitance) (team convention: 4 × the input pin capacitance of the library's `buf_4`). Look the value up in the Liberty file and write it in a comment.
- `set_max_fanout 16 [current_design]` asks the timing tool to report nets with more than 16 loads. Without it, [fanout](02_glossary.md#fanout) is not checked.

## Unconstrained

An [endpoint](02_glossary.md#endpoint) (flip-flop data pin, output port) is **unconstrained** if no clock requirement reaches it.
Example: an output port without `set_output_delay`, or an input that feeds logic but has no `set_input_delay`.

- The timing tool never reports a violation on an unconstrained path. It looks clean, but nothing was checked.
- The team's checks fail on any unconstrained endpoint.
- Your timing tool can list them ([track/reading_logs.md](../track/reading_logs.md)). Fix the SDC, not the design.

## Asynchronous reset

An [asynchronous reset](02_glossary.md#asynchronous-reset) acts without waiting for the clock.
Asserting it at any time is fine. Releasing it right next to a clock edge is not: some flip-flops leave reset one cycle earlier than others.

- Release is checked by [recovery and removal](02_glossary.md#recovery-and-removal), not by setup and hold.
- The safe design is a [reset synchronizer](02_glossary.md#reset-synchronizer): reset asserts at once, but releases on a clock edge. The team's checks fail if flip-flops hang directly on an asynchronous reset port instead of on a synchronizer.
- Things to decide, each with a comment in the SDC:
  - Is the reset input constrained (an input delay), or not, and why?
  - How is its huge fanout treated before physical design builds a reset buffer tree?
  - `set_false_path -from [get_ports rst_n]` removes the reset input from timing. Use it only with a comment saying why it is safe.

## Exceptions

A [timing exception](02_glossary.md#timing-exception) changes the default rule "every path gets one clock cycle".
Every exception needs a comment saying why it is safe. A wrong exception hides a real failure.

- `set_false_path -from A -to B`: no timing check at all on paths from A to B. See [false path](02_glossary.md#false-path).
- `set_multicycle_path -setup N -from A -to B`: the path gets N cycles instead of one. See [multicycle path](02_glossary.md#multicycle-path).
  This also moves the hold check. Look at hold at `ff` after adding one.

## Checking your SDC

1. Run timing analysis.
2. Read the timing tool's constraint check first: missing clocks, unconstrained endpoints, loops.
3. Fix the SDC until that list is empty, then read the timing paths ([06](06_timing_reports.md)).

Commands for your track: [track/reading_logs.md](../track/reading_logs.md).

Next: [06 — Reading timing reports](06_timing_reports.md)
