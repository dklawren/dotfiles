#!/usr/bin/env bash
# Run: bash tests/tree_test.sh
#
# <leader>e opens a tree with the file you are editing already revealed, keeps
# the cursor in the editing window, and moves with you while it is open. The
# tree is hand-rolled on vim.fs, so nothing here is a plugin's default: the
# reveal walks the ancestors itself, and the follow is a BufEnter autocmd that
# has to be switched off for the tree's own buffer or every reveal re-renders
# under the cursor.
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

SCRIPT='
vim.g.mapleader = " "

-- config.tree finds devicons at render time, so the plugin has to be on the
-- runtimepath before the tree draws, not before the module loads.
local devicons = vim.fn.stdpath("data") .. "/site/pack/core/opt/nvim-web-devicons"
local has_icons = vim.fn.isdirectory(devicons) == 1
if has_icons then
	vim.opt.rtp:prepend(devicons)
end
require("config.tree")

local api = vim.api
local checks = 0

local function ok(cond, msg)
	assert(cond, msg)
	checks = checks + 1
end

local function tree_win()
	for _, win in ipairs(api.nvim_list_wins()) do
		if vim.bo[api.nvim_win_get_buf(win)].filetype == "tree" then
			return win
		end
	end
	return nil
end

local function lines()
	return api.nvim_buf_get_lines(api.nvim_win_get_buf(tree_win()), 0, -1, false)
end

local function find_line(pattern)
	for i, line in ipairs(lines()) do
		if line:find(pattern, 1, true) then
			return i, line
		end
	end
	return nil
end

local function listed(pattern)
	return find_line(pattern) ~= nil
end

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/a/b/c", "p")
local deep = tmp .. "/a/b/c/deep.lua"
local other = tmp .. "/a/b/other.lua"
vim.fn.writefile({ "return 1" }, deep)
vim.fn.writefile({ "return 2" }, other)
vim.cmd.cd(vim.fn.fnameescape(tmp))
vim.cmd.edit(vim.fn.fnameescape(deep))

local code_win = api.nvim_get_current_win()
vim.api.nvim_feedkeys(vim.keycode("<leader>e"), "x", false)
ok(vim.wait(2000, function() return tree_win() ~= nil end), "<leader>e should open the tree")
ok(api.nvim_get_current_win() == code_win, "<leader>e should leave the cursor in the file window")

-- The reveal has to expand every directory between the root and the file, and
-- put the cursor on the file itself. A tree that opens at the root and stops
-- there lists a/, b/ and c/ with the file hidden behind them.
for _, name in ipairs({ "a/", "b/", "c/", "deep.lua", "other.lua" }) do
	ok(listed(name), "the revealed path should list " .. name .. ", got " .. vim.inspect(lines()))
end
local dl = find_line("deep.lua")
ok(api.nvim_win_get_cursor(tree_win())[1] == dl,
	"the cursor should be on the current file, line " .. tostring(dl) .. " got " .. tostring(api.nvim_win_get_cursor(tree_win())[1]))

