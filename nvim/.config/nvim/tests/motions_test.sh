#!/usr/bin/env bash
# Run: bash tests/motions_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

SCRIPT='
require("config.keymaps")

local checks, failures = 0, 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then
		failures = failures + 1
		print("FAIL " .. msg)
	end
end

local function mapped(lhs)
	local m = vim.fn.maparg(lhs, "n", false, true)
	return m.lhs ~= nil and m.lhs ~= ""
end

local path = vim.fn.tempname() .. ".txt"
vim.fn.writefile({ "    indented", "second line here", "third" }, path)
vim.cmd.edit(vim.fn.fnameescape(path))

-- gh and gl are a pair: first non-blank and end of line, on a line that starts
-- with spaces, so a plain 0 or $ would give a different column.
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys("gh", "x", false)
check(vim.fn.col(".") == 5, "gh goes to the first non-blank, col " .. vim.fn.col("."))
vim.api.nvim_feedkeys("gl", "x", false)
check(vim.fn.col(".") == 12, "gl goes to the end of the line, col " .. vim.fn.col("."))

check(mapped("=="), "== selects the whole buffer")
check(mapped("<esc>"), "escape clears the search highlight")

-- A move at either end of the buffer is a no-op. It used to raise E16 on every
-- <A-j> at the bottom of a file, which is where the last move ends up.
local function errmsg(keys)
	vim.v.errmsg = ""
	vim.api.nvim_feedkeys(vim.keycode(keys), "x", false)
	vim.wait(50)
	return (vim.v.errmsg:gsub("\n.*", ""))
end
local function lines()
	return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ",")
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three" })
vim.cmd("normal! G")
check(errmsg("<A-j>") == "", "<A-j> on the last line does nothing, got " .. vim.inspect(errmsg("<A-j>")))
check(lines() == "one,two,three", "and leaves the buffer alone, got " .. lines())
vim.cmd("normal! gg")
check(errmsg("<A-k>") == "", "<A-k> on the first line does nothing, got " .. vim.inspect(errmsg("<A-k>")))

vim.cmd("normal! gg")
errmsg("<A-j>")
check(lines() == "two,one,three", "<A-j> in the middle moves the line down, got " .. lines())
check(vim.fn.line(".") == 2, "and the cursor follows it, line " .. vim.fn.line("."))
vim.cmd("normal! G")
errmsg("<A-k>")
check(lines() == "two,three,one", "<A-k> in the middle moves the line up, got " .. lines())

vim.cmd("normal! GV")
check(errmsg("<A-j>") == "", "a visual move on the last line does nothing")
check(lines() == "two,three,one", "and leaves the selection where it was, got " .. lines())

-- the pair has to be able to disappear one key at a time, which is how gh went
-- missing before: gl stayed and nothing said gh was gone.
for _, key in ipairs({ "gh", "gl" }) do
	check(mapped(key), key .. " is mapped")
end

print(("motion checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("motion test failed")
end
print("motion tests passed")
'

run_lua "$SCRIPT"
