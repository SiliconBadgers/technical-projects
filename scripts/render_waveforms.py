#!/usr/bin/env python3
"""Render the introductory waveform worksheets. Requires matplotlib.

Run from any directory: python3 scripts/render_waveforms.py
Outputs are committed PNG assets; reading the guides needs no plotting packages.
"""
from pathlib import Path
import re

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'intro/projects/digital-logic'
ASSETS = PROJECT / 'exercises/images'
BG = '#0c090b'
INK = '#f2e6e6'
MUTED = '#ab9fa5'
GRID = '#382c33'
RED = '#ee526c'


def draw(filename, title, subtitle, tracks, end, rising_edges=()):
    """Each signal is (label, [(transition_time, level), ...]), or None for blank."""
    height = 2.2 + len(tracks) * 0.78
    fig, ax = plt.subplots(figsize=(14, height), dpi=150)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(BG)
    fig.subplots_adjust(left=0.16, right=0.965, bottom=0.12, top=0.77 if len(tracks) == 5 else 0.83)
    fig.text(0.055, 0.95, title, color=INK, fontsize=22, weight='bold', va='top')
    fig.text(0.055, 0.89, subtitle, color=MUTED, fontsize=12, va='top')
    ax.set_xlim(0, end)
    ax.set_ylim(-0.45, len(tracks) * 1.6 - 0.2)
    ax.set_yticks([])
    ax.set_xticks(range(0, end + 1, 10))
    ax.tick_params(axis='x', colors=MUTED, labelsize=11, length=0, pad=12)
    ax.set_xlabel('Time (ns)', color=MUTED, fontsize=12, labelpad=12)
    for spine in ax.spines.values():
        spine.set_visible(False)
    for t in range(0, end + 1, 10):
        ax.axvline(t, color=GRID, linestyle=(0, (2, 4)), linewidth=0.8, zorder=0)
    for idx, t in enumerate(rising_edges):
        ax.axvline(t, color=RED, linestyle=(0, (3, 5)), linewidth=0.9, alpha=0.65, zorder=0)
        ax.text(t, len(tracks) * 1.6 - 0.13, f'edge {idx}', ha='center', va='bottom',
                fontsize=10, color=RED, clip_on=False)
    for i, (label, transitions) in enumerate(tracks):
        low = (len(tracks) - i - 1) * 1.6
        high = low + 0.78
        blank = transitions is None
        for y, value in [(low, '0'), (high, '1')]:
            ax.hlines(y, 0, end, color=GRID, linewidth=0.7, linestyle=(0, (2, 3)))
            ax.text(-0.013 * end, y, value, color=MUTED, fontsize=9,
                    va='center', ha='right', clip_on=False)
        ax.text(-0.055 * end, (low + high) / 2, label, ha='right', va='center',
                color=RED if blank else INK, fontsize=14,
                weight='bold' if blank else 'normal', family='DejaVu Sans Mono', clip_on=False)
        if blank:
            continue
        assert transitions[0][0] == 0 and all(v in (0, 1) for _, v in transitions)
        xs = [t for t, _ in transitions] + [end]
        ys = [low + v * (high - low) for _, v in transitions] + [low + transitions[-1][1] * (high - low)]
        ax.step(xs, ys, where='post', color=INK, linewidth=2.1,
                solid_capstyle='butt', solid_joinstyle='miter')
    ASSETS.mkdir(parents=True, exist_ok=True)
    dest = ASSETS / filename
    fig.savefig(dest, facecolor=BG, dpi=150)
    plt.close(fig)
    print(dest.relative_to(ROOT))


def main():
    # Use the actual slide-21 input sequence already present in the testbench.
    source = (PROJECT / 'tb/day1_combinational_tb.sv').read_text()
    abc = re.findall(r"interval\(3'b([01]{3})\)", source)
    assert len(abc) == 8, 'Expected eight intervals from slide 21'
    draw('day1-waveforms.png', 'Combinational waveform exercise',
         'Day 1, slide 21  /  Draw out1 and out2 on the empty signal lanes.',
         [(name, [(i * 10, int(bits[k])) for i, bits in enumerate(abc)])
          for k, name in enumerate(['a', 'b', 'c'])] + [('out1', None), ('out2', None)], 80)

    # Same five input sets as the original clocked worksheet. Inputs change
    # on falling edges, five nanoseconds before their corresponding rising edge.
    inputs = {
        'rst': [1, 0, 0, 0, 1],
        'a': [1, 1, 0, 1, 1],
        'b': [0, 0, 1, 0, 1],
        'select_b': [0, 0, 1, 1, 0],
        'start': [0, 1, 0, 1, 1],
    }
    clock = [(t, (t // 5) % 2) for t in range(0, 50, 5)]
    tracks = [('clk', clock)] + [(name, list(zip(range(0, 50, 10), values)))
                                   for name, values in inputs.items()]
    tracks += [('selected', None), ('q', None), ('busy', None)]
    draw('clocked-waveforms.png', 'Registers and FSM waveform exercise',
         'Draw selected, q, and busy. Red dashed lines mark rising clock edges.',
         tracks, 50, rising_edges=range(5, 50, 10))


if __name__ == '__main__':
    main()
