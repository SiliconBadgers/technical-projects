#!/usr/bin/env python3
# File:        check.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Track B1 checks (the course's sign-off list): reads the reports in one build folder, reruns no tool,
#              and prints PASS or FAIL per check. Run it with `make check DESIGN=<design>`.

import argparse
import csv
import fnmatch
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qor import COLUMNS, area, period_ns, read, slack, sta_summary  # noqa: E402

CHECKS = []


def check(name, doc, informational=False):
    def deco(fn):
        CHECKS.append((name, doc, informational, fn))
        return fn
    return deco


def need(c, name: str) -> str:
    p = c.build / name
    if not p.exists():
        raise FileNotFoundError(f"{p} does not exist: run the step that writes it (make all)")
    return read(p)


def junit(text: str) -> tuple[list[str], list[str]]:
    """(all test names, failed test names) from a cocotb results.xml."""
    names, failed = [], []
    for case in ET.fromstring(text).iter("testcase"):
        n = f"{case.get('classname')}.{case.get('name')}"
        names.append(n)
        if case.find("failure") is not None or case.find("error") is not None:
            failed.append(n)
    return names, failed


def count(text: str, label: str):
    """The number after a row label in a Genus summary table, or None if the row is missing."""
    m = re.search(rf"^\s*{label}\s+(\d+)\s*$", text, re.M)
    return int(m.group(1)) if m else None


def as_float(x: str) -> float:
    return float("inf") if x.upper().startswith("INF") else float(x)


def waivers(files: list[str]) -> list[tuple[str, str, str]]:
    """(message code, file pattern, signal pattern) per line of the waiver files; '#' starts a comment."""
    out = []
    for f in files:
        for line in read(Path(f)).splitlines():
            fields = line.split("#", 1)[0].split()
            if fields:
                fields += ["*"] * (3 - len(fields))   # no file or signal pattern: any
                out.append((fields[0], fields[1], fields[2]))
    return out


def signal(msg: str) -> str:
    """The first quoted name in a HAL message's text, without its bit select ('a_h[39:32]' -> 'a_h')."""
    m = re.search(r"'([^'\[]+)", msg.split("):", 1)[-1])
    return m.group(1).strip() if m else ""


@check("lint_clean", "../../docs/04_synthesis.md#lint")
def lint_clean(c):
    log = need(c, "lint.log")
    rc = re.search(r"SB: xrun exit status (\d+)", log)
    if not rc:
        return None, "lint.log is incomplete: rerun make lint", []
    if rc.group(1) in ("126", "127"):
        return False, "xrun did not run (not found or not executable): see track/README.md, Setup", []
    lines = [ln.strip() for ln in log.splitlines()]
    errors = [ln for ln in lines if re.search(r"\*[EF],", ln)]
    unwaived, waived = [], 0
    rules = waivers(c.lint_waivers)
    for ln in (x for x in lines if "*W," in x):
        m = re.search(r"\*W,(\w+)", ln)
        code = m.group(1) if m else ""
        m = re.search(r"\*W,\w+\s*\(([^,)]+)", ln)
        where = m.group(1) if m else ""
        name = signal(ln)
        if any(code == wcode and fnmatch.fnmatch(where, pat) and fnmatch.fnmatchcase(name, sig)
               for wcode, pat, sig in rules):
            waived += 1
        else:
            unwaived.append(ln)
    ok = not errors and not unwaived
    return ok, f"HAL: {len(errors)} error(s), {len(unwaived)} warning(s), {waived} waived", (errors + unwaived)[:15]


@check("rtl_sim", "labs/<lab>/README.md (testbench)")
def rtl_sim(c):
    names, failed = junit(need(c, "results.xml"))
    return bool(names) and not failed, f"{len(names) - len(failed)}/{len(names)} cocotb tests pass on the RTL", failed


