# options
setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt no_beep
setopt inc_append_history

# env
source "$ZDOTDIR/.zshenv"

# plugins & plugin manager
source "$ZDOTDIR/plugins.zsh"

# fzf
source "$ZDOTDIR/fzf.zsh"

# history
HISTFILE=${ZDOTDIR}/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
bindkey '^K' up-line-or-history
bindkey '^J' down-line-or-history

# Environment configuration
for file in ~/.{aliases,functions,helpers,path,exports}; do
    [[ -r "$file" ]] && [[ -f "$file" ]] && source "$file"
done
unset file

if [[ -r "$HOME/.local/share/deja/init.zsh" ]]; then
  source "$HOME/.local/share/deja/init.zsh"
else
  eval "$(deja init zsh)"
fi

# opencode
export PATH=/home/dkl/.opencode/bin:$PATH
