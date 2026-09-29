# RTL track

[Home](../README.md) · [Shared introduction](../intro/README.md#shared-introduction) · [CAE setup](../intro/SETUP.md) · [Verification](../verif/README.md#verification-track)

After the [shared PE checkpoint](../intro/README.md#pe-checkpoint), you'll connect
processing elements into a systolic array that computes matrix products. Start
with a 2×2 array, then add parameterization, buffering, and control. You'll build
the array under `rtl/projects/systolic-array/`; the repository provides the shared
PE as your starting block.

The track materials are incomplete. We'll add detailed lessons and more resources
as the project develops.

## On this page

- [Build a systolic array](#build-a-systolic-array)
- [RTL roadmap](#rtl-roadmap)
- [Matmul checkpoint](#matmul-checkpoint)
- [Systolic array checkpoint](#systolic-array-checkpoint)
- [Resources](#rtl-resources)

## Build a systolic array

### Understand how data moves through a PE

Each PE accumulates one entry of the result matrix while passing operands to its
neighbors. For `C = A × B`, PE `(i,j)` needs the pairs `A[i,k]` and `B[k,j]` for
each `k`. Those operands must arrive together on a valid cycle.

Review these parts of your working PE before connecting it to another one:

| Read | What to look for |
| --- | --- |
| [PE ports](../intro/projects/processing-element/rtl/pe.sv#L7-L11)<!-- region:interface --> | Where operands enter and leave, and how wide the accumulator is. |
| [Cycle rules](../intro/projects/processing-element/spec/pe.md#cycle-rules) | How reset, clear, valid input, and bubbles affect the registers. |
| [Arithmetic rules](../intro/projects/processing-element/spec/pe.md#interface-and-arithmetic) | Signed multiplication, sign extension, and accumulator wraparound. |

`valid_out` identifies forwarded operands. The array needs separate control to
identify when a complete matrix result is ready. The PE has no backpressure input
(a way to ask an upstream sender to wait), so your input schedule must account for
when each PE can consume data.

### Start with two connected PEs

Draw the connections and a cycle-by-cycle operand schedule. Label each operand
with its matrix indices so you can check that both inputs to a PE have the same
`k`. Include a bubble (`valid_in = 0`) and follow its effect on the forwarded data
and valid signal.

Use that schedule to build the interconnect, then extend it to a 2×2 array. Compare
every output entry with a matrix product computed independently of your RTL.
The [matmul checkpoint](#matmul-checkpoint) is your first working-array milestone.

Keep the array's specification, diagrams, RTL, and small design tests in
`rtl/projects/systolic-array/`. Document dimensions, numeric widths, operand
timing, reset/clear behavior, and completion signaling in the specification.
Work with the verification track from that same specification so the design and
testbench use the same interface and cycle rules.

## RTL roadmap

| Stage | What you'll build |
| --- | --- |
| 1. PE data movement | Connect PEs and work out the operand schedule. |
| 2. 2×2 matrix multiplication | Compute full matrix products with a small array. |
| 3. Parameterized array | Generalize array dimensions and numeric widths. |
| 4. Input buffering and control | Store incoming data and use a finite-state machine (FSM) to manage the operation. |
| 5. Output handling | Signal when results are valid and handle backpressure where the interface supports it. |
| 6. Integration and documentation | Run the regression suite, review the interface, and document how to use the array. |

The checkpoints are [matmul](#matmul-checkpoint) after stage 2 and
[systolic array](#systolic-array-checkpoint) after stage 6.

## Matmul checkpoint

Run your 2×2 implementation on several input matrices and compare every output
entry with an independent reference. Check operand alignment and the cycle when
the result becomes ready.

## Systolic array checkpoint

Run your completed array for the dimensions and numeric formats in its
specification. Check matrix results, reset and restart, completion signaling, and
input/output control. For interfaces that support stalls, check that pausing and
resuming transfers preserves every result without loss or duplication.

## RTL resources

| Resource | Use it for |
| --- | --- |
| [Shared SystemVerilog guide](../intro/README.md#stage-2-systemverilog-and-systolic-arrays) | Connect combinational and sequential code to the hardware it describes. |
| [PE specification](../intro/projects/processing-element/spec/pe.md) | Review the block you'll reuse in the array. |
| [NYCU systolic-array lab](https://nycu-caslab.github.io/AAML2024/labs/lab_3.html) | Compare its dataflow and operand schedule with yours. |
| [Systolic-array readings](../intro/README.md#systolic-arrays) | Find background explanations and visual introductions. |
| [CAE setup](../intro/SETUP.md#environment-setup) | Set up simulation and waveform viewing. |
