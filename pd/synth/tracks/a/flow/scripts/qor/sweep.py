#!/usr/bin/env python3
# File:        sweep.py
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Clock-period sweep: reruns make synth sta at several periods and tabulates slack and area. Can also search for the shortest passing period (--find-min).

import argparse
import csv
import json
import math
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def sdc_period(pdk: str, design: str) -> float:
    out = subprocess.run(["make", "-s", "-C", str(ROOT), "info", f"PDK={pdk}", f"DESIGN={design}"],
                         capture_output=True, text=True, check=True).stdout
    for line in out.splitlines():
        if line.startswith("SDC="):
            return float(line.split("period=")[1].split()[0])
    raise SystemExit("could not read the SDC period from `make info`")


def run_point(pdk: str, design: str, period: float, extra: list[str]) -> dict:
    p = f"{period:g}"
    build = ROOT / "build" / design / f"{pdk}_p{p}"
    cmd = ["make", "-s", "-C", str(ROOT), "synth", "sta", f"PDK={pdk}", f"DESIGN={design}",
           f"CLOCK_PERIOD={p}", "CORNERS=ss ff", *extra]
    r = subprocess.run(cmd, capture_output=True, text=True)
    row = {"period_ns": period, "build": str(build.relative_to(ROOT))}
    if r.returncode != 0:
        row["error"] = (r.stdout + r.stderr).strip().splitlines()[-1:] or ["make failed"]
        return row
    ss = json.loads((build / "sta_ss.json").read_text())
    ff = json.loads((build / "sta_ff.json").read_text())
    stat = json.loads((build / "synth_stat.json").read_text())["design"]
    row.update(
        wns_ss=float(ss["setup_ws_ns"]), tns_ss=float(ss["setup_tns_ns"]),
        hold_wns_ff=float(ff["hold_ws_ns"]), area_um2=float(stat["area"]),
        cells=int(stat["num_cells"]), unconstrained=int(ss["unconstrained_endpoints"]),
    )
    row["pass"] = row["wns_ss"] >= 0 and row["hold_wns_ff"] >= 0 and row["unconstrained"] == 0
    return row


def show(rows: list[dict]) -> None:
    print(f"{'period_ns':>9} {'wns_ss':>9} {'tns_ss':>10} {'hold_ff':>8} {'area_um2':>10} {'cells':>6}  result")
    for r in sorted(rows, key=lambda r: -r["period_ns"]):
        if "error" in r:
            print(f"{r['period_ns']:>9g}  ERROR: {r['error'][0]}")
            continue
        print(f"{r['period_ns']:>9g} {r['wns_ss']:>9.3f} {r['tns_ss']:>10.3f} {r['hold_wns_ff']:>8.3f} "
              f"{r['area_um2']:>10.1f} {r['cells']:>6}  {'PASS' if r['pass'] else 'fail'}")


def main() -> None:
    ap = argparse.ArgumentParser(description="Clock-period sweep: rerun synth and sta at several periods.",
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pdk", required=True)
    ap.add_argument("--design", required=True)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--factors", nargs="+", type=float, help="multiples of the SDC period")
    g.add_argument("--periods", nargs="+", type=float, help="periods in ns")
    g.add_argument("--find-min", action="store_true", help="search for the shortest passing period")
    ap.add_argument("--step", type=float, default=0.05, help="--find-min resolution in ns (default 0.05)")
    ap.add_argument("--hi", type=float, help="--find-min: a period that passes (default: grow from the SDC's)")
    ap.add_argument("--jobs", type=int, default=4, help="points run in parallel (default 4)")
    ap.add_argument("--csv", type=Path, help="write the table here too")
    ap.add_argument("make_args", nargs="*", help="extra make variables, e.g. ABC_CONSTR=0")
    a = ap.parse_args()

    rows = []
    if a.find_min:
        step = a.step
        snap = lambda x: round(round(x / step) * step, 6)
        hi = snap(a.hi or sdc_period(a.pdk, a.design))
        # grow until a period passes, then bisect on the step grid
        while True:
            r = run_point(a.pdk, a.design, hi, a.make_args); rows.append(r)
            if r.get("pass"):
                break
            if "error" in r:
                show(rows); sys.exit(1)
            hi = snap(hi * 1.5 + step)
        lo = snap(max(step, hi / 4))
        while hi - lo > step * 1.5:
            mid = snap((hi + lo) / 2)
            r = run_point(a.pdk, a.design, mid, a.make_args); rows.append(r)
            if r.get("pass"):
                hi = mid
            else:
                lo = mid
        show(rows)
        print(f"\nshortest passing period: {hi:g} ns  ({a.pdk}, {a.design}, step {step:g} ns)")
    else:
        base = sdc_period(a.pdk, a.design) if a.factors else 1.0
        periods = [round(base * f, 6) for f in (a.factors or a.periods)]
        with ThreadPoolExecutor(max_workers=a.jobs) as ex:
            rows = list(ex.map(lambda p: run_point(a.pdk, a.design, p, a.make_args), periods))
        show(rows)
        passing = [r["period_ns"] for r in rows if r.get("pass")]
        print(f"\nshortest passing period in this sweep: {min(passing):g} ns" if passing
              else "\nno period in this sweep passes")

    if a.csv:
        with a.csv.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["period_ns", "wns_ss", "tns_ss", "hold_wns_ff", "area_um2",
                                              "cells", "unconstrained", "pass", "build", "error"])
            w.writeheader()
            w.writerows(sorted(rows, key=lambda r: -r["period_ns"]))


if __name__ == "__main__":
    main()
