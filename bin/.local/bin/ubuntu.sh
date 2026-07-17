# Install some stuff
sudo apt update && sudo apt upgrade -y && sudo apt install \
	alacritty \
  adb \
  apt-transport-https \
  btop \
  build-essential \
  ca-certificates \
  cmake \
  curl \
	distrobox \
  duf \
  fastboot \
  fastfetch \
  ffmpeg \
  flatpak \
  fonts-cantarell \
  fonts-firacode \
  fonts-inter \
  fonts-jetbrains-mono \
  fonts-liberation2 \
  fonts-noto \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  gcc \
  git \
	gnome-software-plugin-flatpak \
  gnome-tweaks \
  gnupg \
  libfuse2t64 \
  linux-headers-generic \
  make \
  nala \
  nano \
  neovim \
  nodejs \
  npm \
  openjdk-25-jdk \
  7zip \
  perl \
  preload \
  python3-pip \
  rar \
  sassc \
  software-properties-common \
  software-properties-gtk \
	syncthing \
  timeshift \
  tlp \
  tlp-rdw \
  ubuntu-restricted-extras \
  unrar \
  unzip \
  wget \
  wget \
  wmctrl \
  zip

# Remove some stuff
sudo apt remove --purge firefox

# Turn on firewall
sudo ufw enable
timedatectl set-local-rtc 1

# Turn on syncthing
sudo systemctl daemon-reload
echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w fs.inotify.max_user_watches=204800
systemctl --user --now enable syncthing

# Remove Snap support
sudo snap remove --purge firefox
sudo snap remove --purge thunderbird
sudo snap remove --purge gnome-46-2404
sudo snap remove --purge desktop-security-center
sudo snap remove --purge gtk-common-themes
sudo snap remove --purge core24
sudo snap remove --purge core24 mesa-2404
sudo snap remove --purge mesa-2404
sudo snap remove --purge core24 mesa-2404
sudo snap remove --purge core24
sudo snap remove --purge snapd-desktop-integration
sudo snap remove --purge prompting-client
sudo snap remove --purge bare
sudo snap remove --purge core24
sudo snap remove --purge snapd
sudo apt remove --autoremove snapd
sudo umount /run/snapd/ns
sudo rm -rf /snap

sudo tee /etc/apt/preferences.d/no-snap.pref <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

# Add Flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub \
  org.mozilla.thunderbird \
  com.github.tchx84.Flatseal \
  com.mattjakeman.ExtensionManager \
  com.slack.Slack \
  dev.diegovsky.Riff \
  io.missioncenter.MissionCenter \
  it.mijorus.gearlever \
  org.fedoraproject.MediaWriter \
  org.gnome.Platform \
  org.kde.KStyle.Adwaita \
  org.kde.Platform \
  org.mozilla.thunderbird \
  us.zoom.Zoom

# Install Firefox deb repo
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
sudo apt update
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
sudo apt install firefox firefox-nightly

# Install additional drivers
# sudo ubuntu-drivers install

# Turn off apparmor
# sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="apparmor=0 /' /etc/default/grub
# sudo update-grub

# Cleanup
sudo apt autoremove
