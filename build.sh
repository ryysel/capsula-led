#!/bin/sh
# Build capsula-led for the VK Капсула 2019 (aarch64, glibc).
#
# A static binary is used on purpose: the capsule runs Buildroot with glibc
# 2.33, and a static build keeps working regardless of the toolchain version.
set -eu
cd "$(dirname "$0")"

CC=${CC:-aarch64-linux-gnu-gcc}
if ! command -v "$CC" > /dev/null 2>&1; then
    echo "$CC not found. Install gcc-aarch64-linux-gnu," >&2
    echo "or use the container command from README." >&2
    exit 1
fi

"$CC" -O2 -static -o capsula-led src/ledctl.c
echo "built: $(pwd)/capsula-led"
