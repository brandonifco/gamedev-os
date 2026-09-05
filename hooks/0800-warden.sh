#!/bin/bash
# Stage Warden (the AI-agent sandbox layer) into the image.
# Warden provisions itself with Ansible and expects a real host (btrfs + systemd),
# so we clone it at build time and converge it on first boot rather than in the
# build chroot.
set -euo pipefail
echo "[0800] staging Warden"

git clone --depth 1 https://github.com/brandonifco/warden.git /opt/warden \
  || echo "[0800] WARN: could not clone Warden (offline?) — clone manually into /opt/warden"

# Enable rootless podman lingering support so sandboxes survive logout.
loginctl enable-linger root 2>/dev/null || true
echo "[0800] Warden staged at /opt/warden (converge on first boot)"
