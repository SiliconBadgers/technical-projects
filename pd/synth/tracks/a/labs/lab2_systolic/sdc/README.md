# Your SDC goes here

- Write `<platform>.sdc` (e.g. `sky130hd.sdc`) from the timing section of [`../spec.md`](../spec.md). The flow reads `sdc/$(PDK).sdc`.
- What each command means: [docs/05_sdc.md](../../../docs/05_sdc.md).
- Use `set clk_period [sb_clock_period <ns>]` and the `sb_*` helpers for drive and load: [track/README.md](../../../track/README.md#sdc-helpers).

Next: [track/lab2.md](../../../track/lab2.md)
