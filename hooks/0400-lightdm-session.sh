#!/bin/bash
# Make LightDM log in to the XFCE session.
#
# LightDM's built-in default session is "default", but we ship only
# /usr/share/xsessions/xfce.desktop (no default.desktop). So every login — the
# greeter AND casper's live-ISO autologin — fails with "Failed to start session"
# and drops back to the greeter. Setting the default session to xfce fixes it.
#
# This is correct for both the live ISO and the installed system (this is an XFCE
# distro). casper already writes autologin-user for the live session, so with a
# valid session it autologins straight to the desktop.
set -euo pipefail
echo "[0400] configuring LightDM default session (xfce)"

install -d /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/60-gamedevos-session.conf <<'EOF'
[Seat:*]
user-session=xfce
autologin-session=xfce
EOF

echo "[0400] LightDM will start the XFCE session"
