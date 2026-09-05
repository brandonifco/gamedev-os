#!/bin/bash
# Install the .NET SDK and the Godot .NET/C# engine build.
set -euo pipefail
BUILD_ROOT="/opt/distro-build"
source "$BUILD_ROOT/config/distro.conf"
export DEBIAN_FRONTEND=noninteractive

echo "[0500] installing .NET SDK $DOTNET_CHANNEL"
if ! apt-get install -y "dotnet-sdk-$DOTNET_CHANNEL"; then
  echo "[0500] WARN: dotnet-sdk-$DOTNET_CHANNEL unavailable, falling back to 8.0"
  apt-get install -y dotnet-sdk-8.0
fi

echo "[0500] installing Godot $GODOT_VERSION (.NET/C# build)"
# NOTE: the *mono* download is the one with C# support. The plain build cannot run C#.
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_mono_linux_x86_64.zip"
mkdir -p /opt/godot
cd /tmp
wget -q "$GODOT_URL" -O godot.zip
unzip -oq godot.zip -d /opt/godot
rm -f godot.zip
BIN="$(find /opt/godot -maxdepth 2 -name 'Godot_v*_mono_linux.x86_64' | head -n1)"
chmod +x "$BIN"
ln -sf "$BIN" /usr/local/bin/godot

cat > /usr/share/applications/godot.desktop <<'EOF'
[Desktop Entry]
Name=Godot Engine (C#)
Comment=.NET/C# game engine
Exec=/usr/local/bin/godot
Icon=godot
Terminal=false
Type=Application
Categories=Development;IDE;
EOF

# TODO: Godot export templates (needed to *ship* a game) are large and version-locked.
# They are added per-user via Editor > Manage Export Templates, or seed them into
# /etc/skel/.local/share/godot/export_templates/ in a later hook.
echo "[0500] .NET + Godot installed"
