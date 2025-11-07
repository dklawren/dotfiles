# Installation script for workstation host

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
  org.gnome.Firmware \
  org.gnome.NautilusPreviewer \
  org.gnome.SimpleScan \
  org.gnome.Solanum \
  org.gnome.World.PikaBackup \
  org.mamedev.MAME \
  org.mozilla.FirefoxNightly \
  org.mozilla.Thunderbird \
  org.videolan.VLC \
  us.zoom.Zoom

# Enable Wayland support for Thunderbird
flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

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

# Hyprland
sudo dnf -y copr enable solopasha/hyprland/

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

# Install packages
sudo dnf -y install --skip-broken --skip-unavailable \
  act-cli \
  alacritty \
  android-tools \
  ansible \
  awk \
  bat \
  bind-utils \
  black \
  blueman│ \
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
  hub \
  hyperpanel \
  hypridle \
  hyprland \
  hyprlock \
  hyprpanel \
  hyprpaper \
  hyprshot \
  hyprsunset \
  iproute \
  iputils \
  java-21-openjdk \
  jq \
  just \
  just \
  kubernetes-client \
  lazygit \
  lcms2-devel \
  libxkbcommon-devel \
  luarocks \
  mako│ \
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
  poetry \
  procps-ng \
  pseudo│ \
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
  python-decouple \
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
  waybar│ \
  webkit2gtk4.0 \
  wl-clipboard \
  xarchiver \
  xorg-x11-server-Xwayland \
  xz \
  zoxide \
  zsh \
  zsh-autosuggestions  \
  zsh-syntax-highlighting \

sudo dnf clean all

# Enable docker
sudo systemctl --now enable docker.service

# #nable syncthing for current user
systemctl --user --now enable syncthing.service

# Tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ~/.tmux/plugins/tpm/bin/install_plugins
fi

# Oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
fi
chsh -s /bin/zsh dkl

# Starship
curl -sS https://starship.rs/install.sh | sh

# Install perl modules
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm install --quiet --notest \
  AnyEvent \
  App::cpanminus \
  App::cpm \
  App::perlimports \
  Carton \
  Carton::Snapshot \
  common::sense \
  Git::Critic \
  Guard \
  Log::Log4perl \
  Module::CPANfile \
  Mojolicious \
  Open::This \
  Perl::Critic \
  Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText \
  Perl::Critic::Policy::Freenode::PackageMatchesFilename \
  Perl::LanguageServer \
  Perl::Tidy \
  Test::Perl::Critic::Progressive

# Install node support
mkdir $HOME/.nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install node
nvm use node
npm install -g neovim

# Rust support
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo install eza
cargo install stylelua

# Pyenv support
if [ ! -d "$HOME/.pyenv" ]; then
  curl https://pyenv.run | bash
fi

# Lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
