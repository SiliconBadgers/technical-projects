# `sb_fifo` Specification

Version 1.0 (2026-10-08). Ports, handshake rules and example waveforms: [`interface.md`](interface.md).

## 1. Summary

A synchronous FIFO for `WIDTH`-bit entries with a valid/ready handshake on both sides. A producer pushes entries on the write side; a consumer pops them, oldest first, on the read side. The oldest entry is visible on `out_data` whenever `out_valid` is 1 (show-ahead). The FIFO reports how many entries it holds (`count`) and two threshold flags, and `flush` empties it in one cycle.

## 2. Block diagram

```
               +-------------------------------------------------+
  in_valid --->|                                                 |---> out_valid
  in_ready <---|  write side --> storage: DEPTH entries --> read |<--- out_ready
  in_data  ===>|                 (oldest first)            side |===> out_data
               |                                                 |
  flush    --->|  fill counter --> threshold compare             |===> count
  clk, rst_n ->|                                                 |---> almost_full, almost_empty
               +-------------------------------------------------+
```

## 3. Parameters

| Parameter | Default | Valid range | Description |
|---|---|---|---|
| `WIDTH` | 8 | ≥ 1 | Entry width in bits |
| `DEPTH` | 6 | ≥ 2 | Entries the FIFO can hold; need not be a power of two |
| `AF_LEVEL` | `DEPTH` − 1 | 1 … `DEPTH` | `almost_full` threshold |
| `AE_LEVEL` | 1 | 0 … `DEPTH` − 1 | `almost_empty` threshold |

Out-of-range values stop elaboration with `$error`. The course builds the defaults; `make DEPTH=<n> WIDTH=<w>` builds another size with the default thresholds.

| Derived | Value (defaults) |
|---|---|
| `CNT_W` = ⌈log2(`DEPTH`+1)⌉ | 3 |
| `AF_LEVEL`, `AE_LEVEL` | 5, 1 |

## 4. Clock and reset

| Signal | Description |
|---|---|
| `clk` | All ports are synchronous to the rising edge. |
| `rst_n` | Active low. Asynchronous assert, synchronous deassert. |

An *edge* is a rising edge of `clk`. "X at edge *c*" means the value of X sampled at edge *c*. At an edge where `rst_n` is 1:

- a *push* happens if `in_valid` and `in_ready` are both 1;
- a *pop* happens if `out_valid` and `out_ready` are both 1;
- it is a *flush edge* if `flush` is 1.

## 5. Interfaces

| Group | Ports | Direction |
|---|---|---|
| Write | `in_valid`, `in_ready`, `in_data` | producer → FIFO |
| Read | `out_valid`, `out_ready`, `out_data` | FIFO → consumer |
| Control | `flush` | host → FIFO |
| Status | `count`, `almost_full`, `almost_empty` | FIFO → host |

Details are in [`interface.md`](interface.md).

## 6. Status outputs

| Output | Width | Reset | Value |
|---|---|---|---|
| `count` | `CNT_W` | 0 | Entries stored |
| `almost_full` | 1 | 0 | 1 iff `count` ≥ `AF_LEVEL` |
| `almost_empty` | 1 | 1 | 1 iff `count` ≤ `AE_LEVEL` |

With the defaults, `almost_full` means "at most one free slot" and `almost_empty` means "at most one entry".

## 7. Function

**Contents.** The FIFO holds a list of entries, oldest first; `count` is its length. At each edge where `rst_n` is 1, in this order:

1. A pop removes the oldest entry. The consumer receives `out_data` at that edge.
2. A push appends `in_data`.
3. At a flush edge the list is emptied, including an entry pushed in step 2.

**Write side.** `in_ready` = 1 iff `count` < `DEPTH`, except that `in_ready` is 0 while `rst_n` is 0 and at the first edge after `rst_n` rises. `in_ready` does not depend on `out_ready`: when `count` = `DEPTH`, a push waits even if a pop happens at the same edge.

