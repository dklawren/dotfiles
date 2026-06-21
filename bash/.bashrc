# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'


if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init bash)"; fi

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "$HOME/.cargo/env"

# opencode
export PATH=/home/dkl/.opencode/bin:$PATH

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
