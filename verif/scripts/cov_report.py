#!/usr/bin/env python3
# File:        cov_report.py
# Author:      Isaac Hagedorn
# Date:        2025-06-14
# Description: Prints functional coverage (or, with --code, code coverage of the design) from a Verilator coverage.dat
#              or, with --urg, from a VCS URG text report.
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


def print_groups(source, groups, holes, show_holes):
    """groups: covergroup -> point -> (bins hit, bins); holes: 'cg.point.bin' names."""
    tot_hit = tot_bins = 0
    print(f"Functional coverage: {source}\n")
    for cg, points in groups.items():
        g_hit = sum(h for h, _ in points.values())
        g_bins = sum(n for _, n in points.values())
        tot_hit += g_hit
        tot_bins += g_bins
        print(f"{cg:<28} {100.0 * g_hit / max(g_bins, 1):6.1f}%  ({g_hit}/{g_bins})")
        for point, (p_hit, p_bins) in points.items():
            print(f"    {point:<24} {100.0 * p_hit / max(p_bins, 1):6.1f}%  ({p_hit}/{p_bins})")
    print(f"\n{'TOTAL':<28} {100.0 * tot_hit / max(tot_bins, 1):6.1f}%  ({tot_hit}/{tot_bins})")
    if holes and show_holes:
        print(f"\nUnhit bins ({len(holes)}):")
        for h in holes:
            print(f"    {h}")


def urg_groups(report):
    """Covergroups, coverpoints/crosses and unhit bins from URG's grpinfo.txt."""
    groups, holes = collections.OrderedDict(), []
    group = point = table = header = None
    with open(os.path.join(report, "grpinfo.txt"), encoding="utf-8", errors="replace") as fh:
        for line in fh:
            s = line.strip()
            m = re.match(r"Group : (\S+)", s)
            if m:
                group = m.group(1).split("::")[-1]
                groups.setdefault(group, collections.OrderedDict())
                table = None
                continue
            if re.match(r"(Variables|Crosses) for Group", s):
                table = "points"
                continue
            m = re.match(r"Summary for (?:Variable|Cross) (\S+)", s)
            if m:
                point, table = m.group(1), None
                continue
            if s == "Uncovered bins":
                table, header = "holes", None
                continue
            if not s:
                if table == "holes" and header:
                    table = None
                continue
            cols = s.split()
            if table == "points" and len(cols) >= 5 and cols[1].isdigit():
                groups[group][cols[0]] = (int(cols[3]), int(cols[1]))   # covered, expected
            elif table == "holes":
                if header is None:
                    header = cols                                       # NAME (or crossed points) COUNT ...
                else:
                    holes.append(f"{group}.{point}.{' '.join(cols[:header.index('COUNT')])}")
    return groups, holes


def urg_code(report):
    """The DUT instance's row from URG's hierarchy.txt (scores for the DUT and everything below it)."""
    path = os.path.join(report, "hierarchy.txt")
    if not os.path.exists(path):
        print(f"no code coverage in {report} (run make regress CODECOV=1, then make cov-code CODECOV=1)")
        return 1
    header = None
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            cols = line.split()
            if cols[:1] == ["SCORE"]:
                header = cols
            elif header and len(cols) == len(header) + 1 and cols[-1] == "dut":
                print(f"Code coverage of the DUT (tb_top.dut): {report}\n")
                print("  ".join(f"{c:>6}" for c in header))
                print("  ".join(f"{c:>6}" for c in cols[:-1]))
                print(f"\nUncovered lines, conditions, toggles and branches per module: {report}/modinfo.txt")
                return 0
    print(f"no tb_top.dut instance in {path}")
    return 1


def main():
    ap = argparse.ArgumentParser(description='Coverage report from a Verilator coverage.dat or a VCS URG report.')
    ap.add_argument("dat", nargs="?", help="coverage.dat or merged.dat (Verilator)")
    ap.add_argument("--urg", metavar="DIR", help="URG text report directory (VCS) instead of a .dat file")
    ap.add_argument("--no-holes", action="store_true", help="do not list unhit bins")
    ap.add_argument("--min", type=int, default=1, help="hits needed for a bin to count (default 1; Verilator)")
    ap.add_argument("--code", action="store_true", help="report code coverage of the design instead")
    args = ap.parse_args()
    if args.urg:
        if args.code:
            return urg_code(args.urg)
        groups, holes = urg_groups(args.urg)
        if not groups:
            print(f"no covergroups in {args.urg}")
            return 1
        print_groups(args.urg, groups, holes, not args.no_holes)
        return 0
    if not args.dat:
        ap.error("give a coverage .dat file or --urg DIR")
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

    summary = collections.OrderedDict(
        (cg, collections.OrderedDict((point, (sum(1 for c in bins.values() if c >= args.min), len(bins)))
                                     for point, bins in points.items()))
        for cg, points in groups.items())
    holes = [f"{cg}.{point}.{b}" for cg, points in groups.items() for point, bins in points.items()
             for b, c in bins.items() if c < args.min]
    print_groups(args.dat, summary, holes, not args.no_holes)
    return 0


if __name__ == "__main__":
    sys.exit(main())
