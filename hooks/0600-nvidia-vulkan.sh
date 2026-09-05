#!/bin/bash
# NVIDIA proprietary driver + Vulkan userspace (Godot 4 renders via Vulkan).
set -euo pipefail
BUILD_ROOT="/opt/distro-build"
source "$BUILD_ROOT/config/distro.conf"
export DEBIAN_FRONTEND=noninteractive
echo "[0600] installing Vulkan + NVIDIA driver"

apt-get install -y mesa-vulkan-drivers vulkan-tools libvulkan1

# `ubuntu-drivers` autodetection needs real hardware, which the build chroot lacks,
# so we install a branch here as a baseline. The first-boot wizard re-runs
# `ubuntu-drivers install` to pick the exact right driver for the actual GPU.
#
# Modern NVIDIA cards (RTX 20-series onward) prefer the "-open" kernel modules,
# and RTX 50-series REQUIRE them. Older pre-Turing cards need the non-open build.
if [ "${NVIDIA_OPEN:-true}" = "true" ]; then
  CANDIDATES=("nvidia-driver-${NVIDIA_BRANCH}-open" "nvidia-driver-${NVIDIA_BRANCH}")
else
  CANDIDATES=("nvidia-driver-${NVIDIA_BRANCH}" "nvidia-driver-${NVIDIA_BRANCH}-open")
fi
installed=false
for pkg in "${CANDIDATES[@]}"; do
  if apt-get install -y "$pkg"; then installed=true; echo "[0600] installed $pkg"; break; fi
done
$installed || echo "[0600] WARN: no NVIDIA driver installed at build time; first boot will autodetect."
echo "[0600] graphics stack installed"
