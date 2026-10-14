# Reading logs and reports (Track B2)

The ideas are in the main docs ([04](../../../docs/04_synthesis.md), [05](../../../docs/05_sdc.md), [06](../../../docs/06_timing_reports.md), [07](../../../docs/07_equivalence.md), [08](../../../docs/08_gate_level_sim.md)).
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
| `synth_fanout.rpt` | `report_net_fanout` | nets with more than 16 loads, before and after compile |
| `netlist.v`, `synth.svf`, `synth.sdc` | Design Compiler | the netlist, the change log for Formality, the constraints as synthesis saw them |
| `sta_<corner>.log`, `sta_<corner>.rpt`, `sta_<corner>.txt` | `pt_shell` | PrimeTime output, the timing report, a short summary |
| `lec_run.log`, `lec_failing.rpt`, `lec_unmatched.rpt`, `lec_analyze.rpt` | `fm_shell` | Formality output and its reports |
| `gls.log`, `gls_results.xml` | `make gls` | gate-level simulation output and result file |
| `qor.csv` | `make qor` | one row per corner |

## Messages

Design Compiler, PrimeTime, Formality and Library Compiler print messages in one format:

```
Warning:  /path/rtl/pe_ctrl.sv:69: signed to unsigned conversion occurs. (VER-318)
Error: unknown option '-async_pins' (CMD-010)
Information: Ungrouping hierarchy id_stage_i before Pass 1 (OPT-776)
```

- The code in brackets (`VER-318`) names the message. At the tool's prompt, `man VER-318` explains it and says what to do.
- `Error` lines matter first. `make synth`, `sta`, `lec` and `macros` fail on any log line that starts with `Error:` (or `SB-ERROR`), even when the tool went on and exited normally; the make output shows the first ones. The only exceptions are the message IDs in `flow/scripts/tool_error_waivers.txt`, each with its reason.
- Lines that start with `SB:` are the flow's own summary.
- Count each kind: `grep -o '([A-Z]*-[0-9]*)' synth.log | sort | uniq -c | sort -rn`.

## Lint

- **VC SpyGlass** (`lint_vc.rpt`): one entry per violation, with a rule tag, a severity (error, warning, info), a file and line, and a message. Read errors first.
- **VCS** (`lint/vcs.log`): each finding starts with `Lint-[<TAG>]`, then the file, the line and an explanation. Typical findings: width mismatches, unconnected ports, signals never read or never driven.
- VCS stops on real errors, which then fail `make lint`. Example: a variable driven by an `always` block and by a module output (or an `assign`) gives `Error-[ICPSD] Illegal combination of drivers`; two `always` blocks give `Error-[ICPD]`.

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
Inferred memory devices in process in routine 'arbiter' in file
	 '/path/rtl/arbiter.sv'.
