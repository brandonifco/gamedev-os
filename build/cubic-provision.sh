#!/bin/bash
# Run this INSIDE Cubic's chroot terminal to provision the image.
#
# It runs the same ordered hooks the live-build path uses, then seeds the
# first-boot wizard. The Xubuntu base already provides XFCE, so no desktop is
# installed here. Warden is only included when INCLUDE_WARDEN="true".
set -euo pipefail

# Repo root = the directory that contains config/distro.conf.
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/config/distro.conf"

echo ">> ${DISTRO_NAME}: provisioning image inside Cubic chroot"

# Hooks expect their inputs at /opt/distro-build.
BUILD_ROOT="/opt/distro-build"
mkdir -p "$BUILD_ROOT"
cp -r "$HERE/config" "$HERE/packages" "$BUILD_ROOT/"

echo ">> running build hooks"
for h in "$HERE"/hooks/*.sh; do
  echo "==== $(basename "$h") ===="
  bash "$h"
done

# Opt-in AI-agent sandbox layer.
if [ "${INCLUDE_WARDEN:-false}" = "true" ]; then
  echo "==== warden (opt-in component) ===="
  bash "$HERE/components/warden/install-warden.sh"
else
  echo ">> Warden disabled (INCLUDE_WARDEN=false) — skipping"
fi

echo ">> seeding first-boot wizard"
mkdir -p /opt/gamedevos/firstboot /opt/gamedevos/packages
cp "$HERE/firstboot/firstboot-wizard.sh" /opt/gamedevos/firstboot/
cp "$HERE/packages/flatpak.list" "$HERE/packages/vscode-extensions.list" /opt/gamedevos/packages/
chmod +x /opt/gamedevos/firstboot/firstboot-wizard.sh
mkdir -p /etc/skel/.config/autostart
cp "$HERE/firstboot/gamedevos-firstboot.desktop" /etc/skel/.config/autostart/

# Tidy staging (the app lists the wizard needs stay under /opt/gamedevos).
rm -rf "$BUILD_ROOT"

echo ">> provisioning complete."
echo ">> Exit the chroot (type 'exit') and continue Cubic's wizard to build the ISO."
