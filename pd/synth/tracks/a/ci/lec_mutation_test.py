#!/usr/bin/env python3
# File:        lec_mutation_test.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Checks that LEC can still fail. Swaps the D inputs of two flip-flops in the netlist and expects eqy to report FAIL.
import argparse
import random
import re
import subprocess
import sys
from pathlib import Path

# one Yosys netlist cell instance: type, name, pin list
CELL = re.compile(r"^  (\S+) (\S+) \((.*?)\);", re.M | re.S)
PIN = re.compile(r"\.(\w+)\(([^()]*)\)")


def top_module_span(text: str, top: str) -> tuple[int, int]:
    m = re.search(rf"^module {re.escape(top)}\s*\(.*?^endmodule", text, re.M | re.S)
    if not m:
        sys.exit(f"module {top} not found in the netlist")
    return m.start(), m.end()


def flip_flops(body: str) -> list[tuple[re.Match, str]]:
    """(cell match, D net) for every cell with a D and a Q pin."""
    out = []
    for c in CELL.finditer(body):
        pins = dict(PIN.findall(c.group(3)))
        if "D" in pins and ("Q" in pins or "QN" in pins):
            out.append((c, pins["D"]))
    return out


def mutate(text: str, top: str, rng: random.Random) -> tuple[str, str]:
    start, end = top_module_span(text, top)
    body = text[start:end]
    ffs = flip_flops(body)
    # flip-flops whose D is not a constant
    cands = [(c, d) for c, d in ffs if not re.match(r"\d+'[bh][0-9a-fx]+\Z", d.strip())]
    if len(cands) < 2:
        sys.exit("fewer than two flip-flops: nothing to swap")
    for _ in range(100):
        (c1, d1), (c2, d2) = rng.sample(cands, 2)
        if d1.strip() != d2.strip():
            break
    # later cell first so earlier offsets stay valid
    for c, new_d in sorted([(c1, d2), (c2, d1)], key=lambda x: -x[0].start()):
        cell = c.group(0)
        cell = re.sub(r"\.D\([^()]*\)", lambda _m, d=new_d: f".D({d})", cell, count=1)
        body = body[:c.start()] + cell + body[c.end():]
    return text[:start] + body + text[end:], f"swapped D of {c1.group(2)} and {c2.group(2)}"


def main() -> int:
    ap = argparse.ArgumentParser(description="Break the netlist on purpose and check that LEC fails. Run after `make lec`.")
    ap.add_argument("--build", type=Path, required=True, help="the build directory (has netlist.v, lec.eqy)")
    ap.add_argument("--count", type=int, default=2, help="mutations to try (default 2)")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--seed", type=int, default=1)
    a = ap.parse_args()

    build = a.build.resolve()
    netlist, eqy = build / "netlist.v", build / "lec.eqy"
    if not (netlist.exists() and eqy.exists()):
        sys.exit(f"no netlist.v / lec.eqy in {build}: run `make lec` first")
    top = re.search(r"^prep -top (\S+)", eqy.read_text(), re.M).group(1)
    rng = random.Random(a.seed)
    failures = 0
    for k in range(a.count):
        work = build / "lec_mutation" / str(k)
        work.mkdir(parents=True, exist_ok=True)
        text, what = mutate(netlist.read_text(), top, rng)
        (work / "netlist.v").write_text(text)
        (work / "lec.eqy").write_text(eqy.read_text().replace(str(netlist), str(work / "netlist.v")))
        r = subprocess.run(["eqy", "-j", str(a.jobs), "-f", "-d", "lec", "lec.eqy"],
                           cwd=work, capture_output=True, text=True)
        verdict = "FAIL" if "DONE (FAIL" in r.stdout else ("PASS" if "DONE (PASS" in r.stdout else "ERROR")
        ok = verdict == "FAIL"
        failures += not ok
        print(f"SB: lec mutation {k}: {what}: LEC says {verdict} -> {'good' if ok else 'BAD: LEC missed a broken netlist'}")
    print(f"LEC_MUTATION: {'PASS' if failures == 0 else 'FAIL'} ({a.count - failures}/{a.count} caught)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