**Read side.** `out_valid` = 1 iff `count` > 0. While `out_valid` is 1, `out_data` is the oldest entry; while it is 0, `out_data` is undefined. An entry pushed at edge *c* can be popped at edge *c*+1 at the earliest (no bypass).

**Count.** After an edge, `count` is 0 if `rst_n` was 0 or it was a flush edge; otherwise it is `count` + push − pop (a push and a pop at the same edge leave it unchanged).

**Reset.** While `rst_n` is 0, every entry is discarded, `count`, `out_valid`, `in_ready` and `almost_full` are 0, and `almost_empty` is 1.

**Flush.** At a flush edge every stored entry is discarded. A push at that edge completes its handshake, but its entry is discarded too. A pop at that edge still delivers the oldest entry. `rst_n` = 0 overrides `flush`.

### Timing

| Operation | Value |
|---|---|
| Push at edge *c* → entry on `out_data` | From edge *c*+1 |
| Pop at edge *c* → space for a push (when it was full) | From edge *c*+1 |
| Throughput | One push and one pop per edge |
| `rst_n` rises → first push possible | Second edge with `rst_n` = 1 |

## 8. Requirements

| ID | Requirement |
|---|---|
| R01 | While `rst_n` is 0, `count`, `out_valid`, `in_ready` and `almost_full` shall be 0 and `almost_empty` shall be 1. |
| R02 | `in_ready` shall be 0 at the first edge where `rst_n` is 1 again. |
| R03 | No entry pushed before a reset shall be popped after it. |
| R04 | A push shall happen once at every edge where `in_valid` and `in_ready` are both 1, and shall store `in_data`. |
| R05 | Apart from R01 and R02, `in_ready` shall be 1 iff `count` < `DEPTH`, whatever `out_ready` is. |
| R06 | `out_valid` shall be 1 iff `count` > 0. |
| R07 | A pop shall happen once at every edge where `out_valid` and `out_ready` are both 1; the consumer receives `out_data` at that edge. |
| R08 | Entries shall be popped in push order, each exactly once, with the value pushed. |
| R09 | `count` shall be the number of entries stored: +1 after an edge with only a push, −1 after an edge with only a pop, unchanged otherwise. |
| R10 | `almost_full` shall be 1 iff `count` ≥ `AF_LEVEL`. |
| R11 | `almost_empty` shall be 1 iff `count` ≤ `AE_LEVEL`. |
| R12 | If `out_valid` is 1 and `out_ready` and `flush` are 0 at an edge, `out_valid` and `out_data` shall be unchanged at the next edge (unless `rst_n` falls). |
| R13 | At a flush edge, every stored entry and any entry pushed at that edge shall be discarded; `count` shall be 0 at the next edge. |
| R14 | A pop at a flush edge shall deliver the oldest entry; a push at a flush edge shall complete its handshake. |

## 9. Corner cases

| Condition | Behaviour |
|---|---|
| Push offered while full, pop at the same edge | Push waits one edge (R05) |
| Push and pop at the same edge | `count` unchanged (R09) |
| Push into an empty FIFO | `out_valid` from the next edge (R06) |
| `out_ready` = 1 while empty | No pop (R07) |
| Storage wraps around (any `DEPTH`) | Order and values kept (R08) |
| `flush` with a push, a pop or both | R13, R14 |
| `flush` while full or empty | Empty after the edge (R13) |
| `flush` held for several edges | Each one is a flush edge |
| Reset during traffic | Every entry discarded (R03) |
| Producer drops `in_valid` or changes `in_data` before `in_ready` | Undefined (AS2) |

## 10. Assumptions

| ID | Assumption |
|---|---|
| AS1 | Inputs change only after a rising edge. |
| AS2 | Once `in_valid` is 1, it and `in_data` stay unchanged until the push (or reset). |
| AS3 | Inputs are never X or Z out of reset. |
| AS4 | `rst_n` is released synchronously to `clk`. |

## 11. Open questions

| ID | Question | Raised by | Answer |
|---|---|---|---|
| | | | |
