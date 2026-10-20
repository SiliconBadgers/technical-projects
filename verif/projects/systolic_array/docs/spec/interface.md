# `sb_systolic_array` Interface

## 1. Ports

```systemverilog
module sb_systolic_array #(
  parameter int N      = 4,
  parameter int DATA_W = 8,
  parameter int ACC_W  = 32
) (
  input  logic                   clk,
  input  logic                   rst_n,
  input  logic                   wr_valid,
  output logic                   wr_ready,
  input  logic [$clog2(N+1)-1:0] wr_addr,
  input  logic [N*DATA_W-1:0]    wr_data,
  input  logic                   a_valid,
  output logic                   a_ready,
  input  logic [N*DATA_W-1:0]    a_data,
  output logic                   r_valid,
  input  logic                   r_ready,
  output logic [N*ACC_W-1:0]     r_data,
  output logic                   busy
);
```

| Port | Dir | Width (N = 4) | Reset value | Description |
|---|---|---|---|---|
| `clk` | in | 1 | — | Clock |
| `rst_n` | in | 1 | — | Active-low reset |
| `wr_valid` | in | 1 | — | Write offered |
| `wr_ready` | out | 1 | 0 | Write can be accepted |
| `wr_addr` | in | 3 | — | Register address |
| `wr_data` | in | 32 | — | Write data |
| `a_valid` | in | 1 | — | Activation offered |
| `a_ready` | out | 1 | 0 | Activation can be accepted |
| `a_data` | in | 32 | — | Activation vector |
| `r_valid` | out | 1 | 0 | Result offered |
| `r_ready` | in | 1 | — | Result can be taken |
| `r_data` | out | 128 | — | Result vector |
| `busy` | out | 1 | 0 | Results outstanding |

## 2. Bit packing

Lane *i* is at bits `[i·w + w−1 : i·w]`, where *w* is the lane width. Lane 0 is in the least significant bits. All lanes are two's complement.

| Bus | Lane width | Lanes |
|---|---|---|
| `a_data` | 8 | `x[0] .. x[N-1]` |
| `wr_data` (weight row m) | 8 | `W[m][0] .. W[m][N-1]` |
| `wr_data` (CTRL) | — | bit 0 = `RELU_EN` |
| `r_data` | 32 | `y[0] .. y[N-1]` |

## 3. Handshake rules

| Rule | Applies to | Statement |
|---|---|---|
| P1 | all channels | A transfer happens at every rising edge where `valid` and `ready` are both 1. |
| P2 | host (WR, A) | Once `valid` is 1, `valid` and the payload stay unchanged until the transfer (except reset). |
| P3 | DUT (R) | Once `r_valid` is 1, `r_valid` and `r_data` stay unchanged until the transfer (except reset). |
| P4 | all channels | `ready` may be 1 before `valid`. |
| P5 | DUT | `wr_ready` depends combinationally on `a_valid`. No other output depends combinationally on an input. |
