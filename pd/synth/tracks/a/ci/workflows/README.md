# CI workflows

GitHub only runs workflows from `.github/workflows/` at the repo root, so they live there, not here.

- `.github/workflows/track_a.yml`: Lab 1a gcd on all four open platforms; Lab 2 on sky130hd and gf180_7t (once the student SDC exists). Its steps run in `tracks/a`.
- Runs in the team image: set the repository variable `SB_IMAGE` to its registry name (see the top of the workflow).

Next: [track/README.md](../../track/README.md)
