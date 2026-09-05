#!/bin/bash
# Add third-party package repositories: Microsoft (.NET + VSCode) and Flathub.
set -euo pipefail
BUILD_ROOT="/opt/distro-build"
export DEBIAN_FRONTEND=noninteractive
echo "[0200] adding repositories"

apt-get update
apt-get install -y wget gpg apt-transport-https ca-certificates curl

# Microsoft signing key (shared by the VSCode and .NET repos).
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor > /usr/share/keyrings/microsoft.gpg

# VSCode apt repo (provides the `code` package).
cat > /etc/apt/sources.list.d/vscode.list <<'EOF'
deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main
EOF

# Microsoft prod feed for .NET (pinned channels). Ubuntu 24.04 also ships .NET
# in its own repos; this feed guarantees the exact channel in distro.conf.
wget -q "https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb" -O /tmp/ms-prod.deb
dpkg -i /tmp/ms-prod.deb || true
rm -f /tmp/ms-prod.deb

apt-get update

# Flathub (flatpak itself is installed via apt-base.list in hook 0300, but the
# remote must exist before first-boot app installs).
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
echo "[0200] repositories ready"
