# Lab 1 commands (Track B2)

The tasks and questions are in [labs/lab1_reference/README.md](../../../labs/lab1_reference/README.md). This page only shows how to run them here.
Clock periods: [README.md](README.md#clock-targets). Reading the outputs: [reading_logs.md](reading_logs.md).

- `gcd` runs in a few minutes. `ibex` takes much longer: synthesis, LEC and GLS are the slow steps.
- Outputs: `build/<design>/sky130_fd_sc_hd/`. `make clean DESIGN=<design>` deletes one build folder.
- This track has one library (`sky130_fd_sc_hd`), so "every library" means this one.

## 1. Run as shipped

```
make all DESIGN=gcd
make all DESIGN=ibex
```

Then go through [this track's checks](README.md#this-tracks-checks) for each design.

Wall time per step: run the steps one at a time and note the `real` line of each.

```
make clean DESIGN=ibex
mkdir -p build
for s in lint sim synth sta lec gls qor; do echo "== $s"; time make $s DESIGN=ibex; done 2>&1 | tee build/ibex_times.txt
```

## 2. Critical path

```
less build/ibex/sky130_fd_sc_hd/sta_ss.rpt        # section "Setup (max delay): 10 worst paths"
```

- `compile_ultra` dissolves most ibex modules into the top (`Ungrouping hierarchy ... (OPT-776)` in `synth.log`); instance names still start with the module instance, joined with `_` (for example `if_stage_i_instr_rdata_id_o_reg_18_`). Only the register file and the multiplier/divider stay modules of their own (`gen_regfile_ff_register_file_i/...`).
- `synth_timing.rpt` is the same path as Design Compiler saw it during synthesis.

**Ripple-carry adders.** Design Compiler builds adders from DesignWare, its library of ready-made arithmetic blocks. Each block has several structures ("implementations"); `rpl` is the ripple-carry one.
Write a small Tcl file that allows only `rpl`, and run it in a separate build folder so the first result stays:

```
mkdir -p build/lab1
cat > build/lab1/ripple.tcl <<'EOF'
# keep every adder a separate DesignWare block (no merged datapath)
set_app_var hlo_disable_datapath_optimization true
# forbid every adder structure except ripple carry (rpl)
set_dont_use {standard.sldb/DW01_add/cla dw_foundation.sldb/DW01_add/pparch dw_foundation.sldb/DW01_add/apparch}
EOF
make synth sta DESIGN=ibex DC_EXTRA=build/lab1/ripple.tcl BUILD=$PWD/build/ibex/sky130_fd_sc_hd_ripple
```

- `synth_resources.rpt` lists each DesignWare block and the implementation Design Compiler picked. Compare the two builds.
- Still not `rpl` everywhere? In `dc_shell`, `report_synlib dw_foundation.sldb` lists the implementations of `DW01_add`, `DW01_sub` and `DW01_addsub`; add the other ones to the list.

## 3. Clock sweep

Each point is its own build, `build/ibex/sky130_fd_sc_hd_p<ns>/`:

```
for f in 1.3 1.2 1.1 1.0 0.9 0.8 0.7; do
  p=$(awk -v f=$f 'BEGIN { printf "%.2f", 11.6 * f }')    # 11.6 ns = the ibex SDC period
  make synth sta qor DESIGN=ibex CLOCK_PERIOD=$p CORNERS="ss ff"
done
grep -h ',ss,' build/ibex/sky130_fd_sc_hd_p*/qor.csv     # one line per period: WNS, TNS, area
```

`CORNERS="ss ff"` skips the tt run to save time; add tt back for task 5.

## 4. Library comparison

At the shortest passing period, in that build folder:

| Number | Where |
|---|---|
| Area, cell count | `qor.csv` (`area_um2`, `cell_count`), `synth_area.rpt` |
| The 10 most used cells | `awk '$2 ~ /^sky130/ { print $4, $1 }' synth_cells.rpt \| sort -rn \| head` (count, cell) |
| Leakage | `qor.csv` (`leakage`, at the synthesis corner `ss`), `synth_power.rpt` |

## 5. Corner comparison

One netlist, three reports: `sta_tt.rpt`, `sta_ss.rpt`, `sta_ff.rpt` in `build/ibex/sky130_fd_sc_hd/`.
`qor.csv` has one row per corner; the "Slack summary" section of each report has WNS and TNS.

## 6. Equivalence and GLS

```
make lec gls DESIGN=ibex
```

## Where to look

| Question | Look at |
|---|---|
| Which step is slowest | the `real` times from task 1 |
| Start point, endpoint, cells on the worst path | `sta_ss.rpt`, setup section |
| WNS, TNS, area per period | `qor.csv` of each `_p<ns>` build |
| Area, cell count, most used cells, leakage | `synth_area.rpt`, `synth_cells.rpt`, `synth_power.rpt`, `qor.csv` |
| Adder structures | `synth_resources.rpt` |
| Setup at `tt` vs. `ss`, hold at `ff` | `sta_<corner>.rpt` "Slack summary", `qor.csv` |
| What LEC proved | `lec.log` (see [reading_logs.md](reading_logs.md#lec)) |
| GLS result | `gls.log`, `gls_results.xml` |

Next: answer the questions in [labs/lab1_reference/README.md](../../../labs/lab1_reference/README.md), then follow its Next link.
