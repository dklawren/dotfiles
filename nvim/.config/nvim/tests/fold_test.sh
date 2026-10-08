#!/usr/bin/env bash
# Run: bash tests/fold_test.sh
#
# Folds and indentation, as the config actually configures them.
#
# This exists because foldexpr and indentexpr are the two options in this config
# that get evaluated once per line, which makes them the most expensive thing in
# the config per keystroke, and because the fast way to set them (a function
# reference rather than a v:lua string) is invisible in a screenshot. A change
# that makes them cheaper and quietly stops folding looks exactly like a win.
# So the checks are about what the options do, not about how they are written:
# the level has to be right, a fold has to close and reopen, and = has to
# re-indent. The speed is measured in .auto/open_bench.sh, not here.
set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPT='
-- -u NONE does not turn filetype detection on, and this test is about what the
-- config does once a buffer has a filetype, so detection is enabled here rather
-- than the filetype being set by hand as markdown_test.sh does.
vim.cmd("filetype plugin indent on")
require("plugins.treesitter")

local api = vim.api
local checks = 0

local function ok(cond, msg)
	assert(cond, msg)
	checks = checks + 1
end

-- Nested Lua, so there is something to fold. A file of one-liners has no folds
-- and every fold assertion passes vacuously, which is how this check would have
-- been worthless.
local nested = {}
for i = 1, 50 do
	nested[#nested + 1] = ("local function outer%d(a, b)"):format(i)
	nested[#nested + 1] = "\tif a then"
	nested[#nested + 1] = "\t\tif b then"
	nested[#nested + 1] = "\t\t\treturn a + b"
	nested[#nested + 1] = "\t\tend"
	nested[#nested + 1] = "\tend"
	nested[#nested + 1] = "end"
end

local path = vim.fn.tempname() .. ".lua"
vim.fn.writefile(nested, path)
vim.bo.swapfile = false
vim.cmd.edit(vim.fn.fnameescape(path))
ok(vim.bo.filetype == "lua", "expected filetype lua, got " .. vim.bo.filetype)

-- The level has to grow with nesting. This is the assertion that fails first if
-- foldexpr stops being treesitter, whether it is unset, set to a v:lua string
-- that does not resolve, or set to a stale function.
-- Who provides these two options, checked as well as what they produce.
--
-- foldexpr and indentexpr are evaluated once per line, and the v:lua string form
-- costs a string parse and a global lookup on every one of those calls, which is
-- most of the cost of opening a file. The function form that the runtime
-- documents costs neither. Asserting the representation is normally the wrong
-- thing to do in a behaviour test, and it is the right thing here because the
-- representation is the optimisation, and because a v:lua string and a function
-- are indistinguishable from the outside: both produce the same levels and the
-- same indentation.
--
-- The indent one matters for a second reason. With no indentexpr set, nvim falls
-- back to its own GetLuaIndent(), which for Lua happens to produce the same
-- tabs, so every indentation check below passes with treesitter switched off
-- entirely. Only naming the provider catches that.
ok(type(vim.wo.foldexpr) == "function",
	"foldexpr should be a function reference, not a string, so nvim calls it directly; got "
		.. type(vim.wo.foldexpr) .. " " .. tostring(vim.wo.foldexpr):sub(1, 40))
ok(type(vim.bo.indentexpr) == "function",
	"indentexpr should be a function reference, not a string; got "
		.. type(vim.bo.indentexpr) .. " " .. tostring(vim.bo.indentexpr):sub(1, 40))
ok(vim.bo.indentexpr ~= "GetLuaIndent()",
	"indentexpr fell back to the nvim builtin, so indentation is no longer coming from treesitter")
ok(vim.wo.foldmethod == "expr", "foldmethod should be expr, got " .. vim.wo.foldmethod)

local l1, l2, l3, l4 = vim.fn.foldlevel(1), vim.fn.foldlevel(2), vim.fn.foldlevel(3), vim.fn.foldlevel(4)
ok(l1 > 0, "line 1 should be inside a fold, got level " .. l1)
ok(l2 > l1, ("level should deepen into the first if: %d then %d"):format(l1, l2))
ok(l3 > l2, ("level should deepen into the second if: %d then %d"):format(l2, l3))
ok(l4 == l3, "return is at the same depth as its if, got " .. l4 .. " vs " .. l3)

-- A fold that cannot be closed is not a fold.
--
-- foldlevel, not zE: with foldmethod=expr nvim refuses zE and zM, because which
-- folds exist is up to the expression. foldlevel is how many levels are
-- open, and it is the only lever a test has over the starting state. The config
-- sets foldlevel=99 globally, so without setting it here the test would inherit
-- a default and could not tell an unclosed fold from a fold that was never
-- there.
vim.wo.foldlevel = 99
vim.fn.cursor(3, 1)
ok(vim.fn.foldclosed(3) == -1, "foldlevel 99 should leave line 3 open, foldclosed said " .. vim.fn.foldclosed(3))

vim.cmd("normal! zc")
ok(vim.fn.foldclosed(3) == 3, "zc should close the fold that starts at line 3, foldclosed said " .. vim.fn.foldclosed(3))
ok(vim.fn.foldlevel(3) == l3, "closing changed the level: " .. l3 .. " then " .. vim.fn.foldlevel(3))

vim.cmd("normal! zo")
ok(vim.fn.foldclosed(3) == -1, "zo should reopen it, foldclosed said " .. vim.fn.foldclosed(3))

-- foldlevel 0 closes everything, and the outermost fold is the one that reports.
vim.wo.foldlevel = 0
ok(vim.fn.foldclosed(3) == 1, "foldlevel 0 should close the outermost fold, foldclosed said " .. vim.fn.foldclosed(3))
vim.wo.foldlevel = 99

-- Every one of the 50 blocks, not just the first, so a fold table that is only
-- filled for the visible region is caught.
vim.fn.cursor(298, 1)
local deep = vim.fn.foldlevel(298)
ok(deep > 0, "a block far down the file should still fold, got " .. deep)

-- = has to re-indent through treesitter, which is the other per-line option.
local bad = vim.fn.tempname() .. "_i.lua"
vim.fn.writefile({
	"local function g(a)",
	"if a then",
	"if a then",
	"return 1",
	"end",
	"end",
	"end",
}, bad)
vim.cmd.edit(vim.fn.fnameescape(bad))
api.nvim_buf_set_lines(0, 0, -1, false, {
	"local function g(a)",
	"if a then",
	"if a then",
	"return 1",
	"end",
	"end",
	"end",
})
vim.cmd("normal! gg=G")
local out = api.nvim_buf_get_lines(0, 0, -1, false)
ok(out[2] == "\tif a then", "the first if should be indented one level, got " .. vim.inspect(out[2]))
ok(out[3] == "\t\tif a then", "the second if should be indented two, got " .. vim.inspect(out[3]))
ok(out[4] == "\t\t\treturn 1", "return should be indented three, got " .. vim.inspect(out[4]))
vim.fn.delete(bad)

-- A filetype with no treesitter parser is the interesting failure, not a rare
-- one: .txt is detected as "text", treesitter.start() has no parser for it and
-- raises, the config wraps that in a pcall, and the buffer must end up with no
-- foldexpr and no error rather than a foldexpr that calls into nothing.
local txt = vim.fn.tempname() .. ".txt"
vim.fn.writefile({ "plain", "text", "no folding here", "and no structure" }, txt)
local okopen, openerr = pcall(vim.cmd.edit, vim.fn.fnameescape(txt))
ok(okopen, "opening a filetype with no parser should not error: " .. tostring(openerr))
ok(vim.bo.filetype == "text", "expected text, got " .. vim.bo.filetype)
ok(vim.fn.foldlevel(1) == 0, "a file with no fold structure should be level 0, got " .. vim.fn.foldlevel(1))
ok(vim.fn.foldlevel(2) == 0, "and level 0 on line 2 as well, got " .. vim.fn.foldlevel(2))

-- A brand new empty buffer has no filetype at all, which is the one entry the
-- config skips by name. It must not pick up a foldexpr from a previous buffer.
vim.cmd("enew")
ok(vim.bo.filetype == "", "a new buffer should have no filetype, got " .. vim.bo.filetype)
local lvl = vim.fn.foldlevel(1)
ok(lvl == 0, "an empty buffer should be level 0, got " .. lvl)
vim.fn.delete(txt)

-- And the buffer from before is still intact and still folds, because the fold
-- table is per buffer and a second buffer must not have disturbed it.
vim.cmd.edit(vim.fn.fnameescape(path))
ok(vim.fn.foldlevel(3) == l3, ("returning to the first buffer changed its fold level: %d then %d"):format(l3, vim.fn.foldlevel(3)))
vim.fn.delete(path)

print(("fold tests passed (%d checks)"):format(checks))
'

nvim --headless -u NONE -i NONE -c "lua $SCRIPT" -c 'qa!'
