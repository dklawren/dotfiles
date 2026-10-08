#!/usr/bin/env bash
# Run: bash tests/cloak_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Cloaking hides a value on screen and never touches the file, so what a test
# can check is the span it covers: which files it applies to at all, and where on
# the line the mask starts and how wide it is. The spans below are what the
# patterns produce today. On the "key = value" shape the env pattern starts one
# column left, on the space, because the \zs sits after an optional atom; on
# "key=value" it starts on the value. Both cover the value, and the extra column
# is a space, so it is recorded rather than fixed.
SCRIPT='
-- Nothing is loaded under -u NONE, and the masks are drawn by the module own
-- autocmds, so it is required here the way the statusline suite requires its
-- module.
require("config.cloak")

local ns = vim.api.nvim_create_namespace("cloak")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")

local failures, checks = 0, 0

local function case(name, want, got)
	checks = checks + 1
	if got ~= want then
		failures = failures + 1
		print(("FAIL %s\n got %s\nwant %s"):format(name, vim.inspect(got):gsub("%s+", " "), vim.inspect(want):gsub("%s+", " ")))
	end
end

---The mask on every row of a file with this name, as "row:col+width" strings.
---@param name string
---@param lines string[]
---@return string
local function masked(name, lines)
	local path = dir .. "/" .. name
	vim.fn.writefile(lines, path)
	vim.cmd("edit! " .. vim.fn.fnameescape(path))
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	vim.api.nvim_exec_autocmds("BufReadPost", { buffer = 0 })
	local out = {}
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
		local text = m[4].virt_text and m[4].virt_text[1][1] or ""
		out[#out + 1] = ("%d:%d+%d"):format(m[2], m[3], #text)
	end
	table.sort(out)
	return table.concat(out, " ")
end

local plain = { "plain line" }
case("an env file masks the value", "0:9+8 2:9+7", masked("app.env", { "api_key = secret1", "plain line", "PASSWORD=secret3" }))
-- The env pattern is an "=" and everything after it, so a line without one is
-- not masked whatever else it holds.
case("a vars file masks after an =", "0:7+8", masked("app.vars", { "token = secret1", "plain line" }))
case("a vars file leaves a line without one alone", "", masked("app.vars", { "token: secret1", "plain line" }))
case("a tfvars file masks the value", "0:9+8", masked("app.tfvars", { "api_key = secret1", "plain line" }))
case("a quoted json value is masked", "0:13+7", masked("data.json", { [[{ "apiKey": "secret1", "x": 1 }]], "plain line" }))
case("a fish set line is masked", "0:16+7", masked("secrets.fish", { "set -gx API_KEY secret1", "plain line" }))
case("a toml value is masked", "0:10+9", masked("cfg.toml", { [[api_key = "secret1"]], "plain line" }))
case("a yaml value is masked", "0:9+12", masked("cfg.yaml", { "api_key: secret1value", "plain line" }))
case("a file with no secret in it is untouched", "", masked("notes.md", { "api_key = secret1", "plain line" }))

-- The spans say where the mask starts; this says what it is made of
masked("app.env", { "api_key = secret1" })
local all_stars = true
for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
	local text = m[4].virt_text and m[4].virt_text[1][1] or ""
	if not text:match("^%*+$") then
		all_stars = false
	end
end
case("the mask is asterisks", true, all_stars)

-- The toggle takes the masks away and puts them back
masked("app.env", { "api_key = secret1" })
local toggled = false
for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
	if m.desc == "Toggle Cloak" then
		m.callback()
		toggled = true
	end
end
checks = checks + 1
if not toggled then
	failures = failures + 1
	print("FAIL there is no toggle key")
else
	local off = #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
	for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
		if m.desc == "Toggle Cloak" then
			m.callback()
		end
	end
	local on = #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
	case("the toggle takes the masks away", 0, off)
	case("and puts them back", 1, on)
end

print(("cloak checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("cloak test failed")
end
print("cloak tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
