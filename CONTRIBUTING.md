# Contributing

## Choose the right home

| Change | Location |
| --- | --- |
| Common stages 1–3, setup, introductory examples, baseline PE | `intro/` |
| Array design, interfaces, buffering, control, and design smoke tests | `rtl/` |
| Verification methodology, test plans, extended testbenches, coverage, and regressions | `verif/` |

Keep teaching explanations in `intro/README.md`, `rtl/README.md`, or
`verif/README.md`. Add a section and a contents link instead of another guide file.
Keep setup in `intro/SETUP.md` and behavior specifications beside their code.
Each guide should explain what to learn, which exact files and symbols to open, what to try, how to run it, and what behavior to expect.

Use the [guide template](templates/README.md#lesson-template), [project template](templates/README.md#project-template),
and [verification-plan template](templates/README.md#verification-plan-template). Link new content
from the [introduction](intro/README.md#shared-introduction), [RTL track](rtl/README.md#rtl-track), or
[verification track](verif/README.md#verification-track) as appropriate. Mark unfinished work explicitly.
Keep shared specifications and baseline code in one place and link to them from
both tracks; coordinate behavior changes with the other track.

## Keep code links accurate

Use heading links for specifications and worksheets. Code links use an invisible
Markdown annotation, as shown in the [shared code map](intro/README.md#code-map):
`[label](relative/file.sv#L7-L12)<!-- region:interface -->`.

The matching entry in [code_links.json](scripts/code_links.json) locates the code
using existing declarations or statements. `start` must match exactly one line;
`end` selects the first matching line at or after it. Optional `start_offset` and
`end_offset` values adjust those inclusive boundaries. Keep this metadata in the
script directory; no documentation markers are needed in student source files.
If a declaration changes, update its anchor rather than hard-coding line numbers.

After changing code or moving files, run from the repository root:

```sh
python3 scripts/check_docs.py --fix
make check
make smoke
```

The checker refreshes marked line ranges and checks local file, heading, and line
links. It does not validate external URLs or judge prose accuracy. Review the
explanation whenever behavior changes, even if its links still work.

## Completion checks

Only the [four main checkpoints](README.md#completion-checkpoints) require a completion check:
PE, matmul, systolic array, and testbench completion. Keep intermediate exercises
as practice without extra submissions or checkoffs. Guide templates should follow
that same structure.

CI checks the documentation and completed introduction examples. Passing CI does
not mean an unfinished project is complete. Keep generated waveforms, simulator
products, and EDA databases out of Git.
