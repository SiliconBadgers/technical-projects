# File:        Dockerfile
# Author:      Isaac Hagedorn
# Date:        2026-10-09
# Description: Track A team image, a thin layer on IIC-OSIC-TOOLS. Build with `env/start.sh build` (versions come from pdk.lock).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG OPEN_PDKS_SKY130
ARG OPEN_PDKS_GF180
ARG CIEL_VERSION

# /foss/pdks is root-owned
USER root

# base image's ciel and PDKs must match pdk.lock
RUN set -eux; \
    test "$(pip3 show ciel | sed -n 's/^Version: //p')" = "${CIEL_VERSION}"; \
    test "$(cat "${PDK_ROOT}/ciel/sky130/current")"   = "${OPEN_PDKS_SKY130}"; \
    test "$(cat "${PDK_ROOT}/ciel/gf180mcu/current")" = "${OPEN_PDKS_GF180}"

# add sky130_fd_sc_hs (633 MB); drop the sky130B copy it unpacks
RUN set -eux; \
    ciel enable --pdk-family sky130 -l sky130_fd_sc_hd -l sky130_fd_sc_hs "${OPEN_PDKS_SKY130}"; \
    rm -rf "${PDK_ROOT}/sky130B" "${PDK_ROOT}"/ciel/sky130/versions/*/sky130B; \
    ls "${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hs/lib/sky130_fd_sc_hs__ss_100C_1v60.lib"

# Lab 0 Python packages (pinned in requirements.txt); check the base image's cocotb version
COPY requirements.txt /tmp/sb-requirements.txt
RUN set -eux; \
    grep -E '^(liberty-parser|lark)==' /tmp/sb-requirements.txt > /tmp/sb-add.txt; \
    pip3 install --no-cache-dir --break-system-packages -r /tmp/sb-add.txt; \
    test "$(pip3 show cocotb | sed -n 's/^Version: //p')" = \
         "$(sed -n 's/^cocotb==\([^ ]*\).*/\1/p' /tmp/sb-requirements.txt)"

# smoke check: flow tools on PATH, read_slang built in
# NOTE(spec-mismatch): spec §2(b) yosys-slang is already in Yosys.
RUN set -eux; \
    for t in yosys eqy sta verilator verible-verilog-lint iverilog vvp; do command -v "$t"; done; \
    yosys -q -p 'help read_slang' > /dev/null; \
    python3 -c 'import cocotb, yaml, liberty, matplotlib'

# NOTE(spec-mismatch): spec §2(c) flow scripts come from the mounted clone, not the image.
# sky130_scl_9T is not in the image: unpack the mentor's tarball next to your clone
ENV SCL_ROOT=/foss/designs/sky130_scl_9T_0.1.2

# base image's default user
USER 1000:1000
