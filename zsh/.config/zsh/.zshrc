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

# Zoxide
eval "$(zoxide init zsh)"

# ===========================================
# 11. Session Management Checks (tmux/IDE)
# ===========================================
function check_and_spawn_session() {
    # Only act in interactive shells; skip scripts, SSH-exec, etc.
    [[ $- == *i* ]] || return
    # Need tmux available to do anything useful.
    command -v tmux >/dev/null 2>&1 || return
    # Already inside tmux: nothing to do.
    [[ -n "$TMUX" ]] && return

    # Skip inside VS Code / embedded IDE terminals.
    case "$TERM_PROGRAM" in vscode) return ;; esac
    [[ -n "$VSCODE_INJECTION" ]] && return

    # Attach to an existing 'main' session, creating it if needed, and
    # replace this shell so we actually land inside tmux.
    exec tmux new-session -A -s main
}

# Run the check when the shell starts
check_and_spawn_session

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

eval "$(opencode completion)"
