# Documentation templates

Use these sections when extending the introduction or a track guide.

- [Lesson](#lesson-template)
- [Project](#project-template)
- [Verification plan](#verification-plan-template)

## Lesson template

Status: draft / ready. Prerequisites: link to the relevant earlier material.
Outcome: what the learner will be able to explain or build.

### Understand

Explain the concept in the context of a concrete block or example.

### Read the code

| File, symbol, and exact link | What it does | What to notice |
| --- | --- | --- |
| Replace with a real link | Explain behavior | State a question to investigate |

### Try it

Give one bounded exercise, an exact command, and the expected observation.
Distinguish runnable examples from unfinished student work.

### Next step

Link to the next lesson. Only PE, matmul, systolic array, and testbench completion
have formal [checkpoints](../README.md#completion-checkpoints); link the relevant one when this guide
finishes that project. Other exercises are practice.

### Resources and next step

Link the resources and next section within the introduction or track README.
Link shared prerequisites from `intro/` instead of duplicating them.

## Project template

Status: proposed / starter / runnable.
Track: shared introduction / RTL / verification.
Start at: link to the relevant section of the introduction or track README.

### Files

List the specification, RTL, testbench, and any tool configuration. Use real links.
Keep teaching explanations in the corresponding introduction or track guide.

### Run

Give a command from the repository root, prerequisites, output location, and the
expected result. State explicitly if the untouched starter should fail.

### Scope

State what exists, what remains to implement, and where the verification plan lives.

## Verification plan template

Design / specification link:
Configuration and tool requirements:

| Requirement | Stimulus | Expected behavior / checker | Coverage gap | Status |
| --- | --- | --- | --- | --- |
| Replace with a requirement ID | Describe inputs | Define an independent expectation | Identify missing cases | Planned |

### Running the testbench

Give the command and required configuration. Tests should report failures clearly
and support a fixed seed when randomized stimulus is used.

Use this plan to develop checks for the agreed requirements. The formal checkoff
is [testbench completion](../verif/README.md#testbench-completion).
