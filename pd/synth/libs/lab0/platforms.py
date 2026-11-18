#!/usr/bin/env python3
# File:        platforms.py
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Liberty file paths and cell names per library, read from your track's track/libraries.yaml. Run it from your track's folder (tracks/<track>) to list its libraries.
from __future__ import annotations

import gzip
import os
import re
import sys
from functools import lru_cache
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
# the track: tracks/$SB_TRACK if set, else the tracks/<track> folder you run from
_CWD = Path.cwd().resolve()
TRACK = (ROOT / "tracks" / os.environ["SB_TRACK"] if os.environ.get("SB_TRACK") else
         next((d for d in (_CWD, *_CWD.parents) if d.parent == ROOT / "tracks"), None))
LIBRARIES_YAML = TRACK / "track" / "libraries.yaml" if TRACK else None
CORNERS = ("tt", "ss", "ff")

# SB_PDK: the SiliconBadgers PDK repo, cloned next to the course folder unless set
os.environ.setdefault("SB_PDK", str(ROOT.parent / "silicon-badgers-sky130-pdk"))

# cell role -> name stem (sky130_scl_9T: <FUNCTION>X<drive>; others: <lib>__<function>_<drive>)
_SCL = {"inv": "INVX", "nand2": "NAND2X", "dff": "DFFX", "buf": "BUFX"}
_OPEN = {"inv": "inv", "nand2": "nand2", "buf": "buf"}
# plain D flip-flop (no reset, no enable) per family
_DFF = {"sky130": "dfxtp", "gf180mcu": "dffq"}
_CELL = re.compile(r'\s*cell\s*\(\s*"?([^")\s]+)')


class TrackError(RuntimeError):
    """A problem with track/libraries.yaml or a file it names."""


def _hook(kind, err, tb):
    # scripts: print a TrackError as one line instead of a traceback
    if issubclass(kind, TrackError):
        print(f"error: {err}", file=sys.stderr)
    else:
        sys.__excepthook__(kind, err, tb)


sys.excepthook = _hook


def _load() -> dict[str, dict[str, str]]:
    """{library: {corner: path as written}} from track/libraries.yaml."""
    if LIBRARIES_YAML is None or not LIBRARIES_YAML.is_file():
        raise TrackError("no track/libraries.yaml here: run this from your track's folder, "
                         "tracks/<track> (see tracks/README.md)")
    data = yaml.safe_load(LIBRARIES_YAML.read_text()) or {}
    libs = data.get("libraries") or {}
    for name, corners in libs.items():
        missing = [c for c in CORNERS if c not in (corners or {})]
        if missing:
            raise TrackError(f"{LIBRARIES_YAML.name}: library {name} has no {', '.join(missing)} entry")
    return libs


_LIBS = _load()
# every library of the current track, in file order
SPEC_PLATFORMS = list(_LIBS)


@lru_cache(maxsize=None)
def lib_path(pdk: str, corner: str) -> Path:
    """Liberty file of library `pdk` at `corner` (tt, ss or ff). Accepts .lib or .lib.gz."""
    if pdk not in _LIBS:
        raise TrackError(f"library {pdk} is not in {LIBRARIES_YAML.name} "
                         f"(this track has: {', '.join(SPEC_PLATFORMS)})")
    raw = os.path.expanduser(os.path.expandvars(str(_LIBS[pdk][corner])))
    if "$" in raw:
        raise TrackError(f"{pdk} {corner}: environment variable not set in {raw}")
    path = Path(raw) if Path(raw).is_absolute() else ROOT / raw
    # the same file, plain or gzipped
    other = path.with_suffix("") if path.suffix == ".gz" else Path(f"{path}.gz")
    for p in (path, other):
        if p.is_file():
            return p
    raise TrackError(f"{pdk} {corner}: {path} not found (see track/README.md)")


@lru_cache(maxsize=None)
def _first_cell(pdk: str) -> str:
    """Name of the first cell in the tt Liberty file; tells the naming style."""
    path = lib_path(pdk, "tt")
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt") as f:
        for line in f:
            m = _CELL.match(line)
            if m:
                return m.group(1)
    raise TrackError(f"{path}: no cell found")


def cell_base(pdk: str, role: str) -> str:
    """e.g. ('sky130hd', 'inv') -> 'sky130_fd_sc_hd__inv' (append _<drive>)."""
    first = _first_cell(pdk)
    if "__" not in first:            # sky130_scl_9T: INVX1, INVX2, ...
        return _SCL[role]
    lib = first.split("__")[0]
    family = "gf180mcu" if lib.startswith("gf180mcu") else "sky130"
    return f"{lib}__{_DFF[family] if role == 'dff' else _OPEN[role]}"


def cell_name(pdk: str, role: str, drive: int) -> str:
    base = cell_base(pdk, role)
    return f"{base}{drive}" if base.endswith("X") else f"{base}_{drive}"


def main(argv: list[str]) -> int:
    # no arguments: list every library; <library> <corner>: print that file's path
    if len(argv) == 2:
        print(lib_path(argv[0], argv[1]))
        return 0
    if argv:
        print("usage: platforms.py [<library> <tt|ss|ff>]", file=sys.stderr)
        return 2
    for name in SPEC_PLATFORMS:
        for corner in CORNERS:
            print(f"{name:<16} {corner}  {lib_path(name, corner)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
