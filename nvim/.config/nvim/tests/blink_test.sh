#!/usr/bin/env bash
# Run: bash tests/blink_test.sh
#
# blink.cmp, the one plugin in this config that is loaded when a keypress asks
# for it rather than at startup, because its plugin/ file is the largest single
# thing a startup here sources.
#
# The pty is not optional here. A completion menu only exists after keys have
# been typed, and the way to make a headless nvim type is nvim_feedkeys, which
# types into the buffer and then leaves insert mode before a source has produced
# anything: measured, it ends in normal mode with the text mangled and no menu. A
# real terminal delivers the keys one at a time with the UI running, and that is
# the thing being checked.
#
# tests/pty_drive.py is the harness tests/hop_test.sh uses, and it types the keys
# registered at the bottom of this file.
#
# The Lua side is a state machine and not a loop, for a reason that cost a
# wasted run to find: a script loaded with -c owns the main loop until it
# returns, and vim.wait does not pump a UI instance's input, so a -c script that
# waits for "the keys have arrived" waits for nothing at all. The keys sit in
# the pty and are read when the script returns, long after it has given up. So
# the script starts a timer and returns, and the poll runs from the timer, with
# the main loop free to do the reading in between, the way it is for a user.
#
# What it asks of lua/plugins/blink.lua:
#   1. nothing of blink is loaded before insert mode, or the deferral is not
#      deferring anything;
#   2. after one append and five typed letters the plugin is loaded, the menu is
#      up, and the one item a source could have offered is in it. The word is in
#      the buffer and nowhere else, so a menu without it means the sources are
#      not running, not that a matcher is slow.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# The plugins have to be on disk: vim.pack would otherwise go and fetch them, and
# a test that reaches the network is a test that fails on a bad day. So the
# packpath is the machine's own, asked of nvim before XDG_DATA_HOME moves.
data=$(nvim --headless -u NONE -i NONE -c 'lua io.write(vim.fn.stdpath("data"))' -c 'qa!' 2>/dev/null)
if [ -z "$data" ] || [ ! -d "$data/site/pack/core/opt/blink.cmp" ]; then
	echo "blink tests cannot run: no blink.cmp under $data/site/pack/core/opt" >&2
	exit 1
fi

export XDG_CONFIG_HOME="$tmp/conf"
export XDG_STATE_HOME="$tmp/state"
export XDG_RUNTIME_DIR="$tmp/run"
export XDG_CACHE_HOME="$tmp/cache"
# The data directory is the machine's own, and it is the one thing here that
# cannot be isolated. vim.pack decides a plugin is installed by looking for it
# under stdpath("data")/site/pack/core/opt, so a run against an empty data
# directory decides the other thirteen plugins in the lock are missing too, and
# opens a "These plugins will be installed, Proceed?" prompt that swallows every
# key the test types. The lock is the other half of the same decision: without
# an entry for a plugin, installed is false whatever is on disk. So the run
# reads the lock this config is written against and the plugins it names, and
# writes only into the isolated config, state and cache above.
export XDG_DATA_HOME="$(dirname "$data")"
mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_RUNTIME_DIR" "$XDG_CACHE_HOME" "$tmp/buf"
export BLINK_FILE="$tmp/buf/marks.lua"
cp "$repo/nvim-pack-lock.json" "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json"

# The repo is on the runtimepath and the machine's plugins come with the data
# directory. Nothing else from the real config is loaded: this file is about one
# file in lua/plugins, and requiring the whole config here would put 40 modules
# and ten other plugins into what the test is measuring.
cat >"$XDG_CONFIG_HOME/nvim/init.lua" <<LUA
vim.opt.runtimepath:prepend("$repo")
vim.g.mapleader = " "
-- The buffer is typed into, and a swap file left behind by a killed nvim is an
-- ATTENTION prompt in the next one, which is a question a pty cannot answer.
vim.opt.swapfile = false
require("plugins.blink")
LUA

# The word the buffer source is the only thing that can offer. A name no file on
# the machine has, so a path or a snippet source cannot have produced it.
# Not LUA, deliberately: this is a file for nvim to open, not a script to run, and
# the extractor that pulls the Lua out of these test files for the linter takes
# every LUA heredoc as a script. This one is a fragment, ending mid-line on purpose
# so the cursor can be appended to, so it does not parse. A first version of this
# marker was the script one, and the sentence explaining that contained the marker
# itself, which the extractor read as the start of a third heredoc: the extractor
# matches the text, not the shell.
cat >"$BLINK_FILE" <<'BUF'
local zqmarker_thing = 1

local x = 
BUF

