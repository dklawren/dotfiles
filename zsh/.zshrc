
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
if [ -f "/usr/share/fzf/key-bindings.zsh" ]; then
  source /usr/share/fzf/key-bindings.zsh
fi

# Perl setup
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

if [ -f "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [ -f "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [ -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/google-cloud-sdk/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.bash.inc";
fi

eval "$(pyenv init --path)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Omarchy
# source ~/.local/share/omarchy/default/bash/aliases
# source ~/.local/share/omarchy/default/bash/functions
# source ~/.local/share/omarchy/default/bash/envs

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# opencode
export PATH=/var/home/dkl/.opencode/bin:$PATH

# ===========================================
# ZSH Hacks - Dreams of Code
# ===========================================
# Add these to your .zshrc file
# ===========================================

# -------------------------------------------
# 1. Edit Command Buffer
# -------------------------------------------
# Open the current command in your $EDITOR (e.g., neovim)
# Press Ctrl+X followed by Ctrl+E to trigger
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# For Vi mode users:
# bindkey -M vicmd 'v' edit-command-line

# -------------------------------------------
# 2. Undo in ZSH
# -------------------------------------------
# Press Ctrl+_ (Ctrl+Underscore) to undo
# This is built-in, no configuration needed!
# Redo widget exists but has no default binding:
# bindkey '^Y' redo  # Example binding if you want it

# -------------------------------------------
# 3. Magic Space - Expand History
# -------------------------------------------
# Expands history expressions like !! or !$ when you press space
bindkey ' ' magic-space

# -------------------------------------------
# 4. chpwd Hook - Run Commands on Directory Change
# -------------------------------------------
# NOTE: Only one chpwd hook can be defined at once
# To merge them, use add-zsh-hook which is mentioned below

# Example: List directory contents on cd

# chpwd() {
#   ls
# }
#
# # Example: Auto-activate Python virtual environments
# chpwd() {
#   if [[ -d .venv ]]; then
#     source .venv/bin/activate
#   fi
# }
#
# # Example: Auto-load Nix development shells
# chpwd() {
#   if [[ -f flake.nix ]] && [[ -z "$IN_NIX_SHELL" ]]; then
#     nix develop
#   fi
# }
#
# # Example: Auto-use correct Node version with nvm
# chpwd() {
#   if [[ -f .nvmrc ]]; then
#     nvm use
#   fi
# }

# -------------------------------------------
# 4.1. Bonus: Merging Hooks
# -------------------------------------------

# To merge hooks, use add-zsh-hook
autoload -Uz add-zsh-hook

# Then Define separate functions
function auto_venv() {
  # If already in a virtualenv, do nothing
  if [[ -n "$VIRTUAL_ENV" && ! -f "$VIRTUAL_ENV/bin/activate" ]]; then
    deactivate
  fi

  [[ -n "$VIRTUAL_ENV" ]] && return

  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.venv/bin/activate" ]]; then
      source "$dir/.venv/bin/activate"
      return
    fi
    dir="${dir:h}"
  done
}

# function auto_nix() {
#   # If we're already in a nix develop shell, do nothing
#   [[ -n "$IN_NIX_SHELL" ]] && return
#
#   # Walk up to find a flake
#   local dir="$PWD"
#   while [[ "$dir" != "/" ]]; do
#     if [[ -f "$dir/flake.nix" ]]; then
#       # If this project already has .envrc, just allow it (you can remove this if you prefer)
#       if [[ ! -f "$dir/.envrc" ]]; then
#         # Create .envrc that loads the dev env (fast, no interactive shell)
#         cat > "$dir/.envrc" <<'EOF'
# # autogenerated: load flake dev environment
# eval "$(nix print-dev-env)"
# EOF
#         command direnv allow "$dir" >/dev/null 2>&1
#       fi
#
#       command direnv reload >/dev/null 2>&1
#       return
#     fi
#     dir="${dir:h}"
#   done
# }

function auto_nvm() {
  [[ -f .nvmrc ]] && nvm use
}

# Register them all
add-zsh-hook chpwd auto_venv
# add-zsh-hook chpwd auto_nix
add-zsh-hook chpwd auto_nvm

# -------------------------------------------
# 5. Suffix Aliases - Open Files by Extension
# -------------------------------------------
# Just type the filename to open it with the associated program
alias -s json=jless
alias -s md=bat
alias -s go='$EDITOR'
alias -s rs='$EDITOR'
alias -s txt=bat
alias -s log=bat
alias -s py='$EDITOR'
alias -s js='$EDITOR'
alias -s ts='$EDITOR'

# -------------------------------------------
# 6. Global Aliases - Use Anywhere in Commands
# -------------------------------------------
# Redirect stderr to /dev/null
alias -g NE='2>/dev/null'

# Redirect stdout to /dev/null
alias -g NO='>/dev/null'

# Redirect both stdout and stderr to /dev/null
alias -g NUL='>/dev/null 2>&1'

# Pipe to jq
alias -g J='| jq'

# Copy output to clipboard (Linux with xclip)
alias -g C='| xclip -selection clipboard'

# -------------------------------------------
# 7. zmv - Advanced Batch Rename/Move
# -------------------------------------------
# Enable zmv
autoload -Uz zmv

# Usage examples:
# zmv '(*).log' '$1.txt'           # Rename .log to .txt
# zmv -w '*.log' '*.txt'           # Same thing, simpler syntax
# zmv -n '(*).log' '$1.txt'        # Dry run (preview changes)
# zmv -i '(*).log' '$1.txt'        # Interactive mode (confirm each)

# Helpful aliases for zmv
alias zcp='zmv -C'  # Copy with patterns
alias zln='zmv -L'  # Link with patterns

# -------------------------------------------
# 8. Named Directories - Bookmark Folders
# -------------------------------------------
# Access with ~name syntax, e.g., cd ~yt or ls ~yt
hash -d yt=~/projects/youtube
hash -d dot=~/.dotfiles
hash -d dl=~/Downloads
# Add your own commonly used directories here

# -------------------------------------------
# 9. Custom Widgets
# -------------------------------------------
# Clear screen but keep current command buffer
function clear-screen-and-scrollback() {
  echoti civis >"$TTY"
  printf '%b' '\e[H\e[2J\e[3J' >"$TTY"
  echoti cnorm >"$TTY"
  zle redisplay
}
zle -N clear-screen-and-scrollback
bindkey '^X^L' clear-screen-and-scrollback

# For Linux with wl-copy:
function copy-buffer-to-clipboard() {
  echo -n "$BUFFER" | wl-copy
  zle -M "Copied to clipboard"
}

zle -N copy-buffer-to-clipboard
bindkey '^X^C' copy-buffer-to-clipboard

# -------------------------------------------
# 10. Hotkey Insertions - Text Snippets
# -------------------------------------------
# Insert git commit template (Ctrl+X, G, C)
# \C-b moves cursor back one position
bindkey -s '^Xgc' 'git commit -m ""\C-b'

# More examples:
bindkey -s '^Xgp' 'git push origin '
bindkey -s '^Xgs' 'git status\n'
bindkey -s '^Xgl' 'git log --oneline -n 10\n'
