# Lab 0 commands (Track B2)

The tasks and questions are in [labs/lab0_libraries/README.md](../labs/lab0_libraries/README.md). This page only shows how to run them here.
Run everything from the repo root.

## 0. Environment

Do the setup in [README.md](README.md#setup-once) once. Then:

```
make all DESIGN=gcd
```

- It finishes with a `qor.csv` table and no `FAILED` line.
- Note how long it took (`time make all DESIGN=gcd` after a `make clean DESIGN=gcd`).

## Finding the library files

This track has one library, `sky130_fd_sc_hd`, at three corners (tt, ss, ff).
`python3 libs/lab0/platforms.py` lists the Liberty files named in [libraries.yaml](libraries.yaml).

| File | Where (`$SB_PDK` = the PDK repo) |
|---|---|
| Liberty (text), per corner | `$SB_PDK/synopsys/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__<corner>.lib` |
| Liberty compiled for the tools (`.db`) | `$SB_PDK/synopsys/views/sky130_fd_sc_hd__<corner>.db` |
| Technology LEF (layers, site) | `$SB_PDK/synopsys/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.tlef` |
| Cell LEF (cell outlines and pins) | `$SB_PDK/synopsys/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef` |
| Cell simulation models (GLS) | `$SB_PDK/synopsys/sky130_fd_sc_hd/verilog/` |

`<corner>` is `tt_025C_1v80`, `ss_100C_1v60` or `ff_n40C_1v95`: process, temperature, voltage.
`SB_PDK` not set in your shell? The PDK repo sits next to this one: `export SB_PDK=$PWD/../silicon-badgers-sky130-pdk`.

## 1. Parse a Liberty file

```
pytest libs/lab0
LIB=$(python3 libs/lab0/platforms.py sky130_fd_sc_hd tt)
python3 libs/lab0/parse_lib.py summary $LIB
python3 libs/lab0/parse_lib.py table   $LIB sky130_fd_sc_hd__inv_1 Y A cell_rise
python3 libs/lab0/parse_lib.py lookup  $LIB sky130_fd_sc_hd__inv_1 Y A cell_rise --slew 0.04 --load 0.01
```

`python3 libs/lab0/parse_lib.py -h` lists every command.

### The same library, seen by a Synopsys tool (optional)

Library Compiler can print what it read from the compiled library. Compare one cell with your parser's output:

```
mkdir -p build/lab0
lc_shell
lc_shell> read_db $env(SB_PDK)/synopsys/views/sky130_fd_sc_hd__tt_025C_1v80.db
lc_shell> report_lib sky130_fd_sc_hd__tt_025C_1v80 > build/lab0/tt_lib.rpt
lc_shell> exit
```

## 2. Plots

```
python3 libs/lab0/plot_delays.py        # PNGs in build/lab0/
```

With one library, the plots show `sky130_fd_sc_hd` only, plus its three corners.

## 3. Table

```
python3 libs/lab0/make_table.py > labs/lab0_libraries/lab0_table.md
```

## 4. Physical views

```
less $SB_PDK/synopsys/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.tlef     # technology LEF
less $SB_PDK/synopsys/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef      # cell LEF
```

Search for `SITE`, `SIZE` and `PITCH` (type `/` and the word in `less`).

## Where to look

| Question | Look at |
|---|---|
| Units and corner of a library | `parse_lib.py summary`, or the top of the Liberty file |
| A delay table, a lookup by hand | `parse_lib.py table` and `lookup` |
| Delay vs. load, slew and corner | `build/lab0/*.png` |
| Area, pin capacitance, drive strengths | `labs/lab0_libraries/lab0_table.md` |
| Row height, track pitch | technology LEF (site, layer pitches) and cell LEF (cell sizes) |

Next: answer the questions in [labs/lab0_libraries/README.md](../labs/lab0_libraries/README.md), then follow its Next link.
