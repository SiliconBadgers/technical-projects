#!/bin/bash
# File:        gen_cycle_tables.sh
# Author:      Isaac Hagedorn
# Date:        2025-10-04
# Description: Regenerates docs/spec/cycle_tables.md from the golden RTL. Needs verilator on PATH.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
OBJ="$ROOT/build/spec_tables"
verilator --binary --timing -Wno-fatal -Wno-lint -Wno-style --timescale 1ns/1ps \
  -F "$ROOT/rtl/sb_systolic_array.f" "$HERE/cycle_tables_tb.sv" --top-module cycle_tables_tb \
  --Mdir "$OBJ" -o Vtables > "$OBJ.log" 2>&1 || { tail -20 "$OBJ.log"; exit 1; }
{ echo "# sb_systolic_array: cycle tables (N = 4)"
  echo
  echo "Generated from the RTL. One row per rising edge, values sampled at that edge. **xfer** = handshake."
  echo "Weight row m is all m+1. Lanes are printed lane 0 first."
  "$OBJ/Vtables" | grep -v '^- ' | grep -v 'Verilog \$finish'
} > "$ROOT/docs/spec/cycle_tables.md"
echo "wrote docs/spec/cycle_tables.md"