@check("no_latches", "../../docs/04_synthesis.md#latches")
def no_latches(c):
    log = need(c, "synth.log")
    # Genus 25.1 echoes the sourced Tcl (`@file(synth.tcl) N: ... hdl_error_on_latch ...`) and prints
    # the CDFG-508 "Genus removes the flip-flop or latch inferred for an unused signal" help text when it
    # drops an unused register. Both carry "latch"+"infer" but are not a real inferred latch (which, with
    # hdl_error_on_latch true, hard-errors synthesis anyway). Skip those so they are not false positives.
    benign = re.compile(r"@file\(|hdl_error_on_latch|Genus removes the flip-flop or latch", re.I)
    inferred = sorted({ln.strip() for ln in log.splitlines() if re.search(r"latch", ln, re.I)
                       and re.search(r"infer", ln, re.I) and not benign.search(ln)})
    cells = re.findall(r"^\s*([A-Za-z_][\w$]*)\s+\S+\s*\(", read(c.build / "netlist.v"), re.M)
    latches = sorted({x for x in cells if any(fnmatch.fnmatch(x, p) for p in c.latch_cells)})
    ok = not inferred and not latches and (c.build / "netlist.v").exists()
    return ok, "no latch inferred, no latch cell in the netlist" if ok else \
        "a latch was inferred (or synthesis did not finish): see synth.log", inferred[:5] + latches


@check("design_check", "../../docs/04_synthesis.md#check")
def design_check(c):
    rpt, lint = need(c, "check_design.rpt"), need(c, "check_timing.rpt")
    rows = ["Unresolved References", r"Multidriven Port\(s\)", r"Multidriven Leaf Pin\(s\)",
            r"Multidriven hierarchical Pin\(s\)", r"Undriven Port\(s\)", r"Undriven Leaf Pin\(s\)"]
    found = {r.replace("\\", ""): count(rpt, r) for r in rows}
    found["Loop-breaking cells for combinational feedback"] = count(lint, "Loop-breaking cells for combinational feedback")
    missing = [k for k, v in found.items() if v is None]
    bad = [f"{k}: {v}" for k, v in found.items() if v]
    if missing:
        return None, "could not find these rows in check_design.rpt / check_timing.rpt; read them by hand", missing
    return not bad, "no unresolved modules, multiple drivers, undriven pins or loops" if not bad else \
        "structural problems: " + "; ".join(bad), bad


@check("no_unconstrained", "../../docs/05_sdc.md#unconstrained")
def no_unconstrained(c):
    lint = need(c, "check_timing.rpt")
    rows = {"unclocked flip-flops": "Sequential clock pins without clock waveform",
            "inputs without delay": "Inputs without clocked external delays",
            "outputs without delay": "Outputs without clocked external delays"}
    found = {k: count(lint, v) for k, v in rows.items()}
    if None in found.values():
        return None, "could not find the lint summary in check_timing.rpt; read it by hand", []
    # the asynchronous reset input may have no input delay if the SDC handles it another way (comment why)
    if c.reset_port and found["inputs without delay"] and re.search(rf"\b{re.escape(c.reset_port)}\b", lint):
        found["inputs without delay"] -= 1
    bad = {k: v for k, v in found.items() if v}
    return not bad, "every flip-flop is clocked and every port has a delay" if not bad else \
        f"unconstrained: {bad} (see check_timing.rpt)", []


@check("reset_sync", "../../docs/05_sdc.md#asynchronous-reset")
def reset_sync(c):
    if not c.reset_port:
        return True, "no asynchronous reset port declared (ASYNC_RESET_PORT): nothing to check", []
    n = int(sta_summary(c.build).get("reset_port_async_pins", "-1"))
    if n < 0:
        return False, "Tempus could not count the reset pins (see sta.log)", []
    ok = n <= c.reset_sync_flops
    return ok, f"{n} flip-flop reset/set pin(s) on {c.reset_port} directly" + \
        ("" if ok else ": the reset release is not synchronized to the clock"), []


@check("setup_ss", "../../docs/06_timing_reports.md#setup")
def setup_ss(c):
    need(c, "sta_ss_setup.rpt")
    wns, _ = slack(c.build, "ss", "setup")
    if not wns:
        return False, "could not read the setup slack at ss; read sta_ss_setup.rpt", []
    return as_float(wns) >= 0, f"worst setup slack at ss = {wns} ns (period {period_ns(c.build)} ns)", []


@check("hold_ff", "../../docs/06_timing_reports.md#hold")
def hold_ff(c):
    need(c, "sta_ff_hold.rpt")
    wns, _ = slack(c.build, "ff", "hold")
    if not wns:
        return False, "could not read the hold slack at ff; read sta_ff_hold.rpt", []
    return as_float(wns) >= 0, f"worst hold slack at ff = {wns} ns", []


