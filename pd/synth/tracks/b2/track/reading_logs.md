# Reading logs and reports (Track B2)

The ideas are in the main docs ([04](../docs/04_synthesis.md), [05](../docs/05_sdc.md), [06](../docs/06_timing_reports.md), [07](../docs/07_equivalence.md), [08](../docs/08_gate_level_sim.md)).
This page shows where the Synopsys tools write them and what the lines look like.
The examples below are shortened, and their numbers are made up.

## Where the files are

Everything is in `build/<design>/sky130_fd_sc_hd/`.

| File | Written by | What |
|---|---|---|
| `lint.log`, `lint_run.log` | `make lint` | lint summary; details in `lint_vc.rpt` (VC SpyGlass) or `lint/vcs.log` (VCS) |
| `sim.log`, `results.xml` | `make sim` | RTL simulation output and the cocotb result file |
| `synth.log` | `dc_shell` | everything Design Compiler printed |
| `synth_check_design.rpt` | `check_design` | structural problems found before compile |
| `synth_check_timing.rpt` | `check_timing` | constraint problems seen by synthesis |
| `synth_latches.rpt` | `synth.tcl` | latches left in the netlist |
| `synth_area.rpt`, `synth_cells.rpt` | `report_area`, `report_reference` | area; cells used and how many of each |
| `synth_timing.rpt`, `synth_qor.rpt`, `synth_violators.rpt` | Design Compiler | timing as synthesis saw it |
| `synth_resources.rpt`, `synth_power.rpt` | `report_resources`, `report_power` | DesignWare blocks picked; leakage |
| `netlist.v`, `synth.svf`, `synth.sdc` | Design Compiler | the netlist, the change log for Formality, the constraints as synthesis saw them |
| `sta_<corner>.log`, `sta_<corner>.rpt`, `sta_<corner>.txt` | `pt_shell` | PrimeTime output, the timing report, a short summary |
| `lec_run.log`, `lec_failing.rpt`, `lec_unmatched.rpt`, `lec_analyze.rpt` | `fm_shell` | Formality output and its reports |
| `gls.log`, `gls_results.xml` | `make gls` | gate-level simulation output and result file |
| `qor.csv` | `make qor` | one row per corner |

## Messages

Design Compiler, PrimeTime, Formality and Library Compiler print messages in one format:

```
Warning: /path/rtl/pe.sv:42: <what happened> (ELAB-292)
Error: <what happened> (LINK-5)
Information: <for your interest> (OPT-1)
```

- The code in brackets (`ELAB-292`) names the message. At the tool's prompt, `man ELAB-292` explains it and says what to do.
- `Error` lines matter first. The flow fails a step on any line that starts with `Error` or `SB-ERROR`.
- Lines that start with `SB:` are the flow's own summary.
- Count each kind: `grep -o '([A-Z]*-[0-9]*)' synth.log | sort | uniq -c | sort -rn`.

## Lint

- **VC SpyGlass** (`lint_vc.rpt`): one entry per violation, with a rule tag, a severity (error, warning, info), a file and line, and a message. Read errors first.
- **VCS** (`lint/vcs.log`): each finding starts with `Lint-[<TAG>]`, then the file, the line and an explanation. Typical findings: width mismatches, unconnected ports, signals never read or never driven.
- VCS stops on real errors, which then fail `make lint`. Example: a variable written from two `always` blocks gives `Error-[ICPD] Illegal combination of procedural drivers`.

## Synthesis

Design Compiler works in this order. Each stage has its own kind of message in `synth.log`:

1. `analyze`: reads the files. Syntax errors appear here.
2. `elaborate`: turns the code into generic logic. Latches, multiple drivers and sensitivity-list problems appear here.
3. `link`: finds every module and library cell. Missing ones appear here.
4. `check_design`, `check_timing`: written to `synth_check_design.rpt` and `synth_check_timing.rpt`.
5. `compile_ultra`: maps to library cells and optimizes. It ends with `Optimization Complete`.

### Latches

For every `always` block that stores a value, `elaborate` prints a table:

```
Inferred memory devices in process
        in routine pe_ctrl line 57 in file '/path/rtl/pe_ctrl.sv'.
===============================================================================
|    Register Name    |   Type    | Width | Bus | MB | AR | AS | SR | SS | ST |
===============================================================================
|    state_reg        | Flip-flop |   2   |  Y  | N  | Y  | N  | N  | N  | N  |
===============================================================================
```

