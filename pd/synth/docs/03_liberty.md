# 03 — Reading a Liberty file

A [Liberty](02_glossary.md#liberty) file (`.lib`, sometimes gzipped as `.lib.gz`) is the datasheet of a [standard-cell library](02_glossary.md#standard-cell-library) at one [corner](02_glossary.md#corner-pvt).
Your synthesis tool reads it to choose cells. Your timing tool reads it to compute delays.

Analogy: a parts catalog. For every part it lists the size, the price in power, what it does, and how fast it is for a given job.

Find your track's files and open one:

```
python3 libs/lab0/platforms.py                 # every library and corner of your track
less $(python3 libs/lab0/platforms.py <library> tt)
```

For a `.lib.gz` file use `zless` instead of `less`.

## The header

The top of the file sets the units and the corner.

- `time_unit`, `capacitive_load_unit`, `leakage_power_unit`: every number in the file uses these. Check them before you compare two libraries.
- `nom_process`, `nom_temperature`, `nom_voltage`: the corner. It usually matches the file name, e.g. `tt_025C_1v80` = typical process, 25 °C, 1.80 V.

## Cells

Each `cell (...)` group describes one [cell](02_glossary.md#cell).

- `area`: cell area in µm².
- `cell_leakage_power`: [leakage](02_glossary.md#leakage) at this corner. Some libraries instead list `leakage_power` groups, one per input state.
- `pin (...)`: one per pin.
  - `direction`: input or output.
  - `capacitance`: the [load](02_glossary.md#load) this input puts on whatever drives it.
  - `function`: the output's logic, e.g. `"!A"` for an inverter.
- `timing ()` inside an output pin, with `related_pin`: one [timing arc](02_glossary.md#timing-arc) from that input to this output.
  - `cell_rise` / `cell_fall`: the delay when the output rises / falls.
  - `rise_transition` / `fall_transition`: the output [slew](02_glossary.md#slew-transition).
- Flip-flops have an `ff (...)` group (`clocked_on`, `next_state`) and [setup](02_glossary.md#setup) and [hold](02_glossary.md#hold) arcs on the data pin.

Cell names include a [drive strength](02_glossary.md#drive-strength): `..._inv_1`, `..._inv_4` in one library, `INVX1`, `INVX4` in another.

## Delay tables

A cell is slower when its input changes slowly and when its output drives a big load.
So delay and slew are not single numbers. They are 2-D lookup tables ([NLDM](02_glossary.md#nldm)) over input slew and output load:

```
cell_rise ("del_1_7_7") {
    index_1 ("...");
    index_2 ("...");
    values ("...", "...", ...);
}
```

- `values` has one row per `index_1` entry and one column per `index_2` entry.
- Which axis is slew and which is load is set by the `lu_table_template` of the same name near the top of the file.
- Between grid points, the timing tool [interpolates](02_glossary.md#interpolation) from the four surrounding entries (bilinear interpolation). Outside the grid it extrapolates.

Analogy: a table of travel times by distance and traffic. For a trip between two listed distances you estimate from the nearest rows and columns.

Lab 0's script prints a table and does a lookup:

```
python3 libs/lab0/parse_lib.py table  <lib> <cell> <out pin> <in pin> cell_rise
python3 libs/lab0/parse_lib.py lookup <lib> <cell> <out pin> <in pin> cell_rise --slew 0.04 --load 0.01
```

## Corners

One Liberty file per corner. The same cell has different delays in each.

| Corner | Process | Voltage | Temperature | Used for |
|---|---|---|---|---|
| `ss` | slow | low | hot | [setup](02_glossary.md#setup) |
| `tt` | typical | nominal | room | comparison only |
| `ff` | fast | high | cold | [hold](02_glossary.md#hold) |

Example, `sky130_fd_sc_hd`: `ss_100C_1v60`, `tt_025C_1v80`, `ff_n40C_1v95`.

Analogy: the same car on a hot day uphill with a heavy load (`ss`), and on a cool day downhill (`ff`). A schedule must work on both days.

## Physical views (LEF)

The `.lib` has no shapes. Those are in [LEF](02_glossary.md#lef) files:

- Technology LEF: the metal layers (width, pitch, direction) and the placement `SITE`.
- Cell LEF: each cell's outline (`SIZE`) and pin shapes.

Synthesis does not need LEF. Physical design does. Lab 0 asks you to look at both.

Next: [Lab 0 — Library literacy](../labs/lab0_libraries/README.md)
