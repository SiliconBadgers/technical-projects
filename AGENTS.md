# Writing the guides

Apply these conventions to the repository's READMEs, setup instructions, lessons,
and other guide prose. Write for students learning digital design and verification.
Use the user's edits in the top-level README and `intro/` as a guide to tone and
scope. Existing text, especially in `rtl/` and `verif/`, is not automatically a
style example to preserve.

## Voice and explanation

- Sound like a knowledgeable teammate explaining what to do. Use plain language,
  direct verbs, and natural sentences. Contractions and “you” or “we” are fine.
- State supported facts directly. Avoid habitual “may,” “might,” “potentially,”
  “proposed,” and “should” when the behavior or instruction is known. Keep
  conditional language when there is an actual condition.
- Explain concepts at the point where students need them. Define unfamiliar
  terms when first used and give concrete examples where they help.
- Keep enough explanation to understand the task and debug mistakes. Concise
  does not mean reducing a lesson to unexplained commands or jargon.
- Prefer the useful positive statement. Avoid repeatedly explaining what a task
  is not, what a passing test does not prove, or what the guide does not claim.

## Choose what belongs

- Include information that helps students understand, perform, or troubleshoot
  the current task. Remove filler, obvious reminders, and tangents.
- Do not add “last checked,” “reviewed on,” “rechecked on,” or similar dates.
  Dates belong only when they are part of the subject, such as a course schedule,
  or the user explicitly requests them.
- Keep research notes, source-review history, and agent validation logs out of
  guides. Link useful source material directly without narrating how it was found
  or whether it came from a discussion, was added later, or received approval.
- Include a caveat only when it changes what students do or prevents a likely
  misunderstanding. Put it near the relevant step and state the consequence or
  action. Avoid generic warnings about permissions, compatibility, or completeness.
- Explain starter behavior once where students run it: “The starter fails until
  you implement the PE.” Do not repeat that disclaimer throughout the page.
- Describe future work once where needed. Avoid repetitive “Planned” labels and
  administrative sections about mentor approvals or open decisions unless those
  are needed for the exercise or explicitly requested.
- It's fine to say lessons or resources are incomplete and will be added later.
  Keep roadmaps as outlines; do not fabricate lessons to fill gaps.
- Link shared setup and specifications instead of repeating them. Do not repeat
  the same prerequisites, completion rules, or next step in several sections.

## Organize around learning

- Start with what students will do and how it fits into the course.
- Use descriptive headings, paragraphs for explanations, numbered lists for
  steps, and tables when entries benefit from comparison or a mapping.
- Treat documentation templates as aids, not a requirement to fill every field.
  Do not mechanically add “Status,” “Outcome,” “Scope,” or “Next step” sections
  when ordinary prose or an existing section already covers the information.
- Make optional practice clearly optional. Preserve the four existing checkpoints
  (PE, matmul, systolic array, and testbench completion); do not invent submissions,
  extra checkoffs, or mandatory explain-back exercises.
- For commands, give the working directory or environment when needed, the
  command, and the useful expected result. Include relevant output paths and
  debugging details without dumping every testbench implementation detail.

## Accuracy and editing

- Read the relevant code, specification, and existing instructions before making
  technical claims. Verify quietly; do not turn that work into guide commentary.
- Do not invent commands, tool support, project requirements, or completion
  claims. If a needed fact is unknown, resolve it or state the specific missing
  decision once. Do not wrap the whole lesson in uncertainty.
- Preserve the user's edits and intended course structure. Do not restore removed
  material just because it existed before. Stay within the requested edit scope.
- Follow `CONTRIBUTING.md` for file placement and maintained code links. Keep local
  links relative to the document and update contents links when changing headings.
- Run `make check` after documentation changes. Run simulations when changing
  executable examples or their expected behavior, not for prose-only edits.

Before finishing, reread the changed prose: does each sentence teach something,
give a useful instruction, or help navigation? Cut or combine sentences that do
none of those things.
