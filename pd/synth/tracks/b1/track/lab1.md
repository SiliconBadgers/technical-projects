# Lab 1 commands (Track B1)

The tasks and questions are in [labs/lab1_reference/README.md](../../../labs/lab1_reference/README.md). This page only shows how to run them here.
Clock periods: [README.md](README.md#clock-targets). Reading the outputs: [reading_logs.md](reading_logs.md).

- This track has one library, `sky130_scl_9T`, so "every library of your track" means this one.
- `gcd` takes a few minutes, mostly tool start-up and license checkout.
- `ibex` takes much longer: synthesis, LEC and GLS are the slow steps. `make clean DESIGN=ibex` deletes its build folder.

## 1. Run as shipped

```
make all DESIGN=gcd  && make check DESIGN=gcd
make all DESIGN=ibex && make check DESIGN=ibex
```

Wall time per step: `build/<design>/sky130_scl_9T/runtimes.txt` (seconds) and the `*_runtime_s` columns of `qor.csv`.

## 2. Critical path

```
less build/ibex/sky130_scl_9T/sta_ss_setup.rpt     # Tempus: the 10 worst setup paths at ss, worst first
less build/ibex/sky130_scl_9T/timing.rpt           # Genus: its own estimate after synthesis
```

Instance names in the path keep the RTL hierarchy (e.g. `ex_block_i/...`), which tells you the RTL module.

Ripple-carry adders, in a separate build folder so the first result stays:

```
make synth sta qor DESIGN=ibex SYNTH_ADDER=ripple BUILD=$PWD/build/ibex/sky130_scl_9T_ripple
```

`datapath.rpt` in each folder lists the adders and the structure Genus picked.

## 3. Clock sweep

1.3× down to 0.7× the SDC period (17 ns for ibex), one build folder per period:

```
for p in 22.1 20.4 18.7 17 15.3 13.6 11.9; do
  make synth sta qor DESIGN=ibex CLOCK_PERIOD=$p
done
grep -h ',ss,' build/ibex/sky130_scl_9T_p*/qor.csv     # period, WNS, TNS, ..., area per run
```

A run with negative slack does not stop the loop: STA reports the slack, it does not fail on it.

## 4. Library comparison

At the shortest passing period:

```
make synth sta qor DESIGN=ibex CLOCK_PERIOD=<ns>
less build/ibex/sky130_scl_9T_p<ns>/gates.rpt       # cells used, with count and area
```

## 5. Corner comparison

One netlist, three corners from one Tempus run: `sta_tt_setup.rpt`, `sta_ss_setup.rpt`, `sta_ff_hold.rpt` (and the others). `qor.csv` has one row per corner.

## 6. Equivalence and GLS

```
make lec gls DESIGN=ibex
```

## Where to look

| Question | Look at |
|---|---|
| Which step is slowest | `runtimes.txt`, `qor.csv` |
| Start point and endpoint, cells on the worst path | `sta_ss_setup.rpt`, path 1 |
| WNS, TNS, area per period | `qor.csv` of each `_p<ns>` folder |
| Area, cell count, most used cells | `gates.rpt`, `area.rpt`, `qor.csv` |
| Leakage | `power.rpt` (at the synthesis corner, `ss`), `qor.csv` |
| Setup at `tt` vs. `ss`, hold at `ff` | `sta_<corner>_setup.rpt`, `sta_ff_hold.rpt`, `sta_summary.txt` |
| What LEC proved | `lec_run.log` (see [reading_logs.md](reading_logs.md#equivalence-conformal)) |
| GLS result | `gls_results.xml` |

Next: answer the questions in [labs/lab1_reference/README.md](../../../labs/lab1_reference/README.md), then follow its Next link.
