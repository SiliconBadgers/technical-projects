#!/usr/bin/env python3
"""Run a compiled VCS testbench and propagate failures to make.

Run in its build directory. Each repository testbench prints PASS: only after
all checks complete. VCS can return zero after $fatal, so require that marker
and reject fatal/error diagnostics as well as nonzero process exit codes.
"""
import re
import subprocess
import sys


def main():
    passed = False
    failed = False
    with open('simulation.log', 'w') as log:
        with subprocess.Popen(['./simv', '-no_save', *sys.argv[1:]], stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, text=True) as process:
            for line in process.stdout:
                print(line, end='', flush=True)
                log.write(line)
                passed |= line.startswith('PASS:')
                failed |= bool(re.match(r'^(Fatal:|Error[:\-])', line, re.IGNORECASE))
            status = process.wait()
    if status or failed or not passed:
        print('FAIL: simulation did not complete successfully; see simulation.log.', file=sys.stderr)
        return status or 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
