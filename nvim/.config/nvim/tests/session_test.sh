#!/usr/bin/env bash
# Run: bash tests/session_test.sh
# Exercises lua/config/session.lua: a directory's layout is written on the way
# out, put back on the way in, and left alone for a file named on the command
# line. Each nvim gets an empty data dir so the machine's plugins stay out.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="$PWD"
WORK=$(mktemp -d)
STATE="$WORK/state"
DATA="$WORK/data"
CACHE="$WORK/cache"
RUNROOT="$WORK/run"
mkdir -p "$STATE" "$DATA" "$CACHE" "$RUNROOT/nvim-suite/0"
trap 'rm -rf "$WORK"' EXIT

PROJ="$WORK/one-project"
PROJ2="$WORK/two-project"
mkdir -p "$PROJ" "$PROJ2"
printf 'one\nline2\nline3\n' >"$PROJ/one.lua"
printf 'two\n' >"$PROJ/two.lua"
printf 'three\n' >"$PROJ/third.lua"
printf 'x\n' >"$PROJ2/only.lua"

# Scenarios report through this, because `print` from a VimEnter callback in a
# headless nvim never reaches stdout: the messages are still buffered when
# VimEnter quits.
cat >"$WORK/say.lua" <<'LUA'
local path = assert(os.getenv("SESSION_TEST_OUT"))
return function(key, value)
	local f = assert(io.open(path, "a"))
	f:write(key .. "=" .. tostring(value) .. "\n")
	f:close()
end
LUA

cat >"$WORK/scenario.lua" <<'LUA'
local say = dofile(assert(os.getenv("SESSION_TEST_SAY")))
local session = require("config.session")
require("config.tabline")
local function windows()
	local names = vim.tbl_map(function(win)
		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), ":t")
	end, vim.api.nvim_list_wins())
	table.sort(names)
	return table.concat(names, ",")
end

local function tabline_files()
	-- Wide enough that the tabline's width window is not what is under test:
	-- this is about a buffer being rendered at all.
	vim.o.columns = 200
	local line = require("config.tabline").build()
	local found = {}
	for _, name in ipairs({ "one.lua", "two.lua", "third.lua" }) do
		if line:find(name, 1, true) then
			found[#found + 1] = name
		end
	end
	return table.concat(found, ",")
end

local mode = assert(os.getenv("SESSION_TEST_MODE"))

if mode == "layout" then
	-- What a closing nvim looks like: two windows, the right file in each, and
	-- an edit in the second one that has been written.
	vim.cmd("edit one.lua")
	vim.cmd("vsplit two.lua")
	-- Open but not shown: it has to come back on the buffer list.
	vim.cmd("badd third.lua")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "edited" })
	vim.cmd("write")
	say("written", vim.api.nvim_buf_get_lines(0, 0, 1, false)[1])
	-- A project closed up comes back closed up. The global level is set wide
	-- open first, so a window left closed is a state the restore has to bring
	-- back rather than the one it would have anyway.
	vim.o.foldlevel = 99
	local fold_win = vim.fn.win_findbuf(vim.fn.bufnr("one.lua"))[1]
	vim.api.nvim_win_call(fold_win, function()
		vim.wo.foldmethod = "manual"
		vim.cmd("normal! 1,2fold")
		vim.wo.foldlevel = 0
	end)
