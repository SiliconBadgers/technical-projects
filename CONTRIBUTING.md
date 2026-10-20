# Contributing

## Choose the right home

| Change | Location |
| --- | --- |
| Common stages 1–3, setup, introductory examples, baseline PE | `intro/` |
| Array design, interfaces, buffering, control, and design smoke tests | `rtl/` |
| Verification methodology, test plans, extended testbenches, coverage, and regressions | `verif/` |

The [project plan](README.md#project-plan) names the track leads and their
handoffs. Physical-design lessons and flows will live under `pd/` when
[PR #7](https://github.com/SiliconBadgers/technical-projects/pull/7) lands.

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
uv run --locked python scripts/check_docs.py --fix
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

## Automation plan

Implement these in small follow-up PRs after the track leads agree on the shared
interfaces. The current workflow continues to check the course material; the
following checkpoint and track bots are not installed yet.

### 1. Automate the PE checkpoint

Use a dedicated checkpoint request, such as a maintainer-applied `checkpoint:pe`
label on a member's PR. Rerun the check when that PR's head commit changes.
The result applies to the tested commit; a later edit needs another run. Member
solutions stay on their own branches or forks so `main` retains the exercise.

The runner takes only the submitted PE into a clean assessment workspace. Load
the testbench and runner from a recorded, maintainer-controlled course revision,
and flag changes to assessment files for review. A member changing the tests or
printing a PASS message must not be enough to satisfy the checkpoint.

Compile and simulate the PE with the supplied acceptance suite. Check the actual
exit status, error diagnostics, seven distinct configuration completions, and
the final suite completion. Use a wall-clock timeout and require the expected
activity counts. Run the published baseline plus reproducible additional seeds.
Record the student commit, course revision, simulator version, configurations,
seeds, pass/fail counts, and log in the check summary.

Use GitHub-hosted runners for compatible open-source checks. Keep CAE/VCS runs
as a separate controlled step until a licensed execution service exists; report
the simulator used. Use read-only tokens and no secrets in student-code jobs.
Do not run student code through privileged `pull_request_target` jobs or directly
on a shared CAE runner. See GitHub's [workflow security guidance](https://docs.github.com/en/actions/reference/security/secure-use).

### 2. Add track checks when their flows are ready

- **RTL:** run the agreed array configurations against an independent result
  model and check reset, restart, and the documented input/output protocol.
- **Verification:** run the student testbench against a known-good DUT and
  representative broken DUTs. Passing requires clean correct-design results and
  meaningful failures on the broken variants. Preserve seeds, error IDs, checked
  transaction counts, and coverage gaps. Harsh and Isaac curate the bug set;
  hidden variants stay in the mentor-controlled assessment environment.
- **PD:** check constraint coverage, synthesis success, timing targets,
  equivalence, and supported gate-level tests. Isaac defines thresholds for each
  library and configuration. Missing tools or licenses produce an explicit
  unrun result, which cannot count as completion.

For each check, first prove the runner accepts a valid submission and rejects a
known failure, an empty/incomplete run, and a timeout. Publish short summaries
and usable reproduction commands; keep generated databases and restricted
library files out of the repository and public artifacts.

### 3. Route reviews and check understanding

Add `CODEOWNERS` for `rtl/` (Zeb), `verif/` (Harsh and Isaac), and `pd/` (Isaac)
after confirming their GitHub accounts and write access. Configure review rules
separately if approval is to be required: listing two owners normally requests
their review but does not require both to approve. See GitHub's
[CODEOWNERS behavior](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).

A bot can flag missing evidence or edits to assessment files. A mentor reviews
authorship concerns and uses the proposed [code-review interview](README.md#optional-pilot-project-code-review-interviews)
to check understanding. Keep that decision separate from the automated result;
do not infer authorship from formatting, commit volume, or a detector score.

## Regenerate guide images

Run `make render` from the repository root to regenerate the waveform PNGs and
matrix-multiplication GIF. It installs the locked `render` dependency group
(matplotlib and Pillow) only for these commands. `make check` and the simulator
runner use the standard library.
