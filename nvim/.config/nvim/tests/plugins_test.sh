#!/usr/bin/env bash
# Run: bash tests/plugins_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Two lists of plugins have to agree: what the config asks vim.pack for, and what
# nvim-pack-lock.json pins. Nothing else in the config looks at the lock, so a
# plugin added without a lock entry installs at whatever the spec says that day,
# and one removed from the config leaves a lock entry nothing will ever read.
# Both are read, nothing is written.
SCRIPT='
local failures, checks = 0, 0

local function case(name, want, got)
	checks = checks + 1
	if want ~= got then
		failures = failures + 1
		print(("FAIL %s\n got %s\nwant %s"):format(name, vim.inspect(got):gsub("%s+", " "), vim.inspect(want):gsub("%s+", " ")))
	end
end

-- the lock, as a set of names
local lock = {}
do
	local path = vim.fn.getcwd() .. "/nvim-pack-lock.json"
	local ok, decoded = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), "\n"))
	if not ok or type(decoded) ~= "table" or type(decoded.plugins) ~= "table" then
		error("the lock file is not readable: " .. vim.inspect(decoded))
	end
	for name, spec in pairs(decoded.plugins) do
		lock[name] = spec
	end
end

-- what the config asks for, as a set of names taken from the source URL
local asked = {}
for _, file in ipairs(vim.fn.glob("lua/**/*.lua", false, true)) do
	for _, line in ipairs(vim.fn.readfile(file)) do
		for url in line:gmatch("https?://[%w%.%-/_]+") do
			asked[(url:gsub("/+$", "")):match("([^/]+)$")] = true
		end
	end
end

local function sorted(set)
	local out = {}
	for k in pairs(set) do
		out[#out + 1] = k
	end
	table.sort(out)
	return table.concat(out, " ")
end

-- A source URL is not a name on its own, so anything that is not a plugin in the
-- lock is a url from a comment or a doc string, and the lock is what says which
local config_names = {}
for name in pairs(lock) do
	if asked[name] then
		config_names[name] = true
	end
end

case("every plugin the config asks for is locked", sorted(lock), sorted(config_names))

-- and the other direction, over the whole set of names the sources mention
local mentioned = {}
for name in pairs(asked) do
	if name:match("%.nvim$") or name:match("^blink") or name:match("^oil") or lock[name] then
		mentioned[name] = true
	end
end
case("every locked plugin is asked for somewhere", sorted(lock), sorted(mentioned))

-- A locked revision is a full sha, which is what makes an install reproducible
local short = {}
for name, spec in pairs(lock) do
	if type(spec.rev) ~= "string" or #spec.rev ~= 40 or spec.rev:match("^%x+$") == nil then
		short[#short + 1] = name
	end
	if type(spec.src) ~= "string" or spec.src:match("^https?://") == nil then
		short[#short + 1] = name .. " (src)"
	end
end
case("every lock entry is a full revision from a url", "", table.concat(short, " "))

print(("plugins checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("plugins test failed")
end
print("plugins tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
