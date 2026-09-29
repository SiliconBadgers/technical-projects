#!/usr/bin/env python3
"""Render the Stage 2 matrix multiplication animation. Requires Pillow.

Run from the repository root: python3 scripts/render_matmul.py
The committed GIF can be viewed without installing Pillow.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'intro/projects/processing-element/exercises/images/matmul.gif'
A = [[1, 2], [3, 4]]
B = [[5, 6], [7, 8]]
SIZE = (960, 540)
INK = '#172638'
MUTED = '#536174'
BLUE = '#156aab'
PURPLE = '#7443ad'
GREEN = '#177050'


def font(size):
    """Use a readable installed font, with Pillow's bundled font as a fallback."""
    for name in ('DejaVuSans.ttf', '/usr/share/fonts/open-sans/OpenSans-Regular.ttf'):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default(size=size)


def centered(draw, xy, text, size, fill=INK):
    draw.text(xy, text, font=font(size), fill=fill, anchor='mm')


def matrix(draw, x, label, values, color, tint, active=None, selected=None):
    draw.rounded_rectangle((x, 128, x + 244, 358), radius=16,
                           fill='white', outline='#dbe2eb', width=2)
    centered(draw, (x + 122, 154), label, 25, color)
    for row in range(2):
        for col in range(2):
            cell = (row, col)
            left, top = x + 39 + col * 84, 184 + row * 74
            fill = color if cell == active else tint if cell in (selected or ()) else '#f1f4f8'
            draw.rounded_rectangle((left, top, left + 78, top + 66), radius=8, fill=fill)
            value = values[row][col]
            centered(draw, (left + 39, top + 33), '—' if value is None else str(value),
                     32, 'white' if cell == active else INK)


def frame(results, entry=None, k=None, complete=False):
    image = Image.new('RGB', SIZE, '#f6f8fb')
    draw = ImageDraw.Draw(image)
    draw.text((36, 23), 'Matrix multiplication: one result at a time', font=font(30), fill=INK)
    draw.text((36, 72), 'Multiply matching row and column entries, then add the products.',
              font=font(20), fill=MUTED)
    i, j = entry if entry is not None else (None, None)
    matrix(draw, 40, 'A · choose a row', A, BLUE, '#deedf9',
           (i, k) if k is not None else None,
           {(i, col) for col in range(2)} if entry is not None else None)
    matrix(draw, 358, 'B · choose a column', B, PURPLE, '#eee3fa',
           (k, j) if k is not None else None,
           {(row, j) for row in range(2)} if entry is not None else None)
    matrix(draw, 676, 'C · running sums', results, GREEN, '#dcf2e8', active=entry)
    centered(draw, (321, 240), '×', 36)
    centered(draw, (639, 240), '=', 36)
    draw.rounded_rectangle((40, 384, 920, 474), radius=12, fill='white',
                           outline='#dbe2eb', width=2)
    if k is not None:
        a, b = A[i][k], B[k][j]
        prior = sum(A[i][n] * B[n][j] for n in range(k))
        expression = f'{a} × {b}' if k == 0 else f'{prior} + {a} × {b}'
        centered(draw, (480, 430), f'C[{i},{j}] = {expression} = {results[i][j]}', 30)
        note = f'k = {k} · ' + ('first product' if k == 0 else 'second product · result complete')
    elif entry is not None:
        centered(draw, (480, 430), f'C[{i},{j}] is complete: {results[i][j]}', 30)
        note = 'Keep this result and move to the next row / column pair.'
    elif complete:
        centered(draw, (480, 430), 'All four dot products are complete.', 30)
        note = 'C = [[19, 22], [43, 50]]'
    else:
        centered(draw, (480, 430), 'C[i,j] = A[i,0] × B[0,j] + A[i,1] × B[1,j]', 25)
        note = 'Indices start at zero. Each result uses two products.'
    centered(draw, (480, 505), note, 20, MUTED)
    return image


def main():
    results = [[None, None], [None, None]]
    frames = [frame(results)]
    durations = [2200]
    for i in range(2):
        for j in range(2):
            results[i][j] = 0
            for k in range(2):
                results[i][j] += A[i][k] * B[k][j]
                frames.append(frame(results, (i, j), k))
                durations.append(1800)
            frames.append(frame(results, (i, j)))
            durations.append(900)
    frames.append(frame(results, complete=True))
    durations.append(3500)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(OUTPUT, save_all=True, append_images=frames[1:],
                   duration=durations, loop=0, disposal=2, optimize=False)
    print(OUTPUT.relative_to(ROOT))


if __name__ == '__main__':
    main()
