#!/bin/bash
# PRIMARY build path: prepare a Cubic-based ISO build.
#
# Cubic is a GUI tool, so the ISO is actually produced in Cubic's wizard — this
# script just installs Cubic and prints the exact steps. The real provisioning
# (installing your software into the image) is done by cubic-provision.sh, which
# you run INSIDE Cubic's chroot terminal.
#
# Why Cubic: it remasters the official Xubuntu ISO, so you keep Ubuntu's proven
# installer (including btrfs partitioning) and reliable boot — giving you a real,
# installable OS fast. See docs/SPEC.md and build/CUBIC.md.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/config/distro.conf"

if ! command -v cubic >/dev/null 2>&1; then
  echo ">> Cubic not found — installing (needs sudo + network)"
  sudo add-apt-repository -y ppa:cubic-wizard/release
  sudo apt-get update
  sudo apt-get install -y cubic
else
  echo ">> Cubic already installed"
fi

cat <<EOF

==================================================================
  Cubic is ready. To build ${DISTRO_NAME} ${DISTRO_VERSION}:
==================================================================

1. Download the XUBUNTU 24.04 LTS desktop ISO (it's already XFCE, so it matches
   your desktop choice and stays lean):
       https://xubuntu.org/download/

2. Launch Cubic (search your menu, or run: cubic) and point it at that ISO.
   Cubic will open a terminal INSIDE the image (a chroot).

3. In that chroot terminal, copy this repo in and run the provisioner:
       # from your normal system, note this repo's path: ${HERE}
       # inside Cubic's chroot, once you've copied the repo to /root:
       bash /root/$(basename "$HERE")/build/cubic-provision.sh

   (Cubic lets you copy files into the chroot; or mount/scp the repo in.)

4. Continue Cubic's wizard: choose the kernel, optionally trim extra packages,
   then let it generate the ISO.

5. Boot the ISO in a VM (GNOME Boxes / virt-manager / VirtualBox) and install it,
   choosing a btrfs root so snapshots work.

Detailed walkthrough:      build/CUBIC.md
Warden (opt-in) enabled?:  INCLUDE_WARDEN=${INCLUDE_WARDEN}
==================================================================
EOF
