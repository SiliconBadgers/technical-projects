#!/usr/bin/env python3
# File:        test_sa_model.py
# Author:      Isaac Hagedorn
# Date:        2025-04-26
# Description: Self-test for sa_model.py.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sa_model import ACC_W, ADDR_CTRL, DATA_W, N, SystolicArrayModel, example, pack, unpack  # noqa: E402


def check(name, got, exp):
    if got != exp:
        sys.exit(f"FAIL {name}: got {got}, expected {exp}")
    print(f"ok   {name}")


x, y, y_relu, a_bus, r_bus = example()
check("example y", y, [10, 22, -1, -1])
check("example relu", y_relu, [10, 22, 0, 0])
check("example a_data", a_bus, 0x04030201)
check("example r_data", r_bus, (0xFFFFFFFF << 96) | (0xFFFFFFFF << 64) | (22 << 32) | 10)
check("packing lane 0 = LSB", unpack(0xFF030201, DATA_W), [1, 2, 3, -1])

m = SystolicArrayModel()
check("reset weights are 0", m.compute([5, -6, 7, -8]), [0] * N)   # SA-R04
for r in range(N):
    m.write(r, pack([-128] * N, DATA_W))
check("largest result (all -128)", m.compute([-128] * N), [N * 128 * 128] * N)
m.write(ADDR_CTRL, 0xFFFFFFFE)                                # SA-R07: only bit 0 counts
check("CTRL reserved bits ignored", m.relu, 0)
m.write(ADDR_CTRL + 1, 0x12345678)                            # SA-R08: reserved address
check("reserved address ignored", m.W[1], [-128] * N)
assert ACC_W == 32
print("all model checks passed")
