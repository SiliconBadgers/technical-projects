#!/usr/bin/env python3
# File:        plot_delays.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Lab 0 plots of cell delay (mean of cell_rise/cell_fall) vs. output load and input slew. Writes PNGs to your track's build/lab0/.
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from parse_lib import Library  # noqa: E402
from platforms import ROOT, SPEC_PLATFORMS, TRACK, cell_name, lib_path  # noqa: E402

import matplotlib  # noqa: E402
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

LOADS = np.linspace(0.001, 0.18, 40)    # pF
SLEWS = np.linspace(0.02, 1.5, 40)      # ns


def delay(lib: Library, cell: str, slew: float, load: float) -> float:
    c = lib.cell(cell)
    out, inp = c.outputs()[0].name, c.inputs()[0].name
    return 0.5 * (c.table(out, inp, "cell_rise").lookup(slew, load)
                  + c.table(out, inp, "cell_fall").lookup(slew, load))


def main() -> int:
    ap = argparse.ArgumentParser(description="Lab 0 plots: cell delay vs. output load and input slew, written to your track's build/lab0/.")
    ap.add_argument("--platforms", nargs="+", default=SPEC_PLATFORMS)
    ap.add_argument("--cells", nargs="+", default=["inv_1", "inv_4", "nand2_1"],
                    help="<role>_<drive>, role one of inv, nand2, buf")
    ap.add_argument("--slew", type=float, default=0.1, help="fixed input slew (ns) for the load sweep")
    ap.add_argument("--load", type=float, default=0.01, help="fixed output load (pF) for the slew sweep")
    ap.add_argument("--corner-platform", default=None, help="library for the corner plot (default: the first one)")
    ap.add_argument("--corner-cell", default="inv_1")
    ap.add_argument("--out", type=Path, default=TRACK / "build" / "lab0")
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)

    libs = {p: Library.load(lib_path(p, "tt")) for p in a.platforms}
    for spec in a.cells:
        role, drive = spec.rsplit("_", 1)
        for sweep, xs, xlabel in (("load", LOADS, "output load (pF)"), ("slew", SLEWS, "input slew (ns)")):
            fig, ax = plt.subplots(figsize=(6, 4))
            for p, lib in libs.items():
                name = cell_name(p, role, int(drive))
                ys = [delay(lib, name, a.slew, x) if sweep == "load" else delay(lib, name, x, a.load) for x in xs]
                ax.plot(xs, ys, label=f"{p} ({name.split('__')[-1]})")
            fixed = f"input slew {a.slew:g} ns" if sweep == "load" else f"output load {a.load:g} pF"
            ax.set(xlabel=xlabel, ylabel="delay (ns), mean of rise/fall",
                   title=f"{spec} at tt, {fixed}")
            ax.grid(True, alpha=0.3)
            ax.legend()
            fig.tight_layout()
            path = a.out / f"{spec}_vs_{sweep}.png"
            fig.savefig(path, dpi=120)
            plt.close(fig)
            print(f"wrote {path.relative_to(ROOT)}")

    p = a.corner_platform or a.platforms[0]
    role, drive = a.corner_cell.rsplit("_", 1)
    name = cell_name(p, role, int(drive))
    fig, ax = plt.subplots(figsize=(6, 4))
    for corner in ("ss", "tt", "ff"):
        lib = Library.load(lib_path(p, corner))
        cv = lib.corner
        ax.plot(LOADS, [delay(lib, name, a.slew, x) for x in LOADS],
                label=f"{corner}: {cv['voltage']:g} V, {cv['temperature']:g} C")
    ax.set(xlabel="output load (pF)", ylabel="delay (ns), mean of rise/fall",
           title=f"{name} across corners, input slew {a.slew:g} ns")
    ax.grid(True, alpha=0.3)
    ax.legend()
    fig.tight_layout()
    path = a.out / f"corners_{p}_{a.corner_cell}.png"
    fig.savefig(path, dpi=120)
    print(f"wrote {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
