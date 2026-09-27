# Processing element Specification

## Interface and arithmetic

- `DATA_W` defaults to 8; `ACC_W` defaults to 32. Require `DATA_W >= 1` and
  `ACC_W >= 2 * DATA_W`.
- Operands, forwarded operands, and accumulator use signed two's-complement values.
- A product has `2 * DATA_W` bits. Sign-extend it to `ACC_W` before accumulation.
- Overflow wraps modulo `2 ** ACC_W`; this exercise does not saturate.
- Every action below occurs on a rising `clk` edge. There is no ready/backpressure
  input in this first PE. `valid_out` marks forwarded operands, not a completed dot product.

## Cycle rules

| Priority | Inputs at the edge | Outputs after the edge |
| --- | --- | --- |
| 1 | `rst = 1` | Zero accumulator, forwarded operands, and `valid_out` |
| 2 | `rst = 0`, `clear = 1` | Zero accumulator, forwarded operands, and `valid_out`; ignore input operands |
| 3 | Neither above, `valid_in = 1` | Add `a_in * b_in` to accumulator; forward `a_in`, `b_in`; set `valid_out = 1` |
| 4 | Neither above, `valid_in = 0` | Hold accumulator and forwarded operands; set `valid_out = 0` |

## Example trace

Outputs are shown after each rising edge. Start with reset, then supply:

| Action | a_in | b_in | acc_out | valid_out |
| --- | --- | --- | --- | --- |
| clear | — | — | 0 | 0 |
| valid pair | 2 | 3 | 6 | 1 |
| bubble | — | — | 6 | 0 |
| valid pair | -1 | 4 | 2 | 1 |

The result is the dot product `2*3 + (-1)*4 = 2`.
See the [implementation guide](../../../README.md#stage-3-implement-a-processing-element)
and the [verification plan](../../../../verif/README.md#pe-verification-plan).

The [supplied acceptance testbench](../tb/pe_tb.sv) checks this contract. Run
`make pe` from the repository root; the [PE checkpoint instructions](../../../README.md#pe-checkpoint)
explain the required passing result. Students implement the RTL, with the
testbench already provided.
