#!/usr/bin/env python3
# File:        tool_errors.py
# Author:      Isaac Hagedorn
# Date:        2026-10-11
# Description: Fails (exit 1) when a Synopsys tool log has an error line that tool_error_waivers.txt does not waive.
#              dc_shell, pt_shell, fm_shell and lc_shell can print an error and still exit 0. Used by make synth, sta, lec, macros.

import argparse
import re
import sys
from pathlib import Path

# Design Compiler, PrimeTime, Formality, Library Compiler: "Error: <text> (ID)"
ERROR = re.compile(r"^Error:")
MSG_ID = re.compile(r"\(([A-Z][A-Z0-9_]*-\d+)\)|\[([A-Z][A-Z0-9_]*-\d+)\]")


def waived_ids(path: Path) -> set:
    """Message IDs in the waiver file: one per line, '#' starts the reason."""
    ids = set()
    for line in path.read_text().splitlines():
        fields = line.split("#", 1)[0].split()
        if fields:
            ids.add(fields[0])
    return ids


def main() -> int:
    ap = argparse.ArgumentParser(description="Fail on unwaived error lines in a tool log.")
    ap.add_argument("log", type=Path)
    ap.add_argument("--waivers", type=Path, required=True)
    a = ap.parse_args()

    waived = waived_ids(a.waivers)
    errors = []
    for line in a.log.read_text(errors="replace").splitlines():
        if ERROR.match(line):
            m = MSG_ID.search(line)
            if not (m and (m.group(1) or m.group(2)) in waived):
                errors.append(line.strip())
    if errors:
        print(f"SB-ERROR: {len(errors)} error line(s) in {a.log.name} (the tool may still have exited 0):")
        for line in errors[:5]:
            print(f"  {line}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
