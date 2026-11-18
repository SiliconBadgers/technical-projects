# File:        setup.sh
# Author:      Isaac Hagedorn
# Date:        2026-10-23
# Description: Puts the Track A tools from env/install.sh first on PATH and sets PDK_ROOT and SCL_ROOT. Usage, in tracks/a, in every new terminal: source env/setup.sh

if [ "${BASH_SOURCE[0]:-}" = "$0" ]; then
    echo "source this file: source env/setup.sh"
    exit 1
fi

SB_TRACK_A_ENV=${SB_TRACK_A_ENV:-$HOME/.conda/envs/sb-track-a}
export PDK_ROOT=${PDK_ROOT:-$HOME/.ciel}
# sky130_scl_9T release (sky130scl library); the Lab 0 scripts read it from the environment
export SCL_ROOT=${SCL_ROOT:-$PDK_ROOT/sky130_scl_9T_0.1.2}
if [ -x "$SB_TRACK_A_ENV/bin/sta" ]; then
    export PATH="$SB_TRACK_A_ENV/bin:$PATH"
    echo "[sb] Track A tools: $SB_TRACK_A_ENV   PDKs: $PDK_ROOT"
else
    echo "[sb] no Track A tools in $SB_TRACK_A_ENV: run env/install.sh first"
    return 1
fi