-- The icons and the bold current file are extmarks, invisible to a line match,
-- and devicons has to be on the runtimepath at draw time for any of it to show.
if has_icons then
	local function groups(row)
		local ns = api.nvim_create_namespace("config-tree")
		local out = {}
		for _, mark in ipairs(api.nvim_buf_get_extmarks(api.nvim_win_get_buf(tree_win()), ns, { row, 0 }, { row, -1 }, { details = true })) do
			out[#out + 1] = mark[4].hl_group
		end
		return out
	end
	ok(vim.iter(groups(dl - 1)):any(function(g) return g and g:match("^DevIcon") ~= nil end),
		"a file should carry a devicon, got " .. vim.inspect(groups(dl - 1)))
	ok(vim.tbl_contains(groups(dl - 1), "TreeCurrentFile"), "the current file should be marked, got " .. vim.inspect(groups(dl - 1)))
	ok(vim.tbl_contains(groups(find_line("a/") - 1), "Directory"), "a directory should be highlighted as one")
else
	print("nvim-web-devicons not installed, icon checks skipped")
end

vim.cmd.edit(vim.fn.fnameescape(other))
ok(vim.wait(2000, function()
	local l = find_line("other.lua")
	return l ~= nil and api.nvim_win_get_cursor(tree_win())[1] == l
end), "switching buffer should move the tree to that file")

-- h folds the directory under the cursor, the one thing a listing cannot do.
local c = find_line("c/")
ok(c ~= nil and lines()[c]:find("▾", 1, true) ~= nil, "c/ should be open before collapsing it")
api.nvim_set_current_win(tree_win())
api.nvim_win_set_cursor(tree_win(), { c, 0 })
vim.api.nvim_feedkeys("h", "x", false)
ok(not listed("deep.lua"), "h on an open directory should collapse it, got " .. vim.inspect(lines()))
ok(api.nvim_win_get_cursor(tree_win())[1] == find_line("c/"), "h should leave the cursor on the directory it folded")

-- Enter on a file opens it next to the tree and leaves the tree open.
local o = find_line("other.lua")
api.nvim_win_set_cursor(tree_win(), { o, 0 })
vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
ok(api.nvim_get_current_win() ~= tree_win(), "opening a file should leave the tree window")
ok(vim.fs.basename(api.nvim_buf_get_name(0)) == "other.lua", "opening a file should open the one under the cursor")
ok(tree_win() ~= nil, "opening a file should not close the tree")

-- A new file appears in the tree after it is written, without a manual refresh.
vim.cmd.edit(vim.fn.fnameescape(tmp .. "/a/b/fresh.lua"))
ok(not listed("fresh.lua"), "a file that does not exist yet should not be listed")
vim.cmd("silent write")
ok(vim.wait(2000, function() return listed("fresh.lua") end), "writing a file should list it, got " .. vim.inspect(lines()))

vim.api.nvim_feedkeys(vim.keycode("<leader>e"), "x", false)
ok(tree_win() == nil, "a second <leader>e should close the tree")

-- From a directory buffer the tree opens at that directory, which is what
-- <leader>e means inside oil or netrw.
vim.cmd.edit(vim.fn.fnameescape(tmp .. "/a"))
vim.api.nvim_feedkeys(vim.keycode("<leader>e"), "x", false)
ok(tree_win() ~= nil, "<leader>e should open the tree from a directory buffer")
ok(listed("b/") and not listed("deep.lua"), "the tree should start at the directory, got " .. vim.inspect(lines()))

vim.api.nvim_feedkeys(vim.keycode("q"), "x", false)
ok(vim.wait(2000, function() return tree_win() == nil end), "q from the editing window should close the tree")

vim.api.nvim_feedkeys(vim.keycode("qz"), "x", false)
ok(vim.fn.reg_recording() == "z", "q with no tree open should still start a macro")
vim.api.nvim_feedkeys(vim.keycode("q"), "x", false)
ok(vim.fn.reg_recording() == "", "q while recording should stop the macro")

-- A sidebar that lists node_modules is a sidebar nobody opens. git is the one
-- that knows what is ignored, and the tree has to ask before it draws.
vim.fn.delete(tmp, "rf")
vim.fn.mkdir(tmp .. "/secrets", "p")
vim.fn.mkdir(tmp .. "/src", "p")
vim.fn.mkdir(tmp .. "/build", "p")
vim.fn.writefile({ "secrets/", "*.log", "build/" }, tmp .. "/.gitignore")
vim.fn.writefile({ "key" }, tmp .. "/secrets/key.txt")
vim.fn.writefile({ "trace" }, tmp .. "/debug.log")
vim.fn.writefile({ "out" }, tmp .. "/build/out.js")
vim.fn.writefile({ "return 1" }, tmp .. "/src/keep.lua")
vim.fn.system({ "git", "init", "-q", tmp })
vim.cmd.cd(vim.fn.fnameescape(tmp))
vim.cmd.edit(vim.fn.fnameescape(tmp .. "/src/keep.lua"))
vim.api.nvim_feedkeys(vim.keycode("<leader>e"), "x", false)
ok(vim.wait(2000, function() return tree_win() ~= nil end), "<leader>e should open the tree in a git repo")
ok(listed("keep.lua"), "a tracked file should be listed, got " .. vim.inspect(lines()))
ok(not listed("secrets/"), "an ignored directory should be hidden, got " .. vim.inspect(lines()))
ok(not listed("debug.log"), "an ignored file should be hidden, got " .. vim.inspect(lines()))
ok(not listed("build/"), "an ignored build directory should be hidden, got " .. vim.inspect(lines()))
ok(listed(".gitignore"), ".gitignore itself is not ignored and should be listed")

vim.fn.delete(tmp, "rf")
print(("tree tests passed (%d checks)"):format(checks))
'

run_lua "$SCRIPT"
