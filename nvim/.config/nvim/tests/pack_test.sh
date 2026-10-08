#!/usr/bin/env bash
# Run: bash tests/pack_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# The pack UI renders a list of plugins into a scratch buffer. vim.pack.get is
# stubbed so the rows are the same every run, and the assertions are on the text
# of every row and on the byte range of every highlight, which is all the UI is.
# The ranges are bytes, so the nerd font icons count for three.
SCRIPT='
local stubs = {
	{ spec = { name = "alpha", version = "1.0.0", src = "https://example.com/alpha" }, rev = "1111111aaaa", path = "/opt/pack/alpha", active = true },
	{ spec = { name = "beta", src = "https://example.com/beta" }, rev = "2222222bbbb", path = "/opt/pack/beta", active = false },
	{ spec = { name = "gamma", version = "2.0.0", src = "https://example.com/gamma" }, rev = "3333333cccc", path = "/opt/pack/gamma", active = true },
}
vim.pack.get = function()
	return vim.deepcopy(stubs)
end
vim.pack.update = function() end
vim.pack.del = function() end

require("config.pack")
vim.o.columns, vim.o.lines = 100, 40
vim.cmd("Pack")

local failures, checks = 0, 0

local function case(name, want, got)
	checks = checks + 1
	if got ~= want then
		failures = failures + 1
		print(("FAIL %s\n got %q\nwant %q"):format(name, tostring(got), tostring(want)))
	end
end

local buf = vim.api.nvim_get_current_buf()
case("the buffer is the pack one", "pack-ui", vim.bo[buf].filetype)

local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
case("a row each for the header, the rule, the bar, both sections and the three plugins", 10, #lines)
case("the header counts them", " vim.pack  3 plugins  (2 loaded, 1 not loaded)", lines[1])
case("the rule spans the window", " " .. ("─"):rep(79), lines[2])
case("the bar names the keys", "  [U] Update All   [u] Update   [D] Delete", lines[3])
case("the loaded section", " Loaded (2)", lines[5])
case("an active plugin with a version", "  ● alpha  1.0.0", lines[6])
case("an active plugin after it", "  ● gamma  2.0.0", lines[7])
case("the unloaded section", " Not Loaded (1)", lines[9])
case("an inactive plugin falls back to its revision", "  ○ beta   2222222", lines[10])

local ns = vim.api.nvim_create_namespace("pack_ui")
local got = {}
for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
	got[#got + 1] = ("%d:%d-%d:%s"):format(m[2], m[3], m[4].end_col, m[4].hl_group)
end
local want = {
	"0:0-46:PackUiHeader", -- the header
	"1:0-238:PackUiSep", -- the rule, three bytes per box character
	"2:2-5:PackUiButton", -- [U]
	"2:19-22:PackUiButton", -- [u]
	"2:32-35:PackUiButton", -- [D]
	"4:0-11:PackUiSection", -- Loaded (2)
	"5:2-5:PackUiLoaded", -- the icon
	"5:6-11:PackUiLoaded", -- the name
	"5:13-18:PackUiVersion", -- the version
	"6:2-5:PackUiLoaded",
	"6:6-11:PackUiLoaded",
	"6:13-18:PackUiVersion",
	"8:0-15:PackUiSection", -- Not Loaded (1)
	"9:2-5:PackUiUnloaded",
	"9:6-10:PackUiUnloaded",
	"9:13-20:PackUiVersion", -- the revision, in place of a version
}
table.sort(want)
table.sort(got)
case("every highlight lands where it should", table.concat(want, " "), table.concat(got, " "))

-- <CR> on a plugin row says where it came from, and <CR> again takes it away
vim.api.nvim_win_set_cursor(0, { 6, 0 })
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
case("the details are three more rows", 13, #lines)
case("the path", "    path : /opt/pack/alpha", lines[7])
case("the source", "    src  : https://example.com/alpha", lines[8])
case("the revision", "    rev  : 1111111aaaa", lines[9])
case("and the next plugin moved down", "  ● gamma  2.0.0", lines[10])

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
case("and <CR> again takes them away", 10, #vim.api.nvim_buf_get_lines(buf, 0, -1, false))

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("q", true, false, true), "x", false)
case("q closes the window and wipes the buffer", "", vim.bo.filetype)

print(("pack checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("pack test failed")
end
print("pack tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
