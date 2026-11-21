# Shared by the suites: run a Lua script in a headless nvim and fail the suite
# when nvim reports a Lua error. `nvim -c lua` exits 0 on a Lua error, so a
# suite that only ran the command reports a pass for a config module that
# throws on first use. Source it, then call run_lua "$SCRIPT" [extra args].
#
# Source with `. "$(dirname "$0")/lib.sh"`.
#
# run_lua <script> [nvim args...]: a bare nvim, for a check about one module.
# run_lua_full <script> [nvim args...]: this config loaded, for a check about
# what the config ends up doing.
#
# repo_config_home <dir>: a config home that holds this tree as "nvim".
# Neovim reads its config from $XDG_CONFIG_HOME/nvim, and the installed one is
# a snapshot of an older build, so a suite that starts nvim with this config
# proves nothing about the tree it is testing.
repo_config_home() {
	local home="$1"
	mkdir -p "$home"
	ln -sfn "$PWD" "$home/nvim"
	printf '%s' "$home"
}

run_lua() {
	local script=$1
	shift
	_run nvim --headless -u NONE -i NONE "$@" -c "lua $script" -c 'qa!'
}

run_lua_full() {
	local script=$1
	shift
	local home
	home=$(mktemp -d)
	XDG_CONFIG_HOME="$(repo_config_home "$home")" _run nvim --headless -u "$PWD/init.lua" -i NONE "$@" -c "lua $script" -c 'qa!'
	rm -rf "$home"
}

_run() {
	local output status
	output=$("$@" 2>&1)
	status=$?
	printf '%s\n' "$output"
	if [[ $status -ne 0 || "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
		echo "FAIL nvim reported an error, so this suite proved nothing"
		exit 1
	fi
}
