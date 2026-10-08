#!/usr/bin/env bash
# Run: bash tests/scroll_test.sh
#
# Scrolling a window must not repaint the document in the other half of a split.
#
# The config renders a markdown buffer's visible region itself, so a scroll is an
# event that costs something. The handler used to schedule a render of every
# window's buffer, and rendering a document nobody scrolled is work whose result
# is thrown away. Measured with real scrolls in a real terminal
# (.auto/scroll_pty.sh): 5.95ms a scroll of one line in the code file with a
# document open above it, against 0.74ms when only the scrolled window's buffer is
# rendered, with the document's own scroll unchanged.
#
# It has to be a pty for the same reason completion is. A headless nvim does not
# raise WinScrolled for a programmatic scroll, measured: two real <C-e> scrolls and
# the event count stayed at 0. The alternative is to raise the event by hand with
# :doautocmd, and that is not the same event: a real scroll is delivered for the
# window the cursor is in and names it, and the hand-written one made this config
# skip the render entirely, which reads as a 0.13ms scroll and is a renderer
# switched off. tests/pty_drive.py is the harness tests/blink_test.sh uses, and it
# types <C-e> at a real nvim.
#
# What it asks of lua/config/markdown.lua:
#   1. scrolling the other window does not repaint the document;
#   2. scrolling the document does, so the first check cannot be satisfied by a
#      handler that never renders anything.
#
# How "repainted" is observed, since it took two attempts. Not by the marks: a
# full render produces exactly the same marks. Not by extmark ids either, which
# was the second attempt and does not work, because nvim hands the freed ids
# straight back when the same number of marks is set again in the same order, so a
# cleared and redrawn document looks untouched. What works is counting
# nvim_buf_clear_namespace calls on the document's buffer in the render namespace:
# that is the row of work the optimisation removes, it is a public API call the
# config makes, and it is what a scroll of the other window must not cause.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

python3 .auto/mk_interact_fixtures.py "$tmp"
mkdir -p "$tmp/cfg/nvim"
cat >"$tmp/cfg/nvim/init.lua" <<LUA
vim.opt.runtimepath:prepend("$repo")
require("config.markdown")
LUA

# The key is announced once per scroll and pty_drive.py sends whatever is
# registered under the name it sees, so one line drives the whole run.
printf 'scroll\t%s\n' "$(printf '\05' | xxd -p | tr -d '\n')" >"$tmp/keys"

cat >"$tmp/drive.lua" <<'LUA'
local api = vim.api
local dir = assert(vim.env.SCROLL_DIR)
local ns = api.nvim_create_namespace("md-render")

local checks, failures = 0, 0
local report = {}
local function ok(cond, msg)
	checks = checks + 1
	if not cond then
		failures = failures + 1
		report[#report + 1] = "FAIL " .. msg
	end
end

local md_buf
local clears = 0
local real_clear = api.nvim_buf_clear_namespace
api.nvim_buf_clear_namespace = function(buf, nsp, ...)
	if buf == md_buf and nsp == ns then
		clears = clears + 1
	end
	return real_clear(buf, nsp, ...)
end

-- Both are called from an autocommand defined below them.
local announce, finish

local md_win, code_win
local phase = "other"
local start_clears = 0
local pending = false

announce = function()
	local f = io.open(vim.env.PICKER_STATUS, "a")
	f:write("scroll\n")
	f:close()
end

finish = function()
	report[#report + 1] = "scroll checks=" .. checks
	report[#report + 1] = "failures=" .. failures
	vim.fn.writefile(report, vim.env.PICKER_RESULT)
	vim.cmd("qa!")
end

api.nvim_create_autocmd("WinScrolled", {
	pattern = "*",
	callback = function()
		if pending then
			return
		end
		pending = true
		-- One tick for the render the handler queued, one for this, so the
		-- comparison is made after the paint rather than before it.
		vim.schedule(function()
			vim.schedule(function()
				pending = false
				if phase == "other" then
					ok(
						clears == start_clears,
						"scrolling the code window repainted the document: "
							.. (clears - start_clears)
							.. " clears where there should be none"
					)
					ok(
						api.nvim_win_get_tabpage(md_win) == api.nvim_get_current_tabpage(),
						"the document left the tabpage, so there was nothing to leave alone"
					)
					phase = "doc"
					api.nvim_set_current_win(md_win)
					api.nvim_win_set_cursor(md_win, { 40, 0 })
					vim.cmd("normal! zz")
					vim.defer_fn(function()
						start_clears = clears
						vim.defer_fn(announce, 150)
					end, 150)
				else
					ok(
						clears > start_clears,
						"scrolling the document did not repaint it, so the other check cannot be trusted"
					)
					finish()
				end
			end)
		end)
	end,
})

api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		vim.cmd.edit(vim.fn.fnameescape(dir .. "/doc.md"))
		vim.wo.conceallevel = 2
		vim.cmd("belowright split " .. vim.fn.fnameescape(dir .. "/code.lua"))
		code_win = api.nvim_get_current_win()
		md_win = vim.fn.win_getid(vim.fn.winnr("#"))
		md_buf = api.nvim_win_get_buf(md_win)
		-- The render is scheduled, so the marks are not there the moment the
		-- split exists. Waiting for them is right here: this nvim has a real
		-- input loop, so vim.wait does process the tick the render is on.
		vim.wait(4000, function()
			return #api.nvim_buf_get_extmarks(md_buf, ns, 0, -1, {}) > 0
		end, 20)
		ok(
			#api.nvim_buf_get_extmarks(md_buf, ns, 0, -1, {}) > 0,
			"the document was not rendered, so the checks below are vacuous"
		)
		api.nvim_set_current_win(code_win)
		api.nvim_win_set_cursor(code_win, { 40, 0 })
		vim.defer_fn(function()
			start_clears = clears
			vim.defer_fn(announce, 300)
		end, 300)
	end,
})
LUA

XDG_CONFIG_HOME="$tmp/cfg" SCROLL_DIR="$tmp" \
	PTY_DEADLINE=90 python3 "$repo/tests/pty_drive.py" "$tmp/keys" "$tmp/scroll.status" \
	"$tmp/scroll.out" -- nvim -c "luafile $tmp/drive.lua" 2>/dev/null || true

if [ ! -f "$tmp/scroll.out" ]; then
	echo "scroll tests: the pty run wrote no result" >&2
	exit 1
fi
cat "$tmp/scroll.out"
grep -q '^failures=0$' "$tmp/scroll.out"
