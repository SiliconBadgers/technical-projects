# Reading the logs (Track B1)

Where each Cadence tool writes its messages and reports, and where the problems from [04](../docs/04_synthesis.md), [05](../docs/05_sdc.md), [06](../docs/06_timing_reports.md), [07](../docs/07_equivalence.md) and [08](../docs/08_gate_level_sim.md) show up.
Every file below is in `build/<design>/sky130_scl_9T/`. The exact layout of a report changes a little between tool versions; the parts named here stay.

## Message format

Read the first **error** first: later messages are often caused by it. Then read the warnings.

| Tool | Log | A warning looks like | An error looks like |
|---|---|---|---|
| HAL, Xcelium | `lint.log`, `sim_*/xrun_*.log` | `xmvlog: *W,<CODE> (<file>,<line>\|<col>): <text>` | `*E,<CODE>`, or `*F,<CODE>` (fatal: the tool stopped) |
| Genus | `synth.log` | `Warning : <text> [<ID>]` | `Error   : <text> [<ID>]` |
| Tempus | `sta.log` | `**WARN: (<ID>): <text>` | `**ERROR: (<ID>): <text>` |
| Conformal | `lec_run.log`, `lec.log` | `// Warning: <text>` | `// Error: <text>` |

- The word before the colon in an Xcelium message is the part of the tool that complained (`xmvlog` compiles, `xmelab` elaborates, `xmsim` simulates). `xmhelp <that part> <CODE>` explains the code.
- The `<ID>` of a Genus or Tempus message is the key to look it up in the Cadence documentation (`cdnshelp`).
- Lines starting with `SB:` or `SB-WARNING:` come from this repo's scripts, not from the tool.

## Lint

`lint.log` holds HAL's messages. Each names a rule (the code), the file and the line.

