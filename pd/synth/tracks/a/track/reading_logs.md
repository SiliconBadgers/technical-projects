# Reading Track A logs and reports

What the tools print, and where. The concepts behind them are in the main docs: [04_synthesis.md](../docs/04_synthesis.md), [06_timing_reports.md](../docs/06_timing_reports.md), [07_equivalence.md](../docs/07_equivalence.md), [08_gate_level_sim.md](../docs/08_gate_level_sim.md).
Every file below is in `build/<design>/<library>/`.

## Lint

`lint.log` has three parts:

- Verilator `--lint-only -Wall`: any `%Warning-…` or `%Error-…` fails `make lint`.
- Team rule (`flow/scripts/lint/sb_lint.py`): `%Error-SB-SENS` fails `make lint`.
- Verible: style advice only, never fails.

| Warning | Meaning |
|---|---|
| `LATCH` / `COMBDLY` | a combinational block does not assign a signal on every path |
| `MULTIDRIVEN` | two always blocks drive the same signal |
| `WIDTH` | an expression is truncated or extended |
| `UNOPTFLAT` | a combinational loop as Verilator sees it (often harmless) |
| `CASEINCOMPLETE` | a `case` without `default` in combinational logic |
| `SB-SENS` | a hand-written sensitivity list in a combinational block |

- Fix the code, or waive a harmless warning in the design's `lint_waivers.vlt`, with a comment saying why.
- A waiver line looks like `lint_off -rule WIDTH -file "*/my_file.sv" -match "*'my_signal'*"`.

## Simulation

- `make sim` prints one line per cocotb test (`PASS` / `FAIL`) and a summary table. The same results are in `results.xml`.
- An `assert` failure prints the test's message and the Python line.
- `WAVES=1` writes a `.fst` waveform in `sim_rtl/`; open it with GTKWave.

## Synthesis

| File | What |
|---|---|
| `synth.log` | everything Yosys printed |
| `synth_check.txt` | output of Yosys `check` |
| `synth_stat.txt` | cells and area per cell type, total `Chip area` (µm²) |
| `netlist.v` | the gate-level netlist |
| `abc.constr` | input driver and output load given to ABC |

In `synth.log`, search for:

| Search for | What |
|---|---|
| `SB:` | the flow's summary lines (period, ABC target, library) |
| `SB-ERROR` | why the flow stopped |
| `Warning:` | everything Yosys found odd |
| `Replacing memory` / `mapping memory` | a memory turned into flip-flops |
| `Executing ABC` | technology mapping (picking library cells) |

### Latches

- `synth.log`: `SB-ERROR: synthesis inferred a latch`, with the latch cells listed just above.
- The `no_latches` check also scans `netlist.v` for latch cells (`LATCH_CELLS` in `flow/platforms/<library>.mk`).

### Check

Any problem in `synth_check.txt` stops the run with `SB-ERROR: 'check' found structural problems`. Search for `Warning:`:

| Message | Meaning |
|---|---|
| `multiple conflicting drivers for …` | one net driven from two places |
| `found logic loop in module …` | a combinational loop |
| `Wire … is used but has no driver` | a missing connection |

## Timing

`make sta` runs OpenSTA once per corner. Per corner you get:

| File | What |
|---|---|
| `sta_<corner>.rpt` | the full report |
| `sta_<corner>.json` | the numbers the checks and `qor.csv` use |
| `sta_<corner>.log` | OpenSTA's own messages (warnings about the SDC show up here) |

Sections of `sta_<corner>.rpt`, in order:

1. `Instances without a timing model`: cells or macros with no Liberty data. Nothing through them is timed.
2. `Flip-flop reset/set pins driven directly by <port>` (Lab 2 only).
3. `check_setup -verbose`: missing clocks, missing input/output delays, loops.
4. `Unconstrained endpoints`: end points no timing check reaches.
5. `Setup (max delay)`: the 10 worst setup paths.
6. `Hold (min delay)`: the 10 worst hold paths.
7. `Slack summary`: `report_wns`, `report_tns`, worst slack (max and min).
8. `Design rule violators`: nets over the max slew, capacitance or fanout limit. Reported only, never a failure. Fanout is checked only if the SDC sets `set_max_fanout`.
9. `Power`: only the leakage number means something before layout.

### Reading one path

