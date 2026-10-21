#!/usr/bin/env python3
# File:        collect_qor.py
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Collects area, slack, leakage and runtimes from a build directory into qor.csv, one row per corner.

import argparse
import csv
import json
import subprocess
from pathlib import Path

COLUMNS = ["design", "platform", "corner", "period_ns", "wns_ns", "tns_ns", "hold_wns_ns",
           "area_um2", "cell_count", "seq_cells", "leakage", "synth_runtime_s",
           "sta_runtime_s", "git_sha"]


def git_sha(path: Path) -> str:
    try:
        out = subprocess.run(["git", "-C", str(path), "rev-parse", "--short=10", "HEAD"],
                             capture_output=True, text=True, check=True).stdout.strip()
        dirty = subprocess.run(["git", "-C", str(path), "status", "--porcelain"],
                               capture_output=True, text=True, check=True).stdout.strip()
        return out + ("-dirty" if dirty else "")
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"


def runtimes(build: Path) -> dict:
    t = {}
    f = build / "runtimes.txt"
    if f.exists():
        for line in f.read_text().splitlines():
            stage, secs = line.split()
            t[stage] = float(secs)
    return t


def fmt(x, digits=4):
    if isinstance(x, (int, float)):
        return f"{x:.{digits}f}" if isinstance(x, float) else str(x)
    return str(x)


def main() -> None:
    ap = argparse.ArgumentParser(description="Collect QoR numbers into qor.csv (one row per corner).",
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--build", required=True, type=Path)
    ap.add_argument("--design", required=True)
    ap.add_argument("--platform", required=True)
    ap.add_argument("--corners", nargs="+", required=True)
    ap.add_argument("--out", required=True, type=Path)
    a = ap.parse_args()

    stat = json.loads((a.build / "synth_stat.json").read_text())["design"]
    times = runtimes(a.build)
    sha = git_sha(Path(__file__).resolve().parent)

    rows = []
    for corner in a.corners:
        sta = json.loads((a.build / f"sta_{corner}.json").read_text())
        rows.append({
            "design": a.design,
            "platform": a.platform,
            "corner": corner,
            "period_ns": fmt(float(sta["period_ns"]), 3),
            "wns_ns": fmt(float(sta["setup_ws_ns"]), 4),
            "tns_ns": fmt(float(sta["setup_tns_ns"]), 4),
            "hold_wns_ns": fmt(float(sta["hold_ws_ns"]), 4),
            "area_um2": fmt(float(stat["area"]), 2),
            "cell_count": stat["num_cells"],
            "seq_cells": sta["seq_cells"],
            "leakage": f"{float(sta['leakage_w']):.4e}",
            "synth_runtime_s": fmt(times.get("synth", float("nan")), 2),
            "sta_runtime_s": fmt(times.get(f"sta_{corner}", float("nan")), 2),
            "git_sha": sha,
        })

    with a.out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main()
