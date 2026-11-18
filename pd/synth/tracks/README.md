# Pick a track

The course is the same for everyone. The tools are not. Each set of tools is a **track**, and each track lives in its own folder under `tracks/`.

| Track | Tools | Needs | Folder |
|---|---|---|---|
| A | open-source | your own computer or a UW CAE machine | [`tracks/a`](a/track/README.md) |
| B1 | commercial, first vendor | a licensed machine | [`tracks/b1`](b1/track/README.md) |
| B2 | commercial, second vendor | a licensed machine | [`tracks/b2`](b2/track/README.md) |

The tool names are in the [course README](../README.md#tracks). Ask your mentor which track to use.

## What you install

| Track | Tools | Python packages | Cell libraries |
|---|---|---|---|
| A | `env/install.sh` puts them in your home folder (no container, no sudo), or use the container (Docker or Podman) | installed with the tools | the open PDKs, installed with the tools |
| B1, B2 | already on the licensed machine | a Python venv; on UW CAE a conda-forge Python, because the tools run in a container | the SiliconBadgers PDK repo, cloned next to the course folder (B2 also builds its `.db` files) |

On UW CAE, `module load conda-forge/26.3.2` gives conda-forge's `mamba`. Your track's page has the exact steps.

## Go to your track's folder

```
cd tracks/a                # or tracks/b1, tracks/b2
```

Run every command of the course from there; build output goes to its `build/` folder. The track folder holds that track's flow, and its `track/` folder holds the setup steps, the commands for every lab, and how to read its logs.
Open your track's page and follow its setup steps: [Track A](a/track/README.md), [Track B1](b1/track/README.md), [Track B2](b2/track/README.md).

Next: [03 — Reading a Liberty file](../docs/03_liberty.md)
