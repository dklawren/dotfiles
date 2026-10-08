#!/usr/bin/env bash
# Run: bash tests/statusline_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# The statusline is a string built on every redraw, so the only way to know it
# still says what it used to is to build it and read it. Assertions are on
# fragments, not the whole line: the mode, the percentage and the window width
# depend on where the cursor is.
SCRIPT='
local SL = require("config.statusline")

local failures, checks = 0, 0

local function case(name, want, got)
	checks = checks + 1
	if got ~= want then
		failures = failures + 1
		print(("FAIL %s\n got %s\nwant %s"):format(name, vim.inspect(got):gsub("%s+", " "), vim.inspect(want):gsub("%s+", " ")))
	end
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")

---Open a file with filetype ft, let the word count settle, and return the line.
local function line_for(name, text, ft)
	local path = dir .. "/" .. name
	vim.fn.writefile(text, path)
	vim.cmd("edit! " .. vim.fn.fnameescape(path))
	vim.bo.filetype = ft
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = 0 })
	vim.wait(600)
	return SL.build()
end

local words = { "one two three", "four five" }
local many = {}
for i = 1, 400 do
	many[i] = ("word%03d"):format(i)
end

-- A word count, and only for the buffers that get one
case("a lua buffer has no word count", nil, line_for("a.lua", words, "lua"):match("%d+w  %d+m"))
case("a markdown buffer has one", true, line_for("a.md", words, "markdown"):match("%d+w  %d+m") ~= nil)
case("an mdx buffer has one", true, line_for("a.mdx", words, "markdown.mdx"):match("%d+w  %d+m") ~= nil)
case("a text buffer has one", true, line_for("a.txt", words, "text"):match("%d+w  %d+m") ~= nil)
-- 400 words read as two minutes at 200 words a minute
case("the count is the real one", "400w  2m", line_for("b.md", many, "markdown"):match("%d+w  %d+m"))

-- Mode, file, filetype, and the items nvim expands when it draws rather than
-- when the string is built: the position and the percentage are still %l %c %p
-- here, and a screenshot is what proves those.
local line = line_for("c.lua", { "local a = 1" }, "lua")
case("the mode is in the line", true, line:find("%%#StatusMode# %S+ NORMAL %%#StatusModeToNorm#") ~= nil)
case(
	"the file is in the line, relative to the cwd",
	true,
	line:find("%%#StatusFile# " .. vim.pesc(vim.fn.fnamemodify(vim.fn.expand("%:."), ":.")) .. " ") ~= nil
)
case("the filetype is in the line", true, line:find("%%#StatusType# %S*lua%%#StatusTypeToNorm#") ~= nil)
case("the encoding and format are in the line", true, line:find("utf%-8 unix") ~= nil)
case("the position is left for nvim to fill", true, line:find("%%l:%%c ") ~= nil)
case("the percentage is left for nvim to fill", true, line:find("%%#StatusPercent# %%p%%%% $") ~= nil)

-- Git: branch, repo name and the counts
vim.b.gitsigns_head = "main"
vim.b.gitsigns_status_dict = { root = dir .. "/repo", added = 3, changed = 0, removed = 12 }
line = SL.build()
case("the branch is in the line", true, line:find("repo/main") ~= nil)
case("the added count is drawn", true, line:find(" 3 ") ~= nil)
case("the removed count is drawn", true, line:find(" 12 ") ~= nil)
case("a zero count is left out", false, line:find(" 0 ") ~= nil)
vim.b.gitsigns_head = nil
vim.b.gitsigns_status_dict = nil
case("no git, no branch", false, SL.build():find("repo/main") ~= nil)

-- Diagnostics: one count per severity that has any
local sev = vim.diagnostic.severity
vim.diagnostic.set(vim.api.nvim_create_namespace("probe"), 0, {
	{ lnum = 0, col = 0, message = "one", severity = sev.ERROR },
	{ lnum = 0, col = 0, message = "two", severity = sev.ERROR },
	{ lnum = 0, col = 0, message = "three", severity = sev.WARN },
})
vim.api.nvim_exec_autocmds("DiagnosticChanged", { buffer = 0 })
line = SL.build()
case("the errors are counted", true, line:find("%%#StatusErrorIcon#%S+ 2 ") ~= nil)
case("the warning is counted", true, line:find("%%#StatusWarnIcon#%S+ 1 ") ~= nil)
case("an info count is left out", false, line:find("StatusInfoIcon") ~= nil)
case("the diagnostic fragment resets the colour", true, line:find("%%#StatusLine# %%#StatusLSPToNorm#") ~= nil)

print(("statusline checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("statusline test failed")
end
print("statusline tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