cat >"$tmp/drive.lua" <<'LUA'
local uv = vim.uv
local t0 = uv.hrtime()
local report = {}
local function note(s)
	report[#report + 1] = string.format("%6dms %s", (uv.hrtime() - t0) / 1e6, s)
end

-- What the run saw, kept as it is seen and asserted once at the end, so the
-- number of checks does not depend on which poll noticed what first.
local saw = { preloaded = false, typed = false, loaded = false, menu = false, items = {}, labels = {} }

-- The six characters to be typed, announced one per step, because pty_drive.py
-- sends the keys registered under a step name the moment it sees that name.
-- Waiting for the buffer to show each one before announcing the next does not
-- work: the first key is "A", which enters insert mode and changes no text, so
-- there is nothing to wait for. The pace is the harness's own, 0.2s between
-- sends, so the next is announced once that has certainly happened.
local KEYS = { "A", "z", "q", "m", "a", "r" }
local sent = 0
local last_sent = 0
local function announce()
	if sent == 0 then
		sent = 1
		last_sent = uv.hrtime()
		local f = io.open(vim.env.PICKER_STATUS, "a")
		f:write("k1\n")
		f:close()
	end
end

-- How long the poll is given. It is well inside PTY_DEADLINE below, so a run
-- that reaches the end ends by itself rather than by the terminal being cut off
-- mid-report.
local patience = 25000

local function finish()
	local checks, failures = 0, 0
	local function ok(cond, msg)
		checks = checks + 1
		if not cond then
			failures = failures + 1
			report[#report + 1] = "FAIL " .. msg
		end
	end
	ok(not saw.preloaded, "blink.cmp was loaded before anything asked for it")
	ok(saw.typed, "the typed keys never reached the buffer")
	ok(saw.loaded, "blink.cmp was not loaded after insert mode")
	ok(saw.menu, "no completion menu after typing a prefix the buffer contains")
	local found = false
	for _, label in ipairs(saw.labels) do
		if label:find("zqmarker_thing", 1, true) == 1 then
			found = true
		end
	end
	ok(found, "the buffer word is not among the " .. #saw.items .. " items offered: " .. table.concat(saw.labels, " | "):sub(1, 160))

	report[#report + 1] = "blink checks=" .. checks
	report[#report + 1] = "failures=" .. failures
	vim.fn.writefile(report, vim.env.PICKER_RESULT)
	vim.cmd("qa!")
end

local function take_menu()
	if saw.menu or not saw.loaded then
		return false
	end
	local okc, cmp = pcall(require, "blink.cmp")
	if not okc or not cmp.is_visible() then
		return false
	end
	saw.menu = true
	saw.items = require("blink.cmp.completion.list").items or {}
	for _, item in ipairs(saw.items) do
		saw.labels[#saw.labels + 1] = tostring(item.label or "")
	end
	return true
end

local function poll()
	if not saw.typed then
		local line = vim.api.nvim_get_current_line()
		if sent < #KEYS and (uv.hrtime() - last_sent) / 1e6 > 300 then
			sent = sent + 1
			last_sent = uv.hrtime()
			local f = io.open(vim.env.PICKER_STATUS, "a")
			f:write("k" .. sent .. "\n")
			f:close()
		end
		saw.typed = line:find("zqmar", 1, true) ~= nil
		if saw.typed then
			note("keys arrived, mode=" .. vim.fn.mode() .. " line=" .. line)
		end
	end
	if saw.typed and not saw.loaded then
		saw.loaded = package.loaded["blink.cmp"] ~= nil
		if saw.loaded then
			note("blink loaded")
		end
	end
	take_menu()
	if saw.menu then
		note("menu up with " .. #saw.items .. " items")
		finish()
		return
	end
	if (uv.hrtime() - t0) / 1e6 > patience then
		note("gave up, mode=" .. vim.fn.mode() .. " line=" .. vim.api.nvim_get_current_line())
		finish()
		return
	end
	vim.defer_fn(poll, 100)
end

-- After the config has loaded and the terminal is really attached, so the file
-- is open before any key can arrive for it.
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		saw.preloaded = package.loaded["blink.cmp"] ~= nil
		vim.cmd.edit(vim.fn.fnameescape(vim.env.BLINK_FILE))
		vim.api.nvim_win_set_cursor(0, { 3, 0 })
		announce()
		vim.defer_fn(poll, 150)
	end,
})
LUA

# One key per step, not one burst. Sent as a single six byte write the pty run
# ended up with a single character in the buffer and the rest of the burst
# nowhere, which is not a thing a person does to a terminal; sent one at a time
# with the poll in between, every character lands where it was sent.
: >"$tmp/keys"
i=1
for key in A z q m a r; do
	printf 'k%d\t%s\n' "$i" "$(printf '%s' "$key" | xxd -p | tr -d '\n')" >>"$tmp/keys"
	i=$((i + 1))
done

PTY_DEADLINE=45 python3 "$repo/tests/pty_drive.py" "$tmp/keys" "$tmp/blink.status" "$tmp/blink.out" -- \
	nvim -c "luafile $tmp/drive.lua" 2>/dev/null || true

if [ ! -f "$tmp/blink.out" ]; then
	echo "blink tests: the pty run wrote no result" >&2
	exit 1
fi
cat "$tmp/blink.out"
printf 'blink %s %s\n' \
	"$(sed -n 's/^blink checks=/checks=/p' "$tmp/blink.out")" \
	"$(sed -n 's/^failures=/failures=/p' "$tmp/blink.out")"
grep -q '^failures=0$' "$tmp/blink.out"