@check("lec", "../../docs/07_equivalence.md")
def lec(c):
    log = need(c, "lec_run.log") + read(c.build / "lec.log")
    n = {k: [int(x) for x in re.findall(rf"No of {k} points\s*=\s*(\d+)", log)]
         for k in ("compare", "diff", "abort", "unknown")}
    if not n["compare"]:
        return False, "no compare-point summary in lec_run.log: Conformal did not finish", []
    total, diff, abort, unknown = (v[-1] if v else 0 for v in n.values())
    ok = total > 0 and diff == abort == unknown == 0
    return ok, f"Conformal: {total} compare points, {diff} non-equivalent, {abort} aborted, {unknown} unknown", []


@check("gls", "../../docs/08_gate_level_sim.md#gls")
def gls(c):
    names, failed = junit(need(c, "gls_results.xml"))
    rtl_names, _ = junit(need(c, "results.xml"))
    same = sorted(names) == sorted(rtl_names)
    msg = f"{len(names) - len(failed)}/{len(names)} cocotb tests pass on the netlist"
    return bool(names) and not failed and same, msg + ("" if same else "; not the same tests as the RTL run"), failed


@check("qor_columns", "../../docs/06_timing_reports.md#qor")
def qor_columns(c):
    need(c, "qor.csv")
    with (c.build / "qor.csv").open() as f:
        cols = next(csv.reader(f), [])
    missing = [x for x in COLUMNS if x not in cols]
    return not missing, "qor.csv has all columns" if not missing else f"qor.csv lacks {missing}", []


@check("target_tier", "labs/lab2_systolic/spec.md#targets", informational=True)
def target_tier(c):
    if not c.bronze_ns:
        return True, "no Lab 2 targets for this design", []
    um2 = float(area(c.build, c.top)[0] or "nan")
    period = float(period_ns(c.build) or "nan")
    ok = as_float(slack(c.build, "ss", "setup")[0] or "-1") >= 0 and as_float(slack(c.build, "ff", "hold")[0] or "-1") >= 0
    tier = "none"
    if ok and period <= float(c.silver_ns) * 1.00001:
        tier = "silver if area <= 1.25 x your Bronze area (gold also needs the 8x8 array)"
    elif ok and period <= float(c.bronze_ns) * 1.00001:
        tier = "bronze"
    return True, f"period {period:g} ns, area {um2:.0f} um^2, area x period = {um2 * period:.0f} -> {tier}", []


def main() -> int:
    ap = argparse.ArgumentParser(description="Track B1 checks. Run after `make all`.")
    ap.add_argument("--build", required=True, type=Path)
    ap.add_argument("--top", required=True)
    ap.add_argument("--latch-cells", default="", help="space-separated cell-name patterns")
    ap.add_argument("--async-reset-port", default="")
    ap.add_argument("--reset-sync-flops", type=int, default=2)
    ap.add_argument("--bronze-ns", default="")
    ap.add_argument("--silver-ns", default="")
    ap.add_argument("--only", nargs="*", help="run only these checks")
    ap.add_argument("--lint-waivers", default="", help="space-separated waiver files for lint_clean")
    ap.add_argument("--quiet", action="store_true", help="print failures only")
    ap.add_argument("--gate", action="store_true", help="a check that cannot read its report warns instead of failing")
    a = ap.parse_args()
    c = argparse.Namespace(build=a.build.resolve(), top=a.top, latch_cells=a.latch_cells.split(),
                           lint_waivers=a.lint_waivers.split(),
                           reset_port=a.async_reset_port, reset_sync_flops=a.reset_sync_flops,
                           bronze_ns=a.bronze_ns, silver_ns=a.silver_ns)
    failed = []
    for name, doc, informational, fn in CHECKS:
        if a.only and name not in a.only:
            continue
        try:
            ok, msg, details = fn(c)
        except (FileNotFoundError, ValueError, ET.ParseError) as e:
            ok, msg, details = False, str(e), []
        if informational:
            status = "INFO"
        elif ok is None:
            status = "WARN" if a.gate else "FAIL"
        else:
            status = "PASS" if ok else "FAIL"
        if status == "FAIL":
            failed.append(name)
        if status in ("FAIL", "WARN") or not a.quiet:
            print(f"{status:4}  {name:<16}  {msg}")
            if status == "FAIL":
                for d in details:
                    print(f"{'':24}{d}")
                print(f"{'':24}-> read {doc} and track/reading_logs.md")
    if not a.quiet:
        print(f"\n{'all checks OK' if not failed else 'FAILED: ' + ', '.join(failed)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
