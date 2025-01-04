# Installation script for Silverblue host

# Initialize flatpak support
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo
flatpak update --appstream
flatpak update

# Install flatpak apps
flatpak install -y --or-update \
  ca.andyholmes.Valent \
  ca.desrt.dconf-editor \
  com.calibre_ebook.calibre \
  com.github.alexkdeveloper.somafm \
  com.github.d4nj1.tlpui \
  com.github.johnfactotum.Foliate \
  com.github.neithern.g4music \
  com.github.tchx84.Flatseal \
  com.gitlab.newsflash \
  com.google.Chrome \
  com.jeffser.Alpaca \
  com.mattjakeman.ExtensionManager \
  com.slack.Slack \
  com.transmissionbt.Transmission \
  com.ultimaker.cura \
  com.usebottles.bottles \
  com.vivaldi.Vivaldi \
  dev.bragefuglseth.Keypunch \
  fr.handbrake.ghb \
  io.github.alexkdeveloper.radio \
  io.github.flattool.Warehouse \
  io.github.vikdevelop.SaveDesktop \
  io.github.zen_browser.zen \
  io.gitlab.adhami3310.Impression \
  io.gitlab.librewolf-community \
  io.missioncenter.MissionCenter \
  io.podman_desktop.PodmanDesktop \
  it.mijorus.gearlever \
  md.obsidian.Obsidian \
  me.iepure.devtoolbox \
  net.codelogistics.webapps \
  net.waterfox.waterfox \
  one.ablaze.floorp \
  org.cockpit_project.CockpitClient \
  org.fedoraproject.MediaWriter \
  org.gnome.baobab \
  org.gnome.Calculator \
  org.gnome.Characters \
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
  org.mozilla.vpn \
  org.videolan.VLC \
  page.codeberg.libre_menu_editor.LibreMenuEditor \
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
  exa \
  fira-code-fonts \
  fzf \
  git \
  git-extras \
  gnome-tweaks \
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
  syncthing \
  sysstat \
  tlp \
  tlp-rdw \
  tmux \
  waydroid \
  xdg-desktop-portal-wlr \
  xorg-x11-server-Xwayland \
  zsh \
  zsh-syntax-highlighting

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
