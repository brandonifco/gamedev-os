#!/bin/bash
# First-boot setup wizard. Runs once per user on first graphical login.
# Handles the things that can't happen in the build chroot: Flatpak apps,
# per-user VSCode extensions, optional Rider, language profiles, and Warden.
set -uo pipefail

STAMP="$HOME/.config/gamedevos-firstboot-done"
[ -f "$STAMP" ] && exit 0

BUILD_ROOT="/opt/gamedevos"
FLATPAK_LIST="$BUILD_ROOT/packages/flatpak.list"
VSCODE_LIST="$BUILD_ROOT/packages/vscode-extensions.list"

whiptail --title "GameDevOS — first-boot setup" --msgbox \
  "Welcome! This one-time wizard finishes your setup:\n\n • removes Snap (the base needs it only to install)\n • installs your creative apps (Blender, Krita, etc.)\n • adds VSCode C# + Godot extensions\n • optional extras below\n\nPress OK to continue." 17 64

# --- Strip Snap from the INSTALLED system -----------------------------------
# The Xubuntu base uses a snap-based installer (ubuntu-desktop-bootstrap), so
# Snap must survive in the live ISO for it to install itself. We remove Snap
# here — on the installed machine — so the end result is snap-free.
if command -v snap >/dev/null 2>&1; then
  whiptail --title "Removing Snap" --infobox \
    "Removing Snap and its apps (incl. the Firefox snap).\nChromium (Flatpak) is installed below as your browser.\nThis takes a minute..." 9 62
  # Remove installed snaps in reverse order (leaf apps before bases).
  for s in $(sudo snap list 2>/dev/null | awk 'NR>1{print $1}' | tac); do
    sudo snap remove --purge "$s" 2>/dev/null || true
  done
  sudo systemctl disable --now snapd.socket snapd.service snapd.seeded.service 2>/dev/null || true
  sudo apt-get purge -y snapd 2>/dev/null || true
  sudo apt-get autoremove -y --purge 2>/dev/null || true
  rm -rf "$HOME/snap" 2>/dev/null || true
  sudo rm -rf /var/cache/snapd /root/snap /snap 2>/dev/null || true
  # Pin snapd so nothing pulls it back in.
  printf 'Package: snapd\nPin: release a=*\nPin-Priority: -10\n' \
    | sudo tee /etc/apt/preferences.d/no-snapd >/dev/null
fi

# --- Optional toggles -------------------------------------------------------
# Warden is only offered if the opt-in component was actually built in.
WARDEN_OPT=()
if [ -d /opt/warden ]; then
  WARDEN_OPT=( "warden" "Converge Warden AI-sandbox layer (WIP, optional)" OFF )
fi
CHOICES=$(whiptail --title "Optional extras" --checklist \
  "Space to toggle, Enter to confirm:" 15 68 4 \
  "rider"  "JetBrains Rider IDE (free non-commercial)" OFF \
  "${WARDEN_OPT[@]}" \
  "nvidia" "Re-run NVIDIA driver autodetect for this GPU" ON \
  3>&1 1>&2 2>&3) || CHOICES=""

# --- Flatpak apps -----------------------------------------------------------
if [ -f "$FLATPAK_LIST" ]; then
  mapfile -t APPS < <(grep -vE '^\s*(#|$)' "$FLATPAK_LIST")
  for app in "${APPS[@]}"; do
    echo "Installing $app ..."
    sudo flatpak install -y --noninteractive flathub "$app" || echo "  (failed: $app)"
  done
fi
if [[ "$CHOICES" == *rider* ]]; then
  sudo flatpak install -y --noninteractive flathub com.jetbrains.Rider || true
fi

# --- VSCode extensions (per user) -------------------------------------------
if command -v code >/dev/null && [ -f "$VSCODE_LIST" ]; then
  while read -r ext; do
    [[ "$ext" =~ ^\s*(#|$) ]] && continue
    code --install-extension "$ext" --force || true
  done < "$VSCODE_LIST"
fi

# --- NVIDIA autodetect ------------------------------------------------------
if [[ "$CHOICES" == *nvidia* ]]; then
  sudo ubuntu-drivers install || true
fi

# --- Warden converge --------------------------------------------------------
if [[ "$CHOICES" == *warden* ]] && [ -d /opt/warden ]; then
  ( cd /opt/warden \
    && ansible-galaxy collection install -r requirements.yml \
    && sudo ansible-playbook -i inventory/hosts.ini site.yml ) \
    || whiptail --msgbox "Warden converge hit an error — run it manually from /opt/warden later." 10 60
fi

mkdir -p "$(dirname "$STAMP")" && touch "$STAMP"
whiptail --title "Done" --msgbox \
  "Setup complete. Open a project with:\n\n  warden new myproject --repo <path-or-git-url>\n\nHappy building!" 12 64
