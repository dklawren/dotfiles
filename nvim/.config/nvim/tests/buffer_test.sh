#!/usr/bin/env bash
# Run: bash tests/buffer_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# ~/.config/nvim is a symlink into the nix store, so rtp^=$PWD is what makes
# require() pick up the working tree instead of the deployed copy.
SCRIPT='
local M = require("config.buffer")

local function run(desc)
	for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
		if map.desc == desc and map.callback then
			return map.callback()
		end
	end
	error("no mapping with desc: " .. desc)
end

local function tmpfile(name)
	local path = vim.fn.tempname() .. name
	vim.fn.writefile({ "x" }, path)
	return path
end

local function reset()
	vim.cmd("silent! %bwipeout!")
end

-- Listed but never loaded buffers (what a restored session looks like) close
-- when they are to the right of the current buffer in the list.
reset()
vim.cmd("edit " .. tmpfile("current.txt"))
local unloaded = {}
for i = 1, 3 do
	local buf = vim.fn.bufadd(tmpfile("u" .. i .. ".txt"))
	vim.bo[buf].buflisted = true
	unloaded[i] = buf
end
run("Close right buffers")
for _, buf in ipairs(unloaded) do
	assert(not vim.api.nvim_buf_is_valid(buf), "unloaded buffer survived")
end

-- Left closes, current and right survive.
reset()
vim.cmd("edit " .. tmpfile("l.txt"))
local left = vim.api.nvim_get_current_buf()
vim.cmd("edit " .. tmpfile("c.txt"))
local cur = vim.api.nvim_get_current_buf()
vim.cmd("edit " .. tmpfile("r.txt"))
local right = vim.api.nvim_get_current_buf()
vim.cmd("buffer " .. cur)
run("Close left buffers")
assert(not vim.api.nvim_buf_is_valid(left), "left buffer survived")
assert(vim.api.nvim_buf_is_valid(cur), "current buffer was closed")
assert(vim.api.nvim_buf_is_valid(right), "right buffer was closed")

-- Close others leaves exactly the current buffer.
reset()
vim.cmd("edit " .. tmpfile("o1.txt"))
vim.cmd("edit " .. tmpfile("o2.txt"))
vim.cmd("edit " .. tmpfile("o3.txt"))
local keep = vim.api.nvim_get_current_buf()
run("Close other buffers")
local rest = vim.fn.getbufinfo({ buflisted = 1 })
assert(#rest == 1 and rest[1].bufnr == keep, "close others left " .. #rest .. " buffers")

-- Unsaved changes are kept unless the force map is used.
reset()
vim.cmd("edit " .. tmpfile("dirty.txt"))
local dirty = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(dirty, 0, -1, false, { "edited" })
run("Close buffer")
assert(vim.api.nvim_buf_is_valid(dirty), "unsaved buffer was discarded")
M.close({ dirty }, true)
assert(not vim.api.nvim_buf_is_valid(dirty), "force close did not delete")

-- Closing the buffer shown in a split keeps the split.
reset()
vim.cmd("edit " .. tmpfile("s1.txt"))
vim.cmd("split")
vim.cmd("edit " .. tmpfile("s2.txt"))
local wins = #vim.api.nvim_list_wins()
run("Close buffer")
assert(#vim.api.nvim_list_wins() == wins, "window layout changed")

-- A qf buffer closed before the deferred close_with_q keymap ran, which is what
-- a session hop does to a picker preview. The keymap must not be set on it.
require("config.autocmds")
local qf = vim.api.nvim_create_buf(false, true)
local qf_win = vim.api.nvim_open_win(qf, true, { relative = "editor", width = 20, height = 5, row = 0, col = 0 })
vim.bo[qf].filetype = "qf"
vim.api.nvim_win_close(qf_win, true)
vim.api.nvim_buf_delete(qf, { force = true })
assert(not vim.api.nvim_buf_is_valid(qf), "the qf buffer should be gone before the keymap runs")
vim.wait(300, function()
	return false
end)

print("buffer tests passed")
'

# A raise inside vim.schedule is printed, not returned, so the output is the
# only place the deferred keymap failing shows up.
output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1)
printf '%s\n' "$output"
if grep -q "Invalid buffer id" <<<"$output"; then
	printf 'FAIL a keymap was set on a buffer a session hop had closed\n'
	exit 1
fi
