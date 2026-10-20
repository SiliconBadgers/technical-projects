#!/usr/bin/env python3
# File:        block_diagram.py
# Author:      Isaac Hagedorn
# Date:        2025-08-09
# Description: Draws docs/spec/block_diagram.svg.
import os

N = 4
W, H = 1330, 770
out = []
INK, MUTED = "#1f2328", "#57606a"
DATA_FILL, CTRL_FILL, STORE_FILL, PE_FILL = "#ddf4ff", "#fff1d6", "#dafbe1", "#ffffff"
DATA_EDGE, CTRL_EDGE, STORE_EDGE = "#0969da", "#bc4c00", "#1a7f37"


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def box(x, y, w, h, fill, edge, title=None, lines=(), r=8, title_size=14):
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{edge}" stroke-width="1.5"/>')
    ty = y + 22
    if title:
        out.append(f'<text x="{x + w / 2}" y="{ty}" text-anchor="middle" font-size="{title_size}" font-weight="600" fill="{INK}">{esc(title)}</text>')
        ty += 18
    for ln in lines:
        out.append(f'<text x="{x + w / 2}" y="{ty}" text-anchor="middle" font-size="12" fill="{MUTED}">{esc(ln)}</text>')
        ty += 16


def text(x, y, s, size=12, anchor="start", color=INK, weight="normal", mono=False):
    fam = ' font-family="ui-monospace,SFMono-Regular,Menlo,Consolas,monospace"' if mono else ""
    out.append(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-size="{size}" font-weight="{weight}" fill="{color}"{fam}>{esc(s)}</text>')


def arrow(x1, y1, x2, y2, color=INK, width=1.5, dash=None, head=True):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    m = ' marker-end="url(#ah)"' if head else ""
    if color != INK and head:
        m = f' marker-end="url(#ah_{color[1:]})"'
    out.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}"{d}{m}/>')


def poly(points, color=INK, width=1.5, dash=None, head=True):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    m = (f' marker-end="url(#ah_{color[1:]})"' if color != INK else ' marker-end="url(#ah)"') if head else ""
    pts = " ".join(f"{x},{y}" for x, y in points)
    out.append(f'<polyline points="{pts}" fill="none" stroke="{color}" stroke-width="{width}"{d}{m}/>')


def port(x, y, name, direction, side="left"):
    """Draws a port arrow and label on the left or right edge of the DUT."""
    if side == "left":
        if direction == "in":
            arrow(x - 120, y, x - 4, y)
        else:
            arrow(x, y, x - 116, y)
        text(x - 124, y + 4, name, 13, "end", mono=True)
    else:
        if direction == "out":
            arrow(x, y, x + 116, y)
        else:
            arrow(x + 120, y, x + 4, y)
        text(x + 124, y + 4, name, 13, "start", mono=True)


markers = "".join(
    f'<marker id="ah{"_" + c[1:] if c != INK else ""}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>'
    for c in (INK, DATA_EDGE, CTRL_EDGE, STORE_EDGE))

# DUT outline
DX, DY, DW, DH = 170, 20, 840, 735
out.append(f'<rect x="{DX}" y="{DY}" width="{DW}" height="{DH}" rx="14" fill="#f6f8fa" stroke="{MUTED}" stroke-width="1.5" stroke-dasharray="6 4"/>')
text(DX + DW / 2, DY + 22, "sb_systolic_array  (N = 4, DATA_W = 8, ACC_W = 32)", 15, "middle", weight="600")

# Ports, left side
text(DX - 124, 70, "WR channel", 12, "end", MUTED, "600")
for i, (nm, d) in enumerate([("wr_valid", "in"), ("wr_ready", "out"), ("wr_addr[2:0]", "in"), ("wr_data[31:0]", "in")]):
    port(DX, 90 + 22 * i, nm, d)
text(DX - 124, 300, "A channel", 12, "end", MUTED, "600")
for i, (nm, d) in enumerate([("a_valid", "in"), ("a_ready", "out"), ("a_data[31:0]", "in")]):
    port(DX, 320 + 22 * i, nm, d)
for i, nm in enumerate(["clk", "rst_n"]):
    port(DX, 705 + 22 * i, nm, "in")
# Ports, right side
text(DX + DW + 124, 585, "R channel", 12, "start", MUTED, "600")
for i, (nm, d) in enumerate([("r_valid", "out"), ("r_ready", "in"), ("r_data[127:0]", "out")]):
    port(DX + DW, 605 + 22 * i, nm, d, "right")
port(DX + DW, 730, "busy", "out", "right")

# Write port / registers
box(200, 55, 290, 130, STORE_FILL, STORE_EDGE, "Write port + registers",
    ["weights W[N][N]", "CTRL.RELU_EN"])
arrow(DX, 90, 200, 90); arrow(DX, 134, 200, 134); arrow(DX, 156, 200, 156)

# Flow control
box(200, 585, 250, 140, CTRL_FILL, CTRL_EDGE, "Flow control",
    ["a_ready, wr_ready, busy"])

# Input register + skew
SX, SY, SWD, SH = 200, 195, 200, 345
box(SX, SY, SWD, SH, DATA_FILL, DATA_EDGE, "Input reg + skew")
arrow(DX, 364, SX, 364, DATA_EDGE)

