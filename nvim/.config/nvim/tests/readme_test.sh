#!/usr/bin/env bash
# Run: bash tests/readme_test.sh
# Every key the README promises has to exist somewhere in lua/. The cheatsheet
# is where most presses get looked up, and a row for a key that was renamed or
# removed sends someone to a mapping that does nothing. The source is read
# rather than the loaded maps because half of these are buffer-local: the hunk
# keys arrive with gitsigns' attach and the code keys with the language server.
set -uo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

SCRIPT='
-- <space> and <tab> are spelled three ways in this repo, and a key written with
-- a quote in it is escaped in the source. One spelling for the comparison.
local function canon(key)
	key = key:gsub("<space>", " "):gsub("<tab>", "<Tab>"):gsub("\\", ""):gsub("%s+$", "")
	return key
end

local mapped = {}
for _, path in ipairs(vim.fn.globpath("lua", "**/*.lua", false, true)) do
	for line in io.lines(path) do
		for key in line:gmatch("(<leader>[^%s,)]+)") do
			key = key:gsub("[\"\39]$", "")
			mapped[canon(key)] = path
		end
	end
end

local missing, checked = {}, 0
for _, line in ipairs(vim.fn.readfile("README.md")) do
	local row = line:match("^%s+(<leader>%S+)")
	if row and not row:find("%.%.") then
		local rest = row:gsub("^<leader>", "")
		for key in rest:gmatch("[^/]+") do
			checked = checked + 1
			local full = canon("<leader>" .. key)
			if not mapped[full] and not mapped[canon(key)] then
				missing[#missing + 1] = "<leader>" .. key
			end
		end
	end
end

io.write("readme keys checked=", checked, " mapped=", vim.tbl_count(mapped), " missing=", #missing, "\n")
for _, key in ipairs(missing) do
	io.write("  no map for ", key, "\n")
end
assert(checked > 80, "the README parse found too few keys to trust, got " .. checked)
assert(#missing == 0, #missing .. " README rows name a key that lua/ does not map")

-- The module table names files by path, and a rename that skips the README
-- leaves a table pointing at code that is no longer there. Every backticked
-- path in the file is checked, and the count is reported so a pattern that
-- stops matching shows up as 0 checked instead of 0 missing.
local roots = { config = "lua/config/", plugins = "lua/plugins/", lsp = "lsp/", tests = "tests/", docs = "docs/" }
local seen, gone = 0, {}
for line in io.lines("README.md") do
	for named in line:gmatch("`([%w_./-]+%.[a-z]+)`") do
		local dir, rest = named:match("^(%w+)/(.+)$")
		if dir and roots[dir] then
			seen = seen + 1
			if vim.fn.filereadable(roots[dir] .. rest) == 0 and vim.fn.isdirectory(roots[dir] .. rest) == 0 then
				gone[#gone + 1] = named
			end
		end
	end
end
io.write("readme paths checked=", seen, " missing=", #gone, "\n")
for _, named in ipairs(gone) do
	io.write("  no file ", named, "\n")
end
assert(seen > 20, "the README path parse found too few paths to trust, got " .. seen)
assert(#gone == 0, #gone .. " README rows name a file that is not there")
'
run_lua_full "$SCRIPT"
echo "readme tests passed"
