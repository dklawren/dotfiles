#!/usr/bin/env bash
#
# install-sway-ubuntu.sh — packages for the Gruvbox Sway desktop on Ubuntu.
# GNOME/GDM stays; Sway shows up as a session in the GDM menu.
# Configs come from this repo via `stow .` (run it after this script).
set -euo pipefail

PACKAGES=(
  sway swaybg swayidle swaylock waybar fuzzel kanshi
  sway-notification-center libnotify-bin swayosd
  grim slurp swappy wf-recorder wl-clipboard cliphist
  wlsunset brightnessctl playerctl
  pipewire wireplumber pipewire-pulse pavucontrol
  network-manager-gnome blueman policykit-1-gnome gnome-keyring
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk
  papirus-icon-theme fonts-noto-color-emoji jq unzip curl stow
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

# JetBrainsMono Nerd Font (bar icons)
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
  mkdir -p ~/.local/share/fonts
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o /tmp/jbm.zip
  unzip -oq /tmp/jbm.zip -d ~/.local/share/fonts/JetBrainsMonoNerd
  fc-cache -f
fi

command -v ghostty >/dev/null || echo "NOTE: ghostty not installed — see https://github.com/mkasberg/ghostty-ubuntu"
echo "Done. Run 'stow .' in ~/.dotfiles, then pick 'Sway' in the GDM session menu."
