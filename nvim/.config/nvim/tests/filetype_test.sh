#!/usr/bin/env bash
# Run: bash tests/filetype_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# config/autocmds.lua is a set of FileType handlers, and what they do to a buffer
# is invisible everywhere else: an option is set, a panel is unlisted, a key
# closes it. Each case here is one handler, on a buffer that asks for that
# filetype the way a file open would.
SCRIPT='
require("config.autocmds")

local failures, checks = 0, 0

local function case(name, want, got)
	checks = checks + 1
	if got ~= want then
		failures = failures + 1
		print(("FAIL %s\n got %s\nwant %s"):format(name, vim.inspect(got):gsub("%s+", " "), vim.inspect(want):gsub("%s+", " ")))
	end
end

---A fresh buffer with this filetype, and the options the handlers leave on it.
---@param ft string
---@return table
local function buffer_of(ft)
	-- A listed scratch buffer, so "is it listed" is a question about the handler
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "x" })
	vim.api.nvim_win_set_buf(0, buf)
	-- The options start at values this config does not set, so anything the
	-- handler leaves different is the handler and not a default.
	vim.wo.wrap = false
	vim.wo.conceallevel = 2
	vim.bo[buf].iskeyword = "@,48-57,_,192-255"
	-- :setfiletype and not the option: setting "filetype" does not fire FileType,
	-- and these handlers are all listening for it.
	vim.cmd("setfiletype " .. ft)
	-- 'wrap' and 'conceallevel' are window-local, so they are read off the window
	-- the buffer is in, and the rest off the buffer.
	local win = vim.api.nvim_get_current_win()
	local function win_opt(name)
		return vim.api.nvim_get_option_value(name, { win = win })
	end
	local function buf_opt(name)
		return vim.api.nvim_get_option_value(name, { buf = buf })
	end
	return {
		ft = vim.bo[buf].filetype,
		wrap = win_opt("wrap"),
		conceallevel = win_opt("conceallevel"),
		iskeyword = buf_opt("iskeyword"),
		listed = vim.bo[buf].buflisted,
	}
end

-- Wrap the text filetypes, and only those
for _, ft in ipairs({ "text", "plaintex", "typst", "gitcommit", "markdown" }) do
	local b = buffer_of(ft)
	case(ft .. " is wrapped", true, b.wrap)
end
for _, ft in ipairs({ "lua", "help" }) do
	local b = buffer_of(ft)
	case(ft .. " is not wrapped", false, b.wrap)
end

-- json files are not concealed
for _, ft in ipairs({ "json", "jsonc", "json5" }) do
	local b = buffer_of(ft)
	case(ft .. " is not concealed", 0, b.conceallevel)
end
case("lua is left concealed", 2, buffer_of("lua").conceallevel)

-- The separator characters in these filetypes are part of a word
for _, ft in ipairs({ "css", "html", "typescriptreact", "javascriptreact" }) do
	local b = buffer_of(ft)
	case(ft .. " has a dash in iskeyword", true, b.iskeyword:sub(-1) == "-")
end
case("lua does not", false, buffer_of("lua").iskeyword:sub(-1) == "-")

-- Panels are not buffers a list should offer
for _, ft in ipairs({ "man", "qf", "help", "oil", "grug-far", "gitsigns-blame", "terminal" }) do
	case(ft .. " is not listed", false, buffer_of(ft).listed)
end
case("a lua buffer is", true, buffer_of("lua").listed)

-- A panel closes with q, and the key is on that buffer alone. The handler sets
-- it from a scheduled callback, because a session hop can close the buffer
-- between the filetype arriving and the key being wanted, so the key is waited
-- for rather than read at once.
local buf = vim.api.nvim_create_buf(true, true)
vim.api.nvim_win_set_buf(0, buf)
vim.cmd("setfiletype help")
local function has_q(b)
	for _, m in ipairs(vim.api.nvim_buf_get_keymap(b, "n")) do
		if m.lhs == "q" then
			return true
		end
	end
	return false
end
vim.wait(500, function()
	return has_q(buf)
end)
case("a panel has a q", true, has_q(buf))
-- and a buffer the handler does not name has no q of its own
local plain_buf = vim.api.nvim_create_buf(true, true)
vim.api.nvim_win_set_buf(0, plain_buf)
vim.cmd("setfiletype lua")
vim.wait(300)
case("a lua buffer has no q", false, has_q(plain_buf))

print(("filetype checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("filetype test failed")
end
print("filetype tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
