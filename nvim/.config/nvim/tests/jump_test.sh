#!/usr/bin/env bash
# Run: bash tests/jump_test.sh
#
# config/jump.lua: a key marks every occurrence of a letter on screen, and a
# second key jumps to the one whose label was typed. Both halves need real
# keys, because the first is a mapping and the second is getcharstr(), so this
# is driven through the pty harness the way tests/blink_test.sh is.
#
# What the screen shows is the labels: the marks are an attribute as well as
# text, and this reads the text.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/drive.lua" <<'LUA'
local ns = vim.api.nvim_create_namespace("jump")
local report = {}
local function note(s)
	report[#report + 1] = s
end

local checks, failures = 0, 0
local function ok(cond, msg)
	checks = checks + 1
	if not cond then
		failures = failures + 1
		note("FAIL " .. msg)
	end
end

local function labels()
	local out = {}
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
		if m[4].virt_text and m[4].virt_text[1][1] then
			out[#out + 1] = ("%d:%d:%s"):format(m[2], m[3], m[4].virt_text[1][1])
		end
	end
	return out
end

local function announce(name)
	local f = io.open(vim.env.PICKER_STATUS, "a")
	f:write(name .. "\n")
	f:close()
end

-- f is one of the three trigger keys (s, f and t, chosen so that df and dt
-- still work), and the labels start at f, so one key marks and the same key
-- again jumps to the first occurrence.
-- f is one of the three trigger keys (s, f and t, chosen so that df and dt
-- still work). The sequence is three keys: the trigger, the letter to mark, and
-- the label to jump to, because the first two are a mapping and a getcharstr().
local DOC = { "afraid of fakes", "fifty fine", "sofa" }
local started = vim.uv.hrtime()
local stage = "open"

local function poll()
	if stage == "open" then
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(0, buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, DOC)
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		vim.cmd("redraw!")
		stage = "triggered"
		announce("letter")
		vim.defer_fn(poll, 50)
		return
	end
	if stage == "triggered" then
		-- the mapping is now waiting on its first getcharstr()
		stage = "letter"
		announce("go")
		vim.defer_fn(poll, 50)
		return
	end
	if stage == "letter" then
		-- The marks appear once the first getcharstr() has returned, which is
		-- after the letter arrives, not after the trigger.
		local found = labels()
		if #found > 0 then
			note("marks: " .. table.concat(found, " "))
			-- the labels run in LABELS order, so the marks read f, d, s, a, g, h, j
			ok(#found == 7, "seven occurrences of f, " .. #found .. " marks")
			-- The marks are 0-based rows, and "fifty fine" holds three of the
			-- letter, so the second row is three marks.
			local on_second_row = 0
			for _, l in ipairs(found) do
				if l:match("^1:") then
					on_second_row = on_second_row + 1
				end
			end
			ok(on_second_row == 3, "the row with three occurrences has " .. on_second_row .. " marks")
			ok(found[1]:match("^0:1:f") ~= nil, "the first mark is not the first f: " .. found[1])
			stage = "go"
			announce("pick")
			vim.defer_fn(poll, 50)
			return
		end
	elseif stage == "go" then
		-- The labels run f, d, s, a, g, h, j, so the last of the seven marks is
		-- labelled j and is the only f in the third row: the jump is to that
		-- row, which a cursor that always went to the first would not match.
		if #labels() == 0 and vim.api.nvim_win_get_cursor(0)[1] == 3 then
			ok(true, "the cursor is on the row the label named")
			note("jump checks=" .. checks)
			note("failures=" .. failures)
			vim.fn.writefile(report, vim.env.PICKER_RESULT)
			vim.cmd("qa!")
			return
		end
	end
	if (vim.uv.hrtime() - started) / 1e6 > 25000 then
		note("gave up at stage " .. stage .. " with " .. #labels() .. " marks")
		note("jump checks=" .. checks)
		note("failures=" .. failures + 1)
		vim.fn.writefile(report, vim.env.PICKER_RESULT)
		vim.cmd("qa!")
		return
	end
	vim.defer_fn(poll, 50)
end

vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		vim.defer_fn(poll, 150)
	end,
})
LUA

: >"$tmp/keys"
printf 'letter\t%s\n' "$(printf 'f' | xxd -p | tr -d '\n')" >>"$tmp/keys"
printf 'go\t%s\n' "$(printf 'f' | xxd -p | tr -d '\n')" >>"$tmp/keys"
printf 'pick\t%s\n' "$(printf 'j' | xxd -p | tr -d '\n')" >>"$tmp/keys"

PTY_DEADLINE=45 python3 "$repo/tests/pty_drive.py" "$tmp/keys" "$tmp/jump.status" "$tmp/jump.out" -- \
	nvim -c "luafile $tmp/drive.lua" >/dev/null 2>&1 || true

if [ ! -f "$tmp/jump.out" ]; then
	echo "jump tests: the pty run wrote no result" >&2
	exit 1
fi
cat "$tmp/jump.out"
grep -q '^failures=0$' "$tmp/jump.out"