# PE grid
GX, GY, PS, PP = 470, 230, 62, 84
rows_y = [GY + PP * m + PS / 2 for m in range(N)]
for m in range(N):
    # skew delay cells for row m
    for k in range(m):
        cx = SX + SWD - 30 - 24 * (k + 1)
        out.append(f'<rect x="{cx}" y="{rows_y[m] - 9}" width="18" height="18" fill="#ffffff" stroke="{DATA_EDGE}" stroke-width="1"/>')
    text(SX + 14, rows_y[m] + 4, f"x[{m}]", 12, "start", DATA_EDGE, mono=True)
    arrow(SX + SWD - 28, rows_y[m], GX - 2, rows_y[m], DATA_EDGE)
for m in range(N):
    for n in range(N):
        x, y = GX + PP * n, GY + PP * m
        out.append(f'<rect x="{x}" y="{y}" width="{PS}" height="{PS}" rx="6" fill="{PE_FILL}" stroke="{INK}" stroke-width="1.3"/>')
        text(x + PS / 2, y + 26, f"PE({m},{n})", 11, "middle", mono=True)
        text(x + PS / 2, y + 44, f"W[{m}][{n}]", 10, "middle", STORE_EDGE, mono=True)
        if n < N - 1:
            arrow(x + PS, y + PS / 2, x + PP - 2, y + PS / 2, DATA_EDGE)
        if m < N - 1:
            arrow(x + PS / 2, y + PS, x + PS / 2, y + PP - 2, CTRL_EDGE)
for n in range(N):
    x = GX + PP * n + PS / 2
    text(x, GY - 22, "0", 12, "middle", CTRL_EDGE, mono=True)
    arrow(x, GY - 16, x, GY - 2, CTRL_EDGE)

# Deskew, ReLU, FIFO
BY = GY + PP * N - (PP - PS) + 22
for n in range(N):
    x = GX + PP * n + PS / 2
    arrow(x, BY - 22, x, BY - 2, CTRL_EDGE)
box(GX, BY, PP * N - (PP - PS), 52, DATA_FILL, DATA_EDGE, "Deskew", title_size=13)
RY = BY + 74
arrow(GX + 155, BY + 52, GX + 155, RY - 2, CTRL_EDGE)
box(GX, RY, PP * N - (PP - PS), 52, DATA_FILL, DATA_EDGE, "ReLU (if RELU_EN)", title_size=13)
# RELU_EN from CTRL to the ReLU block
poly([(490, 120), (815, 120), (815, RY + 16), (GX + PP * N - (PP - PS) + 2, RY + 16)], STORE_EDGE, 1.3, "5 4")
text(820, 140, "RELU_EN", 11, "start", STORE_EDGE, mono=True)
FX, FY = 860, 585
box(FX, FY, 140, 110, STORE_FILL, STORE_EDGE, "Result FIFO", ["2N+2 entries"], title_size=13)
poly([(GX + PP * N - (PP - PS), RY + 40), (FX - 20, RY + 40), (FX - 20, FY + 55), (FX - 2, FY + 55)], CTRL_EDGE)
text(FX - 60, RY + 56, "push", 11, "start", MUTED, mono=True)
arrow(FX + 140, 605, DX + DW, 605); arrow(DX + DW, 627, FX + 142, 627); arrow(FX + 140, 649, DX + DW, 649)
# flow control <-> ports
poly([(DX, 342), (185, 342), (185, 625), (200, 625)], CTRL_EDGE, 1.2, head=False)
poly([(DX, 320), (192, 320), (192, 605), (198, 605)], CTRL_EDGE, 1.2)
poly([(DX, 112), (180, 112), (180, 645), (200, 645)], CTRL_EDGE, 1.2, head=False)
poly([(450, 715), (DX + DW - 6, 715), (DX + DW - 6, 730), (DX + DW, 730)], CTRL_EDGE, 1.2, head=False)

# Legend
LX, LY = 1035, 40
text(LX, LY, "Legend", 12, "start", INK, "600")
for i, (fill, edge, label) in enumerate([(DATA_FILL, DATA_EDGE, "datapath"), (STORE_FILL, STORE_EDGE, "state / storage"),
                                          (CTRL_FILL, CTRL_EDGE, "control")]):
    out.append(f'<rect x="{LX}" y="{LY + 12 + 24 * i}" width="18" height="14" fill="{fill}" stroke="{edge}"/>')
    text(LX + 26, LY + 24 + 24 * i, label, 12)
arrow(LX, LY + 98, LX + 30, LY + 98, DATA_EDGE); text(LX + 36, LY + 102, "activation (int8)", 12)
arrow(LX, LY + 120, LX + 30, LY + 120, CTRL_EDGE); text(LX + 36, LY + 124, "partial sum (int32)", 12)
poly([(LX, LY + 142), (LX + 30, LY + 142)], STORE_EDGE, 1.3, "5 4", head=False); text(LX + 36, LY + 146, "quasi-static config", 12)

svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W + 160}" height="{H}" viewBox="-160 0 {W + 160} {H}" '
       f'font-family="-apple-system,Segoe UI,Helvetica,Arial,sans-serif">'
       f'<title>sb_systolic_array block diagram</title><defs>{markers}</defs>'
       f'<rect x="-160" y="0" width="{W + 160}" height="{H}" fill="#ffffff"/>' + "".join(out) + "</svg>\n")
dst = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "block_diagram.svg")
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(svg)
print(f"wrote {dst}")
