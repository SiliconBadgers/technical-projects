#!/usr/bin/env python3
# File:        checks.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Track A acceptance checks, one function per check. Reads the flow's outputs; reruns no tool.
from __future__ import annotations

import argparse
import csv
import fnmatch
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QOR_COLUMNS = ["design", "platform", "corner", "period_ns", "wns_ns", "tns_ns", "hold_wns_ns",
               "area_um2", "cell_count", "seq_cells", "leakage", "synth_runtime_s",
               "sta_runtime_s", "git_sha"]


@dataclass
class Result:
    name: str
    status: str            # PASS | FAIL | INFO
    message: str
    doc: str = ""
    details: list[str] = field(default_factory=list)


@dataclass
class Ctx:
    build: Path
    design_dir: Path
    latch_cells: list[str]
    reset_sync_flops: int = 2

    def need(self, name: str) -> Path:
        p = self.build / name
        if not p.exists():
            raise FileNotFoundError(f"{p.relative_to(ROOT) if p.is_relative_to(ROOT) else p} "
                                    "does not exist -- run `make all` first")
        return p

    def sta(self, corner: str) -> dict:
        return json.loads(self.need(f"sta_{corner}.json").read_text())


CHECKS = []


def check(name: str, doc: str, informational: bool = False):
    def deco(fn):
        CHECKS.append((name, doc, informational, fn))
        return fn
    return deco


def junit(path: Path) -> tuple[list[str], list[str]]:
    """(all test names, failed test names) from a cocotb results.xml."""
    names, failed = [], []
    for case in ET.parse(path).getroot().iter("testcase"):
        n = f"{case.get('classname')}.{case.get('name')}"
        names.append(n)
        if case.find("failure") is not None or case.find("error") is not None:
            failed.append(n)
    return names, failed


@check("lint_clean", "docs/04_synthesis.md#lint")
def lint_clean(c: Ctx) -> tuple[bool, str, list[str]]:
    log = c.need("lint.log").read_text()
    warnings = [ln for ln in log.splitlines() if ln.startswith(("%Warning", "%Error"))]
    ok = "LINT_STATUS: verilator+sb_lint PASS" in log and not warnings
    return ok, ("Verilator -Wall and sb_lint: no unwaived warnings" if ok else
                f"Verilator reported {len(warnings)} warning(s)/error(s); fix them or add a "
                "commented waiver to lint_waivers.vlt"), warnings[:10]


@check("rtl_sim", "labs/<lab>/README.md (testbench)")
def rtl_sim(c: Ctx):
    names, failed = junit(c.need("results.xml"))
    ok = bool(names) and not failed
    return ok, f"{len(names) - len(failed)}/{len(names)} cocotb tests pass on the RTL", failed


@check("no_latches", "docs/04_synthesis.md#latches")
def no_latches(c: Ctx):
    cells = re.findall(r"^\s*([A-Za-z_][\w$]*)\s+\S+\s*\(", c.need("netlist.v").read_text(), re.M)
    latches = sorted({x for x in cells if any(fnmatch.fnmatch(x, p) for p in c.latch_cells)})
    log = c.need("synth.log").read_text()
    inferred = sorted(set(re.findall(r"Latch inferred for signal [^\n]*", log)))
    ok = not latches and not inferred
    return ok, ("no latch cells in the netlist" if ok else
                "latches found: an incomplete if/case in a combinational block"), latches + inferred


@check("yosys_check", "docs/04_synthesis.md#check")
def yosys_check(c: Ctx):
    txt = c.need("synth_check.txt").read_text()
    m = re.search(r"Found and reported (\d+) problems", txt)
    ok = m is not None and m.group(1) == "0"
    problems = [ln.strip() for ln in txt.splitlines() if "Warning" in ln][:10]
    return ok, ("Yosys `check -assert` passed" if ok else
                "Yosys `check` found multiple drivers, undriven nets or logic loops"), problems


@check("no_unconstrained", "docs/05_sdc.md#unconstrained")
def no_unconstrained(c: Ctx):
    corners = [k for k in ("tt", "ss", "ff") if (c.build / f"sta_{k}.json").exists()]
    if not corners:
        c.sta("ss")                      # raises "run make all first"
    bad = {k: int(c.sta(k)["unconstrained_endpoints"]) for k in corners}
    bad = {k: v for k, v in bad.items() if v}
    bbox = {k: int(c.sta(k).get("black_boxes", 0)) for k in corners}
    bbox = {k: v for k, v in bbox.items() if v}
    msgs, details = [], []
    if bad:
        msgs.append(f"unconstrained endpoints: {bad} (missing set_input_delay/set_output_delay?)")
        details += [f"see sta_{k}.rpt, section 'Unconstrained endpoints'" for k in bad]
    if bbox:
        msgs.append(f"untimed instances (no Liberty model): {bbox}")
        details += [f"see sta_{k}.rpt, section 'Instances without a timing model'" for k in bbox]
    ok = not bad and not bbox
    return ok, "every timing endpoint is constrained and every instance is timed" if ok else "; ".join(msgs), details


@check("reset_sync", "docs/05_sdc.md#asynchronous-reset")
def reset_sync(c: Ctx):
    n = int(c.sta("ss").get("reset_port_async_pins", -1))
    if n < 0:
        return True, "no asynchronous reset port declared (ASYNC_RESET_PORT) -- nothing to check", []
    ok = n <= c.reset_sync_flops
    return ok, (f"{n} flip-flop(s) on the reset port directly (the synchronizer)" if ok else
                f"{n} flip-flop reset pins hang directly on the asynchronous reset port: "
                "its release is not synchronized to the clock"), []


