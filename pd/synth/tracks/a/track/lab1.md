# Lab 1 commands (Track A)

The tasks and questions are in [labs/lab1_reference/README.md](../labs/lab1_reference/README.md). This page only shows how to run them here.
Clock periods: [README.md](README.md#clock-targets). Reading the outputs: [reading_logs.md](reading_logs.md).

- `gcd` runs in under a minute per library.
- `ibex` takes several minutes (LEC and GLS are the slow steps), and an ibex build uses about 2.5 GB of disk. `make clean PDK=<library> DESIGN=ibex` deletes one.

## 1. Run as shipped

```
for p in sky130hd sky130hs gf180_7t gf180_9t; do
  make all PDK=$p DESIGN=gcd && make check PDK=$p DESIGN=gcd
done
```

Then the same with `DESIGN=ibex`. Wall time per step: `build/<design>/<library>/runtimes.txt` and the `*_runtime_s` columns of `qor.csv`.

## 2. Critical path

```
less build/ibex/sky130hd/sta_ss.rpt          # section "Setup (max delay) -- 10 worst paths"
```

Ripple-carry adders, in a separate build folder so the first result stays:

```
make synth sta PDK=sky130hd DESIGN=ibex SYNTH_ADDER=ripple BUILD=$PWD/build/ibex/sky130hd_ripple
```

`SYNTH_FLATTEN=0` keeps module names in the path (handy for "which RTL module?").

## 3. Clock sweep

```
python3 flow/scripts/qor/sweep.py --pdk sky130hd --design ibex --factors 1.3 1.2 1.1 1.0 0.9 0.8 0.7
python3 flow/scripts/qor/sweep.py --pdk sky130hd --design ibex --periods <ns> <ns> <ns>    # your own periods
```

- Repeat for each library. Add `--csv <file>` to save the table.
- Each point runs synthesis and STA (`ss` and `ff` only) in `build/ibex/<library>_p<ns>/`.

## 4. Library comparison

At each library's shortest passing period:

```
make synth sta qor PDK=sky130hs DESIGN=ibex CLOCK_PERIOD=<ns>
```

## 5. Corner comparison

One netlist, three reports: `build/ibex/sky130hd/sta_tt.rpt`, `sta_ss.rpt`, `sta_ff.rpt`. `qor.csv` has one row per corner.

## 6. Equivalence and GLS

```
make lec gls PDK=sky130hd DESIGN=ibex LEC_JOBS=<cores>
```

## Where to look

| Question | Look at |
|---|---|
| Which step is slowest | `runtimes.txt`, `qor.csv` |
| Start and end point, cells on the worst path | `sta_ss.rpt`, setup section |
| WNS, TNS, area per period | `sweep.py` table |
| Area, cell count, most used cells, leakage | `synth_stat.txt`, `qor.csv` |
| Setup at `tt` vs. `ss`, hold at `ff` | `sta_<corner>.rpt` "Slack summary", `qor.csv` |
| What LEC proved | `lec.log` (see [reading_logs.md](reading_logs.md#lec)) |
| GLS result | `gls_results.xml` |

Next: answer the questions in [labs/lab1_reference/README.md](../labs/lab1_reference/README.md), then follow its Next link.
