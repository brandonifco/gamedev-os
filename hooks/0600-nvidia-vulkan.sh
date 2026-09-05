#!/bin/bash
# NVIDIA proprietary driver + Vulkan userspace (Godot 4 renders via Vulkan).
set -euo pipefail
BUILD_ROOT="/opt/distro-build"
source "$BUILD_ROOT/config/distro.conf"
export DEBIAN_FRONTEND=noninteractive
echo "[0600] installing Vulkan + NVIDIA driver"

apt-get install -y mesa-vulkan-drivers vulkan-tools libvulkan1

# `ubuntu-drivers` autodetection needs real hardware, which the build chroot lacks,
# so we install a specific branch here. On non-NVIDIA hardware this is inert; the
# first-boot wizard can re-run `ubuntu-drivers install` to pick the right one.
if ! apt-get install -y "nvidia-driver-${NVIDIA_BRANCH}"; then
  echo "[0600] WARN: nvidia-driver-${NVIDIA_BRANCH} unavailable at build time;"
  echo "        run 'sudo ubuntu-drivers install' on first boot instead."
fi
echo "[0600] graphics stack installed"
