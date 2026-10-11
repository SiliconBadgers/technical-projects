# Your SDC goes here

Writing this file is one of the Lab 2 tasks. There is no SDC here on purpose.

- Write `sky130_fd_sc_hd.sdc` in this folder from the timing section of [spec.md](../spec.md). The flow reads `labs/lab2_systolic/sdc/sky130_fd_sc_hd.sdc`.
- Write plain SDC. Design Compiler and PrimeTime both read it (with `source`: their `read_sdc` does not know `remove_from_collection`). This track has no helper procedures, so write cell names and numbers yourself, each with a comment saying where it comes from.
- Where the spec names a helper (`$sb_driving_cell`, `sb_pin_cap`), use the library itself: the driver is `sky130_fd_sc_hd__buf_2` (output pin `X`); the load comes from the input capacitance of `sky130_fd_sc_hd__buf_4` pin `A`, which you look up in the Liberty file (Lab 0 tools).
- Put the period on its own line, `set clk_period <ns>`, so `make ... CLOCK_PERIOD=<ns>` can replace it.
- For the style, look at the Lab 1 SDCs, for example [gcd](../../lab1_reference/gcd/sdc/sky130_fd_sc_hd.sdc).
- How to write constraints: [docs/05_sdc.md](../../../docs/05_sdc.md).

Next: commands and checks in [track/lab2.md](../../../track/lab2.md).
