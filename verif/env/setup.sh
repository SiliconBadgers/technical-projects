# File:        setup.sh
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Setup for the optional simulators on CAE Linux (VCS, the default, only needs `module load synopsys/suite`).
#              Source it: `source env/setup.sh [questa] [xcelium] [vcs]`. Always activates the Verilator 5.052 conda env
#              (created on first use); each argument also loads that simulator's module.

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "source this file: source ${0} [questa] [xcelium] [vcs]"
  exit 1
fi

_sb_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SB_UVM_ENV=${SB_UVM_ENV:-$HOME/.conda/envs/sb-uvm}

module load conda-forge/26.3.2 || return 1
if [ ! -x "$SB_UVM_ENV/bin/verilator" ]; then
  echo "[setup] creating $SB_UVM_ENV (first time only: about 1.5 GB and a few minutes)"
  # -p: without it mamba tries the read-only system env directory
  mamba env create -y -p "$SB_UVM_ENV" -f "$_sb_dir/environment.yml" || return 1
  # the downloaded package cache (~1.4 GB) is no longer needed once the env exists
  mamba clean -a -y >/dev/null 2>&1
elif [ ! -x "$SB_UVM_ENV/bin/iverilog" ]; then
  echo "[setup] adding new packages to $SB_UVM_ENV"
  mamba env update -y -p "$SB_UVM_ENV" -f "$_sb_dir/environment.yml" || return 1
  mamba clean -a -y >/dev/null 2>&1
fi
conda activate "$SB_UVM_ENV" || return 1

for _sb_sim in "$@"; do
  case $_sb_sim in
    questa)  module load mentor/suite/2026 ;;
    # the default xcelium (2603) is newer than the campus license
    xcelium) module load cadence/xcelium/2509 ;;
    vcs)     module load synopsys/suite ;;
    *)       echo "[setup] unknown simulator '$_sb_sim' (use questa, xcelium or vcs)" ;;
  esac
done

# mentor/suite puts a Calibre python3 wrapper first on PATH, which breaks the course scripts;
# keep the conda env (python3, verilator) in front. The Makefiles drop it again for the simulator containers.
export PATH="$SB_UVM_ENV/bin:$PATH"

echo "[setup] ready: verilator $(verilator --version | awk '{print $2}')$(for _sb_t in vsim xrun vcs; do case "$(command -v $_sb_t)" in ""|/usr/local/cae/bin/*) ;; *) printf ', %s' $_sb_t ;; esac; done)"
unset _sb_dir _sb_sim _sb_t
