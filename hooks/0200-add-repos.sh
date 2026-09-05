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

# NOTE: .NET is NOT pulled from a Microsoft feed. As of Dec 2025, Canonical ships
# dotnet-sdk-10.0 natively in the Ubuntu 24.04 repos, and mixing the Microsoft
# feed with Ubuntu's is a known source of dependency conflicts. We use Ubuntu's.

apt-get update

# NOTE: the Flathub remote is added in hook 0300 (AFTER the flatpak package is
# installed) and again in the first-boot wizard — NOT here, because flatpak
# isn't installed yet at this point in the build.
echo "[0200] repositories ready"
