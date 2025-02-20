# Installation script for workstation host

# Initialize flatpak support
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo
flatpak update --appstream
flatpak update

# Install flatpak apps
flatpak install -y --or-update \
  ca.desrt.dconf-editor \
  com.calibre_ebook.calibre \
  com.github.alexkdeveloper.somafm \
  com.github.johnfactotum.Foliate \
  com.github.d4nj1.tlpui \
  com.github.tchx84.Flatseal \
  com.google.Chrome \
  com.jeffser.Alpaca \
  com.mattjakeman.ExtensionManager \
  com.slack.Slack \
  com.transmissionbt.Transmission \
  com.ultimaker.cura \
  com.usebottles.bottles \
  io.github.alexkdeveloper.radio \
  io.github.flattool.Warehouse \
  io.gitlab.adhami3310.Impression \
  io.gitlab.librewolf-community \
  io.missioncenter.MissionCenter \
  io.podman_desktop.PodmanDesktop \
  it.mijorus.gearlever \
  md.obsidian.Obsidian \
  me.iepure.devtoolbox \
  org.cockpit_project.CockpitClient \
  org.gnome.Cheese \
  org.gnome.clocks \
  org.gnome.Connections \
  org.gnome.Evince \
  org.gnome.Firmware \
  org.gnome.font-viewer \
  org.gnome.Logs \
  org.gnome.Loupe \
  org.gnome.NautilusPreviewer \
  org.gnome.SimpleScan \
  org.gnome.Solanum \
  org.gnome.TextEditor \
  org.gnome.Weather \
  org.gnome.World.PikaBackup \
  org.libreoffice.LibreOffice \
  org.mamedev.MAME \
  org.mozilla.firefox \
  org.mozilla.Thunderbird \
  org.videolan.VLC \
  page.codeberg.libre_menu_editor.LibreMenuEditor \
  us.zoom.Zoom

# Enable Wayland support for Thunderbird
flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

# Install Docker CE
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
  sudo tee -a /etc/yum.repos.d/docker-ce.repo << EOM
[docker-ce-stable]
name=Docker CE Stable - x86_64
baseurl=https://download.docker.com/linux/fedora/41/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOM
fi

# Install packages
sudo dnf upgrade -y
sudo dnf remove -y \
  firefox \
  firefox-langpacks
sudo dnf install -y --skip-broken --skip-unavailable --allowerasing \
  alacritty \
  ansible \
  btop \
  cascadia-code-fonts \
  containerd.io \
  distrobox \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  fira-code-fonts \
  fzf \
  git \
  git-extras \
  gnome-tweaks \
  grim \
  grimshot \
  htop \
  mako \
  mousepad \
  neovim \
  nodejs \
  onedrive \
  openssl \
  pandoc \
  playerctl \
  podman-compose \
  polkit \
  ripgrep \
  rofi \
  slurp \
  swaybg \
  swayidle \
  swayimg \
  swaylock \
  SwayNotificationCenter \
  sway-wallpapers \
  syncthing \
  sysstat \
  thunar \
  tlp \
  tlp-rdw \
  tmux \
  udiskie \
  waybar \
  waydroid \
  wf-recorder \
  wireplumber \
  wlsunset \
  xdg-desktop-portal-wlr \
  xorg-x11-server-Xwayland \
  zsh \
  zsh-syntax-highlighting

# Enable docker
sudo systemctl --now enable docker.service

# #nable syncthing for current user
systemctl --user --now enable syncthing.service

# tlp
sudo cp "$HOME/.local/bin/files/tlp.conf" /etc/tlp.conf
sudo systemctl --now enable tlp.service
sudo systemctl stop power-profiles-daemon.service
sudo systemctl disable power-profiles-daemon.service
sudo systemctl mask power-profiles-daemon.service
