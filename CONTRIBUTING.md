# Contributing

## Choose the right home

| Change | Location |
| --- | --- |
| Shared overview, hardware foundation, setup, introductory examples, baseline PE | `intro/` |
| Array design, interfaces, buffering, control, and design smoke tests | `rtl/` |
| Verification methodology, test plans, extended testbenches, coverage, and regressions | `verif/` |
| Synthesis, timing constraints, and physical design flows | `pd/` |

The [project plan](README.md#project-plan) names the four track leads and the
onboarding requirements they need to define. Akanksha will choose the location
for software onboarding. The verification and PD courses are already available
under `verif/` and `pd/`.

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

Keep the [four course checkpoints](README.md#completion-checkpoints): PE, matmul,
systolic array, and testbench completion. Intermediate exercises remain practice.
The [membership interview](README.md#code-review-interviews) follows completion
of the required track work. Software and PD leads define their required work
and evidence without adding checkoffs to every practice exercise.

CI checks the documentation and completed introduction examples. Passing CI does
not mean an unfinished project is complete. Keep generated waveforms, simulator
products, and EDA databases out of Git.

## Automation plan

Implement the [FigJam workflow](README.md#project-plan) in follow-up PRs. The
existing Actions workflow checks course documentation, renders guide images,
simulates completed introductory examples, and runs verification-script tests.
The membership bot and track-completion checks described here are not deployed.

### 1. Bot service and identity

Use Discord commands, buttons, and forms for registration, PR submission,
availability, booking, results, and the officer's alumni action. Commands shown
in future implementation PRs must be labeled as examples until installed.

The initial hosting proposal is a Cloudflare Worker receiving
[Discord HTTP interactions](https://docs.discord.com/developers/interactions/receiving-and-responding),
with D1 storing linked identities, track progress, submissions, weekly hours,
bookings, cooldowns, and integration status. Workers and D1 have free tiers;
check their [Workers](https://developers.cloudflare.com/workers/platform/pricing/)
and [D1](https://developers.cloudflare.com/d1/platform/pricing/) limits before
deployment. GitHub Actions runs finite assessment jobs; the Worker handles live
bot interactions between those jobs.

Verify ownership when linking Discord, GitHub, and the university email. Keep
email and interview feedback in the bot's restricted records, not public PR
comments. An officer assigns `interviewer` and allowed tracks to any core-team
member who can use the corresponding rubric. Only the assigned interviewer can
record a result; only officers can initiate alumni changes. Validate webhook
signatures and permissions on the server.

### 2. Fork submissions and trusted checks

The recruit pushes to their fork and opens a PR to the club repository. The bot
accepts the PR submission, validates its author, target repository, and track,
and records the exact head commit. Exercise PRs are reviewed without merging.

Run assessment logic and supplied tests from a pinned, club-controlled course
revision in a clean workspace. Take only the student's permitted exercise files
from the submission. A student-modified workflow, edited acceptance tests, or a
printed PASS message must not be enough to establish completion. Check the trusted
run's identity, course revision, track, and submitted commit before recording it.
Later commits invalidate eligibility until checked again.

- **Shared PE:** require the suite's seven configuration completions, actual
  simulator status, no error diagnostics, and expected activity counts. Record
  simulator version, course revision, commit, configurations, seeds, and logs.
- **Software:** Akanksha defines the project checks and reproduction command.
- **RTL:** Zeb defines the required array configurations, independent result
  model, and reset/control/interface cases.
- **Verification:** Harsh defines the reference DUT and bug set. Check the
  student's testbench on a correct DUT and representative broken DUTs, preserving
  seeds, checked transaction counts, errors, and coverage gaps.
- **PD:** Isaac defines the required constraint, synthesis, timing, equivalence,
  and simulation evidence for the chosen tool/library configuration.

Prove each assessment accepts valid work and rejects a known failure, an empty
or incomplete run, and a timeout. Missing tools or licenses produce an explicit
unrun result, which cannot count as completion. Failed checks allow immediate
fixes and resubmission; only a failed interview starts the 30-day cooldown.

Use GitHub-hosted runners for compatible open-source checks. Treat licensed
CAE/VCS execution as a separate controlled integration. Use read-only tokens
and no membership-service secrets in student-code jobs. Do not execute student
code in privileged `pull_request_target` jobs or on a shared privileged runner.
See GitHub's [workflow security guidance](https://docs.github.com/en/actions/reference/security/secure-use).
Fork jobs can require [maintainer approval](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/approve-runs-from-forks);
show that pending state to the recruit instead of treating it as a test failure.

### 3. Weekly availability, interviews, and cooldown

Interviewers edit recurring weekday/time windows, timezone, and date exceptions.
Generate 30-minute appointments: 20 minutes of review and a 10-minute buffer.
Assign one eligible core-team interviewer per session. Leads provide rubrics and
help with escalations; availability comes from the whole interviewer pool.

At booking, recheck completed track, submitted commit, cooldown, and availability.
Reserve the candidate and interviewer atomically so simultaneous requests cannot
double-book either person. Handle timezones and daylight-saving changes explicitly.
Send the calendar invitation with the PR, commit, and meeting details; expose
delivery failures for retry rather than claiming the invite was sent.

Availability edits affect unbooked slots. Canceling or rescheduling an existing
appointment is explicit. With no available slots, notify the interviewer pool.
The cancellation/no-show policy needs agreement before rollout.

Accept pass/fail only from the assigned interviewer, tied to the interview,
track, and reviewed commit. Store feedback and the interview timestamp. Failure
sets the next eligible booking time to 30 days after that interview. Passing
starts membership activation for the completed track.

AI assistance is allowed under the [interview policy](README.md#understanding-ai-assistance-and-the-result).
The interview assesses whether the member can explain and modify their work.
Do not infer understanding or authorship from a detector score, formatting, or
commit volume.

### 4. Membership activation and alumni cleanup

Implement the [system-by-system changes](README.md#membership-and-alumni) as
separate, retryable steps. Repeated events must not duplicate invitations or
roster entries. Track pending GitHub acceptance, calendar delivery, and officer
Notion-access tasks; notify an officer when a step needs intervention.

The Notion workspace is on Plus. Use the normal API for roster data and officer
tasks for access grants/revocations. Enterprise SCIM is a different capability
and does not manage guests. Keep that distinction explicit when reporting status.

When alumni status is set, stop pending activation work before applying cleanup,
including pending technical-team invitations. Remove future member/subteam
calendar invitations while preserving past meeting history. Record which officer
initiated the transition and completion of each affected service.

### 5. Lead review and rollout

Akanksha owns the software plan, Zeb RTL, Harsh verification, and Isaac PD.
Course-maintenance review routing and the pool of code-review interviewers are
separate responsibilities. Confirm GitHub accounts before adding `CODEOWNERS`.
Any core-team member can interview for the tracks they can assess.

Before launch, assign the bot maintainer and service-account owner, agree on
the cancellation/no-show policy, and map Discord roles, the GitHub technical
team, Notion roster/access locations, and meeting calendars. Exercise the full
pass, fail/retry, and alumni paths with test accounts, including duplicate events,
partial service failures, and simultaneous booking attempts.

## Regenerate guide images

Run `make render` from the repository root to regenerate the waveform PNGs and
matrix-multiplication GIF. It installs the locked `render` dependency group
(matplotlib and Pillow) only for these commands. `make check` and the simulator
runner use the standard library.
