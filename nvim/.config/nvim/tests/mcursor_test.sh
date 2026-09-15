#!/usr/bin/env bash
# Run: bash tests/mcursor_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# The config module only needs the nvim.multicursor namespace to be empty or
# populated, so this exercises the real align() on any nvim, with or without
# native multicursor. Synthetic extmarks stand in for cursors.
SCRIPT='
local M = require("config.mcursor")
local NS = vim.api.nvim_create_namespace("nvim.multicursor")

local function lines(...)
	local t = vim.fn.range(1, select("#", ...))
	for i = 1, select("#", ...) do
		t[i] = select(i, ...)
	end
	vim.api.nvim_buf_set_lines(0, 0, -1, false, t)
end

local function cursor(row, col)
	vim.api.nvim_buf_set_extmark(0, NS, row, col, {})
end

local function expect_lines(want)
	local got = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i, l in ipairs(want) do
		assert(got[i] == l, ("line %d:\n got %q\nwant %q"):format(i, got[i], l))
	end
end

-- Ragged cursors align to a shared column; nothing moves left.
lines("ab;", "abc;")
cursor(0, 2)
cursor(1, 3)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
M.align()
expect_lines({ "ab ;", "abc;" })
assert(vim.api.nvim_win_get_cursor(0)[2] == 0)

-- The primary cursor keeps its column when its line gets padded.
lines("ab;", "abc;")
cursor(0, 2)
cursor(1, 3)
vim.api.nvim_win_set_cursor(0, { 2, 3 })
M.align()
expect_lines({ "ab ;", "abc;" })
assert(vim.api.nvim_win_get_cursor(0)[2] == 3)

-- No cursors, no crash.
lines("untouched")
vim.api.nvim_win_set_cursor(0, { 1, 0 })
M.align()
expect_lines({ "untouched" })

print("mcursor tests passed")
'

nvim --headless -u NONE -i NONE -c "lua $SCRIPT" -c 'qa!'
