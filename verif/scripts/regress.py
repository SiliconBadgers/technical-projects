#!/usr/bin/env python3
# File:        regress.py
# Author:      Isaac Hagedorn
# Date:        2025-05-17
# Description: Runs every test x seed in a regression list against one simulator build and merges coverage. A run passes on exit status 0, the PASS banner and 0 UVM errors/fatals.
import argparse
import concurrent.futures as cf
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time


def read_list(path, default_seeds):
    tests = []
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.split("#", 1)[0].split()
            if not line:
                continue
            seeds = int(line[1]) if len(line) > 1 else default_seeds
            tests.append((line[0], seeds))
    return tests


# simulator name and the pattern that finds its version in a run log
SIM_VERSIONS = (
    ("VCS", r"Runtime version (\S+?);"),
    ("Questa", r"^# //\s+Version (\S+)"),
    ("Xcelium", r"^xrun\(64\): (\S+?):"),
    ("Verilator", r"R e p o r t: Verilator (\S+)"),
)


def sim_version(log):
    for name, pattern in SIM_VERSIONS:
        m = re.search(pattern, log, re.M)
        if m:
            return f"{name} {m.group(1)}"
    return None


def run_one(template, test, seed, outdir, verbosity, plusargs, timeout):
    rundir = os.path.join(outdir, f"{test}_s{seed}")
    os.makedirs(rundir, exist_ok=True)
    cov = os.path.join(rundir, "coverage.dat")
    cmd = shlex.split(template.replace("{test}", test).replace("{seed}", str(seed))
                      .replace("{verb}", verbosity).replace("{cov}", cov)) + plusargs
    t0 = time.time()
    try:
        p = subprocess.run(cmd, cwd=rundir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           timeout=timeout, text=True, errors="replace")
        log, rc, timed_out = p.stdout, p.returncode, False
    except subprocess.TimeoutExpired as e:
        log = (e.stdout or b"").decode(errors="replace") if isinstance(e.stdout, bytes) else (e.stdout or "")
        rc, timed_out = -1, True
    with open(os.path.join(rundir, "sim.log"), "w", encoding="utf-8") as fh:
        fh.write(log)

    def count(sev):
        m = re.search(rf"^(?:# )?{sev} :\s*(\d+)", log, re.M)
        return int(m.group(1)) if m else None

    n_err, n_fatal = count("UVM_ERROR"), count("UVM_FATAL")
    m = re.search(r"\[SB\] compared (\d+)", log)
    # Questa prefixes transcript lines with "# "
    first = re.search(r"^(?:# )?(UVM_(?:ERROR|FATAL) .*?\[([^\]]+)\].*)$", log, re.M)
    passed = ("*** TEST PASSED ***" in log and n_err == 0 and n_fatal == 0
              and first is None and not timed_out and rc == 0)
    ids = sorted(set(re.findall(r"^(?:# )?UVM_(?:ERROR|FATAL) .*?\[([^\]]+)\]", log, re.M)))
    vdb = os.path.join(rundir, "cov.vdb")      # VCS writes a coverage database per run
    return {
        "test": test, "seed": seed, "passed": passed, "rc": rc, "timed_out": timed_out,
        "simulator": sim_version(log),
        "errors": n_err, "fatals": n_fatal, "compared": int(m.group(1)) if m else None,
        "error_ids": ids, "first_error": first.group(1)[-300:] if first else None,
        "seconds": round(time.time() - t0, 1), "dir": rundir,
        "coverage": cov if os.path.exists(cov) else (vdb if os.path.isdir(vdb) else None),
    }


def main():
    ap = argparse.ArgumentParser(description='Run a regression list against one simulator build.')
    ap.add_argument("--run", required=True,
                    help="command for one run, with {test} {seed} {verb} {cov} placeholders (make print-run)")
    ap.add_argument("--list", required=True)
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--seed-base", type=int, default=1)
    ap.add_argument("--out", required=True)
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--verbosity", default="UVM_LOW")
    ap.add_argument("--plusargs", default="", help="extra plusargs, space separated")
    ap.add_argument("--timeout", type=int, default=900, help="wall-clock seconds per run")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    if os.path.isdir(args.out):
        shutil.rmtree(args.out)
    os.makedirs(args.out)

    jobs = [(t, args.seed_base + i) for t, n in read_list(args.list, args.seeds) for i in range(n)]
    plusargs = args.plusargs.split()
    results = []
    with cf.ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futs = [ex.submit(run_one, args.run, t, s, args.out, args.verbosity, plusargs, args.timeout)
                for t, s in jobs]
        for f in cf.as_completed(futs):
            r = f.result()
            results.append(r)
            if not args.quiet:
                tag = "PASS" if r["passed"] else "FAIL"
                extra = "" if r["passed"] else f"  {', '.join(r['error_ids']) or ('timeout' if r['timed_out'] else 'no PASS banner')}"
                print(f"  {tag}  {r['test']:<24} seed {r['seed']:<4} compared {str(r['compared']):>6}  {r['seconds']:6.1f}s{extra}",
                      flush=True)

    results.sort(key=lambda r: (r["test"], r["seed"]))
    n_pass = sum(r["passed"] for r in results)

    merged = os.path.join(args.out, "merged.dat")
    covs = [r["coverage"] for r in results if r["coverage"] and r["coverage"].endswith(".dat")]
    if covs and shutil.which("verilator_coverage"):
        subprocess.run(["verilator_coverage", "--write", merged] + covs,
                       stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

    with open(os.path.join(args.out, "results.json"), "w", encoding="utf-8") as fh:
        simulator = next((r["simulator"] for r in results if r["simulator"]), None)
        json.dump({"passed": n_pass, "total": len(results), "simulator": simulator, "runs": results}, fh, indent=1)

    vdbs = any(r["coverage"] and r["coverage"].endswith(".vdb") for r in results)
    print(f"\n{n_pass}/{len(results)} runs passed"
          + (f"; merged coverage: {merged}" if os.path.exists(merged) else "")
          + ("; coverage report: make cov" if vdbs else ""))
    for r in results:
        if not r["passed"]:
            print(f"  FAILED {r['test']} seed {r['seed']}: {r['first_error'] or ('timeout' if r['timed_out'] else 'no PASS banner')}")
            print(f"         log: {r['dir']}/sim.log")
    return 0 if n_pass == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
