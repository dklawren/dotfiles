#!/usr/bin/env bash
# Run: bash tests/yank_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export XDG_CONFIG_HOME="$(repo_config_home "$TMP/conf")"

# Pasting over a selection with p replaces the unnamed register with the replaced
# text, so the thing just yanked cannot be pasted again. P keeps it. The keys go
# through the mappings, since that is what a finger presses.
SCRIPT='
local failures, checks = 0, 0
local UNNAMED = string.char(34)
-- The unnamed register syncs to the system clipboard when 'clipboard' says so,
-- and the paste under test is about the register, not about the clipboard.
vim.opt.clipboard = ""

local function case(name, want, got)
	checks = checks + 1
	if got ~= want then
		failures = failures + 1
		print(("FAIL %s\n got %s\nwant %s"):format(name, vim.inspect(got), vim.inspect(want)))
	end
end

local function setup()
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha", "beta", "gamma" })
	vim.cmd("normal! 2Gyy")
end

---@param keys string
local function feed(keys)
	-- :normal (no bang) runs the mappings and finishes before returning, so the
	-- next read is not taken mid-mapping.
	vim.cmd("normal " .. keys)
end

local function register()
	return table.concat(vim.fn.getreg(UNNAMED, 1, true), "|")
end

setup()
feed("1GVjp")
case("a visual paste replaces the selection", "beta|gamma", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "|"))

setup()
feed("1GVjP")
case("a kept visual paste writes the same text", "beta|gamma", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "|"))
case("and the yank survives", "beta", register())

print(("yank checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("yank test failed")
end
print("yank tests passed")
'

output=$(nvim --headless -u "$PWD/init.lua" -i NONE -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
