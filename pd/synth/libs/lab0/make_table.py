#!/usr/bin/env python3
# File:        make_table.py
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Lab 0 table: area, input capacitance and drive strengths of INV, NAND2 and DFF in each library. Prints Markdown.
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from parse_lib import Library  # noqa: E402
from platforms import SPEC_PLATFORMS, cell_base, cell_name, lib_path  # noqa: E402

ROLES = [("inv", "INV"), ("nand2", "NAND2"), ("dff", "DFF")]


def drives(lib: Library, base: str) -> list[int]:
    if base.endswith("X"):           # sky130_scl_9T: INVX1, INVX2, ...
        return sorted(int(n[len(base):]) for n in lib.cell_names()
                      if n.startswith(base) and n[len(base):].isdigit())
    return [int(n.rsplit("_", 1)[1]) for n in lib.drive_strengths(base)]


def main() -> int:
    ap = argparse.ArgumentParser(description="Lab 0 Markdown table of INV, NAND2 and DFF per library.")
    ap.add_argument("--platforms", nargs="+", default=SPEC_PLATFORMS)
    ap.add_argument("--corner", default="tt")
    a = ap.parse_args()

    print(f"| Cell | Platform | Cell name | Area (um^2) | Input cap (pF) | Drive strengths |")
    print("|---|---|---|---|---|---|")
    for role, label in ROLES:
        for p in a.platforms:
            lib = Library.load(lib_path(p, a.corner))
            name = cell_name(p, role, 1)
            cell = lib.cell(name)
            # data inputs only (not the clock)
            pins = [x for x in cell.inputs() if x.name not in ("CLK", "CK")]
            caps = ", ".join(f"{x.name} {x.capacitance:.5g}" for x in pins)
            ds = drives(lib, cell_base(p, role))
            print(f"| {label} | {p} | {name} | {cell.area:.4g} | {caps} | {', '.join(map(str, ds))} |")
    return 0


if __name__ == "__main__":
    sys.exit(main())
