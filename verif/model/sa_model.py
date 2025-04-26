#!/usr/bin/env python3
# File:        sa_model.py
# Author:      Isaac Hagedorn
# Date:        2025-04-26
# Description: Python reference model of sb_systolic_array (y = x . W, optional ReLU). Writes golden-vector files with --vectors.
import argparse
import random

N, DATA_W, ACC_W = 4, 8, 32
ADDR_CTRL = N


def to_signed(v, bits):
    """Two's-complement value of the low `bits` bits."""
    v &= (1 << bits) - 1
    return v - (1 << bits) if v >> (bits - 1) else v


def pack(lanes, width):
    """List of lanes to bus; lane 0 is the least significant."""
    bus = 0
    for i, v in enumerate(lanes):
        bus |= (v & ((1 << width) - 1)) << (i * width)
    return bus


def unpack(bus, width, n=N):
    """Bus to list of signed lanes."""
    return [to_signed(bus >> (i * width), width) for i in range(n)]


class SystolicArrayModel:
    def __init__(self, n=N):
        self.n = n
        self.reset()

    def reset(self):                       # SA-R04
        self.W = [[0] * self.n for _ in range(self.n)]
        self.relu = 0

    def write(self, addr, data_bus):       # SA-R06..R08
        if addr < self.n:
            self.W[addr] = unpack(data_bus, DATA_W, self.n)
        elif addr == self.n:
            self.relu = data_bus & 1
        # reserved: no effect

    def compute(self, x):                  # SA-R13, R15
        y = [sum(x[m] * self.W[m][c] for m in range(self.n)) for c in range(self.n)]
        if self.relu:
            y = [max(v, 0) for v in y]
        assert all(-(1 << (ACC_W - 1)) <= v < (1 << (ACC_W - 1)) for v in y)
        return y


def example():
    """Small fixed example used by the self-test."""
    m = SystolicArrayModel()
    W = [[1, 0, 2, -1], [0, 1, 0, 0], [3, 0, -1, 0], [0, 5, 0, 0]]
    for r, row in enumerate(W):
        m.write(r, pack(row, DATA_W))
    x = [1, 2, 3, 4]
    y = m.compute(x)
    m.write(ADDR_CTRL, 1)
    y_relu = m.compute(x)
    return x, y, y_relu, pack(x, DATA_W), pack(y, ACC_W)


def gen_vectors(path, count, seed):
    """Writes a golden-vector file: lines `W <addr> <hex>`, `X <x...>`, `Y <y...>`."""
    rng = random.Random(seed)
    m = SystolicArrayModel()
    picks = [-128, -127, -1, 0, 1, 126, 127]
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(f"# sb_systolic_array golden vectors: N={N} seed={seed} count={count}\n")
        for i in range(count):
            if i % 25 == 0:                 # new weights and RELU_EN every 25 vectors
                for r in range(N):
                    row = [rng.choice(picks) if rng.random() < 0.3 else rng.randint(-128, 127) for _ in range(N)]
                    m.write(r, pack(row, DATA_W))
                    fh.write(f"W {r} {pack(row, DATA_W):0{N * 2}x}\n")
                ctrl = rng.randint(0, 1)
                m.write(ADDR_CTRL, ctrl)
                fh.write(f"W {ADDR_CTRL} {ctrl:0{N * 2}x}\n")
            x = [rng.choice(picks) if rng.random() < 0.3 else rng.randint(-128, 127) for _ in range(N)]
            fh.write("X " + " ".join(map(str, x)) + "\n")
            fh.write("Y " + " ".join(map(str, m.compute(x))) + "\n")


def main():
    ap = argparse.ArgumentParser(description='sb_systolic_array reference model and golden-vector generator.')
    ap.add_argument("--example", action="store_true")
    ap.add_argument("--vectors")
    ap.add_argument("--count", type=int, default=200)
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args()
    if args.example:
        x, y, y_relu, a_bus, r_bus = example()
        print(f"x = {x}\ny = x.W = {y}\nwith RELU_EN = 1: {y_relu}")
        print(f"a_data = 32'h{a_bus:08x}\nr_data = 128'h{r_bus:032x}")
    if args.vectors:
        gen_vectors(args.vectors, args.count, args.seed)
        print(f"wrote {args.vectors}")


if __name__ == "__main__":
    main()
