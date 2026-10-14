# sb_systolic_tile — interface and timing specification

Your RTL implements the interface. Your SDC implements the timing section; every number in it must trace to a line here.
Where the SDC goes: your track's `track/lab2.md`.

## Function

    C[r][c] = Σ_{k=0}^{K-1} A[r][k] · W[k][c]      r < N_ROWS, c < N_COLS, K ≤ WBUF_DEPTH

Signed int8 operands. Output-stationary systolic array: N_ROWS × N_COLS PEs, each holding one accumulator C[r][c]. Activations flow left to right, weights top to bottom, one step per clock.

## Parameters

| Parameter | Default | Range | Meaning |
|---|---|---|---|
| `N_ROWS`, `N_COLS` | 4, 4 | 2–8 each | array size |
| `DATA_W` | 8 | 8 | signed operand width (the weight-buffer macro is 8 bits wide) |
| `WBUF_DEPTH` | 256 | 256 | weight-buffer depth = largest K (the macro has 256 words) |
| `ACC_W` | see `rtl/params.svh` | 16–32 | accumulator width: must hold the largest possible C[r][c] |
| `MUL_PIPE` | 0 | 0–2 | pipeline registers inside each PE's multiplier: 1 = on its two partial products, 2 = also on their sum |
| `ACC_PIPE` | 0 | 0–1 | register between multiplier and accumulator |
| `OUT_PIPE` | 0 | 0–1 | register on the result path (res_data) |

The `*_PIPE` parameters change latency, never results. The testbench needs no change (valid/ready handshakes).

## Ports

| Port | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | clock, rising edge |
| `rst_n` | in | 1 | reset, active low. **Asserted and released asynchronously**; the tile must release its internal reset synchronously to `clk` |
| `cfg_k_len` | in | 8 | K − 1 for the next tile. **Quasi-static**: changes only while idle, stable ≥ 2 cycles before the first activation beat |
| `w_we` | in | 1 | write one weight this cycle (only while idle) |
| `w_addr` | in | log2(N_COLS) + 8 | `{column, k}`: weight W[k][column] |
| `w_data` | in | 8 | the weight, signed |
| `act_valid` | in | 1 | an activation beat is offered |
| `act_ready` | out | 1 | the tile accepts it (beat moves when both are 1 at a rising edge) |
| `act_data` | in | N_ROWS × 8 | beat k: A[r][k] in bits `[r*8 +: 8]` |
| `res_sel` | in | log2(N_ROWS·N_COLS) | which result: `r * N_COLS + c` |
| `res_valid` | out | 1 | `res_data` holds C for the current `res_sel` |
| `res_ready` | in | 1 | the reader takes it (moves when both are 1 at a rising edge) |
| `res_data` | out | ACC_W | C[r][c], signed |

## Protocol

1. **Load weights** (idle): one `w_we` write per cycle, any order.
2. **Stream activations**: set `cfg_k_len = K − 1`, offer beats k = 0 … K−1 with `act_valid`. The first accepted beat starts the tile and clears all accumulators. Gaps (`act_valid = 0`) allowed.
3. **Read results**: when the array is done, `res_valid` rises. Set `res_sel`, raise `res_ready`; each handshake delivers one C[r][c]. After N_ROWS·N_COLS handshakes the tile is idle.

## Timing specification

| Item | Value |
|---|---|
| Clock frequency | the clock target for your library is in your track's `track/README.md` |
| Clock transition at the clock pin | sky130 libraries: 0.10 ns; gf180 libraries: 0.20 ns |
| Clock uncertainty | setup: 10 % of the period; hold: 0.05 ns ([05](../../docs/05_sdc.md#clocks)) |
| Input delay | 30 % of the period after the clock edge, **every** input except `clk` and `rst_n` |
| Output delay | 30 % of the period before the next edge, **every** output |
| Input driver | the library's `buf_2` (or its equivalent, e.g. `BUFX2`) |
| Output load | 4 × the input capacitance of the library's `buf_4` (or its equivalent, e.g. `BUFX4`); write the Liberty value in a comment |
| Max transition | library defaults; reported, not signed off |
| Max fanout | 16; reported, not signed off |
| `cfg_k_len` | may be given 2 cycles (see ports). Any multicycle or false path needs a comment explaining why it is safe |
| `rst_n` | asynchronous (see ports); constrain it and explain how in a comment |

Sign-off rule (your track's checks): setup at `ss`, hold at `ff`, no unconstrained endpoints.

## Targets

The Bronze clock target for your library is in your track's `track/README.md`.

- **Bronze**: everything passes at the clock target.
- **Silver**: 0.70 × that period at `ss`, hold clean at `ff`, area ≤ 1.25 × Bronze.
- **Gold**: Silver in a second library, plus `N_ROWS = N_COLS = 8` at the Bronze period.
- **Leaderboard**: area (µm²) × clock period (ns) at `ss`.

Next: [Lab 2 tasks](README.md#tasks)
