#!/bin/bash
# Shell polish (fish + starship) and mise version manager. Seed defaults via /etc/skel.
set -euo pipefail
BUILD_ROOT="/opt/distro-build"
source "$BUILD_ROOT/config/distro.conf"
export DEBIAN_FRONTEND=noninteractive
echo "[0700] shell polish + mise"

# starship prompt (network required at build time).
curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin \
  || echo "[0700] WARN: starship install skipped (offline?)"

# mise version manager (pin/switch .NET, Node, etc. per project).
curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh \
  || echo "[0700] WARN: mise install skipped (offline?)"

# Seed fish config for every new user.
mkdir -p /etc/skel/.config/fish
cat > /etc/skel/.config/fish/config.fish <<'EOF'
if status is-interactive
    starship init fish | source
    test -x /usr/local/bin/mise; and /usr/local/bin/mise activate fish | source
end
EOF

# Make fish the default login shell for users created from skel.
sed -i 's|^SHELL=.*|SHELL='"$DEFAULT_SHELL"'|' /etc/default/useradd 2>/dev/null || true
echo "[0700] shell configured"
