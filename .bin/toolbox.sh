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