- `Type` `Flip-flop` is a clocked register. `Latch` in a combinational block means a signal is not assigned on every path ([04](../docs/04_synthesis.md#latches)).
- The flow also turns on a warning for every inferred latch (`hdlin_check_no_latch`).
- After compile, `synth_latches.rpt` counts the latches left. In ibex the clock-gating cell (`sdlclkp`) holds a latch on purpose.

### Multiple drivers

- Two drivers on one net stop `elaborate` with an error such as `Net '<name>' or a directly connected net is driven by more than one source ... (ELAB-366)`.
- The message gives the net name; search the RTL for every place that assigns it ([04](../docs/04_synthesis.md#multiple-drivers)).

### Combinational loops

- Timing tools cannot time a loop, so they cut one arc in it: `Disabling timing arc between pins ... to break a timing loop`.
- `synth_check_timing.rpt` and the `check_timing` section of `sta_<corner>.rpt` list loops ([04](../docs/04_synthesis.md#combinational-loops)).

### Black boxes

- `Unable to resolve reference '<module>' in '<design>'. (LINK-5)`: a module or library cell was not found. The flow adds `SB-ERROR: link could not resolve every instance`.
- Lab 2's SRAM is a library cell from its own `.db`, so it links. Its area is in the `Macro/Black Box area` line of `synth_area.rpt` ([04](../docs/04_synthesis.md#black-boxes)).

### Check

`synth_check_design.rpt` lists structural problems before compile: undriven inputs, unconnected outputs, constant ports, multiple drivers.
Many are harmless (an unused port of a reused module); each one deserves a look ([04](../docs/04_synthesis.md#check)).

### Other things in `synth.log`

| Search for | What |
|---|---|
| `ELAB-292` | a hand-written sensitivity list misses a signal the block reads: simulation and synthesis disagree |
| `LINK-5` | an instance without a module or library cell |
| `Inferred memory devices` | the register tables above |
| `Optimization Complete` | the end of compile |
| `SB:` | the flow's summary lines |

## Timing

`sta_<corner>.rpt` has these sections, in this order. Read the first two before any path ([05](../docs/05_sdc.md#checking-your-sdc)).

1. `check_timing`: unconstrained endpoints, inputs without an input delay, loops, clocks.
2. Analysis coverage of the checks your SDC decides (setup, hold, recovery, removal, outputs): how many are met, violated or **untested** (untested = nothing checks them). A short section after it covers the library's pulse-width checks; reset pins are untested there (`no_clock`: a reset is not a clock), which is expected.
3. Setup paths, then hold paths (10 each).
4. Slack summary (`report_global_timing`): WNS, TNS and the number of violating paths, for setup and hold.
5. All violators (`report_constraint -all_violators`): setup, hold, max transition, max capacitance, max fanout.
6. Lab 2 only: the flip-flop reset pins driven straight from the reset port.

`sta_<corner>.txt` repeats the key numbers. Sign-off: setup at `ss`, hold at `ff`.

### Setup

```
  Startpoint: dpath/a_reg_reg_3_
               (rising edge-triggered flip-flop clocked by core_clock)
  Endpoint: dpath/b_reg_reg_15_
               (rising edge-triggered flip-flop clocked by core_clock)
  Path Group: core_clock
  Path Type: max

  Point                                         Incr       Path
  ----------------------------------------------------------------
  clock core_clock (rise edge)                 0.000      0.000
  clock network delay (ideal)                  0.290      0.290
  dpath/a_reg_reg_3_/CLK (sky130_fd_sc_hd__dfxtp_1)
                                               0.000      0.290 r
  dpath/a_reg_reg_3_/Q (sky130_fd_sc_hd__dfxtp_1)
                                               0.512      0.802 f
  ...
  dpath/b_reg_reg_15_/D (sky130_fd_sc_hd__dfxtp_1)
                                               0.101      4.210 r
  data arrival time                                       4.210

  clock core_clock (rise edge)                 9.000      9.000
  clock network delay (ideal)                  0.290      9.290
  clock uncertainty                           -0.900      8.390
  library setup time                          -0.180      8.210
  data required time                                      8.210
  ----------------------------------------------------------------
  data arrival time                                      -4.210
  ----------------------------------------------------------------
  slack (MET)                                             4.000
```

- `Path Type: max` is a setup check. `Incr` is the delay of one stage, `Path` the running total; `r` and `f` mark rising and falling.
- Slack = required − arrival. `(VIOLATED)` instead of `(MET)` means negative slack.
- A start point `(input port clocked by vclk_core_clock)` is an input; its `input external delay` line is your `set_input_delay`.
- Instance names like `U123` are made up by synthesis; net names (with `-nets`) keep RTL names.

### Hold

- `Path Type: min`, at `ff`. The capture side shows `library hold time` instead of setup time.
- Slack = arrival − required: data must not arrive too early. The clock period does not appear.
- Before layout, hold is often clean or tight; real fixes come in physical design ([09](../docs/09_synthesis_vs_pd.md)).

### Unconstrained endpoints

- `check_timing` prints a warning such as `There are 5 endpoints which are not constrained for maximum delay`, then lists them.
- The coverage section shows them as `untested`, with a reason. Two reasons are fine: `false_paths` on the reset synchronizer's flip-flops (your `rst_n` false path) and `constant_disabled` or `no_paths` on pins driven by a constant. Any other untested check is a hole in your SDC.
- Fix the SDC (a missing `set_input_delay` or `set_output_delay`), not the design ([05](../docs/05_sdc.md#unconstrained)).

### Recovery and removal

Reset pins of flip-flops get their own checks: recovery (like setup) and removal (like hold) ([05](../docs/05_sdc.md#asynchronous-reset)).
They appear as paths ending at a reset pin (`RESET_B`), with `library recovery time` or `library removal time` on the capture side.
In Lab 2 the synchronized reset is launched by `clk`, so these checks are timed at every flip-flop except the synchronizer's own two, which `rst_n` drives directly.

### Violators and fanout

- `report_constraint -all_violators` lists each violated limit with its required value, actual value and slack.
- Max fanout is listed only when the SDC sets `set_max_fanout`.

## LEC

Formality proves that the netlist (implementation, `i:`) does the same as the RTL (reference, `r:`).

1. Reads `synth.svf`, Design Compiler's change log, so it knows about renamed and merged registers.
2. Reads the RTL and the netlist, then **matches** compare points by name: outputs, flip-flops (`DFF`), latches (`LAT`), black-box pins (`BBPin`).
3. **Verifies** each matched pair: the logic in front of it must compute the same value in both designs.

The result block in `lec_run.log`:

```
********************************* Verification Results *********************************
Verification SUCCEEDED
------------------------------------------------------------------------------------------
 Reference design: r:/WORK/gcd
 Implementation design: i:/WORK/gcd
 140 Passing compare points
------------------------------------------------------------------------------------------
Matched Compare Points     BBPin    Loop   BBNet     Cut    Port     DFF     LAT   TOTAL
------------------------------------------------------------------------------------------
Passing (equivalent)           0       0       0       0      51      89       0     140
Failing (not equivalent)       0       0       0       0       0       0       0       0
```

- `SUCCEEDED`: every compare point is equal. `FAILED`: at least one is not. `INCONCLUSIVE`: the tool ran out of effort on some points; tell a mentor.
- `lec_failing.rpt` lists failing points (`Ref` and `Impl` names of the same register or port).
- `lec_analyze.rpt` (`analyze_points -failing`) suggests a cause for each one.
- `lec_unmatched.rpt` lists points without a partner. Registers that synthesis removed (constants) show up here and are fine.
- Formality also stops reading the RTL when the code means one thing in simulation and another in synthesis (for example an incomplete sensitivity list). The error gives the file and line: that is a finding, not a tool problem.
- To see a failing cone as a schematic: `source lec.env`, `SB_STAY=1 fm_shell -f ../../../flow/fm/lec.tcl`, then `start_gui`.

## Simulation

RTL simulation and GLS print the same things (`sim.log`, `gls.log`):

- VCS compile messages: `Error-[<CODE>]` or `Warning-[<CODE>]`, then the file and line.
- cocotb, one line per test (`PASS` or `FAIL`), then a summary table, then the flow's line `SB: 3/3 cocotb tests passed`.
- A failed test prints the Python assertion with the expected and actual values. An `x` or `z` in a value is unknown or undriven ([08](../docs/08_gate_level_sim.md#gls)).
- Waveforms: add `WAVES=1`, then open `sim_rtl/waves.vcd` or `sim_gls/waves.vcd`.
- A simulation that never ends is stopped after `SIM_TIMEOUT` seconds (`SB-ERROR: the simulation did not finish within SIM_TIMEOUT=...`). The usual cause is a combinational loop ([04](../docs/04_synthesis.md#combinational-loops)).

## QoR

`make qor` writes one row per corner to `qor.csv`:

| Column | Meaning |
|---|---|
| `period_ns` | clock period |
| `setup_wns_ns`, `setup_tns_ns` | worst setup slack, and the sum of negative setup slacks |
| `hold_wns_ns`, `hold_tns_ns` | the same for hold |
| `area_um2`, `cell_count` | total cell area (no wires) and number of cells, from Design Compiler |
| `leakage` | leakage power at the synthesis corner (`ss`), from `report_power` |

Next: go back to the lab page you came from: [Lab 0](lab0.md), [Lab 1](lab1.md) or [Lab 2](lab2.md).
