#!/bin/bash
# Remove Snap and block it from coming back (you chose to strip Snap).
set -euo pipefail
echo "[0100] removing snapd"
export DEBIAN_FRONTEND=noninteractive

apt-get purge -y snapd || true
apt-get autoremove -y --purge || true
rm -rf /var/cache/snapd /root/snap /snap 2>/dev/null || true

# Pin snapd to never reinstall.
cat > /etc/apt/preferences.d/no-snapd <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
echo "[0100] snapd removed and pinned out"
