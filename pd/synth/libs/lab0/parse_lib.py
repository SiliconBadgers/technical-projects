#!/usr/bin/env python3
# File:        parse_lib.py
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Lab 0 exercise: read a Liberty (.lib) file and report on its cells. Fill in every TODO and check with `pytest libs/lab0`.
from __future__ import annotations

import argparse
import gzip
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
# parsed group g: g.args, g["attr"], g.get_groups(kind), g.get_group(kind, name), g.get_array(attr)
from liberty.parser import parse_liberty

TABLES = ("cell_rise", "cell_fall", "rise_transition", "fall_transition")


def _s(x) -> str:
    """liberty-parser keeps quotes on string values; drop them."""
    return str(x).strip().strip('"')


def _num(x) -> float | None:
    return None if x is None else float(_s(x))


@dataclass
class Table:
    """One NLDM lookup table: values[i][j] at (index_1[i], index_2[j])."""
    name: str
    var_1: str
    var_2: str
    index_1: np.ndarray
    index_2: np.ndarray
    values: np.ndarray

    def axes(self) -> tuple[np.ndarray, np.ndarray]:
        """(slew axis, load axis), whichever order the template uses."""
        if self.var_1.startswith("input_net_transition"):
            return self.index_1, self.index_2
        return self.index_2, self.index_1

    def lookup(self, slew: float, load: float) -> float:
        """TODO: return the value at (slew, load) by bilinear interpolation, as STA does.
        Outside the table, extrapolate linearly."""
        raise NotImplementedError("Table.lookup")


@dataclass
class Pin:
    name: str
    direction: str
    capacitance: float | None
    function: str | None
    _group: object
    _lib: "Library"

    def table(self, related_pin: str, kind: str) -> Table:
        """TODO: return the `kind` table (e.g. cell_rise) of the timing arc related_pin -> this pin.
        Indexes not in the table group come from its lu_table_template. Raise KeyError if there is no such table."""
        raise NotImplementedError("Pin.table")

    def related_pins(self) -> list[str]:
        return sorted({_s(t["related_pin"]) for t in self._group.get_groups("timing")})


@dataclass
class Cell:
    name: str
    area: float
    leakage: float | None
    _group: object
    _lib: "Library"

    @property
    def pins(self) -> list[Pin]:
        """TODO: return one Pin per `pin` group (direction, capacitance, function)."""
        raise NotImplementedError("Cell.pins")

    def pin(self, name: str) -> Pin:
        for p in self.pins:
            if p.name == name:
                return p
        raise KeyError(f"{self.name} has no pin {name}")

    def inputs(self) -> list[Pin]:
        return [p for p in self.pins if p.direction == "input"]

    def outputs(self) -> list[Pin]:
        return [p for p in self.pins if p.direction == "output"]

    def table(self, out_pin: str, related_pin: str, kind: str = "cell_rise") -> Table:
        return self.pin(out_pin).table(related_pin, kind)

    def is_sequential(self) -> bool:
        return bool(self._group.get_groups("ff") or self._group.get_groups("latch"))


class Library:
    def __init__(self, raw, path: Path):
        self._raw = raw
        self.path = path
        self.name = _s(raw.args[0])
        self._cells = {_s(c.args[0]): c for c in raw.get_groups("cell")}

    @classmethod
    def load(cls, path: str | Path) -> "Library":
        path = Path(path)
        opener = gzip.open if path.suffix == ".gz" else open
        with opener(path, "rt") as f:
            return cls(parse_liberty(f.read()), path)

    def attr(self, name: str):
        return self._raw[name]

    @property
    def units(self) -> dict[str, str]:
        """TODO: return {"time": "1ns", "capacitance": "1 pf", "leakage_power": "1nW", "voltage": "1V"}
        from time_unit, capacitive_load_unit, leakage_power_unit, voltage_unit."""
        raise NotImplementedError("Library.units")

    @property
    def corner(self) -> dict[str, float]:
        """TODO: return {"process", "voltage", "temperature"} as floats from the nom_* attributes."""
        raise NotImplementedError("Library.corner")

    def cell_names(self) -> list[str]:
        return sorted(self._cells)

    def cell(self, name: str) -> Cell:
        g = self._cells[name]
        return Cell(name, _num(g["area"]), self._leakage(g), g, self)

    @staticmethod
    def _leakage(g) -> float | None:
        """TODO: return cell_leakage_power. gf180 has none: use its `leakage_power`
        group without a `when`, else the mean over all of them."""
        raise NotImplementedError("Library._leakage")

    def drive_strengths(self, base: str) -> list[str]:
        """TODO: return the cell names <base>_<n> sorted by n (e.g. ..._inv_1, ..._inv_2, ..._inv_4)."""
        raise NotImplementedError("Library.drive_strengths")


# --- command line (given) ---
def _print_table(t: Table) -> None:
    print(f"{t.name}: rows = {t.var_1}, columns = {t.var_2}")
    print(" " * 10 + "".join(f"{v:>10.4g}" for v in t.index_2))
    for i, row in enumerate(t.values):
        print(f"{t.index_1[i]:>10.4g}" + "".join(f"{v:>10.4g}" for v in row))


def main() -> int:
    ap = argparse.ArgumentParser(description="Lab 0: read a Liberty (.lib) file and report on its cells.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("summary"); s.add_argument("lib")
    c = sub.add_parser("cell"); c.add_argument("lib"); c.add_argument("cell")
    t = sub.add_parser("table")
    for a in ("lib", "cell", "out_pin", "related_pin"):
        t.add_argument(a)
    t.add_argument("kind", nargs="?", default="cell_rise", choices=TABLES)
    lk = sub.add_parser("lookup")
    for a in ("lib", "cell", "out_pin", "related_pin"):
        lk.add_argument(a)
    lk.add_argument("kind", choices=TABLES)
    lk.add_argument("--slew", type=float, required=True, help="input transition, library time unit")
    lk.add_argument("--load", type=float, required=True, help="output load, library capacitance unit")
    a = ap.parse_args()

    lib = Library.load(a.lib)
    if a.cmd == "summary":
        print(f"library {lib.name}  ({len(lib.cell_names())} cells)")
        print("units:  " + ", ".join(f"{k} {v}" for k, v in lib.units.items()))
        print("corner: " + ", ".join(f"{k} {v:g}" for k, v in lib.corner.items()))
        return 0
    cell = lib.cell(a.cell)
    if a.cmd == "cell":
        print(f"{cell.name}: area {cell.area:g}, leakage {cell.leakage}  ({lib.units['leakage_power']})")
        for p in cell.pins:
            extra = f"cap {p.capacitance:g}" if p.capacitance is not None else ""
            if p.function:
                extra += f"  function {p.function}"
            if p.direction == "output":
                extra += f"  arcs from {', '.join(p.related_pins())}"
            print(f"  {p.direction:>8} {p.name:<8} {extra}")
        return 0
    table = cell.table(a.out_pin, a.related_pin, a.kind)
    if a.cmd == "table":
        _print_table(table)
        return 0
    print(f"{a.kind} {a.cell} {a.related_pin}->{a.out_pin} at slew {a.slew:g}, load {a.load:g}: "
          f"{table.lookup(a.slew, a.load):.5g} {lib.units['time']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
