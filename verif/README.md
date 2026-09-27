# Verification track

[Home](../README.md) · [Shared introduction](../intro/README.md#shared-introduction) · [CAE setup](../intro/SETUP.md) · [RTL](../rtl/README.md#rtl-track)

Use the shared PE to learn to develop independent checks and find design bugs.
The exercises, verification plan, roadmap, and resources are all on this page.

## On this page

- [Getting started](#getting-started-with-verification)
- [PE verification plan](#pe-verification-plan)
- [Learning roadmap](#verification-roadmap)
- [Testbench completion](#testbench-completion)
- [Resources](#verification-resources)
- [Project files](#project-files)

The PE starter and supplied acceptance testbench remain in the introduction.
UVM, DPI-C, and regression extensions are planned; the formal completion check
is the finished testbench.

## Getting started with verification

**Prerequisite:** basic waveforms and the [PE contract](../intro/projects/processing-element/spec/pe.md).
**Outcome:** translate a requirement into a repeatable test that detects a real bug.

### Start with the shared design

The current practice block is the PE, not a complete SoC. Read its
[ports](../intro/projects/processing-element/rtl/pe.sv#L7-L11)<!-- region:interface --> and draw the boundary
between inputs driven by the testbench and outputs observed by checks. A mentor
can later provide the project SoC diagram and explain where the block belongs.

The shared PE checkpoint uses the supplied testbench. Students implement the PE
and pass that suite before branching into track work; writing a testbench is not
an extra prerequisite. Here, use the supplied code as a reference for learning
verification and developing checks for the later array project.

| File section | Role | What to understand |
| --- | --- | --- |
| [`step` and output checker](../intro/projects/processing-element/tb/pe_tb.sv#L75-L107)<!-- region:checker --> | Drives inputs away from rising edges and compares every output before/after the active edge. | Why early output changes, unknown values, and incorrect forwarded data are failures. |
| [Reference model](../intro/projects/processing-element/tb/pe_tb.sv#L32-L74)<!-- region:model --> | Uses shift/add multiplication and explicit accumulator truncation. | Why an independently expressed expectation helps catch signedness and width bugs. |
| [Test phases](../intro/projects/processing-element/tb/pe_tb.sv#L137-L242)<!-- region:stimulus --> | Directed, exhaustive operand-pair, overflow, and deterministic random cases. | Which requirement each phase checks and what simulation cannot prove. |
| [Width configurations](../intro/projects/processing-element/tb/pe_tb.sv#L244-L272)<!-- region:configurations --> | Runs seven DUTs and waits for every suite to finish. | How narrow and wide configurations expose hard-coded assumptions. |

### Learn by detecting a bug

Run `make pe` against your implemented PE (or a mentor-provided working branch).
Temporarily introduce a relevant bug, such as accumulating during a bubble, and
check that the supplied suite fails. Read its inputs and actual/expected outputs,
then restore the correct implementation and rerun. This is optional practice in
understanding checks, not another introductory completion gate.

New verification suites and supporting scripts belong in
[the track project](#project-files). Use the shared PE suite as a reference when
building the array testbench; agree on the array contract with the RTL track.

### Grow the methodology

Study the supplied scoreboard and reproducible stimulus, then adapt those ideas
to array-level scheduling, independent matrix results, and functional coverage.
Introduce SystemVerilog assertions for timing properties, then learn UVM components
and DPI-C reference models when their purpose is clear.
Use the [verification resources](#verification) and
[CAE setup](../intro/SETUP.md#uwmadison-cae-and-synopsys).

Before moving to subsystem or system verification, agree on the block diagram,
protocols (such as APB/AXI), interface ownership, regression commands, and tool
support. RTL simulation, synthesized-netlist simulation, timing analysis, and
physical checks answer different questions; an RTL pass alone does not validate
all of them. Netlist testing needs the actual netlist and appropriate cell models,
and timing simulation may also need delay annotation.

## PE verification plan

Contract: [PE specification](../intro/projects/processing-element/spec/pe.md). Walkthrough: [verification guide](#getting-started-with-verification).

These checks are supplied in `pe_tb.sv`. Their presence does not mean the
unfinished RTL passes them. See the [intro instructions](../intro/README.md#use-the-supplied-reference-testbench)
for running the suite, interpreting failures, seeds, and waveforms.

| Requirement | Supplied check |
| --- | --- |
| Reset and clear zero all state; clear ignores valid input | Directed reset/clear cases and all 64 control transitions after loading nonzero state |
| State updates only on rising edges | Compare outputs after changing inputs at a falling edge, then again after the rising edge |
| Signed multiply-accumulate | Independent shift/add reference; every operand pair at widths 1, 2, 4, and 8 |
| Forward both operands with valid | Compare `a_out`, `b_out`, and `valid_out` every step |
| Bubbles hold data and deassert valid | Repeated invalid cycles with changed input operands |
| Consecutive valid cycles | Exhaustive operand-pair sweep without gaps plus directed dot products |
| Arithmetic boundaries | Cross-product of minimum, minimum+1, −1, 0, 1, maximum−1, maximum |
| Accumulator wraps rather than saturates | Long positive/negative walks through the modulus, including default 8/32 widths |
| Parameterization | 1/2, 2/4, 4/11, 8/16, 8/32, 17/40, and 33/72 data/accumulator widths |
| Longer mixed traffic | 4,000 deterministic random cycles per configuration with occasional reset and clear |
| Suite completes | Control-transition and wrap counters, seven completion flags, and a global timeout |

One-bit signed operands cannot form a negative product. Exhaustive operand-pair
coverage applies through 8 bits; wider operands use boundary and random cases.
The suite does not prove all input histories or all possible legal widths.
UVM, functional coverage collection, assertions, and DPI-C remain later learning
topics. Build the extended array testbench for the [testbench milestone](#testbench-completion).

## Verification roadmap

The Day 1 outline proposes three verification stages after the shared introduction.
This is a proposed grouping of the discussion's learning goals; mentors should
confirm scope and tool support before expanding the exercises.

| Track stage | Practice | Current status |
| --- | --- | --- |
| 1. Directed tests and debugging | Read the supplied PE suite, map requirements to checks, and observe how a design bug is detected. | PE acceptance suite supplied. |
| 2. Scoreboards and coverage | Use the PE reference to build array checks, matrix expected results, stimulus, assertions, and coverage goals. | Array extensions planned. |
| 3. UVM and integration | Organize driver, monitor, and scoreboard responsibilities; extend to array/subsystem regressions. Introduce DPI-C if a reference model needs it. | Planned; tool configuration must be validated. |

Start at [Getting started](#getting-started-with-verification) and track cases in the
[PE verification plan](#pe-verification-plan). The supplied tests do not pass
until the shared PE is implemented.

### Completion check

Check the work at [testbench completion](#testbench-completion).
The stages above guide learning; they do not require individual checkoffs.

### Open verification decisions

Confirm CAE simulator versions and UVM/DPI-C support, the project's block diagram,
interface ownership, coverage goals, and regression commands. Agree on the array's
behavior with the [RTL track](../rtl/README.md#rtl-roadmap). Update tests and design
contracts together when requirements change.

## Testbench completion

Run the completed array testbench against a correct implementation and confirm it
checks the agreed array requirements, including edge cases. Introduce representative design
bugs and confirm the testbench reports failures, then restore the correct design
and rerun. Use an array verification plan, modeled on the [PE plan](#pe-verification-plan),
to identify what the testbench covers.

The array and extended testbench are still planned. Their run commands will be
added when implemented. These are completion criteria, not claims that those
projects already exist.

## Verification resources

### Verification

| Resource | Use it for | Apply it |
| --- | --- | --- |
| [Siemens Verification Academy: UVM basics](https://verificationacademy.com/topics/uvm-universal-verification-methodology/uvm-basics/) | UVM components and methodology after basic testbenches | Sketch how driver, monitor, and scoreboard would surround the PE |
| [Doulos SystemVerilog assertions tutorial](https://www.doulos.com/knowhow/systemverilog/systemverilog-tutorials/systemverilog-assertions-tutorial/) | Reading and writing temporal checks | Propose a property for reset or valid behavior |
| [UVM video series from the discussion](https://www.youtube.com/watch?v=imH4CFmVGWE&list=PLBIILfL2t1lnvzw7vF0arlvu36Wj4--D7) | Optional supplementary training | Apply the concepts to your testbench |

Tool support must be validated in the team's environment. A tentative comment in
the discussion about ModelSim/UVM support is not a confirmed compatibility rule.

### Tools and shared prerequisites

- [Shared setup](../intro/SETUP.md#environment-setup): recommended CAE VCS workflow and optional local simulation.
- [PE contract](../intro/projects/processing-element/spec/pe.md): the baseline behavior to verify.
- [Verification-plan template](../templates/README.md#verification-plan-template): record requirements, checks, and coverage gaps.

Apply each reading to a concrete check in the [PE plan](#pe-verification-plan).

## Project files

| File | Role |
| --- | --- |
| [PE specification](../intro/projects/processing-element/spec/pe.md) | Defines required behavior. |
| [PE RTL](../intro/projects/processing-element/rtl/pe.sv) | Shared design under test; initially a student TODO. |
| [Acceptance testbench](../intro/projects/processing-element/tb/pe_tb.sv) | Supplied reference model, stimulus, and checks used by both tracks. |
| [Track verification plan](#pe-verification-plan) | Maps PE requirements to the supplied checks and states coverage limits. |

Run `make pe` at the repository root against your implemented PE. The untouched
starter is expected to fail. Keep the supplied acceptance suite available to both
tracks. Place new array scoreboards, test suites, and regression scripts under
`verif/projects/pe-verification/tb/` and `verif/projects/pe-verification/scripts/`,
referencing the shared RTL and specification. Document exact commands as those
extensions become runnable.
