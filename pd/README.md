# Physical design

**Lead: Isaac.** The [onboarding plan](../README.md#physical-design-scope-the-onboarding-assignment)
asks Isaac to define the required subset, deliverables, and interview rubric.
The full synthesis course below is available learning material; its entire
six-week sequence is not automatically the onboarding requirement.

This area covers how RTL becomes a chip. It starts with synthesis: turning RTL into gates, writing the timing constraints, and checking that the gates are correct and fast enough. Place-and-route material will be added here later.

| Read | What is there |
| --- | --- |
| **[Synthesis course](synth/README.md)** | Lint, synthesis, SDC constraints, static timing, equivalence checking and gate-level simulation, with three labs: library literacy, two reference designs, and an accelerator tile. |

## Tools and the PDK

The synthesis course runs with one of three tool sets; [Pick a track](synth/tracks/README.md) explains the choice. Track A uses open-source tools on your own computer. Tracks B1 (Cadence) and B2 (Synopsys) need a licensed machine such as CAE.

Tracks B1 and B2 read their standard-cell libraries from the SiliconBadgers PDK repository. Clone it into this folder as `pd/silicon-badgers-sky130-pdk`, where the course looks for it and Git ignores it. Ask a mentor for access.
