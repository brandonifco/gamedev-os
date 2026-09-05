#!/bin/bash
# Install the curated apt package set.
set -euo pipefail
BUILD_ROOT="/opt/distro-build"
export DEBIAN_FRONTEND=noninteractive
echo "[0300] installing apt packages"

LIST="$BUILD_ROOT/packages/apt-base.list"
mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$LIST" | sed 's/#.*//' | awk '{print $1}')
echo "[0300] ${#PKGS[@]} packages: ${PKGS[*]}"
apt-get install -y "${PKGS[@]}"

# Enable git-lfs globally and turn on the firewall + auto-updates.
git lfs install --system || true
systemctl enable ufw || true
systemctl enable unattended-upgrades || true
echo "[0300] apt install complete"
