#!\bin/bash

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
sudo dnf upgrade -y

#Remove unneeded packages
sudo dnf -y remove abrt 

#Disable openh264 repo
sudo dnf config-manager --set-disabled fedora-cisco-openh264 -y

# Enable copr for lazygit
sudo dnf copr enable atim/lazygit -y

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
sudo dnf -y install \
  android-tools \
  bind-utils \
  black \
  bzip2 \
  cairo-devel \
  cargo \
  cifs-utils \
  cmake \
  composer \
  cpanminus \
  ctags \
  exa \
  fd-find \
  fzf \
  gd-devel \
  gh \
  git \
  git-extras \
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
  man \
  mercurial \
  neovim \
  nodejs \
  openssl-devel \
  patch \
  perl-App-cpanminus \
  php \
  php-curl \
  php-json \
  procps-ng \
  pylint \
  python3 \
  python3-flake8 \
  python3-invoke \
  python3-ipykernel \
  python3-pip \
  python3-rstcheck \
  python3-sphinx \
  python3-virtualenv \
  ripgrep \
  rsync \
  ruby \
  ruby-devel \
  rubygems \
  socat \
  sysstat \
  tar \
  tmux \
  tokei \
  util-linux-user \
  xz \
  zsh

sudo dnf clean all

# Install perl modules
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"
cpanm install --quiet --notest --local-lib $HOME/perl5/lib/perl5 \
  AnyEvent \
  App::cpanminus \
  App::perlimports \
  Carton \
  common::sense \
  Guard \
  Log::Log4perl \
  Mojolicious \
  Open::This \
  Perl::Critic \
  Perl::Critic::Policy::Freenode::PackageMatchesFilename \
  Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText \
  Perl::LanguageServer \
  Perl::Tidy \
  Test::Perl::Critic::Progressive

# Allow use of podman and docker inside the distrobox
sudo ln -s /usr/bin/distrobox-host-exec /usr/local/bin/podman
sudo ln -s /usr/bin/distrobox-host-exec /usr/local/bin/docker
sudo ln -s /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree
