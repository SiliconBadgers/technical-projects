# `sb_apb_regs` Specification

Version 1.0 (2026-10-08). Ports, APB phases and an example waveform: [`interface.md`](interface.md).

## 1. Summary

An APB4 completer (slave) with seven 32-bit registers: an ID, a control register, a scratch register, a 32-bit down-counting timer with one-shot and auto-reload modes, and two interrupt sources (timer expired, access error) that drive a level interrupt `irq`. Reads of the timer counter take one wait state. Unmapped addresses and writes to read-only registers complete with an error response.

## 2. Block diagram

```
                         +----------------+       +-------------------------+
 psel penable pwrite --->| APB4 completer |<----->| registers               |
 paddr pwdata pstrb      |  decode        |       |  ID          SCRATCH    |
                         |  wait state    |       |  CTRL        TIMER_LOAD |
 prdata pready pslverr <-|  error response|--ERR->|  INT_ENABLE  INT_STATUS |
                         +----------------+       +---------------------^---+
                                                                        |
                         +----------------+                             |
 CTRL, TIMER_LOAD ------>| timer counter  |------ expiry (TMR) ---------+
                         | (TIMER_VALUE)  |
                         +----------------+

 irq = |(INT_STATUS & INT_ENABLE) -------------------------------------------> irq
```

## 3. Parameters

| Parameter | Default | Valid range | Description |
|---|---|---|---|
| `ADDR_W` | 8 | ≥ 5 | `paddr` width (byte address) |
| `DATA_W` | 32 | 32 | `pwdata`/`prdata` width; `pstrb` has `DATA_W/8` bits |

Out-of-range values stop elaboration with `$error`.

## 4. Clock and reset

| Signal | Description |
|---|---|
| `pclk` | All ports are synchronous to the rising edge. |
| `presetn` | Active low. Asynchronous assert, synchronous deassert. |

An *edge* is a rising edge of `pclk`. "X at edge *c*" means the value of X sampled at edge *c*, just before it. A register "after edge *c*" holds the value the edge wrote.

## 5. Interfaces

| Interface | Ports | Direction |
|---|---|---|
| APB4 completer | `psel`, `penable`, `pwrite`, `paddr`, `pwdata`, `pstrb`, `prdata`, `pready`, `pslverr` | host ↔ DUT |
| Interrupt | `irq` | DUT → host |

`pprot` is not implemented. Details are in [`interface.md`](interface.md).

## 6. Register map

Offsets are byte addresses; the register is selected by `paddr[ADDR_W-1:2]` and `paddr[1:0]` is ignored.

| Offset | Register | Access | Reset | Fields |
|---|---|---|---|---|
| `0x00` | `ID` | RO | `0x5342_4150` | `[31:0]` block identifier ("SBAP") |
| `0x04` | `CTRL` | RW | `0x0000_0000` | `[0]` `EN` timer enable; `[1]` `RELOAD` 1 = auto-reload, 0 = one-shot |
| `0x08` | `SCRATCH` | RW | `0x0000_0000` | `[31:0]` software scratch; no other effect |
| `0x0C` | `TIMER_LOAD` | RW | `0x0000_0000` | `[31:0]` reload value; a write also loads the counter |
| `0x10` | `TIMER_VALUE` | RO | `0x0000_0000` | `[31:0]` the counter; reads take one wait state |
| `0x14` | `INT_STATUS` | W1C | `0x0000_0000` | `[0]` `TMR` timer expired; `[1]` `ERR` error response given |
| `0x18` | `INT_ENABLE` | RW | `0x0000_0000` | `[0]` `TMR_IE`; `[1]` `ERR_IE` |
| `0x1C`–`0xFC` | — | — | — | Unmapped: error response |

| Access | Read | Write |
|---|---|---|
| RO | Register value | Error response; no change |
| RW | Register value | Written value |
| W1C | Register value | Each bit written as 1 is cleared; bits written as 0 are unchanged |

Bits not listed (`CTRL[31:2]`, `INT_STATUS[31:2]`, `INT_ENABLE[31:2]`) are reserved: they read 0 and writes to them are ignored.

## 7. Function

### APB transfers

| Term | Definition |
|---|---|
| Setup edge | An edge with `psel` = 1 and `penable` = 0. |
| Access edge | An edge with `psel` = 1 and `penable` = 1. |
| Completion edge | An access edge with `pready` = 1. The transfer takes effect at this edge and the response (`prdata`, `pslverr`) is valid. |
| Wait state | An access edge with `pready` = 0. |

| Transfer | Wait states | `pslverr` | Effect | `prdata` at completion |
|---|---|---|---|---|
| Read of `TIMER_VALUE` | 1 | 0 | none | Counter at the first access edge |
| Read of another mapped register | 0 | 0 | none | Register value |
| Write to `CTRL`, `SCRATCH`, `TIMER_LOAD`, `INT_STATUS`, `INT_ENABLE` | 0 | 0 | Register map, byte strobes below | 0 |
| Write to `ID` or `TIMER_VALUE` | 0 | 1 | `INT_STATUS.ERR` set | 0 |
| Read or write of an unmapped address | 0 | 1 | `INT_STATUS.ERR` set | 0 |

At every edge that is not a completion edge, `pslverr` = 0 and `prdata` = 0.

**Byte strobes.** A write changes byte lane *i* (bits `8i+7 : 8i`) only if `pstrb[i]` = 1. `CTRL`, `INT_STATUS` and `INT_ENABLE` have all their bits in lane 0: a write to them with `pstrb[0]` = 0 changes nothing. `pstrb` is ignored for reads.

### Timer

The counter is read as `TIMER_VALUE`. A **strobed write** has at least one `pstrb` bit set. At each edge where `presetn` = 1, using the values at that edge, the first row that applies sets the counter after the edge:

| Condition | Counter after the edge | Also |
|---|---|---|
| A strobed write to `TIMER_LOAD` completes | The new `TIMER_LOAD` value | — |
| `CTRL.EN` = 0 | Unchanged | — |
| Counter ≠ 0 | Counter − 1 | — |
| Counter = 0 (*expiry*) | `TIMER_LOAD` | `INT_STATUS.TMR` set; if `CTRL.RELOAD` = 0, `CTRL.EN` cleared |

- A write to `CTRL` takes effect after its completion edge; the timer row at that edge uses the old `EN` and `RELOAD`.
- A `TIMER_LOAD` write with `pstrb` = 0 leaves the load value unchanged and lets the timer count down or expire normally.
- If a write to `CTRL` with `pstrb[0]` = 1 completes at a one-shot expiry, `CTRL` takes the written value (the write wins over the clear).
- So: when a write sets `EN` = 1 at edge *e* with the counter at *L*, the timer expires at edge *e* + *L* + 1. In auto-reload mode it then expires every `TIMER_LOAD` + 1 edges.

### Interrupts

For each `INT_STATUS` bit, at each edge:

| Event at the edge | Bit after the edge |
|---|---|
| Set: `TMR` — the timer expires; `ERR` — a transfer completes with `pslverr` = 1 | 1 |
| Clear: a write to `INT_STATUS` with `pstrb[0]` = 1 and a 1 in this bit completes | 0, unless also set (set wins) |
| Neither | Unchanged |

`irq` = |(`INT_STATUS` & `INT_ENABLE`), computed from the register values: it changes right after the edge that changes them.

### Reset

While `presetn` = 0, every register (and the counter) holds its reset value from Section 6, and `irq`, `pslverr` and `prdata` are 0. A transfer in progress when reset asserts is abandoned.

## 8. Requirements

