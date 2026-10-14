# Lab 0 — Library literacy (week 1)

**Goal:** understand the [standard-cell libraries](../../docs/02_glossary.md#standard-cell-library) that synthesis picks from.
Read [03 — Reading a Liberty file](../../docs/03_liberty.md) first.

Commands for your track: its `track/lab0.md` ([tracks/README.md](../../tracks/README.md)). Run them, and the commands below, from your track's folder (`tracks/<track>`).

## 0. Environment

- Set up your track's tools (its `track/README.md`).
- Run the whole flow once on `gcd`, the small design from Lab 1.
- It finishes without an error. Target: under an hour. If it takes longer, tell your mentor what was slow.

## 1. Parse a Liberty file — `libs/lab0/parse_lib.py`

Fill in the `TODO`s. The command line is defined at the bottom of the file.
`libs/lab0/platforms.py` lists your track's libraries (from its `track/libraries.yaml`) and prints the path of one file.

```
python3 ../../libs/lab0/platforms.py                                  # libraries and corners
pytest ../../libs/lab0                                                # self-check
python3 ../../libs/lab0/parse_lib.py summary $(python3 ../../libs/lab0/platforms.py <library> tt)
python3 ../../libs/lab0/parse_lib.py table   $(python3 ../../libs/lab0/platforms.py <library> tt) <inverter cell> Y A cell_rise
```

## 2. Plots — `libs/lab0/plot_delays.py`

`python3 ../../libs/lab0/plot_delays.py` writes PNGs to your track's `build/lab0/`:

- `inv_1`, `inv_4`, `nand2_1` in every library of your track at `tt`: delay vs. output load, and delay vs. input slew.
- `inv_1` of the first library at `tt`, `ss` and `ff`.

Answer:

- Three sentences on the order of the three corner curves.
- Why is `inv_4`'s delay-vs-load slope about a quarter of `inv_1`'s?

## 3. Table — `lab0_table.md`

```
python3 ../../libs/lab0/make_table.py > ../../labs/lab0_libraries/lab0_table.md
```

Under the table, explain:

- why a cell with a higher drive strength has more area and more input capacitance,
- if your track has more than one library: why the same function costs a different area in each (for example 2–4× more in gf180 than in sky130, or more in hs than in hd).

## 4. Physical views

Open each library's technology LEF and cell LEF (your track's `track/lab0.md` says where they are).
Find the standard-cell `SITE` (its `SIZE`) and the `PITCH` of the first signal metal layer.

One paragraph: what is a routing "track" (nothing to do with your course track), how many tracks tall is each library's row, and what does a taller row buy (and cost)?

## Exit check (mentor)

Do one NLDM table lookup by hand (slew and load between table points) and compare it with `parse_lib.py lookup`.

## Deliverables

| File | What |
|---|---|
| `libs/lab0/parse_lib.py` | passes `pytest ../../libs/lab0` (run from your track folder) |
| `tracks/<track>/build/lab0/*.png` | copy the plots you discuss into your report |
| `labs/lab0_libraries/lab0_table.md` | the table and your answers from §2, §3 and §4 |

Next: [04 — Synthesis and its common problems](../../docs/04_synthesis.md)