- The topics are the ones in [04 — Lint](../docs/04_synthesis.md#lint): latches, multiple drivers, widths, loops, incomplete `case`, sensitivity lists. The text after the code says which.
- The last lines come from `make`: `SB: xrun exit status`, then the check: errors, warnings, and how many were waived.
- A warning you checked and found harmless goes in the design's `hal_waivers.txt` with a reason (`<code> [<file pattern>]  # why`).

## Synthesis (Genus)

`synth.log` is the whole Genus session, in the order of `flow/genus/synth.tcl`: settings, libraries, reading the RTL, elaboration, SDC, the three synthesis steps, reports, output files.

### Latches

[04 — Latches](../docs/04_synthesis.md#latches). The flow sets `hdl_error_on_latch`, so Genus **stops** during elaboration with an `Error` that names the signal, the file and the line.
Search: `grep -n -i latch synth.log`. As a second net, `make check` looks for latch cells (`TLATX1`, `TLATSRX1`) in `netlist.v`.

### Black boxes and missing modules

[04 — Black boxes](../docs/04_synthesis.md#black-boxes). A module whose file was not read is an **unresolved reference**.
The flow sets `hdl_error_on_blackbox`, so Genus stops with an `Error` naming the module. `check_design.rpt` counts them in the `Unresolved References` row.
Lab 2's SRAM is a black box on purpose: Genus reads its Liberty model, so it is a library cell (`sb_sram_256x8`), not an unresolved reference.

### Multiple drivers and undriven nets

[04 — Multiple drivers](../docs/04_synthesis.md#multiple-drivers). Genus may already complain while elaborating (search `synth.log` for `driver`).
After synthesis, `check_design.rpt` lists them by name, with a count per kind in its summary: `Multidriven Port(s)`, `Multidriven Leaf Pin(s)`, `Undriven Port(s)`, `Undriven Leaf Pin(s)`, and more.

### Combinational loops

[04 — Combinational loops](../docs/04_synthesis.md#combinational-loops). A timing tool must cut a loop to time it.
`check_timing.rpt` counts the cut points in the row `Loop-breaking cells for combinational feedback`; any number above 0 means a loop.

### Check

[04 — Check](../docs/04_synthesis.md#check). After Genus finishes, `make synth` reads `check_design.rpt`, `check_timing.rpt`, `synth.log` and the netlist. If it finds a latch, a missing module, multiple drivers, an undriven pin or a loop, `make synth` fails and removes `netlist.v`. The reports stay.

### SDC

Right after `read_sdc`, Genus prints how many SDC commands it ran and lists the ones that failed, with the line of your file. A failed command was **not applied**.
`netlist.sdc` is the constraint set as Genus understood it.

### Reports

| File | What | Look for |
|---|---|---|
| `timing.rpt` | Genus's own 10 worst paths | an early estimate; Tempus has the final word |
| `area.rpt` | area per module (instance), total at the top | the top line is the whole design |
| `gates.rpt` | every cell used, with count and area; totals per type | most used cells; the `sequential` and `total` rows |
| `qor.rpt` | summary: slack, area, cell counts, fanout | the largest fanout and its net |
| `datapath.rpt` | adders, multipliers, comparators and the structure Genus picked | changes with `SYNTH_ADDER` |
| `power.rpt` | leakage, internal and switching power per category | only leakage means something here (no real activity) |

Genus usually prints times in **ps** and capacitance in **fF**. Tempus uses the library's units: **ns** and **pF**.

## Constraint checks

[05 — Unconstrained](../docs/05_sdc.md#unconstrained). Read these before any timing path.

`check_timing.rpt` (Genus) ends with a lint summary, one count per problem, then lists the objects:

| Row | Meaning |
|---|---|
| `Sequential clock pins without clock waveform` | flip-flops with no clock: everything they capture is unconstrained |
| `Inputs without clocked external delays` | inputs with no `set_input_delay` |
| `Outputs without clocked external delays` | outputs with no `set_output_delay`: unconstrained endpoints |
| `Inputs without external driver/transition`, `Outputs without external load` | missing drive or load |
| `Timing exceptions with no effect`, `Suspicious multi_cycle exceptions` | an exception that matches nothing, or looks wrong |

`sta_check_timing.rpt` (Tempus) is the same kind of check at sign-off. `make check` fails on unclocked flip-flops and on ports without delays; the asynchronous reset input may be the one exception, if your SDC handles it another way (with a comment).

## Timing (Tempus)

[06 — Reading timing reports](../docs/06_timing_reports.md). One Tempus run checks three **views**: one per corner (`view_tt`, `view_ss`, `view_ff`), each with your SDC and that corner's Liberty files (`flow/tempus/mmmc.tcl`).

### Setup

`sta_<corner>_setup.rpt` holds the 10 worst setup paths at that corner, one per endpoint, worst first. Each path has:

1. A header: `Path 1: MET` or `VIOLATED`, the slack, and the endpoint pin (`Setup Check with Pin <instance>/<pin>`).
2. The start point, the endpoint, the clock edges and the view.
3. The required time: the capture clock edge, minus setup, minus uncertainty.
4. The arrival time, then **Slack** = required − arrival.
5. A table with one line per pin on the path: instance and cell, edge (rise or fall), delay of that stage, arrival time so far.

Sign-off reads setup at `ss` ([06 — Setup](../docs/06_timing_reports.md#setup)).

### Hold

`sta_<corner>_hold.rpt`: the same layout, `Hold Check`, early (fastest) delays. Sign-off reads hold at `ff` ([06 — Hold](../docs/06_timing_reports.md#hold)).
Paths that end on a reset pin of a flip-flop are called `Recovery Check` (like setup) and `Removal Check` (like hold).

### Summary and design rules

- `sta_summary.txt`: WNS and TNS for setup and hold at each corner, the clock period, and for Lab 2 the number of flip-flop reset pins hanging directly on `rst_n`.
- `sta_drv.rpt`: design-rule violators (max transition, max capacitance, max fanout). Reported, not signed off.
- `sta.log`: the session. `**ERROR` here usually means a netlist or SDC problem; the SDC line is named.

## Equivalence (Conformal)

[07 — Equivalence checking](../docs/07_equivalence.md). `make lec` runs `flow/conformal/lec.do`. By default it runs `genus_lec.do`, the script Genus wrote: it knows how Genus renamed registers and which adder and multiplier structures it chose.

`lec_run.log` (everything Conformal printed) has, in order:

1. Which script ran (`SB: running ...`).
2. Reading the libraries, the RTL (golden) and the netlist (revised). `// Error` here means a file did not read. `report_black_box` lists the black boxes; on Lab 2 that is only the SRAM.
3. Mapping: Conformal pairs the [key points](../docs/02_glossary.md#key-point) of both sides. **Unmapped points** are key points with no partner, often renamed or removed registers.
4. Compare: each compare point is **equivalent**, **non-equivalent**, **aborted** (gave up: too hard) or **not compared**.
5. The last lines: `No of compare points`, `No of diff points` (non-equivalent), `No of abort points`, `No of unknown points`. Pass = compare points above 0, the other three 0.

When points are non-equivalent, the Genus script may also write `noneq.*` files in the build folder: the non-equivalent points, the source lines involved, and an input pattern that shows the difference.
To look at one in the GUI: copy `genus_lec.do`, delete its last `exit` line, and run `lec -xl -dofile <copy>` from the build folder (after `source flow.env`). The GUI stays open; its diagnosis view shows the logic cone and the input pattern.

## Simulation (Xcelium and cocotb)

- The terminal shows cocotb's output: one line per test with `PASS` or `FAIL`, and a table at the end. `results.xml` (RTL) and `gls_results.xml` (netlist) hold the same.
- `sim_rtl/xrun_build.log` (`sim_gls/` for GLS): compiling and elaborating. `*E` here means the code did not compile; nothing was simulated.
- `sim_rtl/xrun_test.log`: the simulation itself, with any `$display` output.
- A failing test prints the cycle and the values it expected; see [08 — When GLS fails](../docs/08_gate_level_sim.md#when-gls-fails-but-rtl-simulation-passes).
- `WAVES=1` writes `cocotb_waves.shm` in `sim_rtl/` or `sim_gls/`. Open it with `simvision <folder>/cocotb_waves.shm`.

## QoR

[06 — QoR](../docs/06_timing_reports.md#qor). `qor.csv` has one row per corner:

| Column | From |
|---|---|
| `period_ns`, `wns_ns`, `tns_ns`, `hold_wns_ns` | `sta_summary.txt` (Tempus) |
| `area_um2`, `cell_count`, `seq_cells` | `gates.rpt` (Genus) |
| `leakage` (W) | `power.rpt` (Genus), at the synthesis corner only |
| `synth_runtime_s`, `sta_runtime_s` | `runtimes.txt` |

Next: go back to the page that sent you here. Coming from the learning path: [Lab 1 — Reference designs](../labs/lab1_reference/README.md).