| ID | Requirement |
|---|---|
| R01 | A transfer shall take effect once, at its completion edge. |
| R02 | A read of `TIMER_VALUE` shall have exactly one wait state; every other transfer shall have none. |
| R03 | A read with `pslverr` = 0 shall return the register's value at the completion edge (reserved bits 0); a read of `TIMER_VALUE` shall return the counter at its first access edge. |
| R04 | A transfer to an unmapped address, and a write to `ID` or `TIMER_VALUE`, shall complete with `pslverr` = 1; every other transfer shall complete with `pslverr` = 0. |
| R05 | A transfer with `pslverr` = 1 shall change no register except `INT_STATUS.ERR`; `pslverr` shall be 0 at every edge that is not a completion edge. |
| R06 | `prdata` shall be 0 at every edge except the completion edge of a read with `pslverr` = 0. |
| R07 | `paddr[1:0]` shall be ignored. |
| R08 | A write shall change only the byte lanes whose `pstrb` bit is 1. |
| R09 | A read shall change no register. |
| R10 | `ID` shall read `0x5342_4150`. |
| R11 | `CTRL.EN` and `CTRL.RELOAD` shall be read/write; `CTRL[31:2]` shall read 0 and ignore writes. |
| R12 | `SCRATCH` shall be read/write in all 32 bits and have no other effect. |
| R13 | A strobed write to `TIMER_LOAD` shall update `TIMER_LOAD` and load the counter with the new value at its completion edge. |
| R14 | `INT_ENABLE[1:0]` shall be read/write; `INT_ENABLE[31:2]` shall read 0 and ignore writes. |
| R15 | Writing 1 to an `INT_STATUS` bit shall clear it; writing 0 shall leave it unchanged; `INT_STATUS[31:2]` shall read 0. |
| R16 | `INT_STATUS.ERR` shall be set at the completion edge of every transfer with `pslverr` = 1. |
| R17 | A status bit set by hardware at the same edge that a write clears it shall be 1 after that edge. |
| R18 | At an edge where `CTRL.EN` = 1, the counter ≠ 0 and no strobed write to `TIMER_LOAD` completes, the counter shall decrement by 1. |
| R19 | At an edge where `CTRL.EN` = 1, the counter = 0 and no strobed write to `TIMER_LOAD` completes, the timer shall expire: `INT_STATUS.TMR` is set and the counter is loaded from `TIMER_LOAD`. |
| R20 | When the timer expires with `CTRL.RELOAD` = 0, `CTRL.EN` shall be cleared, unless a write to `CTRL` with `pstrb[0]` = 1 completes at the same edge. |
| R21 | When the timer expires with `CTRL.RELOAD` = 1, `CTRL.EN` shall stay 1. |
| R22 | While `CTRL.EN` = 0, the counter shall not change except by a strobed write to `TIMER_LOAD`. |
| R23 | A write to `CTRL` shall affect the timer from the edge after its completion edge. |
| R24 | `irq` shall equal \|(`INT_STATUS` & `INT_ENABLE`) at every edge. |
| R25 | While `presetn` = 0, every register shall take its reset value, and `irq`, `pslverr` and `prdata` shall be 0. |

## 9. Corner cases

| Condition | Behaviour |
|---|---|
| Strobed write to `TIMER_LOAD` while the timer runs | Counter restarts from the new value (R13) |
| Strobed write to `TIMER_LOAD` at an expiry edge | The write wins; no expiry at that edge (R13, R19) |
| `CTRL` written at a one-shot expiry | The written `EN` and `RELOAD` win (R20) |
| W1C clears `TMR` at the edge the timer expires | `TMR` stays 1 (R17) |
| `EN` set while the counter is 0 | Expires at the next edge (R19) |
| `TIMER_LOAD` = 0 in auto-reload mode | Expires at every edge (R19, R21) |
| Read of `INT_STATUS` | Does not clear it (R09) |
| Write with `pstrb` = 0 | Completes with `pslverr` = 0, changes nothing (R08) |
| Write to `ID` or `TIMER_VALUE` with any `pstrb` | `pslverr` = 1, no change (R04, R05) |
| `paddr[1:0]` ≠ 0 | Same as `paddr[1:0]` = 0 (R07) |
| Reset during a transfer | Transfer abandoned; registers reset (R25) |
| Host breaks an assumption below | Undefined |

## 10. Assumptions

| ID | Assumption |
|---|---|
| AS1 | Inputs change only after a rising edge. |
| AS2 | The host follows APB4: a setup edge is followed by access edges until `pready` = 1; `pwrite`, `paddr`, `pwdata` and `pstrb` do not change from the setup edge to the completion edge; `penable` is 0 at the edge after a completion. |
| AS3 | `pstrb` is 0 during reads. |
| AS4 | `psel` is 0 while `presetn` is 0, and `presetn` is released synchronously to `pclk`. |
| AS5 | Inputs are never X or Z out of reset. |

## 11. Open questions

| ID | Question | Raised by | Answer |
|---|---|---|---|
| | | | |
