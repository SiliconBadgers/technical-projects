#!/usr/bin/env bash
# File:        start.sh
# Author:      Isaac Hagedorn
# Date:        2026-10-08
# Description: Builds and starts the Track A team container. Usage: env/start.sh [build|shell|print].
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$HERE/.." && pwd)
LOCK="$REPO/pdk.lock"

# lock_top KEY: value of a top-level "KEY: value" line
lock_top() { sed -n "s/^$1:[[:space:]]*\([^[:space:]#]*\).*/\1/p" "$LOCK"; }
# lock_pdk FAMILY KEY: value of "KEY: value" in the FAMILY block under pdks:
lock_pdk() {
    awk -v fam="$1" -v key="$2" '
        /^pdks:/                  { in_pdks = 1; next }
        in_pdks && /^[^ #]/       { in_pdks = 0 }
        in_pdks && $0 ~ "^  " fam ":" { in_fam = 1; next }
        in_fam && /^  [^ ]/       { in_fam = 0 }
        in_fam && $1 == key ":"   { print $2; exit }
    ' "$LOCK"
}

BASE_TAG=$(lock_top container)                # hpretl/iic-osic-tools:2026.09
BASE_DIGEST=$(lock_top container_digest)
CIEL_VERSION=$(lock_top ciel_version)
OPDK_SKY130=$(lock_pdk sky130 open_pdks)
OPDK_GF180=$(lock_pdk gf180mcu open_pdks)
for v in BASE_TAG BASE_DIGEST CIEL_VERSION OPDK_SKY130 OPDK_GF180; do
    [ -n "${!v}" ] || { echo "start.sh: could not read $v from $LOCK" >&2; exit 1; }
done

TEAM_IMAGE=sb-track-a                            # local image, never pulled
TEAM_TAG="${BASE_TAG##*:}-${OPDK_SKY130:0:8}"    # base release + PDK version

ENGINE=${CONTAINER_ENGINE:-$(command -v docker >/dev/null 2>&1 && echo docker || echo podman)}

cmd=${1:-shell}
case "$cmd" in
build)
    echo "[sb] building localhost/$TEAM_IMAGE:$TEAM_TAG from $BASE_TAG ($BASE_DIGEST)"
    # DRY_RUN=1 prints the command instead of running it
    ${DRY_RUN:+echo \$} "$ENGINE" build \
        --build-arg "BASE_IMAGE=${BASE_TAG}@${BASE_DIGEST}" \
        --build-arg "OPEN_PDKS_SKY130=$OPDK_SKY130" \
        --build-arg "OPEN_PDKS_GF180=$OPDK_GF180" \
        --build-arg "CIEL_VERSION=$CIEL_VERSION" \
        -f "$HERE/Dockerfile" -t "localhost/$TEAM_IMAGE:$TEAM_TAG" "$REPO"
    ;;
shell|print)
    export DESIGNS=${DESIGNS:-$(dirname "$REPO")}            # host dir mounted at /foss/designs
    export DOCKER_REGISTRY=none DOCKER_USER=localhost
    export DOCKER_IMAGE=$TEAM_IMAGE DOCKER_TAG=$TEAM_TAG
    export CONTAINER_USER=${CONTAINER_USER:-$(id -u)}        # files you create stay yours
    export CONTAINER_GROUP=${CONTAINER_GROUP:-$(id -g)}
    export CONTAINER_NAME=${CONTAINER_NAME:-sb-track-a_uid_$(id -u)}
    export CONTAINER_ENGINE=$ENGINE
    if [ "$cmd" = print ]; then
        echo "image:     localhost/$DOCKER_IMAGE:$DOCKER_TAG"
        echo "base:      $BASE_TAG@$BASE_DIGEST"
        echo "open_pdks: sky130 $OPDK_SKY130, gf180mcu $OPDK_GF180 (ciel $CIEL_VERSION)"
        echo "mount:     $DESIGNS -> /foss/designs"
        echo "user:      $CONTAINER_USER:$CONTAINER_GROUP   container: $CONTAINER_NAME   engine: $ENGINE"
        exit 0
    fi
    if [ -z "${DRY_RUN:-}" ] && ! "$ENGINE" image inspect "localhost/$TEAM_IMAGE:$TEAM_TAG" >/dev/null 2>&1; then
        echo "[sb] image localhost/$TEAM_IMAGE:$TEAM_TAG not found: run 'env/start.sh build' first" >&2
        exit 1
    fi
    echo "[sb] in the container:  cd /foss/designs/$(basename "$REPO") && make PDK=sky130hd DESIGN=gcd all"
    exec "$HERE/iic/start_shell.sh"    # IIC-OSIC-TOOLS' launcher (vendored)
    ;;
*)
    echo "usage: env/start.sh [build|shell|print]"
    echo "  build   build the team image (once, and again whenever pdk.lock changes)"
    echo "  shell   start a shell in the team image (default)"
    echo "  print   show the image name and settings, start nothing"
    exit 2
    ;;
esac
