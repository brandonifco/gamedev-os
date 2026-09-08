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
#   sudo apt install live-build debootstrap \
#                    grub-pc-bin grub-efi-amd64-bin mtools xorriso
#   (the grub-* / mtools / xorriso set is for the grub-mkrescue repackage at the end)
#
# Usage:
#   ./build/build-livebuild.sh
#
# Output: .build/live-image-amd64.iso  (BIOS + UEFI bootable, via grub-mkrescue — see LIVEBUILD.md)
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
  --debian-installer false \
  --bootloader grub2 \
  --binary-images iso \
  `# boot=casper, NOT boot=live: the Xubuntu/casper base puts the squashfs in` \
  `# /casper, and casper mounts it. live-boot (boot=live) looks in /live, finds` \
  `# nothing, and drops to an initramfs shell ("Unable to find a medium...").` \
  --bootappend-live "boot=casper components hostname=$DISTRO_ID"

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
# Ubuntu's live-build (3.0~aXX) only scans local hooks at config/hooks/*.chroot
# (top level, non-recursive). The config/hooks/live/ subdirectory is a newer
# Debian live-build convention this version does NOT scan — hooks there run never.
mkdir -p config/hooks
for h in "$HERE"/hooks/*.sh; do
  dest="config/hooks/$(basename "$h" .sh).chroot"
  cp "$h" "$dest"
  chmod +x "$dest"
done

# Warden is an isolated, opt-in component (WIP). Only injected when explicitly
# enabled in distro.conf; the base build never depends on it.
if [ "${INCLUDE_WARDEN:-false}" = "true" ]; then
  echo ">> INCLUDE_WARDEN=true — injecting Warden component as hook 0800"
  cp "$HERE/components/warden/install-warden.sh" config/hooks/0800-warden.chroot
  chmod +x config/hooks/0800-warden.chroot
else
  echo ">> Warden disabled (INCLUDE_WARDEN=false) — base build only"
fi

echo ">> desktop metapackage"
mkdir -p config/package-lists
# task-xfce-desktop pulls XFCE + LightDM. Add live tooling to reach a bootable live session.
echo "task-xfce-desktop lightdm live-boot live-config systemd-sysv" \
  > config/package-lists/desktop.list.chroot

# ISO-assembly tooling that must exist IN the chroot (LB_BUILD_WITH_CHROOT=true).
# live-build's iso stage runs `isohybrid`, but on noble it lives in syslinux-utils,
# NOT the `syslinux` package live-build tries to install — so without this the build
# dies at the end with `isohybrid: not found`. genisoimage builds the ISO itself.
echo "syslinux-utils genisoimage" \
  > config/package-lists/isotools.list.chroot

echo ">> build (this takes a while and needs network + sudo)"
sudo lb build 2>&1 | tee build.log

# --- Fix the ISO bootloader --------------------------------------------------
# live-build's grub2 El Torito core (`grub-mkimage biosdisk iso9660`) does NOT
# initialize under GRUB 2.12: the ISO hangs at "Booting from DVD/CD..." with no
# menu, so nothing boots. Repackage the built ISO with grub-mkrescue, which emits
# a proper BIOS + UEFI El Torito that boots reliably (and adds UEFI support).
# Needs grub-pc-bin (BIOS i386-pc), grub-efi-amd64-bin (UEFI), mtools and xorriso
# on the build host — without grub-pc-bin, grub-mkrescue silently makes a
# UEFI-only image.
BUILT="$(ls "$WORK"/*.iso 2>/dev/null | grep -v "/live-image-${ARCH}.iso$" | head -1)"
FINAL="$WORK/live-image-${ARCH}.iso"
if [ -n "$BUILT" ] && command -v grub-mkrescue >/dev/null; then
  echo ">> repackaging ISO with grub-mkrescue (BIOS + UEFI bootable)"
  if [ ! -d /usr/lib/grub/i386-pc ]; then
    echo ">> WARN: grub-pc-bin missing — resulting ISO will be UEFI-only"
  fi
  ISOROOT="$WORK/isoroot"
  sudo rm -rf "$ISOROOT"; mkdir -p "$ISOROOT"
  sudo xorriso -osirrox on -indev "$BUILT" -extract / "$ISOROOT" >/dev/null 2>&1
  sudo grub-mkrescue -o "$FINAL.new" "$ISOROOT" -- -volid "$DISTRO_ID" 2>&1 | tail -3
  sudo rm -rf "$ISOROOT"
  if [ -s "$FINAL.new" ]; then
    sudo rm -f "$BUILT"
    sudo mv "$FINAL.new" "$FINAL"
    echo ">> bootable ISO ready: $FINAL"
  else
    echo ">> WARN: grub-mkrescue produced nothing; keeping original $BUILT"
    sudo rm -f "$FINAL.new"
  fi
else
  echo ">> WARN: grub-mkrescue not found — install grub-pc-bin grub-efi-amd64-bin;"
  echo ">>       the raw live-build ISO does NOT boot under GRUB 2.12."
fi
# -----------------------------------------------------------------------------

echo ">> DONE. ISO:"
ls -lh "$WORK"/*.iso 2>/dev/null || echo "no ISO produced — check build.log"
