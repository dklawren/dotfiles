# Installation script for Silverblue host

# Initialize flatpak support
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo
flatpak install https://gitlab.com/projects261/firefox-nightly-flatpak/-/raw/main/firefox-nightly.flatpakref
flatpak update --appstream
flatpak update

# Install flatpak apps
flatpak install -y --or-update \
  ca.desrt.dconf-editor \
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
rpm-ostree install -y --allow-inactive --idempotent \
  alacritty \
  android-tools \
  ansible \
  btop \
  cascadia-code-fonts \
  containerd.io \
  distrobox \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  edk2-ovmf \
  fira-code-fonts \
  fzf \
  git \
  git-extras \
  gnome-boxes \
  gnome-tweaks \
  htop \
  neovim \
  nodejs \
  onedrive \
  openssl \
  pandoc \
  pandoc-pdf \
  podman-compose \
  polkit \
  ripgrep \
  rsms-inter-fonts \
  rsms-inter-vf-fonts \
  smbios-utils \
  swtpm-tools \
  syncthing \
  sysstat \
  tlp \
  tlp-rdw \
  tmux \
  wireplumber \
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
