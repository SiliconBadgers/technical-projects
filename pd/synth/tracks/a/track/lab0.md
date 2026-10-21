# Lab 0 commands (Track A)

The tasks and questions are in [labs/lab0_libraries/README.md](../../../labs/lab0_libraries/README.md). This page only shows how to run them here.
Run everything from this track's folder, `tracks/a`.

## 0. Environment

```
env/start.sh build      # once
env/start.sh shell      # then, inside the container (start.sh prints this cd line):
cd /foss/designs/<course folder>/tracks/a
make env-check
make all   PDK=sky130hd DESIGN=gcd
make check PDK=sky130hd DESIGN=gcd
```

- `make env-check` prints `OK` for both PDKs.
- `make check` ends with every check OK.
- Not using the container? See [README.md](README.md#setup).

## Finding the library files

`make -s print-<VAR> PDK=<library>` prints one setting from `flow/platforms/<library>.mk`:

| VAR | File |
|---|---|
| `LIB_tt`, `LIB_ss`, `LIB_ff` | Liberty file at each corner |
| `TECH_LEF` | technology LEF (layers, site) |
| `CELL_LEF` | cell LEF (cell outlines and pins) |

```
less $(make -s print-LIB_tt PDK=sky130hd)
zless $(make -s print-LIB_tt PDK=sky130scl)     # sky130scl files are gzipped
```

The Lab 0 scripts read the same Liberty paths from [libraries.yaml](libraries.yaml).

## 1. Parse a Liberty file

```
pytest ../../libs/lab0
python3 ../../libs/lab0/parse_lib.py summary $(make -s print-LIB_tt PDK=sky130hd)
python3 ../../libs/lab0/parse_lib.py table   $(make -s print-LIB_tt PDK=sky130hd) sky130_fd_sc_hd__inv_1 Y A cell_rise
python3 ../../libs/lab0/parse_lib.py lookup  $(make -s print-LIB_tt PDK=sky130hd) sky130_fd_sc_hd__inv_1 Y A cell_rise --slew 0.04 --load 0.01
```

`python3 ../../libs/lab0/parse_lib.py -h` lists every command.

## 2. Plots

```
python3 ../../libs/lab0/plot_delays.py        # PNGs in build/lab0/
```

## 3. Table

```
python3 ../../libs/lab0/make_table.py > ../../labs/lab0_libraries/lab0_table.md
```

No `sky130scl` files (they come from a mentor)? Add `--platforms sky130hd sky130hs gf180_7t gf180_9t` to `plot_delays.py` and `make_table.py`.

## 4. Physical views

```
less $(make -s print-TECH_LEF PDK=sky130hd)
less $(make -s print-CELL_LEF PDK=sky130hd)
```

Search for `SITE`, `SIZE` and `PITCH`.

## Where to look

| Question | Look at |
|---|---|
| Units and corner of a library | `parse_lib.py summary`, or the top of the Liberty file |
| A delay table, a lookup by hand | `parse_lib.py table` and `lookup` |
| Delay vs. load, slew and corner | `build/lab0/*.png` |
| Area, pin capacitance, drive strengths | `../../labs/lab0_libraries/lab0_table.md` |
| Row height, track pitch | `TECH_LEF` (site, layer pitches) and `CELL_LEF` (cell sizes) |

Next: answer the questions in [labs/lab0_libraries/README.md](../../../labs/lab0_libraries/README.md), then follow its Next link.
