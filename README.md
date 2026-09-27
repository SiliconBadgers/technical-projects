# Silicon Badgers technical projects

Start with the shared introduction, then choose RTL or verification.

| Read | What is there |
| --- | --- |
| **[CAE setup](intro/SETUP.md)** | Connect, get the repository, run VCS, and view waveforms. |
| **[Shared introduction](intro/README.md)** | Digital logic, waveform exercises, SystemVerilog, and the PE project. |
| **[RTL track](rtl/README.md)** | Build the systolic array design. |
| **[Verification track](verif/README.md)** | Develop tests, follow the verification plan, and complete the testbench. |

Each page has a short contents list for jumping between sections. Links to code
open the relevant file and line range.

## First run

Follow [CAE setup](intro/SETUP.md), then run from the repository root on CAE:

```sh
make check
module load synopsys/suite
synopsys-run
make smoke
```

`make day1` simulates the supplied gates, full adder, mux, and slide 21 waveform
expressions, checks their outputs, and writes `build/day1/waves.vcd` for viewing
in GTKWave.

`make pe` runs processing element (PE) testbench;
the template RTL is expected to fail until you implement it.

## Completion checkpoints

Exercises between these milestones are self-paced practice.

| Checkpoint | Applies to | Completion check |
| --- | --- | --- |
| [PE](intro/README.md#pe-checkpoint) | Shared introduction | The PE passes all seven configurations of the supplied acceptance suite. |
| [Matmul](rtl/README.md#matmul-checkpoint) | RTL | The 2×2 implementation computes complete matrix products correctly. |
| [Systolic array](rtl/README.md#systolic-array-checkpoint) | RTL | The completed array handles the agreed configurations and control behavior. |
| [Testbench completion](verif/README.md#testbench-completion) | Verification | The completed testbench checks requirements and detects design errors. |

The array and extended testbench are still planned; their guides describe what
to build next. For repository changes, see [Contributing](CONTRIBUTING.md).
