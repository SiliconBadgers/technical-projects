# Lab 0 commands (Track B1)

The tasks and questions are in [labs/lab0_libraries/README.md](../labs/lab0_libraries/README.md). This page only shows how to run them here.
Run everything from the repo root, with the tools and the Python environment from [README.md](README.md#setup) loaded.

## 0. Environment

```
make env-check
make all   DESIGN=gcd
make check DESIGN=gcd
```

- `make env-check` finds every tool and every library file.
- `make check` ends with `all checks OK`. If it does not on the first ever run, tell your mentor which check failed (see the [First run checklist](README.md#first-run-checklist)).
- `make all` stops at the first failing step. `make -k all` keeps going with the steps that do not depend on it.

## Finding the library files

The Lab 0 scripts read [libraries.yaml](libraries.yaml): `sky130_scl_9T` (this track's library) and `sky130_fd_sc_hd` (for comparison only).
`$SB_PDK` is the PDK repo; if you did not set it, it is `../silicon-badgers-sky130-pdk`.

```
python3 libs/lab0/platforms.py                      # every library and corner, with its file
python3 libs/lab0/platforms.py sky130_scl_9T tt     # one file
make -s print-LIB_tt                                # the same file, as the flow uses it
zless $(python3 libs/lab0/platforms.py sky130_scl_9T tt)    # the sky130_scl_9T files are gzipped
```

| What | sky130_scl_9T | sky130_fd_sc_hd |
|---|---|---|
| Liberty files | `$SB_PDK/cadence/sky130_scl_9T/lib/` | `$SB_PDK/synopsys/sky130_fd_sc_hd/lib/` |
| Technology LEF (layers, site) | `$SB_PDK/cadence/sky130_scl_9T_tech/lef/sky130_scl_9T.tlef` | `$SB_PDK/synopsys/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.tlef` |
| Cell LEF (cell outlines and pins) | `$SB_PDK/cadence/sky130_scl_9T/lef/sky130_scl_9T.lef` | `$SB_PDK/synopsys/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef` |

Cell names differ: `sky130_scl_9T` writes function and drive strength as `INVX1`, `INVX4`, `NAND2X1`; `sky130_fd_sc_hd` as `sky130_fd_sc_hd__inv_1`.

## 1. Parse a Liberty file

```
pytest libs/lab0
python3 libs/lab0/parse_lib.py summary $(python3 libs/lab0/platforms.py sky130_scl_9T tt)
python3 libs/lab0/parse_lib.py table   $(python3 libs/lab0/platforms.py sky130_scl_9T tt) INVX1 Y A cell_rise
python3 libs/lab0/parse_lib.py lookup  $(python3 libs/lab0/platforms.py sky130_scl_9T tt) INVX1 Y A cell_rise --slew 0.04 --load 0.01
```

`python3 libs/lab0/parse_lib.py -h` lists every command. The same commands work for `sky130_fd_sc_hd` with `sky130_fd_sc_hd__inv_1`.

## 2. Plots

```
python3 libs/lab0/plot_delays.py        # PNGs in build/lab0/
```

The corner plot uses the first library in [libraries.yaml](libraries.yaml), `sky130_scl_9T` (`INVX1`).

## 3. Table

```
python3 libs/lab0/make_table.py > labs/lab0_libraries/lab0_table.md
```

## 4. Physical views

```
less $(make -s print-TECH_LEF)          # sky130_scl_9T technology LEF
less $(make -s print-CELL_LEF)          # sky130_scl_9T cell LEF
```

Search for `SITE`, `SIZE` and `PITCH`. Do the same in the `sky130_fd_sc_hd` files from the table above.

## Where to look

| Question | Look at |
|---|---|
| Units and corner of a library | `parse_lib.py summary`, or the top of the Liberty file |
| A delay table, a lookup by hand | `parse_lib.py table` and `lookup` |
| Delay vs. load, slew and corner | `build/lab0/*.png` |
| Area, pin capacitance, drive strengths | `labs/lab0_libraries/lab0_table.md` |
| Row height, track pitch | technology LEF (site, layer pitches) and cell LEF (cell sizes) |

Next: answer the questions in [labs/lab0_libraries/README.md](../labs/lab0_libraries/README.md), then follow its Next link.
