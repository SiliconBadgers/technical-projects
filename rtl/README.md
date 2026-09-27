# RTL track

[Home](../README.md) · [Shared introduction](../intro/README.md#shared-introduction) · [CAE setup](../intro/SETUP.md) · [Verification](../verif/README.md#verification-track)

Build on the shared PE to create a systolic array. The design guide, roadmap,
resources, and completion checks are all on this page.

## On this page

- [Build a systolic array](#build-a-systolic-array)
- [Implementation roadmap](#rtl-roadmap)
- [Matmul checkpoint](#matmul-checkpoint)
- [Systolic array checkpoint](#systolic-array-checkpoint)
- [Resources](#rtl-resources)

The array implementation is still planned. Complete the
[shared PE](../intro/README.md#pe-checkpoint) first, then add array specifications,
RTL, and design smoke tests under `rtl/projects/systolic-array/`. Refer to the
[shared PE contract](../intro/projects/processing-element/spec/pe.md) rather than
keeping a second copy. Coordinate interface changes with verification.

## Build a systolic array

**Prerequisite:** the [shared PE checkpoint](../intro/README.md#pe-checkpoint).
**Outcome:** extend a working PE into a matrix-multiplication design with specified
cycle behavior and reproducible checks.

### Read the starting block

| Open this section | What to understand before connecting PEs |
| --- | --- |
| [PE ports](../intro/projects/processing-element/rtl/pe.sv#L7-L11)<!-- region:interface --> | Operand direction, accumulator width, and the meaning of `valid_out`. |
| [PE implementation](../intro/projects/processing-element/rtl/pe.sv#L13-L21)<!-- region:implementation --> | The student TODO must be completed before array integration. |
| [Cycle contract](../intro/projects/processing-element/spec/pe.md#cycle-rules) | Reset, clear, valid data, and bubble behavior at each edge. |
| [Supplied acceptance cases](../intro/projects/processing-element/tb/pe_tb.sv#L137-L242)<!-- region:stimulus --> | The signed arithmetic, control, timing, and parameter checks required before array integration. |

### First design exercise

Draw two connected PEs. For every cycle, label which operand pair each PE should
consume and when its output is valid. The shared PE has one input-valid signal
and no backpressure input, so the array must align useful operand pairs and define
how bubbles propagate. Check that both operands correspond to the same dot-product
index before accumulating.

Write the proposed schedule and interface under `rtl/projects/systolic-array/`
as you develop the interconnect RTL. When the schedule is clear, progress to a 2×2
array and compare complete matrix results with an independent reference.

### What belongs in this track

Add array specifications, block diagrams, design RTL, and small design smoke tests
under `rtl/projects/systolic-array/`. The [verification track](../verif/README.md#verification-track)
owns the extended checking methodology and regression work. Both tracks should
reference the same behavior contract and agree on interface changes.

## RTL roadmap

These are proposed stages after the shared introduction. They group the design
milestones from the team discussion into six stages, consistent with the Day 1
track outline. Mentors can adjust pacing; these are not fixed weekly deadlines.

| Track stage | Build | Current status |
| --- | --- | --- |
| 1. PE data movement | Connect working PEs and define operand timing. | Planned |
| 2. 2×2 matrix multiplication | Complete a small array. | Planned |
| 3. Parameterized array | Generalize dimensions and numeric widths. | Planned |
| 4. Input buffering and control | Add input storage, an FSM, and status signals. | Planned |
| 5. Output handling | Define output validity and backpressure. | Planned |
| 6. Integration and documentation | Finish regression, interface review, and walkthrough. | Planned |

The [shared PE starter](../intro/README.md#stage-3-implement-a-processing-element) exists,
but its RTL is intentionally unfinished. No array RTL is present yet. The
[design guide](#build-a-systolic-array) explains the first implementation exercise.

### Completion checks

The formal checks are [matmul](#matmul-checkpoint) after stage 2 and
[systolic array](#systolic-array-checkpoint) after stage 6. The intervening
stages are implementation steps with no separate checkoffs.

### Open design decisions

Agree on array dimensions, numeric formats, input scheduling, latency/throughput
expectations, reset/flush behavior, and completion signaling. Coordinate those
requirements with [verification](../verif/README.md#verification-roadmap) before implementing
checks against them. Record decisions alongside the array specification.

## Matmul checkpoint

Run the completed 2×2 matrix-multiplication implementation and compare all output
entries against an independent reference on multiple input matrices. Check that
operands align correctly and completion occurs at the expected time. This is the
first working matrix-product milestone in the [RTL roadmap](#rtl-roadmap).

## Systolic array checkpoint

Run the completed array for the dimensions and numeric formats in its agreed
specification. Check results, reset/restart, completion signaling, and input/output
control, including stalls where supported. Check that results are neither lost
nor duplicated. This is the final implementation milestone in the
[RTL roadmap](#rtl-roadmap).

## RTL resources

| Resource | Use it for |
| --- | --- |
| [Shared SystemVerilog guide](../intro/README.md#stage-2-systemverilog-and-systolic-arrays) | Map combinational and sequential constructs to hardware. |
| [Shared PE contract](../intro/projects/processing-element/spec/pe.md) | Confirm signed arithmetic, reset, and cycle semantics before reuse. |
| [NYCU systolic-array lab](https://nycu-caslab.github.io/AAML2024/labs/lab_3.html) | Compare another teaching example with your operand schedule. |
| [Shared systolic-array readings](../intro/README.md#systolic-arrays) | Review terminology and visual introductions. |
| [Recommended CAE setup](../intro/SETUP.md#environment-setup) | Run simulation with the shared tool instructions. |

Keep the array's agreed contract in its project directory rather than assuming an external
example uses the same interfaces or timing.