```
Fanout      Cap     Slew    Delay     Time   Description
-------------------------------------------------------------------
                   0.000    0.000    0.000   clock core_clock (rise edge)
                            0.290    0.290   clock network delay (ideal)
                   0.000    0.000    0.290 ^ _304_/CLK (sky130_fd_sc_hd__edfxtp_1)
     3    0.008    0.197    0.836    1.126 v _304_/Q (sky130_fd_sc_hd__edfxtp_1)
 ...
                                     6.983   data arrival time
 ...
                           -0.900    8.390   clock uncertainty
                           -0.821    7.569   library setup time
                                     7.569   data required time
-------------------------------------------------------------------
                                     0.586   slack (MET)
```

- `Delay`: this stage. `Time`: running total (ns). `^` / `v`: rising / falling.
- `Fanout`, `Cap`, `Slew`: how many pins the net drives, its load (pF), its transition time (ns).
- `clock network delay (ideal)`: there is no clock tree yet, so the clock arrives everywhere at the same time.
- `(MET)` or `(VIOLATED)`: positive or negative slack.
- `_304_`: instance names come from synthesis; net names keep the RTL names. `SYNTH_FLATTEN=0` keeps module names in the path.

### Rerunning OpenSTA by hand

```
cd build/gcd/sky130hd && source sta_ss.env
sta -no_init -no_splash $SB_ROOT/flow/scripts/sta/sta.tcl     # no -exit: you stay at the sta prompt
report_checks -through [get_pins _123_/Y] -fields {slew cap fanout}
report_checks -to [get_ports <port>]
```

### QoR

`make qor` writes one row per corner to `qor.csv`:

| Column | Meaning |
|---|---|
| `period_ns` | clock period |
| `wns_ns`, `tns_ns` | worst / total negative setup slack |
| `hold_wns_ns` | worst hold slack |
| `area_um2` | sum of cell areas (no wires) |
| `cell_count`, `seq_cells` | all cells, flip-flops |
| `leakage` | leakage power (W) |
| `synth_runtime_s`, `sta_runtime_s` | step wall time |
| `git_sha` | repo commit (`-dirty` = uncommitted changes) |

`runtimes.txt` has the wall time of every step.

## LEC

`make lec` runs [eqy](https://github.com/YosysHQ/eqy). It proves that the netlist does the same as the RTL for every input sequence.

How eqy works:

1. Reads the RTL ("gold") and the netlist ("gate").
2. Matches key points by name: ports, register outputs, black-box outputs.
3. Cuts both designs into small pieces (partitions) at the matched nets.
4. Proves each pair of pieces equal: strategy `sat` first, then `abc` for what is left.

Like checking two translations of a book chapter by chapter instead of all at once: the chapter breaks are the matched names.

- `Could not prove … using strategy 'sat': timeout` is normal. Only the final `DONE` line counts.
- `SYNTH_FSM=1` or `SYNTH_RETIME=1` renames or moves registers, so they no longer match.
- Partitions run in parallel (`LEC_JOBS`, default one per CPU core).

| File | What |
|---|---|
| `lec.eqy` | the generated eqy configuration |
| `lec_run.log` / `lec.log` | eqy's log; last line `DONE (PASS…)` or `DONE (FAIL…)` |
| `lec/matched.ids` | matched gold/gate name pairs |
| `lec/partitions/<name>.sv` | one partition, gold and gate side by side |
| `lec/strategies/<name>/sat/run.log` | the SAT run for that partition |
| `lec/strategies/<name>/abc/<name>/logfile.txt` | the ABC run, if `sat` did not settle it |

### Reading a failure

```
Failed to prove equivalence of partition ibex_core.load_store_unit_i.data_type_q.0
```

The partition is named after a matched net it drives. Open `lec/strategies/<partition>/sat/run.log`:

- `Base case … proven` lines, then `Induction step failed`: no difference found, but the proof did not close. Check the `abc` run.
- A base case fails (a trace where `gold` ≠ `gate`): a real difference. The trace gives the input values that show it.

### Big partitions

`ls -S lec/partitions/*.il | head` lists the biggest. A very large partition is slow and may time out; tell a mentor which one.

## GLS

- `make gls` runs the RTL testbench, unchanged, on `netlist.v` plus the library's cell models (no timing: STA checks timing).
- Results: `gls_results.xml`. Waveforms with `WAVES=1`: `sim_gls/`.
- If the testbench needs changes to pass GLS, talk to a mentor.

Next: back to [track/README.md](README.md), or to the lab you are working on ([lab1.md](lab1.md), [lab2.md](lab2.md)).
