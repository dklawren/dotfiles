# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(cpanm docker docker-compose dnf fzf gitfast git-extras mercurial perl ssh-agent z)

#SPACESHIP_GIT_STATUS_SHOW=false

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
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"

# These tasks should only run inside of a container such as toolbox/distrobox
if [ "$DISTTAG" ]; then
  export TMUX_PLUGIN_MANAGER_PATH="~/.tmux/plugins"
  if [ -z "$TMUX" ]; then
    tmux attach -t default || tmux new -s default && exit
  fi

  source ~/perl5/perlbrew/etc/bashrc
fi

# Disable stuff for Spacehip prompt
#SPACESHIP_GIT_SHOW="false"
#SPACESHIP_DOCKER_SHOW="false"

#[ -z $DISPLAY  ] && export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}'):0.0

#if [[ -z "$XDG_RUNTIME_DIR" ]]; then
#  export XDG_RUNTIME_DIR=/run/user/$UID
#  if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
#    export XDG_RUNTIME_DIR=/tmp/$USER-runtime
#    if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
#      mkdir -m 0700 "$XDG_RUNTIME_DIR"
#    fi
#  fi
#fi

# Start Docker daemon automatically when logging in if not running.
#RUNNING=`ps aux | grep dockerd | grep -v grep`
#if [ -z "$RUNNING"  ]; then
#  sudo dockerd > /dev/null 2>&1 &
#  dockerd-rootless.sh > /dev/null 2>&1 &
#  disown
#fi

# Start Onedrive daemon automatically when logging in if not running.
#RUNNING=`ps aux | grep onedrive | grep -v grep`
#if [ -z "$RUNNING"  ]; then
#  onedrive --monitor > /dev/null 2>&1 &
#  disown
#fi

# Start Syncthing daemin automatically when logging in if not running.
#RUNNING=`ps aux | grep syncthing | grep -v grep`
#if [ -z "$RUNNING"  ]; then
#  syncthing 2>&1 > /dev/null &
#  disown
#fi

#eval "$(starship init zsh)"

#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm use node
