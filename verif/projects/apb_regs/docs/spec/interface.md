# `sb_apb_regs` Interface

## 1. Ports

```systemverilog
module sb_apb_regs #(
  parameter int ADDR_W = 8,
  parameter int DATA_W = 32
) (
  input  logic                pclk,
  input  logic                presetn,
  input  logic                psel,
  input  logic                penable,
  input  logic                pwrite,
  input  logic [ADDR_W-1:0]   paddr,
  input  logic [DATA_W-1:0]   pwdata,
  input  logic [DATA_W/8-1:0] pstrb,
  output logic [DATA_W-1:0]   prdata,
  output logic                pready,
  output logic                pslverr,
  output logic                irq
);
```

| Port | Dir | Width | Reset value | Description |
|---|---|---|---|---|
| `pclk` | in | 1 | — | Clock |
| `presetn` | in | 1 | — | Active-low reset |
| `psel` | in | 1 | — | Completer selected |
| `penable` | in | 1 | — | Access phase |
| `pwrite` | in | 1 | — | 1 = write, 0 = read |
| `paddr` | in | 8 | — | Byte address; `[1:0]` ignored |
| `pwdata` | in | 32 | — | Write data |
| `pstrb` | in | 4 | — | Write byte lane enables; 0 for reads |
| `prdata` | out | 32 | 0 | Read data |
| `pready` | out | 1 | 1 (with `psel` = 0) | 0 = wait state |
| `pslverr` | out | 1 | 0 | Error response |
| `irq` | out | 1 | 0 | Interrupt, active high, level |

## 2. APB4 phases

Every transfer has one setup edge followed by one or more access edges:

| Phase | `psel` | `penable` | `pready` | What happens at the edge |
|---|---|---|---|---|
| Idle | 0 | 0 | — | Nothing |
| Setup | 1 | 0 | — | Nothing; the host presents `pwrite`, `paddr`, `pwdata`, `pstrb` |
| Access, wait state | 1 | 1 | 0 | Nothing; the host holds everything |
| Access, completion | 1 | 1 | 1 | The transfer takes effect; `prdata` and `pslverr` are valid |

After a completion the host either starts the next setup at the following edge (back-to-back) or drops `psel`.

**Wait states.** Reads of `TIMER_VALUE` (`0x10`) have exactly one wait state: `pready` is 0 at the first access edge and 1 at the second. The value returned is the counter at the first access edge. Every other transfer completes at its first access edge.

**Responses.** See the transfer table in the spec, Section 7. `prdata` is 0 except at the completion edge of a read without error; `pslverr` is 0 except at the completion edge of an error transfer.

## 3. Example

`TIMER_LOAD` = 4 and `INT_ENABLE` = `0x1` were written earlier. Values are at each edge (sampled just before it); "counter" and `INT_STATUS` are internal, shown for reference. `-` means "don't care".

| Edge | `psel` | `penable` | `pwrite` | `paddr` | `pwdata` | `pstrb` | `pready` | `prdata` | `pslverr` | counter | `INT_STATUS` | `irq` | Note |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 1 | `04` | `00000001` | `F` | 1 | `00000000` | 0 | 4 | `00` | 0 | Setup: write `CTRL` = `EN` (one-shot) |
| 2 | 1 | 1 | 1 | `04` | `00000001` | `F` | 1 | `00000000` | 0 | 4 | `00` | 0 | Completes; `EN` = 1 after this edge |
| 3 | 1 | 0 | 1 | `08` | `CAFE0123` | `3` | 1 | `00000000` | 0 | 4 | `00` | 0 | Setup: write `SCRATCH`, lanes 0–1; first count |
| 4 | 1 | 1 | 1 | `08` | `CAFE0123` | `3` | 1 | `00000000` | 0 | 3 | `00` | 0 | Completes; `SCRATCH` = `00000123` |
| 5 | 1 | 0 | 0 | `10` | - | `0` | 1 | `00000000` | 0 | 2 | `00` | 0 | Setup: read `TIMER_VALUE` |
| 6 | 1 | 1 | 0 | `10` | - | `0` | **0** | `00000000` | 0 | 1 | `00` | 0 | Wait state; counter 1 is captured |
| 7 | 1 | 1 | 0 | `10` | - | `0` | 1 | `00000001` | 0 | 0 | `00` | 0 | Completes with 1; counter is 0: expiry |
| 8 | 1 | 0 | 0 | `20` | - | `0` | 1 | `00000000` | 0 | 4 | `01` | 1 | Reloaded, `EN` cleared; `TMR` = 1, `irq` = 1. Setup: read `0x20` |
| 9 | 1 | 1 | 0 | `20` | - | `0` | 1 | `00000000` | **1** | 4 | `01` | 1 | Unmapped: completes with `pslverr` |
| 10 | 1 | 0 | 1 | `14` | `00000001` | `F` | 1 | `00000000` | 0 | 4 | `11` | 1 | `ERR` = 1. Setup: write `INT_STATUS` = 1 |
| 11 | 1 | 1 | 1 | `14` | `00000001` | `F` | 1 | `00000000` | 0 | 4 | `11` | 1 | Completes: clears `TMR` |
| 12 | 0 | 0 | - | - | - | - | 1 | `00000000` | 0 | 4 | `10` | 0 | `ERR` stays; `ERR_IE` = 0, so `irq` = 0 |

## 4. Rules

| Rule | Applies to | Statement |
|---|---|---|
| P1 | both | A transfer completes at every edge where `psel`, `penable` and `pready` are all 1. |
| P2 | host | A setup edge is followed by an access edge; `pwrite`, `paddr`, `pwdata`, `pstrb` stay unchanged until the completion edge (AS2). |
| P3 | host | `pstrb` is 0 for reads (AS3); `psel` is 0 during reset (AS4). |
| P4 | DUT | `pready`, `prdata` and `pslverr` depend combinationally on `psel`, `penable`, `pwrite` and `paddr`. |
| P5 | DUT | `irq` depends only on register values, never combinationally on an input. |
