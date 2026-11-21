#!/usr/bin/env bash
# Run: bash tests/toggles_test.sh
# Every toggle under <leader>u that is a plain option: pressed twice it has to
# land back on the value it started from, and never raise. A `set opt!` on a
# number option raises E488 instead of toggling, which is invisible until the
# key is pressed.
set -euo pipefail
cd "$(dirname "$0")/.."

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

-- Press a mapping once, whether it is a callback or a <cmd>...</cmd> string.
local function press(lhs)
	local m = vim.fn.maparg(lhs, "n", false, true)
	if type(m.callback) == "function" then
		return pcall(m.callback)
	end
	local cmd = (m.rhs or ""):lower():match("<cmd>(.-)<cr>")
	if not cmd then
		return false, lhs .. " is neither a callback nor a <cmd> command: " .. tostring(m.rhs)
	end
	return pcall(vim.cmd, cmd)
end

-- A list, not a map: the pairing is what the check compares.
local pairs = {
	{ "<leader>uw", "wrap" },
	{ "<leader>uL", "relativenumber" },
	{ "<leader>ul", "number" },
	{ "<leader>us", "spell" },
	{ "<leader>uA", "showtabline" },
}

for _, pair in ipairs(pairs) do
	local lhs, opt = pair[1], pair[2]
	local start = vim.o[opt]
	local ok, err = press(lhs)
	check(ok, lhs .. " raised: " .. tostring(err))
	check(vim.o[opt] ~= start, lhs .. " did not change " .. opt .. " from " .. tostring(start))
	ok, err = press(lhs)
	check(ok, lhs .. " raised on the second press: " .. tostring(err))
	check(vim.o[opt] == start, lhs .. " left " .. opt .. " at " .. tostring(vim.o[opt]))
end

-- Conceal is a window option, 0 or 2.
local before = vim.wo.conceallevel
local ok = press("<leader>uc")
check(ok, "conceal raised")
check(vim.wo.conceallevel == 2, "conceal did not turn on, got " .. vim.wo.conceallevel)
press("<leader>uc")
check(vim.wo.conceallevel == before, "conceal did not come back, got " .. vim.wo.conceallevel)

print(("toggle checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	vim.cmd("cq")
end
'

nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1 | grep -v '^$'
