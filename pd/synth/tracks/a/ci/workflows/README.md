# CI workflows

GitHub only runs workflows from `.github/workflows/`, so they live there, not here (track/course_spec.md §3).

- `.github/workflows/track_a.yml`: Lab 1a gcd on all four open platforms; Lab 2 on sky130hd and gf180_7t (once the student SDC exists); `ci/verify_seeded_bugs.sh` on the mentor branch.
- Runs in the team image: set the repository variable `SB_IMAGE` to its registry name (see the top of the workflow).

NOTE(spec-mismatch): see [track/spec_deviations.md](../../track/spec_deviations.md).

Next: [track/maintainers.md](../../track/maintainers.md)
