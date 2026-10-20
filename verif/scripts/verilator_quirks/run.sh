#!/bin/bash
# File:        run.sh
# Author:      Isaac Hagedorn
# Date:        2025-11-15
# Description: Re-checks Verilator quirks Q1-Q4 and prints PRESENT or FIXED for each. Needs verilator and z3 on PATH.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
verilator --version
for f in "$HERE"/q*.sv; do
  q=$(basename "$f" .sv); top=${q%%_*}
  extra=""; [ "$top" = q4 ] && extra="--coverage-user"
  if ! verilator --binary --timing -Wno-fatal $extra "$f" --top-module "$top" --Mdir "$W/$q" > "$W/$q.log" 2>&1; then
    echo "$q: does not compile (see below)"; tail -3 "$W/$q.log"; continue
  fi
  (cd "$W" && "$W/$q/V$top" 2>&1) | grep QUIRK-RESULT | sed "s/QUIRK-RESULT q[0-9]*/$q:/"
  if [ "$top" = q4 ]; then
    if tr '\001\002' '| ' < "$W/coverage.dat" | grep -q "cp.neg' [1-9]"; then echo "$q: FIXED"; else echo "$q: PRESENT (neg bin not hit)"; fi
  fi
done