==================================================================================
|    Register Name    |   Type    | Width | Bus | MB |  Set  | Reset | ST | Line |
==================================================================================
|      grant_reg      |   Latch   |   1   |  N  | N  | None  | None  | -  |  27  |
|     state_q_reg     | Flip-flop |   2   |  Y  | N  | None  | Async | N  |  52  |
==================================================================================
Warning:  Latch inferred in design arbiter read with 'hdlin_check_no_latch' (ELAB-395)
```

- `Type` `Flip-flop` is a clocked register; `Line` is the line of its `always` block. `Latch` in a combinational block means a signal is not assigned on every path ([04](../../../docs/04_synthesis.md#latches)).
- The flow turns on a warning for every inferred latch (`hdlin_check_no_latch`): `ELAB-395`, right after the table.
- After compile, `synth_latches.rpt` counts the latches left. ibex's clock-gating cell (`sdlclkp`) holds a latch on purpose, but it is not counted there.

### Multiple drivers

- Two `always` blocks of one module that drive the same variable stop `elaborate`: `Net '<name>' or a directly connected net is driven by more than one source ... (ELAB-366)`.
- A module output that the parent module also drives does not stop synthesis. `synth_check_design.rpt` counts it (`Net has multiple drivers (LINT-4)`), and `synth.log` says `Information: In design '<design>', net '<name>' has multiple drivers.  Wired AND assumed. (LINT-4)`: Design Compiler quietly ANDs the drivers.
- VCS (`make lint`, `make sim`) stops on both: `Error-[ICPSD] Illegal combination of drivers`.
- The message gives the net name; search the RTL for every place that assigns it ([04](../../../docs/04_synthesis.md#multiple-drivers)).

### Combinational loops

- Timing tools cannot time a loop, so they cut one arc in it: `Disabling timing arc between pins ... to break a timing loop`.
- `synth_check_timing.rpt` and the `check_timing` section of `sta_<corner>.rpt` list loops ([04](../../../docs/04_synthesis.md#combinational-loops)).

### Black boxes

- `Warning: Unable to resolve reference '<module>' in '<design>'. (LINK-5)`: a module or library cell was not found. It is only a warning, so the flow adds `SB-ERROR: link could not resolve every instance` and fails the step.
- Lab 2's SRAM is a library cell from its own `.db`, so it links. Its area is in the `Macro/Black Box area` line of `synth_area.rpt` ([04](../../../docs/04_synthesis.md#black-boxes)).

### Check

`synth_check_design.rpt` lists structural problems before compile: undriven inputs, unconnected outputs, constant ports, multiple drivers.
Many are harmless (an unused port of a reused module); each one deserves a look ([04](../../../docs/04_synthesis.md#check)).

### Other things in `synth.log`

| Search for | What |
|---|---|
| `LINK-5` | an instance without a module or library cell |
| `Inferred memory devices` | the register tables above |
| `Optimization Complete` | the end of compile |
| `SB:` | the flow's summary lines |

## Timing

`sta_<corner>.rpt` has these sections, in this order. Read the first two before any path ([05](../../../docs/05_sdc.md#checking-your-sdc)).

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
- Before layout, hold is often clean or tight; real fixes come in physical design ([09](../../../docs/09_synthesis_vs_pd.md)).

### Unconstrained endpoints

- `check_timing` prints a warning such as `There are 5 endpoints which are not constrained for maximum delay`, then lists them.
- The coverage section shows them as `untested`, with a reason. Two kinds are fine: recovery/removal of the reset synchronizer's two flip-flops, which only `rst_n` reaches (`no_startpoint_clock`, or `false_paths`), and pins driven by a constant (`constant_disabled`, `no_paths`: the synchronizer's first `D` input; in ibex, the six outputs its configuration ties to a constant, `instr_addr_o[1:0]`, `data_addr_o[1:0]`, `alert_minor_o` and `alert_major_o`). Any other untested check is a hole in your SDC.
- Fix the SDC (a missing `set_input_delay` or `set_output_delay`), not the design ([05](../../../docs/05_sdc.md#unconstrained)).

### Recovery and removal

Reset pins of flip-flops get their own checks: recovery (like setup) and removal (like hold) ([05](../../../docs/05_sdc.md#asynchronous-reset)).
They appear as paths ending at a reset pin (`RESET_B`), with `library recovery time` or `library removal time` on the capture side.
In Lab 2 the synchronized reset is launched by `clk`, so these checks are timed at every flip-flop except the synchronizer's own two, which `rst_n` drives directly.

### Violators and fanout

- `report_constraint -all_violators` lists each violated limit with its required value, actual value and slack.
- Max fanout is listed only when the SDC sets `set_max_fanout`. Design Compiler fixes that limit during compile, so the high-fanout nets are in `synth_fanout.rpt` instead: their fanout before compile, then the buffer trees (fanout and depth) after it.

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
- An incomplete sensitivity list (`always @(a)` in a block that also reads `b`) gets no message from Design Compiler or Formality (Y-2026.03): synthesis builds the logic as if the list were complete, Formality reads the RTL the same way, and LEC passes. Only RTL simulation, which honors the list, disagrees with GLS ([08](../../../docs/08_gate_level_sim.md#gls)).
- To see a failing cone as a schematic: `source lec.env`, `SB_STAY=1 fm_shell -f ../../../flow/fm/lec.tcl`, then `start_gui`.

## Simulation

RTL simulation and GLS print the same things (`sim.log`, `gls.log`):

- VCS compile messages: `Error-[<CODE>]` or `Warning-[<CODE>]`, then the file and line.
- cocotb, one line per test (`PASS` or `FAIL`), then a summary table, then the flow's line `SB: 3/3 cocotb tests passed`.
- A failed test prints the Python assertion with the expected and actual values. An `x` or `z` in a value is unknown or undriven ([08](../../../docs/08_gate_level_sim.md#gls)).
- Waveforms: add `WAVES=1`, then open `sim_rtl/waves.vcd` or `sim_gls/waves.vcd`.
- A simulation that never ends is stopped after `SIM_TIMEOUT` seconds (`SB-ERROR: the simulation did not finish within SIM_TIMEOUT=...`). The usual cause is a combinational loop ([04](../../../docs/04_synthesis.md#combinational-loops)).

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
