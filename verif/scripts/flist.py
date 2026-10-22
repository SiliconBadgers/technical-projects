#!/usr/bin/env python3
# File:        flist.py
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Prints the source files of one or more file lists (verilator -F style: paths relative to the list) as absolute paths, so every simulator can read them.
import os
import sys


def expand(path, out):
    base = os.path.dirname(os.path.abspath(path))
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.split("//", 1)[0].split("#", 1)[0].strip()
            if not line:
                continue
            words = line.split()
            if words[0] in ("-f", "-F") and len(words) == 2:
                expand(os.path.join(base, words[1]), out)
            elif line.startswith("+") or line.startswith("-"):
                sys.exit(f"{path}: unsupported option '{line}' (list source files only)")
            else:
                out.append(os.path.normpath(os.path.join(base, line)))


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: flist.py <list.f> [<list.f> ...]")
    out = []
    for path in sys.argv[1:]:
        expand(path, out)
    print(" ".join(out))


if __name__ == "__main__":
    main()
