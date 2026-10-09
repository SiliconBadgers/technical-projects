#!/usr/bin/env python3
# File:        lock.py
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Reads values from pdk.lock and checks installed PDKs against it. Usage: lock.py get <key> | lock.py check --pdk-root <dir>

import argparse
import sys
from pathlib import Path

import yaml

LOCK = Path(__file__).resolve().parents[3] / "pdk.lock"


def load(path: Path = LOCK) -> dict:
    return yaml.safe_load(path.read_text())


def get(data: dict, dotted: str):
    for key in dotted.split("."):
        data = data[key]
    return data


def installed_version(pdk_root: Path, family: str) -> str | None:
    """ciel records the enabled version in <root>/ciel/<family>/current."""
    current = pdk_root / "ciel" / family / "current"
    return current.read_text().strip() if current.is_file() else None


def check(pdk_root: Path, lock: dict) -> int:
    bad = 0
    for family, spec in lock["pdks"].items():
        want = spec["open_pdks"]
        have = installed_version(pdk_root, family)
        variant = pdk_root / spec["variant"]
        if have is None or not variant.is_dir():
            print(f"MISSING  {family}: no ciel install under {pdk_root} "
                  f"(run: ciel enable --pdk-root {pdk_root} --pdk-family {family} "
                  + " ".join(f"-l {lib}" for lib in spec["libraries"]) + f" {want})")
            bad += 1
            continue
        if have != want:
            print(f"WRONG    {family}: {have[:10]} is enabled, pdk.lock wants {want[:10]} "
                  f"(run: ciel enable --pdk-root {pdk_root} --pdk-family {family} {want})")
            bad += 1
            continue
        missing = [lib for lib in spec["libraries"] if not (variant / "libs.ref" / lib).is_dir()]
        if missing:
            print(f"PARTIAL  {family} {want[:10]}: missing libraries {' '.join(missing)} "
                  f"(run: ciel enable --pdk-root {pdk_root} --pdk-family {family} "
                  + " ".join(f"-l {lib}" for lib in missing) + f" {want})")
            bad += 1
            continue
        print(f"OK       {family} {want[:10]} ({spec['variant']}: {', '.join(spec['libraries'])})")
    return 1 if bad else 0


def main() -> None:
    ap = argparse.ArgumentParser(description="Read pdk.lock values or check installed PDKs against it.",
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("get")
    g.add_argument("key")
    c = sub.add_parser("check")
    c.add_argument("--pdk-root", required=True, type=Path)
    c.add_argument("--optional", nargs="*", default=["sky130_fd_pr"],
                   help="libraries that may be missing (default: sky130_fd_pr)")
    a = ap.parse_args()

    lock = load()
    if a.cmd == "get":
        val = get(lock, a.key)
        print(" ".join(val) if isinstance(val, list) else val)
        return
    for spec in lock["pdks"].values():
        spec["libraries"] = [lib for lib in spec["libraries"] if lib not in a.optional]
    sys.exit(check(a.pdk_root, lock))


if __name__ == "__main__":
    main()
