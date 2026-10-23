#!/usr/bin/env bash
# File:        install.sh
# Author:      Isaac Hagedorn
# Date:        2026-10-23
# Description: Installs the Track A tools and PDKs without a container or sudo. Usage, in tracks/a: env/install.sh
#              Tools: a conda environment (env/environment.yml) plus eqy, sby and OpenSTA built from source. PDKs: ciel.
#              Versions come from pdk.lock. Run it again to finish an install that stopped.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TRACK=$(cd "$HERE/.." && pwd)                                # tracks/a
ENV=${SB_TRACK_A_ENV:-$HOME/.conda/envs/sb-track-a}          # the tools, about 3 GB
PDK_ROOT=${PDK_ROOT:-$HOME/.ciel}                            # the PDKs, about 3 GB
JOBS=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}
CUDD_VERSION=3.0.0                                           # BDD library OpenSTA needs

say() { echo "[sb] $*"; }
die() { echo "[sb] $*" >&2; exit 1; }

# conda-forge package manager
CONDA=$(command -v mamba || command -v micromamba || command -v conda || true)
[ -n "$CONDA" ] || die "no mamba, micromamba or conda. On UW CAE: module load conda-forge/26.3.2. Elsewhere: install Miniforge (no sudo), https://conda-forge.org/download/"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/sb-track-a.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
# downloaded packages go to the scratch folder, so no cache stays behind in ~/.conda/pkgs
export CONDA_PKGS_DIRS=$WORK/pkgs

# 1. conda environment and Python packages
if [ ! -x "$ENV/bin/yosys" ]; then
    [ ! -e "$ENV" ] || die "$ENV exists but has no yosys: delete it and run env/install.sh again"
    say "creating $ENV (about 3 GB)"
    case $(basename "$CONDA") in
        micromamba) "$CONDA" create -y -p "$ENV" -f "$HERE/environment.yml" ;;
        *)          "$CONDA" env create -y -p "$ENV" -f "$HERE/environment.yml" ;;
    esac
fi
export PATH="$ENV/bin:$PATH"
say "Python packages (requirements.txt)"
pip install -q --no-cache-dir -r "$TRACK/requirements.txt"
lock() { python3 "$TRACK/flow/scripts/util/lock.py" get "$1"; }

# 2. eqy and sby: same release tag as yosys
TAG=$(lock tools.eqy.version)
if [ ! -x "$ENV/bin/eqy" ] || [ ! -x "$ENV/bin/sby" ]; then
    say "building eqy and sby $TAG"
    # conda's yosys-config names the compiler of the machine that built the package; use this environment's
    sed 's#/[^ ]*/_\{0,1\}build_env/bin/##g' "$ENV/bin/yosys-config" > "$WORK/yosys-config"
    chmod +x "$WORK/yosys-config"
    command -v "$("$WORK/yosys-config" --cxx)" >/dev/null || die "compiler $("$WORK/yosys-config" --cxx) not found in $ENV"
    for r in eqy sby; do
        { git clone -q --depth 1 -b "$TAG" "https://github.com/YosysHQ/$r.git" "$WORK/$r" &&
          make -C "$WORK/$r" install PREFIX="$ENV" YOSYS_CONFIG="$WORK/yosys-config"; } > "$WORK/$r.log" 2>&1 ||
            { tail -20 "$WORK/$r.log"; die "$r build failed"; }
    done
fi

# 3. CUDD and OpenSTA
STA_COMMIT=$(lock tools.opensta.commit)
if [ ! -x "$ENV/bin/sta" ]; then
    say "building CUDD $CUDD_VERSION and OpenSTA ${STA_COMMIT:0:8}"
    (
        git clone -q --depth 1 -b "$CUDD_VERSION" https://github.com/cuddorg/cudd.git "$WORK/cudd"
        cd "$WORK/cudd"
        # git does not keep file times: make the generated autotools files newer than their sources
        find . -path ./.git -prune -o -type f -exec touch -t 202001010000.00 {} +
        touch -t 202001010001.00 aclocal.m4
        touch -t 202001010002.00 configure Makefile.in config.h.in
        ./configure --prefix="$ENV"
        make -j "$JOBS"
        make install
    ) > "$WORK/cudd.log" 2>&1 || { tail -20 "$WORK/cudd.log"; die "CUDD build failed"; }
    (
        git init -q "$WORK/opensta"
        cd "$WORK/opensta"
        git fetch -q --depth 1 https://github.com/The-OpenROAD-Project/OpenSTA.git "$STA_COMMIT"
        git checkout -q FETCH_HEAD
        cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$ENV" -DCMAKE_PREFIX_PATH="$ENV" \
            -DCUDD_DIR="$ENV" -DTCL_LIB_PATHS="$ENV/lib" -DUSE_TCL_READLINE=OFF -DBUILD_TESTS=OFF
        cmake --build build -j "$JOBS"
        cmake --install build
    ) > "$WORK/opensta.log" 2>&1 || { tail -20 "$WORK/opensta.log"; die "OpenSTA build failed"; }
fi

# 4. PDKs
for fam in sky130 gf180mcu; do
    ver=$(lock "pdks.$fam.open_pdks")
    variant=$(lock "pdks.$fam.variant")
    libs=()
    for lib in $(lock "pdks.$fam.libraries"); do
        [ "$lib" = sky130_fd_pr ] || libs+=(-l "$lib")     # sky130_fd_pr is optional
    done
    say "PDK $fam ${ver:0:8} in $PDK_ROOT"
    ciel enable --pdk-root "$PDK_ROOT" --pdk-family "$fam" "${libs[@]}" "$ver"
    # keep only the variant the flow uses; ciel unpacks all of them
    for dir in "$PDK_ROOT/ciel/$fam/versions/$ver"/*/; do
        name=$(basename "$dir")
        [ "$name" = "$variant" ] || { rm -rf "$dir"; rm -f "$PDK_ROOT/$name"; }
    done
done

say "done: $(yosys -V | cut -d' ' -f1-2), OpenSTA $(sta -version), $(verilator --version | cut -d' ' -f1-2), $(vvp -V 2>&1 | head -1 | cut -d" " -f1-2,4-5)"
say "next, in every new terminal: source env/setup.sh, then make env-check"
