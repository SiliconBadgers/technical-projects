# Environment setup

**Use CAE for this project.** Working in the same environment makes it easier to
follow the guides, help each other debug, and continue into the RTL and
verification tracks. The repository defaults to Synopsys VCS on CAE. Local Icarus
Verilog simulation is available as an [alternative](#local-simulation-optional).

## UW–Madison CAE and Synopsys

### 1. Connect to CAE

For the easiest start, use the **[CAE browser desktop](https://guacamole.cae.wisc.edu)**.
Follow the [CAE graphical-access instructions](https://kb.wisc.edu/cae/163323),
sign in with your NetID, and open a terminal in that desktop. This also gives you
a graphical environment for viewing waveforms without configuring local software.

If you prefer your own terminal, connect over SSH. Replace `YOUR_NETID` with your
NetID:

```sh
ssh YOUR_NETID@best-linux.cae.wisc.edu
```

An SSH key is optional; follow the login method configured for your account.
See [CAE remote access](https://kb.wisc.edu/cae/106117) for supported connection
options. The commands below run on CAE, not in a terminal on your laptop.

### 2. Get the repository on the CAE host

Before entering the Synopsys container, run:

```sh
cd ~
git clone https://github.com/SiliconBadgers/technical-projects.git
cd technical-projects
make check
```

### 3. Enter the simulation environment

In the CAE host terminal, with your repository as the current directory:

```sh
module load synopsys/suite
synopsys-run
```

The prompt changes to `synopsys>`. `module load synopsys/suite` is necessary to run synopsys commands.
This is also explained in the [CAE software guide](https://kb.wisc.edu/cae/163133) and
[EDA quickstart](https://kb.wisc.edu/cae/163136).

### 4. Run the exercises

Inside the Synopsys container, from the repository root:

```sh
make smoke
```

This compiles and runs both completed introductory examples. Look for:

```text
PASS: Day 1 gates, full adder, mux, and waveform exercise (16 combinations)
PASS: digital logic smoke
```

`make day1` compiles and simulates the supplied Day 1 Verilog examples: logic
gates, a full adder, a mux, and the waveform expressions from slide 21. It applies
slide 21's input sequence, then checks all 16 combinations of `a`, `b`, `c`, and
`sel`. It prints `PASS` when the checks succeed and creates
`build/day1/waves.vcd` for viewing in GTKWave (a waveform viewer). Use it to compare your predicted
waveforms with the simulated circuits.

Use `make pe` when working on the processing element; the untouched PE starter
is expected to fail until you implement it. These are the same commands used
throughout the guides.

The [Makefile](../Makefile) selects VCS by default and supplies `-full64` and
`-sverilog`. If you write a VCS command yourself, include `-full64`; the default
32-bit invocation failed with a missing `libelf.so.1` on the tested CAE setup.
Generated files stay under `build/`.

### 5. View waveforms on the CAE desktop

The simulations generate:

- `build/day1/waves.vcd`
- `build/digital-logic/waves.vcd`
- `build/pe/waves.vcd` when running the PE exercise (first 10 µs by default; see the [PE debugging instructions](README.md#use-the-supplied-reference-testbench))

In a **CAE desktop host terminal**, outside the Synopsys container (your terminal prompt shouldn't be `synopsys>` when doing this step), run:

```sh
cd ~/technical-projects
gtkwave build/day1/waves.vcd
```

Use `exit` to leave the synopsys container first, or open a second terminal in the CAE
desktop. In the
viewer, add the signals named in the exercise and zoom to the relevant interval.
For Day 1, compare `a`, `b`, `c`, `out1`, and `out2` over the first 80 ns.

Plain SSH does not provide a desktop. Use the browser desktop for the viewer, or
copy the VCD to your computer and open it in a locally installed waveform viewer.

## Local simulation (optional)

Use this if you already have a local setup or want to work offline. CAE is the
recommended environment for shared project work.

Install Git, Python 3.9 or newer, GNU Make, and Icarus Verilog (`iverilog` and `vvp`).
GTKWave is optional. Follow the [Icarus installation documentation](https://steveicarus.github.io/iverilog/usage/installation.html)
for your platform, then clone the repository and run:

```sh
cd technical-projects
export SIM=iverilog
make check
make smoke
```

`export SIM=iverilog` applies to the current terminal. It lets the guide's
`make day1`, `make smoke`, and `make pe` commands use Icarus without changing each
command. Alternatively, select it for one run with `make SIM=iverilog smoke`.
CI uses Icarus for the completed examples; this does not establish compatibility
with future UVM or DPI-C exercises.

To inspect a waveform locally:

```sh
gtkwave build/day1/waves.vcd
```

## Common problems

| Symptom | What to do |
| --- | --- |
| `module` is unavailable | Use a CAE host terminal, outside the Synopsys container. |
| `git` is unavailable | Leave the Synopsys container and run Git on the host. |
| VCS is unavailable | Run `module load synopsys/suite`, then `synopsys-run`, before the simulation command. |
| `libelf.so.1` error from VCS | Use `-full64`; the Makefile already includes it. |
| License checkout fails | Check the module selection and error with your mentor or CAE. |
| GTKWave is missing in the container | Run it in a CAE desktop host terminal. |
| GUI cannot open over SSH | Use the CAE browser desktop for waveforms. |
| Icarus runs when you expected VCS | Run `unset SIM` or select VCS explicitly with `make SIM=vcs smoke`. |
| PE simulation fails | The starter is unfinished; follow the [PE guide](README.md#stage-3-implement-a-processing-element). |
