#!/bin/bash
# Warden — AI-agent sandbox layer. ISOLATED, OPT-IN component.
#
# Warden is still a work in progress upstream, so it is NOT part of the default
# build. It is injected into the build only when INCLUDE_WARDEN="true" in
# config/distro.conf (build.sh handles that). The base distro is fully functional
# without it; Podman (in apt-base.list) already provides generic containers.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "[warden] installing opt-in Warden component (WIP)"

# Ansible is Warden's provisioner — kept here, not in the base, so the base
# carries no Warden dependency.
apt-get install -y ansible

git clone --depth 1 https://github.com/brandonifco/warden.git /opt/warden \
  || echo "[warden] WARN: clone failed (offline?) — clone into /opt/warden manually"

# Rootless podman sandboxes survive logout.
loginctl enable-linger root 2>/dev/null || true
echo "[warden] staged at /opt/warden — converge on first boot"
