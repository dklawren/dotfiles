# Installation script for Silverblue host

# Initialize flatpak support
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo
flatpak update --appstream
flatpak update

# Install flatpak apps
flatpak install -y --or-update \
  com.github.johnfactotum.Foliate \
  com.github.tchx84.Flatseal \
  com.gitlab.newsflash \
  com.mattjakeman.ExtensionManager \
  com.slack.Slack \
  org.gnome.World.PikaBackup \
  org.mozilla.Thunderbird \
  org.mozilla.firefox \
  org.videolan.VLC \
  us.zoom.Zoom

# Enable Wayland support for Thunderbird
flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

# Firefox nightly
flatpak install https://gitlab.com/projects261/firefox-nightly-flatpak/-/raw/main/firefox-nightly.flatpakref

# Install packages
rpm-ostree upgrade
rpm-ostree remove -y \
  firefox \
  firefox-langpacks
rpm-ostree install -y \
  cascadia-code-fonts\
  distrobox \
  #dunst \
  exa \
  fira-code-fonts \
  #foot \
  fzf \
  # fuzzel \
  git \
  git-extras \
  gnome-tweaks \
  #grim \
  htop \
  moby-engine \
  neovim \
  nodejs \
  onedrive \
  openssl \
  pandoc \
  podman-compose \
  polkit \
  ripgrep \
  # `slurp \
  # sway \
  # swaybg \
  # swayidle \
  # swaylock \
  syncthing \
  sysstat \
  tlp \
  tlp-rdw \
  # waybar \
  waydroid \
  # wmenu \
  xdg-desktop-portal-wlr \
  xorg-x11-server-Xwayland \
  zsh 

# Enable docker
sudo systemctl --now enable docker.service

# #nable syncthing for current user
systemctl --user --now enable syncthing.service

# tlp
sudo cp $HOME/.local/bin/files/tlp.conf /etc/tlp.conf
sudo systemctl --now enable tlp.service
sudo systemctl stop power-profiles-daemon.service
sudo systemctl disable power-profiles-daemon.service
sudo systemctl mask power-profiles-daemon.service
