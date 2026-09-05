#!/bin/bash
# ADVANCED / "going public" build path — Debian live-build (Ubuntu noble base).
#
# This is NOT the recommended first build. It produces a LIVE-ONLY image with
# no installer, so it cannot set up the btrfs root your snapshots depend on, and
# live-build is finicky against Ubuntu. Use build.sh (Cubic) for a real,
# installable ISO. Keep this for when you want a fully reproducible, from-scratch
# build for public distribution — at which point prefer Ubuntu autoinstall
# (see installer/) over this.
#
# Requirements (on an Ubuntu 24.04 build host):
#   sudo apt install live-build debootstrap
#
# Usage:
#   ./build/build-livebuild.sh
#
# Output: .build/live-image-amd64.hybrid.iso
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/config/distro.conf"

WORK="$HERE/.build"
echo ">> clean workspace"
sudo rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

echo ">> lb config ($BASE_SUITE / $ARCH)"
lb config \
  --distribution "$BASE_SUITE" \
  --archive-areas "main restricted universe multiverse" \
  --mirror-bootstrap "$BASE_MIRROR" \
  --mirror-binary "$BASE_MIRROR" \
  --architectures "$ARCH" \
  --debian-installer none \
  --bootappend-live "boot=live components hostname=$DISTRO_ID"

echo ">> stage build inputs into chroot (/opt/distro-build, /opt/gamedevos)"
mkdir -p config/includes.chroot/opt/distro-build
cp -r "$HERE/config" "$HERE/packages" config/includes.chroot/opt/distro-build/

mkdir -p config/includes.chroot/opt/gamedevos/firstboot config/includes.chroot/opt/gamedevos/packages
cp "$HERE/firstboot/firstboot-wizard.sh" config/includes.chroot/opt/gamedevos/firstboot/
cp "$HERE/packages/flatpak.list" "$HERE/packages/vscode-extensions.list" config/includes.chroot/opt/gamedevos/packages/
chmod +x config/includes.chroot/opt/gamedevos/firstboot/firstboot-wizard.sh

echo ">> seed first-boot autostart into /etc/skel"
mkdir -p config/includes.chroot/etc/skel/.config/autostart
cp "$HERE/firstboot/gamedevos-firstboot.desktop" config/includes.chroot/etc/skel/.config/autostart/

echo ">> install ordered chroot hooks"
mkdir -p config/hooks/live
for h in "$HERE"/hooks/*.sh; do
  dest="config/hooks/live/$(basename "$h" .sh).hook.chroot"
  cp "$h" "$dest"
  chmod +x "$dest"
done

# Warden is an isolated, opt-in component (WIP). Only injected when explicitly
# enabled in distro.conf; the base build never depends on it.
if [ "${INCLUDE_WARDEN:-false}" = "true" ]; then
  echo ">> INCLUDE_WARDEN=true — injecting Warden component as hook 0800"
  cp "$HERE/components/warden/install-warden.sh" config/hooks/live/0800-warden.hook.chroot
  chmod +x config/hooks/live/0800-warden.hook.chroot
else
  echo ">> Warden disabled (INCLUDE_WARDEN=false) — base build only"
fi

echo ">> desktop metapackage"
mkdir -p config/package-lists
# task-xfce-desktop pulls XFCE + LightDM. Add live tooling to reach a bootable live session.
echo "task-xfce-desktop lightdm live-boot live-config systemd-sysv" \
  > config/package-lists/desktop.list.chroot

echo ">> build (this takes a while and needs network + sudo)"
sudo lb build 2>&1 | tee build.log

echo ">> DONE. ISO:"
ls -lh "$WORK"/*.iso 2>/dev/null || echo "no ISO produced — check build.log"
