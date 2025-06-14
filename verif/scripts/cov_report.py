#!/usr/bin/env python3
# File:        cov_report.py
# Author:      Isaac Hagedorn
# Date:        2025-06-14
# Description: Prints functional coverage (or, with --code, rtl/ line and toggle coverage) from a Verilator coverage.dat.
import argparse
import collections
import os
import re
import sys


def parse(path):
    """Yield (fields dict, count) for every record in a Verilator coverage file."""
    rec = re.compile(r"^C '(.*)' (\d+)\s*$")
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = rec.match(line)
            if not m:
                continue
            fields = {}
            for kv in m.group(1).split("\x01"):
                if "\x02" in kv:
                    k, v = kv.split("\x02", 1)
                    fields[k] = v
            yield fields, int(m.group(2))


def code_report(path):
    """Line and toggle coverage per RTL file, merged over instances (a line counts once)."""
    per = collections.defaultdict(lambda: collections.defaultdict(dict))   # file -> type -> point -> hits
    for f, count in parse(path):
        fn = f.get("f", "")
        if "/rtl/" not in fn or f.get("t") not in ("line", "toggle", "branch"):
            continue
        key = (f.get("l"), f.get("n"), f.get("o"), f.get("S"))
        d = per[os.path.relpath(fn)][f["t"]]
        d[key] = d.get(key, 0) + count
    if not per:
        print(f"no rtl/ line/toggle records in {path} (build with CODECOV=1)")
        return 1
    print(f"Code coverage (rtl/ only): {path}\n")
    print(f"{'file':<34} {'line':>16} {'toggle':>16}")
    for fn in sorted(per):
        cells = []
        for t in ("line", "toggle"):
            pts = per[fn].get(t, {})
            hit = sum(1 for c in pts.values() if c > 0)
            cells.append(f"{100.0 * hit / len(pts):5.1f}% ({hit}/{len(pts)})" if pts else "-")
        print(f"{fn:<34} {cells[0]:>16} {cells[1]:>16}")
        miss = sorted({int(k[0]) for k, c in per[fn].get("line", {}).items() if c == 0})
        if miss:
            print(f"    lines never executed: {miss}")
    return 0


def main():
    ap = argparse.ArgumentParser(description='Coverage report from a Verilator coverage.dat.')
    ap.add_argument("dat", help="coverage.dat or merged.dat")
    ap.add_argument("--no-holes", action="store_true", help="do not list unhit bins")
    ap.add_argument("--min", type=int, default=1, help="hits needed for a bin to count (default 1)")
    ap.add_argument("--code", action="store_true", help="report line/toggle coverage of files under rtl/ instead")
    args = ap.parse_args()
    if args.code:
        return code_report(args.dat)

    # hierarchy: covergroup -> point -> bin -> count
    groups = collections.OrderedDict()
    for f, count in parse(args.dat):
        if f.get("t") != "covergroup":
            continue
        h = f.get("h", "")                       # __vlAnonCG_<cg>.<point>.<bin>
        parts = h.split(".", 2)
        if len(parts) < 3:
            continue
        cg = re.sub(r"^__vlAnonCG_", "", parts[0])
        point, binname = parts[1], parts[2]
        groups.setdefault(cg, collections.OrderedDict()).setdefault(point, collections.OrderedDict())
        groups[cg][point][binname] = groups[cg][point].get(binname, 0) + count

    if not groups:
        print(f"no covergroup records in {args.dat} (built with COV=1?)")
        return 1

    tot_hit = tot_bins = 0
    holes = []
    print(f"Functional coverage: {args.dat}\n")
    for cg, points in groups.items():
        g_hit = sum(1 for p in points.values() for c in p.values() if c >= args.min)
        g_bins = sum(len(p) for p in points.values())
        tot_hit += g_hit
        tot_bins += g_bins
        print(f"{cg:<28} {100.0 * g_hit / g_bins:6.1f}%  ({g_hit}/{g_bins})")
        for point, bins in points.items():
            p_hit = sum(1 for c in bins.values() if c >= args.min)
            print(f"    {point:<24} {100.0 * p_hit / len(bins):6.1f}%  ({p_hit}/{len(bins)})")
            holes += [f"{cg}.{point}.{b}" for b, c in bins.items() if c < args.min]
    print(f"\n{'TOTAL':<28} {100.0 * tot_hit / tot_bins:6.1f}%  ({tot_hit}/{tot_bins})")
    if holes and not args.no_holes:
        print(f"\nUnhit bins ({len(holes)}):")
        for h in holes:
            print(f"    {h}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
