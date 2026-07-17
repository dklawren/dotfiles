#!/usr/bin/env bash
#
# install.sh — Sway + Catppuccin Mocha desktop setup for Ubuntu 26.04
#
# Installs Sway and a matching set of Wayland desktop tools (waybar, mako,
# fuzzel, alacritty, swaylock/swayidle, screenshot tools, portals), then
# unpacks a Catppuccin-Mocha-themed config tarball into ~/.config.
#
# Assumes: GNOME/GDM stays installed as the login manager. This script adds
# a Sway session entry so you can pick "Sway" from the GDM session menu
# without removing GNOME.
#
# Usage:
#   ./install.sh
#
set -euo pipefail

CONFIG_TARBALL="${1:-sway-catppuccin-config.tar.gz}"

echo "==> Checking for config tarball: ${CONFIG_TARBALL}"
if [[ ! -f "${CONFIG_TARBALL}" ]]; then
  echo "ERROR: ${CONFIG_TARBALL} not found in the current directory." >&2
  echo "Run this script from the same directory as the tarball, or pass its path as \$1." >&2
  exit 1
fi

echo "==> Updating package lists"
sudo apt update

PACKAGES=(
  sway
  swaybg
  swayidle
  swaylock
  waybar
  mako-notifier
  fuzzel
  alacritty
  grim
  slurp
  swappy
  wl-clipboard
  xdg-desktop-portal-wlr
  xwayland
  brightnessctl
  playerctl
  pavucontrol
  network-manager-gnome
  papirus-icon-theme
  fonts-jetbrains-mono
  jq
)

echo "==> Installing packages: ${PACKAGES[*]}"
sudo apt install -y "${PACKAGES[@]}"

# --- Polkit authentication agent -------------------------------------------
# GDM/GNOME normally supplies one implicitly; a bare Sway session needs its
# own. policykit-1-gnome was dropped from the default install set in recent
# Ubuntu releases but is still installable.
echo "==> Installing a polkit authentication agent"
if ! sudo apt install -y policykit-1-gnome 2>/dev/null; then
  echo "    policykit-1-gnome unavailable, falling back to polkit-kde-agent-1"
  sudo apt install -y polkit-kde-agent-1
fi

# --- Catppuccin-flavored GTK theme (for GTK apps launched from Sway) -------
# The official catppuccin/gtk repo is archived and no longer maintained.
# It was built on top of vinceliuice/Colloid-gtk-theme, which IS still
# actively maintained and ships a Catppuccin color scheme built in via its
# --tweaks flag. We build from that upstream instead.
GTK_THEME_NAME="Colloid-catppuccin-Dark"
GTK_THEME_DIR="$HOME/.themes/${GTK_THEME_NAME}"
if [[ ! -d "${GTK_THEME_DIR}" ]]; then
  echo "==> Installing Colloid GTK theme (Catppuccin color scheme)"
  # Build dependencies for Colloid's install.sh
  sudo apt install -y sassc optipng inkscape

  TMP_GTK=$(mktemp -d)
  git clone --depth=1 https://github.com/vinceliuice/Colloid-gtk-theme.git "${TMP_GTK}/colloid-gtk" || {
    echo "    Could not clone Colloid-gtk-theme (network-restricted?) — skipping GTK theme install."
    echo "    You can install it manually later from https://github.com/vinceliuice/Colloid-gtk-theme"
  }
  if [[ -d "${TMP_GTK}/colloid-gtk" ]]; then
    mkdir -p "$HOME/.themes"
    (
      cd "${TMP_GTK}/colloid-gtk" && \
      ./install.sh --tweaks catppuccin -c dark -l -d "$HOME/.themes"
    ) || echo "    Colloid install.sh failed — see output above."
  fi
  rm -rf "${TMP_GTK}"
fi
echo "==> GTK theme(s) now in ~/.themes:"
ls "$HOME/.themes" 2>/dev/null | grep -i colloid || echo "    (none found — check the install output above for errors)"
echo "    Use the exact folder name above as the value for:"
echo "    gsettings set org.gnome.desktop.interface gtk-theme '<name>'"

# --- GPU driver check --------------------------------------------------------
# The --unsupported-gpu workaround is only needed when sway detects the
# proprietary NVIDIA driver. If you're on nouveau (as you are now), it's
# not required — but we check live rather than assume.
echo "==> Checking active GPU driver"
NEEDS_UNSUPPORTED_FLAG=0
if lsmod | grep -q '^nvidia '; then
  echo "    Proprietary NVIDIA driver detected — Sway will need --unsupported-gpu."
  NEEDS_UNSUPPORTED_FLAG=1
else
  echo "    No proprietary NVIDIA driver loaded (nouveau/other) — no flag needed."
fi

# --- GDM session entry -------------------------------------------------------
SWAY_BIN="$(command -v sway)"
DESKTOP_FILE="/usr/share/wayland-sessions/sway-catppuccin.desktop"
EXEC_LINE="${SWAY_BIN}"
if [[ "${NEEDS_UNSUPPORTED_FLAG}" -eq 1 ]]; then
  EXEC_LINE="${SWAY_BIN} --unsupported-gpu"
fi

echo "==> Writing GDM session entry to ${DESKTOP_FILE}"
sudo tee "${DESKTOP_FILE}" > /dev/null <<EOF
[Desktop Entry]
Name=Sway (Catppuccin)
Comment=Sway, a tiling Wayland compositor
Exec=${EXEC_LINE}
Type=Application
EOF

# --- Unpack config tarball ---------------------------------------------------
echo "==> Backing up any existing configs that would be overwritten"
for d in sway waybar mako alacritty fuzzel swaylock; do
  if [[ -d "$HOME/.config/$d" ]]; then
    mv "$HOME/.config/$d" "$HOME/.config/${d}.bak.$(date +%s)"
    echo "    backed up ~/.config/$d"
  fi
done

echo "==> Extracting Catppuccin Mocha config into ~/.config"
mkdir -p "$HOME/.config"
tar xzf "${CONFIG_TARBALL}" -C "$HOME/.config"

echo "==> Done."
echo ""
echo "Log out, and at the GDM login screen click the gear icon next to your"
echo "name, then choose 'Sway (Catppuccin)' before signing in."
echo ""
echo "First-launch checklist:"
echo "  - mod key is Super (Windows key) by default; see ~/.config/sway/config"
echo "  - mod+d opens fuzzel (app launcher)"
echo "  - mod+Return opens alacritty"
echo "  - mod+Shift+e opens the exit menu"
