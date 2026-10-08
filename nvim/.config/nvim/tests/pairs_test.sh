#!/usr/bin/env bash
# Run: bash tests/pairs_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Pairs is expr-mapped in insert mode, so every case here types a key and reads
# the buffer back. The fence case keeps its code fence in the buffer and types
# inside it, so the treesitter half of in_code_context() is the real thing.
SCRIPT='
-- The module maps the keys when it loads, which is what a real session has done
-- by the time a key is pressed.
require("config.pairs")

local failures, checks = 0, 0

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local code, prose, fence, text = dir .. "/code.lua", dir .. "/prose.md", dir .. "/fence.md", dir .. "/a.txt"
vim.fn.writefile({ "local x = 1" }, code)
vim.fn.writefile({ "prose here" }, prose)
vim.fn.writefile({ "```lua", "local y = 1", "```" }, fence)
vim.fn.writefile({ "text here" }, text)

---Filetype detection is off in this nvim (-u NONE), and pairs is asked for the
---filetype of the buffer, so every case says which one it is.
local function open(path, rows, ft)
	vim.cmd("edit! " .. vim.fn.fnameescape(path))
	vim.bo.filetype = ft
	vim.api.nvim_buf_set_lines(0, 0, -1, false, rows)
	-- In a session the markdown highlighter has parsed the buffer before a key
	-- is pressed; here nothing does, so the fence case parses it itself.
	if ft == "markdown" then
		vim.treesitter.get_parser(0, "markdown"):parse()
	end
end

---Type at the end of a row, the way typing at the end of a line does.
local function type_at(path, rows, row, keys, ft)
	open(path, rows, ft)
	vim.api.nvim_win_set_cursor(0, { row, 0 })
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("A" .. keys, true, false, true), "x", false)
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)[row]
end

---Type before a column, the way typing in the middle of a line does.
local function type_before(path, rows, row, col, keys, ft)
	open(path, rows, ft)
	vim.api.nvim_win_set_cursor(0, { row, col })
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i" .. keys, true, false, true), "x", false)
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)[row]
end

local function case(name, want, got)
	checks = checks + 1
	if got ~= want then
		failures = failures + 1
		print(("FAIL %s\n got %q\nwant %q"):format(name, tostring(got), want))
	end
end

-- In a code buffer every opener closes itself.
case("an opener closes itself", "local x = ()", type_at(code, { "local x = " }, 1, "(", "lua"))
case("and so does a bracket", "local x = []", type_at(code, { "local x = " }, 1, "[", "lua"))
case("and a brace", "local x = {}", type_at(code, { "local x = " }, 1, "{", "lua"))
case("and a quote", "local x = \"\"", type_at(code, { "local x = " }, 1, "\x22", "lua"))
case("and a backtick", "local x = ``", type_at(code, { "local x = " }, 1, "`", "lua"))

-- A closer with nothing in front of it is typed as itself.
case("a lone closer stays", "local x = a))", type_at(code, { "local x = a)" }, 1, ")", "lua"))

-- A closer in front of its own pair steps over it instead of doubling it.
case("a closer steps over its pair", "local x = ()", type_before(code, { "local x = ()" }, 1, 11, ")", "lua"))

-- Backspace between a pair takes both.
case("backspace between a pair takes both", "local x = ", type_before(code, { "local x = ()" }, 1, 11, "<BS>", "lua"))

-- Prose is left alone, in markdown and in text.
case("no pairs in markdown prose", "prose here(", type_at(prose, { "prose here" }, 1, "(", "markdown"))
case("no pairs in text", "text here(", type_at(text, { "text here" }, 1, "(", "text"))

-- Inside a fenced block markdown pairs like code.
case("a fence pairs like code", "local y = ()", type_at(fence, { "```lua", "local y = ", "```" }, 2, "(", "markdown"))

print(("pairs checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("pairs test failed")
end
print("pairs tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
