# Add deno completions to search path
if [[ ":$FPATH:" != *":/var/home/dkl/.zsh/completions:"* ]]; then export FPATH="/var/home/dkl/.zsh/completions:$FPATH"; fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME=""

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  cpanm
  deno
  dnf
  docker
  docker-compose
  fzf
  gh
  gitfast
  git-extras
  npm
  nvm
  perl
  podman
  python
  rsync
  rust
  ssh-agent
  starship
  systemd
  tmux
  zoxide
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration
for file in ~/.{aliases,functions,helpers,path,exports}; do
    [[ -r "$file" ]] && [[ -f "$file" ]] && source "$file"
done
unset file

# key bindings
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[3~" delete-char
bindkey "\e[2~" quoted-insert
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\ee[C" forward-word
bindkey "\ee[D" backward-word
bindkey "^H" backward-delete-word

# for rxvt
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line

# for non RH/Debian xterm, can't hurt for RH/DEbian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line

# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line

# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# FZF Keybindings
source /usr/share/fzf/shell/key-bindings.zsh

# These tasks should only run inside of a container such as toolbox/distrobox
if [[ -n "$CONTAINER_ID" || -n "$TOOLBOX_PATH" || -n "$WSL_DISTRO_NAME" ]]; then
  export TMUX_PLUGIN_MANAGER_PATH="~/.tmux/plugins"
  if [[ -z "$TMUX" && -z "$VSCODE_INJECTION" ]]; then
    tmux attach -t default || tmux new -s default && exit
  fi
fi

# Perl setup
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/google-cloud-sdk/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/google-cloud-sdk/completion.bash.inc"; fi

. "$HOME/.local/share/../bin/env"

eval "$(pyenv init --path)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
