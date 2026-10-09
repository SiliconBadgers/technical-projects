# ibex: where these files come from

| | |
|---|---|
| Copied from | OpenROAD-flow-scripts `flow/designs/src/ibex_sv/` at `babdf6e26cac84a79f7814a5c61c53ee84f43994` (last change to that directory: `c4d858d2`, 2026-09-02) |
| Original | lowRISC/ibex `77d801001554cce8fe69e742e96539eecbe74425`, pruned upstream (see `rtl/README.orfs.md`) |
| License | Apache-2.0, `LICENSE` (lowRISC contributors) |

## Team changes

- `rtl/prim_clock_gating.sv` replaces the upstream `syn/rtl/prim_clock_gating.v`: the library clock-gating cell `sb_icg` (each track provides one) when `SYNTHESIS` is defined, a behavioural latch for RTL simulation.
- Nothing else in `rtl/` is modified. The flows keep `ibex_register_file_ff` as its own module so that equivalence checking can cut the design at its ports.

Next: [Lab 1](../README.md)
