#!/usr/bin/env python3
"""Run one simulation with the same pass criteria as the regression runner."""
import argparse
from pathlib import Path
import re
import sys

from regress import run_one


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--run", required=True)
    ap.add_argument("--test", required=True)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--verbosity", default="UVM_MEDIUM")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    result = run_one(args.run, args.test, args.seed, args.out, args.verbosity, [], None)
    log_path = Path(result["dir"]) / "sim.log"
    interesting = re.compile(r"UVM_(ERROR|FATAL) [^:]|\*\*\* TEST|Assertion|%Error|\*\* (Error|Fatal)|\*E,|\*F,|^Error-")
    lines = [line for line in log_path.read_text().splitlines() if interesting.search(line)]
    for line in lines[:40]:
        print(line)
    if not result["passed"]:
        print(f"FAIL: simulator exit={result['rc']}, UVM errors={result['errors']}, "
              f"fatals={result['fatals']}; requires exit 0, a PASS banner and no UVM errors/fatals")
        print(f"log: {log_path}")
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
