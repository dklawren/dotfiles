# Installation script for workstation host

# Speed up DNF
grep -qxF 'fastestmirror=1' /etc/dnf/dnf.conf
result=$?
if [ $result = 1 ]; then
  sudo echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
  sudo echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
  sudo echo 'deltarpm=true' | sudo tee -a /etc/dnf/dnf.conf
  sudo echo 'countme=false' | sudo tee -a /etc/dnf/dnf.conf
fi

# Update packages
sudo dnf -y upgrade

# Remove unneeded packages
sudo dnf -y remove abrt

sudo dnf -y install dnf-plugins-core

# Disable openh264 repo
sudo dnf -y config-manager --set-disabled fedora-cisco-openh264

# Enable copr for lazygit
sudo dnf -y copr enable atim/lazygit

# Act CLI for Github Actions
sudo dnf -y copr enable rubemlrm/act-cli

# Terraform
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

# Install Google Cloud CLI
if [ ! -f /etc/yum.repos.d/google-cloud-sdk.repo ]; then
  sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
fi

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

# Install base packages
sudo dnf -y install --skip-broken --skip-unavailable \
  act-cli \
  alacritty \
  android-tools \
  ansible \
  awk \
  bat \
  bind-utils \
  black \
  btop \
  bzip2 \
  cairo-devel \
  cargo \
  cascadia-fonts-all \
  chafa \
  cifs-utils \
  cmake \
  composer \
  containerd.io \
  cpanminus \
  ctags \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  edk2-ovmf \
  expat-devel \
  fd-find \
  fira-code-fonts \
  fuse \
  fuse-libs \
  fzf \
  gd-devel \
  gh \
  git \
  git-credential-libsecret \
  git-delta \
  git-extras \
  glib \
  glibc-all-langpacks \
  gnome-boxes \
  gnome-tweaks \
  golang \
  google-cloud-sdk-gke-gcloud-auth-plugin \
  helix \
  htop \
  iproute \
  iputils \
  java-21-openjdk \
  jq \
  just \
  kubernetes-client \
  lazygit \
  lcms2-devel \
  libxkbcommon-devel \
  luarocks \
  man \
  mercurial \
  mysql-devel \
  ncurses-devel \
  neovim \
  nikola \
  nodejs \
  ollama \
  onedrive \
  openssh-server \
  openssl \
  openssl-devel \
  openssl-perl \
  pandoc \
  pandoc-pdf \
  patch \
  perl-App-cpanminus \
  php \
  php-curl \
  php-json \
  podman-compose \
  poetry \
  procps-ng \
  pylint \
  python3 \
  python3-flake8 \
  python3-invoke \
  python3-ipykernel \
  python3-lsp-server \
  python3-pip \
  python3-rstcheck \
  python3-sphinx \
  python3-virtualenv \
  python-devel \
  readline-devel \
  ripgrep \
  rsms-inter-fonts \
  rsms-inter-vf-fonts \
  rsync \
  ruby \
  ruby-devel \
  rubygems \
  ruff \
  smbios-utils \
  socat \
  sqlite-devel \
  stow \
  swtpm-tools \
  syncthing \
  sysstat \
  tar \
  tk-devel \
  tlp \
  tlp-rdw \
  tmux \
  util-linux-user \
  uv \
  xorg-x11-server-Xwayland \
  xz \
  zoxide \
  zsh \
  zsh-autosuggestions  \
  zsh-syntax-highlighting \

# Clean up DNF cache
sudo dnf clean all

# Enable docker
sudo systemctl --now enable docker.service

# #nable syncthing for current user
systemctl --user --now enable syncthing.service

# #nable onedrive for current user
systemctl --user --now enable onedrive.service
