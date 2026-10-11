#!/usr/bin/env python3
# File:        qor.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Collects period, slack, area, cell counts, leakage and runtimes from a Track B1 build folder into qor.csv, one row per corner.
#              The report parsers here are also used by check.py.

import argparse
import csv
import re
import subprocess
from pathlib import Path

COLUMNS = ["design", "platform", "corner", "period_ns", "wns_ns", "tns_ns", "hold_wns_ns",
           "area_um2", "cell_count", "seq_cells", "leakage", "synth_runtime_s",
           "sta_runtime_s", "git_sha"]
NUM = r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"


def read(path: Path) -> str:
    return path.read_text(errors="replace") if path.exists() else ""


def sta_summary(build: Path) -> dict:
    """sta_summary.txt from Tempus: {(corner, check): (wns, tns)}, plus 'period_ns' and 'reset_port_async_pins'."""
    out = {}
    for line in read(build / "sta_summary.txt").splitlines():
        f = line.split()
        if not f or f[0].startswith("#"):
            continue
        if len(f) == 4:
            out[(f[0], f[1])] = (f[2], f[3])
        elif len(f) == 2:
            out[f[0]] = f[1]
    return out


def path1_slack(report: str) -> str:
    """Slack of the first path in a Tempus timing report (text), 'INF' if it has no path, '' if unreadable."""
    m = re.search(rf"Path 1:\s*(?:MET|VIOLATED)\s*\(\s*({NUM})", report)
    if m:
        return m.group(1)
    m = re.search(rf"Slack(?: Time)?\s*:?=?\s*({NUM})", report)
    if m:
        return m.group(1)
    return "INF" if re.search(r"No (constrained )?(timing )?paths", report, re.I) else ""


def slack(build: Path, corner: str, check: str) -> tuple[str, str]:
    """(wns, tns) in ns for setup or hold at one corner; text report as a fallback."""
    wns, tns = sta_summary(build).get((corner, check), ("NA", "NA"))
    if wns == "NA":
        wns, tns = path1_slack(read(build / f"sta_{corner}_{check}.rpt")), ""
    return wns, tns


def period_ns(build: Path) -> str:
    p = sta_summary(build).get("period_ns", "NA")
    if p != "NA":
        return p
    sdc = read(build / "constraints.sdc")
    m = re.search(rf"^\s*set\s+clk_period\s+({NUM})\s*(?:;|#|$)", sdc, re.M) or \
        re.search(rf"create_clock\b[^\n]*-period\s+({NUM})", sdc)
    return m.group(1) if m else ""


def area(build: Path, top: str) -> tuple[str, str, str]:
    """(area um^2, cell count, sequential cells) from Genus report_gates, else report_area."""
    gates = read(build / "gates.rpt")
    total = re.search(rf"^\s*total\s+(\d+)\s+({NUM})", gates, re.M)
    seq = re.search(r"^\s*sequential\s+(\d+)", gates, re.M)
    if total:
        return total.group(2), total.group(1), seq.group(1) if seq else ""
    m = re.search(rf"^\s*{re.escape(top)}\s+(?:\S+\s+)?(\d+)\s+({NUM})", read(build / "area.rpt"), re.M)
    return (m.group(2), m.group(1), seq.group(1) if seq else "") if m else ("", "", "")


def leakage_w(build: Path, top: str) -> str:
    """Leakage power in W from Genus report_power (Subtotal row in W, or the top row in nW)."""
    txt = read(build / "power.rpt")
    m = re.search(rf"^\s*Subtotal\s+({NUM})", txt, re.M)
    if m:
        return f"{float(m.group(1)):.4e}"
    m = re.search(rf"^\s*{re.escape(top)}\s+\d+\s+({NUM})", txt, re.M)
    return f"{float(m.group(1)) * 1e-9:.4e}" if m else ""


def runtimes(build: Path) -> dict:
    t = {}
    for line in read(build / "runtimes.txt").splitlines():
        f = line.split()
        if len(f) == 2:
            t[f[0]] = f[1]       # the last run of a step wins
    return t


def git_sha(path: Path) -> str:
    try:
        sha = subprocess.run(["git", "-C", str(path), "rev-parse", "--short=10", "HEAD"],
                             capture_output=True, text=True, check=True).stdout.strip()
        dirty = subprocess.run(["git", "-C", str(path), "status", "--porcelain"],
                               capture_output=True, text=True, check=True).stdout.strip()
        return sha + ("-dirty" if dirty else "")
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"


def main() -> None:
    ap = argparse.ArgumentParser(description="Collect QoR numbers into qor.csv (one row per corner).")
    ap.add_argument("--build", required=True, type=Path)
    ap.add_argument("--design", required=True)
    ap.add_argument("--top", default=None, help="top module (default: --design)")
    ap.add_argument("--library", required=True)
    ap.add_argument("--corners", nargs="+", required=True)
    ap.add_argument("--synth-corner", default="ss", help="Genus mapped at this corner; leakage is reported there")
    ap.add_argument("--out", required=True, type=Path)
    a = ap.parse_args()

    top = a.top or a.design
    um2, cells, seq = area(a.build, top)
    leak = leakage_w(a.build, top)
    times = runtimes(a.build)
    sha = git_sha(Path(__file__).resolve().parent)
    rows = []
    for corner in a.corners:
        wns, tns = slack(a.build, corner, "setup")
        hold, _ = slack(a.build, corner, "hold")
        rows.append({
            "design": a.design, "platform": a.library, "corner": corner,
            "period_ns": period_ns(a.build), "wns_ns": wns, "tns_ns": tns, "hold_wns_ns": hold,
            "area_um2": um2, "cell_count": cells, "seq_cells": seq,
            "leakage": leak if corner == a.synth_corner else "",
            "synth_runtime_s": times.get("synth", ""), "sta_runtime_s": times.get("sta", ""),
            "git_sha": sha,
        })
    with a.out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main()
