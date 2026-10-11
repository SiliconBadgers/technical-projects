# Lab 4: Bug hunt (day 10)

**Goal:** find out how many bugs your testbench catches. Mentors have a broken version of the design with 8 seeded bugs, built one at a time as `M01 … M08`.

## Process

1. Commit your testbench and tell your mentor the commit.
2. The mentor runs your `tb/regress.list` against the golden design and each broken build, and sends you a scorecard.
3. Write a bug report for each caught build, using `../../docs/templates/bug-report-template.md`.
4. Improve your test plan and tests, then ask for another round.

A bug counts as caught when your regression fails on that build and passes on the golden design. If your regression fails on the golden design, the round scores 0. The broken builds use the default `DEPTH`.

## Scoring

| Tier | Caught |
|---|---|
| Bronze | 4 or more |
| Silver | 6 or more, plus coverage target met |
| Gold | 8 |
