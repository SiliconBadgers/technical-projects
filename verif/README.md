# Verification track

[Home](../README.md) · [Shared introduction](../intro/README.md#shared-introduction) · [CAE setup](../intro/SETUP.md) · [RTL](../rtl/README.md#rtl-track)

After the [shared PE checkpoint](../intro/README.md#pe-checkpoint), you'll use its
supplied testbench to learn how to find design bugs. Then you'll build a testbench
for the RTL track's systolic array, starting with directed tests and growing into
scoreboards, coverage, and UVM.

The track materials are incomplete. We'll add detailed lessons and more resources
as the project develops.

## On this page

- [Getting started](#getting-started-with-verification)
- [PE verification plan](#pe-verification-plan)
- [Verification roadmap](#verification-roadmap)
- [Testbench completion](#testbench-completion)
- [Resources](#verification-resources)
- [Project files](#project-files)

## Getting started with verification

### Read the supplied testbench

A testbench drives a design's inputs and checks its outputs against the behavior
in the specification. Start with the [PE ports](../intro/projects/processing-element/rtl/pe.sv#L7-L11)<!-- region:interface -->
and [cycle rules](../intro/projects/processing-element/spec/pe.md#cycle-rules),
then see how the supplied tests check them:

| Read | What to notice |
| --- | --- |
| [`step` and output checker](../intro/projects/processing-element/tb/pe_tb.sv#L75-L107)<!-- region:checker --> | Inputs change on falling edges. Outputs are checked before the rising edge to catch early changes, and afterward to check the registered update. |
| [Reference model](../intro/projects/processing-element/tb/pe_tb.sv#L32-L74)<!-- region:model --> | Shift/add multiplication computes the expected product independently of the RTL. The model also tracks accumulation and forwarded operands. |
| [Test phases](../intro/projects/processing-element/tb/pe_tb.sv#L137-L242)<!-- region:stimulus --> | Small, targeted cases check individual behaviors; operand sweeps and reproducible random sequences exercise more combinations. |
| [Width configurations](../intro/projects/processing-element/tb/pe_tb.sv#L244-L272)<!-- region:configurations --> | Narrow and wide configurations catch assumptions about fixed operand or accumulator widths. |

An independent reference helps catch mistakes that copying the RTL's calculation
could carry into the testbench. For each test, look for the requirement it checks
and the observation that would reveal a bug.

### Try detecting a bug (optional practice)

From the repository root in the [CAE environment](../intro/SETUP.md), run the suite
against your working PE:

```sh
make pe
```

A passing run ends with `PASS: PE acceptance suite (7 configurations; all checks complete)`.
The untouched starter fails until you implement the PE.

Temporarily change the PE to accumulate during a bubble, then rerun the suite.
Use the failure message's inputs and actual/expected outputs to locate the
mismatch. Restore your working implementation and rerun to confirm it passes.
See the [PE debugging instructions](../intro/README.md#use-the-supplied-reference-testbench)
for waveforms, seeds, and later failures.

### Build checks for the array

Work with the RTL track to define the [array's behavior](../rtl/README.md#build-a-systolic-array)
in a shared specification. Compute expected matrix results independently, then
compare them with the array's outputs. Track which results are due and when;
this tracking and comparison is called a scoreboard.

Start with directed tests: choose inputs and timing to exercise one requirement
at a time, such as reset during work or consecutive matrix operations. Add
reproducible random stimulus to vary operands and control sequences. Use
functional coverage to record which cases you've exercised, and SystemVerilog
assertions to check timing rules.

Keep an array verification plan using the [PE plan](#pe-verification-plan) or
[plan template](../templates/README.md#verification-plan-template) as a starting
point. Map each requirement to its stimulus and checker so you can see where tests
are missing. Put the new testbench and regression scripts in the [track project](#project-files).

## PE verification plan

The supplied suite checks the [PE specification](../intro/projects/processing-element/spec/pe.md)
as follows:

| Requirement | Supplied check |
| --- | --- |
| Reset and clear zero all state; clear ignores valid input | Directed cases and all 64 transitions between reset/clear/valid combinations, with nonzero state loaded before each case. |
| State updates only on rising edges | Compare outputs before and after the rising edge. |
| Signed multiply-accumulate | Independent shift/add reference; every operand pair at widths 1, 2, 4, and 8. |
| Forward valid operands; hold data and deassert valid during bubbles | Compare both forwarded operands, the accumulator, and `valid_out` every step, including repeated bubbles with changing inputs. |
| Consecutive valid cycles | Back-to-back operand sweeps and directed dot products. |
| Arithmetic boundaries | Pair minimum, minimum+1, −1, 0, 1, maximum−1, and maximum operands. |
| Accumulator wraparound | Accumulate through positive and negative overflow, including the default 32-bit accumulator. The one-bit case checks positive wraparound because its operands are only −1 and 0. |
| Parameterization | Test `DATA_W/ACC_W` configurations `1/2`, `2/4`, `4/11`, `8/16`, `8/32`, `17/40`, and `33/72`. |
| Mixed traffic and restart | Run 4,000 reproducible random cycles per configuration with occasional reset and clear, then reset, idle, and restart. |
| Suite completes | Check phase counters and all seven completion flags; a timeout catches a stalled run. |

Operand-pair sweeps cover widths through 8 bits. Wider configurations use boundary
and random cases.

## Verification roadmap

| Stage | What you'll practice |
| --- | --- |
| 1. Directed tests and debugging | Read the PE suite, connect requirements to checks, and see how failures identify design bugs. |
| 2. Scoreboards and coverage | Build array stimulus, an independent matrix reference, timing assertions, and coverage goals. |
| 3. UVM and integration | Organize reusable testbench components and build regressions for the array and larger subsystems. |

UVM (Universal Verification Methodology) provides a structure for reusable
components: a driver applies inputs, a monitor observes transfers, and a
scoreboard checks the results. DPI-C (Direct Programming Interface for C) lets a
SystemVerilog testbench call C code, for example to use a C reference model.
These build on the checking techniques you learn with the PE and array.

## Testbench completion

Run your completed array testbench against a correct implementation. Use your
verification plan to check that it covers the array's requirements and edge cases.
Introduce representative design bugs and confirm that the tests report failures,
then restore the correct design and rerun. Document the regression command so
someone else can run the same checks.

## Verification resources

### Verification

| Resource | Use it for |
| --- | --- |
| [Siemens Verification Academy: UVM basics](https://verificationacademy.com/topics/uvm-universal-verification-methodology/uvm-basics/) | Learn how drivers, monitors, and scoreboards fit together. |
| [Doulos SystemVerilog assertions tutorial](https://www.doulos.com/knowhow/systemverilog/systemverilog-tutorials/systemverilog-assertions-tutorial/) | Write timing checks for behavior such as reset and valid signaling. |
| [UVM video series](https://www.youtube.com/watch?v=imH4CFmVGWE&list=PLBIILfL2t1lnvzw7vF0arlvu36Wj4--D7) | Supplement the UVM readings with worked explanations. |

### Tools and shared prerequisites

- [CAE setup](../intro/SETUP.md#environment-setup): simulation and waveform viewing.
- [PE specification](../intro/projects/processing-element/spec/pe.md): the behavior checked by the supplied suite.
- [Verification-plan template](../templates/README.md#verification-plan-template): organize requirements, checks, and coverage gaps.

## Project files

| File | Role |
| --- | --- |
| [PE specification](../intro/projects/processing-element/spec/pe.md) | Defines the shared block's behavior. |
| [PE RTL](../intro/projects/processing-element/rtl/pe.sv) | The design being tested. |
| [Acceptance testbench](../intro/projects/processing-element/tb/pe_tb.sv) | The supplied reference model, stimulus, and checks. |

You'll build the array testbench under `verif/projects/pe-verification/tb/` and
regression scripts under `verif/projects/pe-verification/scripts/`. Reference the
shared PE and the RTL track's array design and specification. Keep the supplied
PE acceptance suite available for the shared checkpoint.
