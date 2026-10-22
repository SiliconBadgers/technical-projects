# 06 — Reading timing reports

[Static timing analysis](02_glossary.md#static-timing-analysis-sta) (STA) does not simulate.
It adds up the delays along every path from a [start point](02_glossary.md#start-point) (input port, flip-flop clock pin)
to an [endpoint](02_glossary.md#endpoint) (output port, flip-flop data pin), and compares the sum with the [SDC](05_sdc.md).

Analogy: checking a train timetable. You do not ride every train; you add up the travel times on paper and see which connections are missed.

- Before layout there are no real wires ([wire delay](02_glossary.md#wire-delay) is not known) and the clock is [ideal](02_glossary.md#ideal-clock).
- Each [corner](02_glossary.md#corner-pvt) is a separate run with its own Liberty file.

| Corner | Checked for |
|---|---|
| `ss` | setup |
| `ff` | hold |
| `tt` | comparison only |

The layout of the report differs between timing tools. The parts below are in every one.
Your track shows a real report in its `track/reading_logs.md`.

## Setup

The [setup](02_glossary.md#setup) check: does data arrive before the next clock edge? One path report has three parts.

- **Data arrival time**: the launch clock edge, the [clock-to-Q](02_glossary.md#clock-to-q) of the first flip-flop, then each gate on the way.
  One line per gate: the delay of that stage and the running total. A rising or falling edge is marked on each line.
- **Data required time**: the next clock edge, minus [clock uncertainty](02_glossary.md#clock-uncertainty), minus the capturing flip-flop's setup time.
- **[Slack](02_glossary.md#slack)** = required − arrival. Negative means the data is too late: the path is violated.

Analogy: slack is how many minutes early you reach the platform. Negative slack: you missed the train.

- [WNS](02_glossary.md#wns): the worst slack of all paths. [TNS](02_glossary.md#tns): the sum of all negative slacks.
- The worst path is the [critical path](02_glossary.md#critical-path).
- Instance names in the path (such as `_271_`) are made up by synthesis. Net names keep their RTL names, so follow the nets to find the RTL.
- If synthesis keeps the module hierarchy (does not flatten), module names appear in the path too.

## Hold

The [hold](02_glossary.md#hold) check: does new data stay away long enough after the clock edge for the flip-flop to capture the old data?

- Checked at `ff`, where cells are fastest. The report uses the shortest paths (min delay), not the longest.
- Slack = arrival − required. Negative means the data is too early.
- The clock period does not appear in a hold check. A slower clock does not fix a hold violation.

## Recovery and removal

The setup-like and hold-like checks on [asynchronous reset](02_glossary.md#asynchronous-reset) pins: is reset released far enough from a clock edge?
See [05 — Asynchronous reset](05_sdc.md#asynchronous-reset).

## Design-rule violations

The library sets limits on [slew](02_glossary.md#slew-transition), [capacitance](02_glossary.md#capacitance) and (if the SDC sets one) [fanout](02_glossary.md#fanout).
The timing tool can list the nets over these limits.

- These are reported, not a failure of the team's checks.
- Fanout is only checked if the SDC sets `set_max_fanout`.
- Physical design fixes most of them later ([09](09_synthesis_vs_pd.md)).

## QoR

[QoR](02_glossary.md#qor) (quality of results) is the set of numbers that sums up one run. Your track collects them into one table per run.

| Number | Meaning |
|---|---|
| clock period | the period the run was constrained to (ns) |
| WNS, TNS | worst and total negative setup slack (ns) |
| hold WNS | worst hold slack (ns) |
| area | sum of cell areas in µm² (no wires) |
| cell count, sequential cells | all cells; flip-flops and latches |
| leakage | leakage power (W) |
| runtime | wall time of synthesis and of timing analysis |
| commit | which version of the repo produced the numbers |

A **sweep** runs the same design at several clock periods and records the QoR of each. It shows the shortest period that passes, and how area changes with the period.

Next: [07 — Equivalence checking](07_equivalence.md)