elseif mode == "enter" then
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			say("wins", #vim.api.nvim_list_wins())
			say("windows", windows())
			local buf = vim.fn.bufnr("two.lua")
			say("content", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
			local fold_win = vim.fn.win_findbuf(vim.fn.bufnr("one.lua"))[1]
			say("fold", vim.wo[fold_win].foldmethod .. "/" .. vim.wo[fold_win].foldlevel)
			say("unshown", vim.fn.bufexists("third.lua") and "yes" or "no")
			say("tabline", tabline_files())
			say("cursor", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") .. ":" .. vim.fn.line("."))
			vim.cmd("qa!")
		end,
	})
elseif mode == "unsaved" then
	-- An unsaved buffer has to come back out of a load still unsaved, or the
	-- load either raises E37 on its `badd` or loses the modified flag.
	vim.cmd("edit one.lua")
	vim.cmd("normal! Gdd")
	say("loaded", session.load(assert(os.getenv("SESSION_TEST_PROJ"))))
	local buf = vim.fn.bufnr("one.lua")
	say("modified", vim.bo[buf].modified)
	say("lines", #vim.api.nvim_buf_get_lines(buf, 0, -1, false))
elseif mode == "empty" then
	session.save()
elseif mode == "delete" then
	say("deleted", session.delete(assert(os.getenv("SESSION_TEST_PROJ"))))
end
LUA

# run <mode> [args...] : one headless nvim in $PROJ against the isolated tree.
# No config and no plugins: the session layer is the only thing under test, and
# an empty data dir would have every run reinstall the machine's plugins.
run() {
	local mode="$1"
	shift
	# The enter scenario quits from its own VimEnter callback, and a `qa!` given
	# as a startup command would quit before that callback ever fires.
	local quit=(-c "qa!")
	if [[ "$mode" == "enter" ]]; then
		quit=()
	fi
	SESSION_TEST_OUT="$OUT" SESSION_TEST_SAY="$WORK/say.lua" SESSION_TEST_MODE="$mode" \
		SESSION_TEST_PROJ="$PROJ" XDG_STATE_HOME="$STATE" XDG_DATA_HOME="$DATA" \
		XDG_CACHE_HOME="$CACHE" XDG_RUNTIME_DIR="$RUNROOT/nvim-suite/0" \
		timeout 120 nvim --headless -u NONE -i NONE --cmd "set rtp^=$REPO" \
		--cmd "cd $PROJ" -c "luafile $WORK/scenario.lua" "${quit[@]}" "$@" >/dev/null 2>&1 || true
}

CHECKS=0
FAILURES=0

# check <name> <expected> <got>
check() {
	CHECKS=$((CHECKS + 1))
	if [[ "$2" != "$3" ]]; then
		FAILURES=$((FAILURES + 1))
		printf 'not ok %d - %s\n  expected: %s\n  got:      %s\n' "$CHECKS" "$1" "$2" "$3"
	else
		printf 'ok %d - %s\n' "$CHECKS" "$1"
	fi
}

# fact <key> : the value the last run reported
fact() {
	sed -n "s/^$1=//p" "$OUT" | tail -1
}

# sessions : the session files written so far
sessions() {
	find "$STATE" -name '*.vim' | wc -l | tr -d ' '
}

# The layout a closing nvim had is what the next nvim opens on, and VimLeavePre
# is the only thing that wrote it.
OUT=$(mktemp)
run layout
check "one session file is written on the way out" "1" "$(sessions)"
check "the edit was written to disk" "edited" "$(fact written)"

OUT=$(mktemp)
run enter
check "both windows come back" "2" "$(fact wins)"
check "the files come back" "one.lua,two.lua" "$(fact windows)"
check "the buffer contents come back" "edited" "$(fact content)"
check "the fold state comes back" "manual/0" "$(fact fold)"
check "a buffer that was open but not shown comes back" "yes" "$(fact unshown)"
check "and the tabline shows every file from the session" "one.lua,two.lua,third.lua" "$(fact tabline)"
check "the cursor comes back" "two.lua:1" "$(fact cursor)"

OUT=$(mktemp)
run unsaved
check "a load accepts an unsaved buffer" "true" "$(fact loaded)"
check "an unsaved buffer is still unsaved after a load" "true" "$(fact modified)"
check "the unsaved edit is still there" "2" "$(fact lines)"

# A named file is the layout the user asked for, and the run behind it leaves
# its own layout behind on the way out, which is why it comes after the checks
# that want the session written above.
OUT=$(mktemp)
run enter "$PROJ2/only.lua"
check "a file named on the command line wins over the session" "1" "$(fact wins)"
check "and it is the one that is open" "only.lua" "$(fact windows)"

OUT=$(mktemp)
run empty
check "an empty nvim does not overwrite a session" "1" "$(sessions)"

OUT=$(mktemp)
run delete
check "a session can be thrown away" "true" "$(fact deleted)"
check "throwing it away removed the file" "0" "$(sessions)"

printf 'session checks=%d failures=%d\n' "$CHECKS" "$FAILURES"
[[ "$FAILURES" -eq 0 ]]