# config directories
# export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/.ripgreprc"

# deja overrides
export DEJA_ACCEPT_KEY=␌
export DEJA_CYCLE_KEY=^N
export DEJA_CYCLE_FUZZY_KEY=
export DEJA_CYCLE_FUZZY_BACK_KEY=
export DEJA_TOGGLE_EMPTY_KEY=

# fzf overrides
export FZF_DEFAULT_OPTS='
  --layout=reverse
  --color=fg:#908caa,hl:#ebbcba
	--color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba
	--color=border:#403d52,header:#31748f,gutter:#191724
	--color=spinner:#f6c177,info:#9ccfd8
	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa
'

# editor
export EDITOR="nvim"
export VISUAL="nvim"

# distrobox: /etc/profile.d/distrobox_profile.sh runs `host-spawn` on every
# login shell when this is empty, and host-spawn swallows pending terminal
# input (e.g. the `claude` command workmux sends to new panes). Any non-empty
# value skips that call. Only openSUSE's xauth reads it.
export XAUTHLOCALHOSTNAME="${XAUTHLOCALHOSTNAME:-$HOST}"
