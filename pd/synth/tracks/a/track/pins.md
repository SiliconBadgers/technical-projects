# Version pins (Track A)

- Every version below is pinned in [`pdk.lock`](../pdk.lock) (read by `env/start.sh`, `env/Dockerfile`, `env/install.sh` and `make env-check`).
- Python packages are pinned in [`requirements.txt`](../requirements.txt).
- To move a pin: change `pdk.lock` and this file in one PR, then rerun Lab 1a on every platform.

## Container

| What | Pin |
|---|---|
| Image | `hpretl/iic-osic-tools:2026.09` |
| Index digest | `sha256:b87b3f1af9ba72d9486466ea777cf4248e96e20d9dba76d67259bc185db3859c` |
| amd64 digest | `sha256:12ffcf4190d0bb447d98c4223dda7996814d3c448dc84ed384b9b45e8738d148` |
| arm64 digest | `sha256:f681688372462b229aeffe5a8ddf0ceec0e65659a5e8040064d364abcc46b2d0` |
| ciel | `2.6.1` |

## PDKs

| What | Pin |
|---|---|
| open_pdks (both PDKs) | `1689ac3f2dc763876eaf967227c7dfe831b031ae` (tag `1.0.608`) |
| sky130 variant | `sky130A` |
| gf180 variant | `gf180mcuD`, 5 V supply (`tt_025C_5v00` / `ss_125C_4v50` / `ff_n40C_5v50`) |

Library commits (from `fossi-foundation/skywater-pdk-libs-<lib>` and `fossi-foundation/globalfoundries-pdk-libs-<lib>`):

| Library | Commit |
|---|---|
| sky130_fd_sc_hd | `9cb2d7cb8ed4619094263614039a61b6b2d22a88` |
| sky130_fd_sc_hs | `c3d7991a9bcb4fc33cbd43262b44bb5560d6fdd0` |
| sky130_fd_pr | `403964dc7f9cca5ec1a8cc7b4f2a6f532b781676` |
| gf180mcu_fd_sc_mcu7t5v0 | `0ef8889a8df0acf959683fbe73013f342a2206a2` |
| gf180mcu_fd_sc_mcu9t5v0 | `02b7af3f8d88c0b014d9af3db6a17f02aa983305` |

Not installed by ciel: `sky130_scl_9T` 0.1.2 (`extra_libraries` in `pdk.lock`, with its tarball sha256). Ask a mentor for it.

## Tools (fixed by the container digest)

| Tool | Version / commit |
|---|---|
| yosys | `v0.69` (`9f75ca1f9834a39a863915b5dae0c7b1e33533bc`) |
| eqy | `v0.69` (`4a72eb94fc253062464afee4d0018359017bb846`) |
| sv-elab (`read_slang`) | `povik/sv-elab@43a93f44b790ae5af57a25bfb5177c4dff0b22f9` |
| OpenSTA | `3.1.0`, `The-OpenROAD-Project/OpenSTA@f89887b59600cd3a2a10c3de31bda4235d904cdf` |
| verilator | `v5.052` (`ea338be98e1e838d3518809ce8899f85a009963c`) |
| verible | `v0.0-4294-gc1d8f5e8` |
| iverilog | `d1982fc7d823f1786f4788a88551f0664c16d7e7` |
| cocotb | `2.1.0` |
| kepler-formal | `f025fa2f254efd6c702cef004e55995c1f13a11a` |
| ORFS reference | `3a964e13f11a4e435aac01ffa14db0a7d2853720` |

## Without the container

`env/install.sh` ([README.md](README.md#setup), Option 1) installs the same versions where it can:

| Tool | From | Same as the container |
|---|---|---|
| yosys (with `read_slang`), verilator | conda-forge, [`env/environment.yml`](../env/environment.yml) | yes: 0.69 and 5.052 |
| eqy, sby | built from YosysHQ's `v0.69` tags | yes |
| OpenSTA | built from the commit above, with CUDD 3.0.0 | yes |
| iverilog | conda-forge | the 13.0 release, not the later commit above |
| verible | conda-forge | an older build; it only gives style advice |
| cocotb and the other Python packages | [`requirements.txt`](../requirements.txt) | yes |
| PDKs | ciel, at the `pdk.lock` hashes | yes |
| kepler-formal | not installed; the flow does not use it | |

To move a pin: change `pdk.lock`, `env/environment.yml` and this file in one PR.

Next: [README.md](README.md)
