# Your SDC goes here

Write `sky130_scl_9T.sdc` in this folder, from the timing section of [spec.md](../spec.md). The flow reads `labs/lab2_systolic/sdc/sky130_scl_9T.sdc`.

- Plain SDC: Genus and Tempus both read this file.
- Start with `set clk_period <ns>` and use `$clk_period` everywhere after it. `make ... CLOCK_PERIOD=<ns>` replaces that line.
- The clock target is in [track/README.md](../../../track/README.md#clock-targets). How to write each part: [05 — Writing constraints](../../../docs/05_sdc.md).
- Lab 1's SDCs (`labs/lab1_reference/*/sdc/sky130_scl_9T.sdc`) show the syntax.

Next: [track/lab2.md](../../../track/lab2.md)
