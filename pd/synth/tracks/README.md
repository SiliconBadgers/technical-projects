# Pick a track

The course is the same for everyone. The tools are not. Each set of tools is a **track**, and each track lives on its own git branch.

| Track | Tools | Needs | Branch |
|---|---|---|---|
| A | open-source | your own computer | `track-a` |
| B1 | commercial, first vendor | a licensed machine | `track-b1` |
| B2 | commercial, second vendor | a licensed machine | `track-b2` |

The tool names are in the [course README](../README.md#tracks). Ask your mentor which track to use.

## Check out a track

```
git checkout track-a       # or track-b1, track-b2
```

On `main` this folder holds only this page. On a track branch, `track/` holds that track's setup steps, the commands for every lab, and how to read its logs.
After the checkout, open `track/README.md` again and follow its setup steps.

Next: [03 — Reading a Liberty file](../docs/03_liberty.md)
