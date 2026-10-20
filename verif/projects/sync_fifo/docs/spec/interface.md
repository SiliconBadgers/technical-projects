# `sb_fifo` Interface

## 1. Ports

```systemverilog
module sb_fifo #(
  parameter int WIDTH    = 8,
  parameter int DEPTH    = 6,
  parameter int AF_LEVEL = DEPTH - 1,
  parameter int AE_LEVEL = 1
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       flush,
  input  logic                       in_valid,
  output logic                       in_ready,
  input  logic [WIDTH-1:0]           in_data,
  output logic                       out_valid,
  input  logic                       out_ready,
  output logic [WIDTH-1:0]           out_data,
  output logic [$clog2(DEPTH+1)-1:0] count,
  output logic                       almost_full,
  output logic                       almost_empty
);
```

| Port | Dir | Width (defaults) | Reset value | Description |
|---|---|---|---|---|
| `clk` | in | 1 | — | Clock |
| `rst_n` | in | 1 | — | Active-low reset |
| `flush` | in | 1 | — | Empty the FIFO at this edge |
| `in_valid` | in | 1 | — | Producer offers `in_data` |
| `in_ready` | out | 1 | 0 | FIFO can take an entry |
| `in_data` | in | 8 | — | Entry offered |
| `out_valid` | out | 1 | 0 | An entry is available |
| `out_ready` | in | 1 | — | Consumer takes the entry |
| `out_data` | out | 8 | undefined | Oldest entry, while `out_valid` is 1 |
| `count` | out | 3 | 0 | Entries stored (unsigned) |
| `almost_full` | out | 1 | 0 | `count` ≥ `AF_LEVEL` |
| `almost_empty` | out | 1 | 1 | `count` ≤ `AE_LEVEL` |

`in_data` and `out_data` are opaque: the FIFO never changes an entry.

## 2. Handshake rules

| Rule | Applies to | Statement |
|---|---|---|
| P1 | both sides | A transfer happens at every rising edge where `valid` and `ready` are both 1 and `rst_n` is 1. |
| P2 | producer | Once `in_valid` is 1, `in_valid` and `in_data` stay unchanged until the push (except reset). |
| P3 | FIFO | Once `out_valid` is 1, `out_valid` and `out_data` stay unchanged until the pop (except flush and reset). |
| P4 | both sides | `ready` may be 1 before `valid`. The producer does not wait for `in_ready` to raise `in_valid`. |
| P5 | FIFO | No output depends combinationally on an input: every output changes only after a rising edge. In particular `in_ready` does not depend on `out_ready`. |

## 3. Examples

One row per rising edge, with values sampled at that edge (`DEPTH` = 6, `AF_LEVEL` = 5, `AE_LEVEL` = 1). **push** and **pop** mark transfers. Data are hex; blank means "don't care".

### E1. Reset release, backpressure, push and pop at the same edge

| edge | rst_n | flush | in_valid | in_ready | in_data | out_valid | out_ready | out_data | count | almost_full | almost_empty |
|---:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 0 | 0 | 0 | 0 | 0 |  | 0 | 0 |  | 0 | 0 | 1 |
| 1 | 0 | 0 | 0 | 0 |  | 0 | 0 |  | 0 | 0 | 1 |
| 2 | 1 | 0 | 1 | 0 | a1 | 0 | 0 |  | 0 | 0 | 1 |
| 3 | 1 | 0 | 1 | 1 **push** | a1 | 0 | 0 |  | 0 | 0 | 1 |
| 4 | 1 | 0 | 1 | 1 **push** | b2 | 1 | 0 | a1 | 1 | 0 | 1 |
| 5 | 1 | 0 | 0 | 1 |  | 1 | 0 | a1 | 2 | 0 | 0 |
| 6 | 1 | 0 | 1 | 1 **push** | c3 | 1 | 1 **pop** | a1 | 2 | 0 | 0 |
| 7 | 1 | 0 | 0 | 1 |  | 1 | 1 **pop** | b2 | 2 | 0 | 0 |
| 8 | 1 | 0 | 0 | 1 |  | 1 | 1 **pop** | c3 | 1 | 0 | 1 |
| 9 | 1 | 0 | 0 | 1 |  | 0 | 1 |  | 0 | 0 | 1 |

Edge 2: first edge after reset, so `in_ready` is still 0 (R02). Edges 4–5: the consumer stalls and `a1` stays on `out_data` (P3). Edge 6: a push and a pop; `count` stays 2.

### E2. Full: a push waits even when a pop happens at the same edge

| edge | rst_n | flush | in_valid | in_ready | in_data | out_valid | out_ready | out_data | count | almost_full | almost_empty |
|---:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 0 | 1 | 0 | 1 | 1 **push** | 14 | 1 | 0 | 10 | 4 | 0 | 0 |
| 1 | 1 | 0 | 1 | 1 **push** | 15 | 1 | 0 | 10 | 5 | 1 | 0 |
| 2 | 1 | 0 | 1 | 0 | 16 | 1 | 0 | 10 | 6 | 1 | 0 |
| 3 | 1 | 0 | 1 | 0 | 16 | 1 | 1 **pop** | 10 | 6 | 1 | 0 |
| 4 | 1 | 0 | 1 | 1 **push** | 16 | 1 | 1 **pop** | 11 | 5 | 1 | 0 |
| 5 | 1 | 0 | 0 | 1 |  | 1 | 0 | 12 | 5 | 1 | 0 |

The FIFO held `10`–`13` before edge 0. Edge 3: the FIFO is full, so `16` waits although `10` is popped (R05, P5). It is pushed at edge 4.

### E3. Flush with a push and a pop at the same edge

| edge | rst_n | flush | in_valid | in_ready | in_data | out_valid | out_ready | out_data | count | almost_full | almost_empty |
|---:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 0 | 1 | 0 | 1 | 1 **push** | 23 | 1 | 0 | 21 | 2 | 0 | 0 |
| 1 | 1 | 0 | 1 | 1 **push** | 24 | 1 | 0 | 21 | 3 | 0 | 0 |
| 2 | 1 | 1 | 1 | 1 **push** | 25 | 1 | 1 **pop** | 21 | 4 | 0 | 0 |
| 3 | 1 | 0 | 1 | 1 **push** | 26 | 0 | 0 |  | 0 | 0 | 1 |
| 4 | 1 | 0 | 0 | 1 |  | 1 | 1 **pop** | 26 | 1 | 0 | 1 |

The FIFO held `21` and `22` before edge 0. Edge 2: `21` is delivered (R14); `22`, `23`, `24` and the entry pushed at the flush edge, `25`, are discarded (R13).
