#!/usr/bin/env bash
# Run: bash tests/tabline_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

# The tabline is one string built on every redraw from the buffer list, and it
# is cached under a key made of that list. Both halves are testable: what the
# line says about a set of buffers, and that a rename is not served from the
# cache. It runs through the real config, because the icon comes from a plugin.
SCRIPT='
local failures, checks = 0, 0
local function check(ok, msg)
	checks = checks + 1
	if not ok then
		failures = failures + 1
		print("FAIL: " .. msg)
	end
end
local function case(name, want, got)
	checks = checks + 1
	if want ~= got then
		failures = failures + 1
		print(("FAIL %s\n  want: %s\n  got : %s"):format(name, vim.inspect(want), vim.inspect(got)))
	end
end
local function plain(s)
	return (s:gsub("%%#[^#]*#", ""))
end
local function width(s)
	return vim.api.nvim_strwidth((plain(s):gsub("%%%%", "%%")))
end

local TL = require("config.tabline")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")

-- One buffer of each kind: listed, unlisted, and the one on screen.
local shown = vim.fn.bufadd(dir .. "/shown.lua")
vim.bo[shown].buflisted = true
local hidden = vim.fn.bufadd(dir .. "/hidden.lua")
vim.bo[hidden].buflisted = false
vim.cmd("buffer " .. shown)
local line = TL.build()
case("a listed buffer is in the line", true, plain(line):find("shown.lua", 1, true) ~= nil)
case("an unlisted one is not", false, plain(line):find("hidden.lua", 1, true) ~= nil)
case("the buffer on screen is highlighted as the active one", true, line:find("%#MyBufActive#", 1, true) ~= nil)

-- The icon belongs to the name, so it comes and goes with it.
local icon_span = plain(line):sub(0, plain(line):find("shown.lua", 1, true) - 1)
case("a buffer gets an icon from the name", true, vim.api.nvim_strwidth(icon_span) > 0)

-- A % in a name is a statusline item unless it is doubled, and a file called
-- 100%.md is a file someone has.
local pct = vim.fn.bufadd(dir .. "/100%.md")
vim.bo[pct].buflisted = true
vim.cmd("buffer " .. pct)
line = TL.build()
case("a percent in a name is doubled", true, plain(line):find("100%%", 1, true) ~= nil)
case("and the line still names the file", true, (plain(line):gsub("%%%%", "%%")):find("100%.md", 1, true) ~= nil)

-- A rename redraws: the cache key holds the buffer numbers, not the names.
vim.cmd("file " .. vim.fn.fnameescape(dir .. "/renamed.md"))
case("a renamed buffer shows its new name", true, plain(TL.build()):find("renamed.md", 1, true) ~= nil)

-- Twice in a row with nothing changed is the same line, so a redraw does not
-- rebuild what it already has.
local first = TL.build()
case("a redraw with nothing changed is the same line", first, TL.build())

-- More buffers than columns: the active one stays, and the line still fits.
for i = 1, 40 do
	local buf = vim.fn.bufadd(dir .. ("/a-long-name-number-%02d.lua"):format(i))
	vim.bo[buf].buflisted = true
end
local last = vim.fn.bufnr(dir .. "/a-long-name-number-20.lua")
vim.cmd("buffer " .. last)
line = TL.build()
case("the active buffer survives the overflow", true, plain(line):find("number-20", 1, true) ~= nil)
case("the line fits the screen", true, width(line) <= vim.o.columns)
case("and the hidden buffers are counted", true, (line:find("«", 1, true) ~= nil) or (line:find("»", 1, true) ~= nil))

print(("tabline checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("tabline test failed")
end
print("tabline tests passed")
'

run_lua_full "$SCRIPT"