@check("setup_ss", "docs/06_timing_reports.md#setup")
def setup_ss(c: Ctx):
    s = c.sta("ss")
    ws = float(s["setup_ws_ns"])
    return ws >= 0, f"worst setup slack at ss = {ws:.3f} ns (period {float(s['period_ns']):g} ns)", []


@check("hold_ff", "docs/06_timing_reports.md#hold")
def hold_ff(c: Ctx):
    ws = float(c.sta("ff")["hold_ws_ns"])
    return ws >= 0, f"worst hold slack at ff = {ws:.3f} ns", []


@check("lec", "track/reading_logs.md#lec")
def lec(c: Ctx):
    log = c.need("lec.log").read_text() if (c.build / "lec.log").exists() else \
        c.need("lec_run.log").read_text()
    ok = "DONE (PASS" in log
    failed = re.findall(r"Failed to prove equivalence of partition (\S+)", log)
    return ok, "eqy: RTL and netlist are equivalent" if ok else \
        f"eqy could not prove {len(failed)} partition(s) equivalent", failed[:10]


@check("gls", "docs/08_gate_level_sim.md#gls")
def gls(c: Ctx):
    names, failed = junit(c.need("gls_results.xml"))
    rtl_names, _ = junit(c.need("results.xml"))
    same = sorted(names) == sorted(rtl_names)
    ok = bool(names) and not failed and same
    msg = f"{len(names) - len(failed)}/{len(names)} cocotb tests pass on the netlist"
    if not same:
        msg += "; the gate-level run did not run the same tests as the RTL run"
    return ok, msg, failed


@check("qor_committed", "docs/06_timing_reports.md#qor")
def qor_committed(c: Ctx):
    with c.need("qor.csv").open() as f:
        cols = next(csv.reader(f), [])
    missing = [x for x in QOR_COLUMNS if x not in cols]
    committed = sorted(str(p.relative_to(ROOT)) for p in c.design_dir.glob("**/qor*.csv")
                       if tracked(p))
    note = f"; committed: {', '.join(committed)}" if committed else "; no qor*.csv committed in the design dir yet"
    return not missing, ("qor.csv has all required columns" if not missing else
                         f"qor.csv is missing columns {missing}") + note, []


@check("target_tier", "labs/lab2_systolic/spec.md#targets", informational=True)
def target_tier(c: Ctx):
    tfile = c.design_dir / "targets.yaml"
    if not tfile.exists():
        return True, "no targets.yaml for this design (tiers apply to Lab 2)", []
    import yaml
    t = yaml.safe_load(tfile.read_text())
    stat = json.loads(c.need("synth_stat.json").read_text())["design"]
    ss, ff = c.sta("ss"), c.sta("ff")
    period, area = float(ss["period_ns"]), float(stat["area"])
    timing_ok = float(ss["setup_ws_ns"]) >= 0 and float(ff["hold_ws_ns"]) >= 0
    plat = c.build.name.split("_p")[0]
    tier = "none"
    pt = t.get("platforms", {}).get(plat)
    if pt and timing_ok:
        if period <= pt["silver_period_ns"] * (1 + 1e-5) and area <= pt["silver_max_area_um2"]:
            tier = "silver (gold also needs a second PDK and the 8x8 array, checked by a mentor)"
        elif period <= 1000.0 / pt["bronze_mhz"] * (1 + 1e-5):   # STA rounds the period
            tier = "bronze"
    return True, f"{plat}: period {period:g} ns, area {area:.0f} um^2, " \
                 f"leaderboard area x period = {area * period:.0f} -> tier {tier}", []


def tracked(p: Path) -> bool:
    r = subprocess.run(["git", "-C", str(ROOT), "ls-files", "--error-unmatch", str(p)],
                       capture_output=True)
    return r.returncode == 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Track A acceptance checks. Run after `make all`.")
    ap.add_argument("--build", required=True, type=Path)
    ap.add_argument("--design-dir", required=True, type=Path)
    ap.add_argument("--latch-cells", default="", help="space-separated glob patterns (platform LATCH_CELLS)")
    ap.add_argument("--reset-sync-flops", type=int, default=2,
                    help="flip-flops allowed directly on the async reset port (RESET_SYNC_FLOPS)")
    ap.add_argument("--only", nargs="*", help="run only these checks")
    ap.add_argument("--json", type=Path, help="also write the results here")
    a = ap.parse_args()
    c = Ctx(a.build.resolve(), a.design_dir.resolve(), a.latch_cells.split(), a.reset_sync_flops)

    results = []
    for name, doc, informational, fn in CHECKS:
        if a.only and name not in a.only:
            continue
        try:
            ok, msg, details = fn(c)
            status = "INFO" if informational else ("PASS" if ok else "FAIL")
        except FileNotFoundError as e:
            status, msg, details = ("INFO" if informational else "FAIL"), str(e), []
        results.append(Result(name, status, msg, doc, details))

    width = max(len(r.name) for r in results)
    for r in results:
        print(f"{r.status:4}  {r.name:<{width}}  {r.message}")
        if r.status == "FAIL":
            for d in r.details:
                print(f"{'':6}{'':<{width}}    {d}")
            print(f"{'':6}{'':<{width}}    -> read {r.doc}")
    failed = [r.name for r in results if r.status == "FAIL"]
    print(f"\n{len(results) - len(failed)}/{len(results)} checks OK" + (f"; FAILED: {', '.join(failed)}" if failed else ""))
    if a.json:
        a.json.write_text(json.dumps([r.__dict__ for r in results], indent=2))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
