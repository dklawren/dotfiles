#!/bin/bash

#Moving to the home directory
cd $HOME || exit

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

# Install packages
sudo dnf -y install --skip-broken \
  act-cli \
  android-tools \
  bind-utils \
  black \
  bzip2 \
  btop \
  cairo-devel \
  cargo \
  chafa \
  cifs-utils \
  cmake \
  composer \
  cpanminus \
  ctags \
  exa \
  expat-devel \
  fd-find \
  fzf \
  gd-devel \
  gh \
  git \
  git-delta \
  git-extras \
  git-credential-libsecret \
  glib \
  glibc-all-langpacks \
  golang \
  google-cloud-sdk-gke-gcloud-auth-plugin \
  htop \
  hub \
  iproute \
  iputils \
  jq \
  kubernetes-client \
  lazygit \
  lcms2-devel \
  libxkbcommon-devel \
  luarocks \
  webkit2gtk4.0 \
  man \
  mercurial \
  mysql-devel \
  ncurses-devel \
  neovim \
  nodejs \
  openssh-server \
  openssl-devel \
  openssl-perl \
  patch \
  perl-App-cpanminus \
  php \
  php-curl \
  php-json \
  podman-compose \
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
  readline-devel \
  ripgrep \
  rsync \
  ruby \
  ruby-devel \
  rubygems \
  sqlite-devel \
  socat \
  sysstat \
  tar \
  tk-devel \
  tmux \
  util-linux-user \
  wl-clipboard \
  xz \
  zsh \
  zsh-autosuggestions  \
  zsh-syntax-highlighting

sudo dnf clean all

# Tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins

# Oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
curl -sS https://starship.rs/install.sh | sh

# Perlbrew
curl -L https://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
perlbrew install perl-5.38.2
perlbrew use perl-5.38.2

# Install perl modules
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

# Allow use of podman and docker inside the distrobox
sudo ln -s /usr/bin/distrobox-host-exec /usr/bin/podman
sudo ln -s /usr/bin/distrobox-host-exec /usr/bin/docker
sudo ln -s /usr/bin/distrobox-host-exec /usr/bin/rpm-ostree

# Install node support
mkdir $HOME/.nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install node
nvm use node
npm install -g neovim
npm install -g prettier
npm install -g wormhole
npm install -g dockerfile-language-server-nodejs
npm install -g intelephense
npm install -g vscode-langservers-extracted
npm install -g yaml-language-server@next
npm install -g perlnavigator-server
npm install -g typescript typescript-language-server

# Rust support
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# Install Deno
curl -fsSL https://deno.land/install.sh | sh

# Pyenv support
curl https://pyenv.run | bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
