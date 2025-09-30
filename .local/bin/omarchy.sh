#!/bin/bash

# Pacman packages
sudo pacman -Syu --needed \
  cpanminus \
  tmux \
  stow \
  yazi \
  flatpak \
  npm \
  wget \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting

# Gcloud CLI
yay -S google-cloud-cli

# Initialize flatpak support
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update --appstream
flatpak update

# Install flatpak apps
flatpak install -y --or-update \
  it.mijorus.gearlever \
  org.gnome.World.PikaBackup

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
export PATH="$PATH:/usr/bin/vendor_perl"
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

# Extra themes
omarchy-theme-install https://github.com/abhijeet-swami/omarchy-ayaka-theme

if [ ! -d "$HOME/.pyenv" ]; then
  curl https://pyenv.run | bash
fi

# INstall firefox nightly
mkdir -p "$HOME/Applications"
if [ ! -d "$HOME/Applications/firefox" ]; then
  wget -qO- "https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=en-US" | tar -Jx -C /home/dkl/Applications
fi

# Install thunderbird beta
if [ ! -d "$HOME/Applications/thunderbird" ]; then
  wget -qO- "https://download.mozilla.org/?product=thunderbird-144.0b1-SSL&os=linux64&lang=en-US" | tar -Jx -C /home/dkl/Applications
fi

# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
. "$HOME/.config/nvm/nvm.sh"
nvm install node

# Install node support
npm install neovim
npm install wormhole
