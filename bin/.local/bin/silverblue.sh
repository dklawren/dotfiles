# Installation script for Silverblue host

# Install Docker CE
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
  sudo tee -a /etc/yum.repos.d/docker-ce.repo << EOM
[docker-ce-stable]
name=Docker CE Stable - x86_64
baseurl=https://download.docker.com/linux/fedora/43/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOM
fi

rpm-ostree install -y \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Install packages
rpm-ostree install -y --allow-inactive --idempotent \
  akmod-nvidia \
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
  neovim \
  nodejs \
  ollama \
  onedrive \
  openssl \
  pandoc \
  pandoc-pdf \
  podman-compose \
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
  zsh \
  zsh-syntax-highlighting

# Enable docker
sudo systemctl --now enable docker.service

# #nable syncthing for current user
systemctl --user --now enable syncthing.service

# Enable onedrive for current user
systemctl --user --now enable onedrive.service

# tlp
#sudo cp "$HOME/.local/bin/files/tlp.conf" /etc/tlp.conf
#sudo systemctl --now enable tlp.service
#sudo systemctl stop power-profiles-daemon.service
#sudo systemctl disable power-profiles-daemon.service
#sudo systemctl mask power-profiles-daemon.service
