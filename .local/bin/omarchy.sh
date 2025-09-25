#!/bin/bash

# Pacman packages
sudo pacman -Syu \
  cpanminus \
  tmux \
  stow \
  yazi \
  flatpak \
  nodejs \
  npm

# Initialize flatpak support
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak install https://gitlab.com/projects261/firefox-nightly-flatpak/-/raw/main/firefox-nightly.flatpakref
flatpak update --appstream
flatpak update

# Install flatpak apps
flatpak install -y --or-update \
  it.mijorus.gearlever \
  org.gnome.World.PikaBackup \
  org.mozilla.Thunderbird \
  org.mozilla.FirefoxNightly

# Enable Wayland support for Thunderbird
flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

# Tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins

# Oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
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
npm install -g neovim
npm install -g wormhole

# Pyenv support
curl https://pyenv.run | bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# Extra themes
omarchy-theme-install https://github.com/abhijeet-swami/omarchy-ayaka-theme

