#!/usr/bin/env python3
# File:        collect_qor.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Writes qor.csv, one row per corner: clock period, slack (PrimeTime sta_<corner>.txt), area and leakage (Design Compiler synth_area.rpt, synth_power.rpt).

import argparse
import csv
import re
import sys
from pathlib import Path

COLUMNS = ["design", "library", "corner", "period_ns", "setup_wns_ns", "setup_tns_ns",
           "hold_wns_ns", "hold_tns_ns", "area_um2", "cell_count", "leakage"]


def area(build: Path) -> tuple[str, str]:
    """(total cell area, number of cells) from report_area."""
    text = (build / "synth_area.rpt").read_text()
    a = re.search(r"Total cell area:\s+([\d.]+)", text)
    n = re.search(r"Number of cells:\s+(\d+)", text)
    return (a.group(1) if a else "", n.group(1) if n else "")


def leakage(build: Path) -> str:
    """'<value> <unit>' from report_power at the synthesis corner, or '' without that report."""
    rpt = build / "synth_power.rpt"
    if not rpt.exists():
        return ""
    m = re.search(r"Cell Leakage Power\s*=\s*([-+.\deE]+)\s*(\w+)", rpt.read_text())
    return f"{m.group(1)} {m.group(2)}" if m else ""


def sta(build: Path, corner: str) -> dict[str, str]:
    """key -> value from the summary sta.tcl writes (one 'key value' per line)."""
    values = {}
    for line in (build / f"sta_{corner}.txt").read_text().splitlines():
        key, _, value = line.partition(" ")
        values[key] = value.strip()
    return values


def main() -> int:
    ap = argparse.ArgumentParser(description="Collect area and slack into qor.csv.")
    ap.add_argument("--build", required=True, type=Path, help="build folder")
    ap.add_argument("--design", required=True)
    ap.add_argument("--library", required=True)
    ap.add_argument("--corners", nargs="+", default=["tt", "ss", "ff"])
    ap.add_argument("--out", required=True, type=Path)
    a = ap.parse_args()

    cell_area, cells = area(a.build)
    leak = leakage(a.build)
    with a.out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        for corner in a.corners:
            s = sta(a.build, corner)
            w.writerow({"design": a.design, "library": a.library, "corner": corner,
                        "period_ns": s.get("period_ns", ""),
                        "setup_wns_ns": s.get("setup_wns_ns", ""), "setup_tns_ns": s.get("setup_tns_ns", ""),
                        "hold_wns_ns": s.get("hold_wns_ns", ""), "hold_tns_ns": s.get("hold_tns_ns", ""),
                        "area_um2": cell_area, "cell_count": cells, "leakage": leak})
    return 0


if __name__ == "__main__":
    sys.exit(main())
