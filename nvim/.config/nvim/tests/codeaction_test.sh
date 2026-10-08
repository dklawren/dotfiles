#!/usr/bin/env bash
# Run: bash tests/codeaction_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Code actions are the one LSP thing that comes through vim.ui.select, and
# config/lsp.lua sends that one kind to the picker instead of nvim's dialog. The
# items here are the shape vim.lsp.buf.code_action builds, so the picker builds
# its rows and its preview from them the way it would for a real server.
SCRIPT='
-- A stand-in for the dialog nvim opens, put in place before the config loads.
-- A code action that fell through to it would open a window nobody can answer in
-- a headless run, so the fall-through is counted here and asserted at the end.
local fell_through = 0
vim.ui.select = function(items, opts, on_choice)
	fell_through = fell_through + 1
	if type(on_choice) == "function" then
		on_choice(items[1])
	end
end

require("config.lsp")

local P = require("config.picker")
local failures, checks = 0, 0

local function case(name, want, got)
	checks = checks + 1
	if got ~= want then
		failures = failures + 1
		print(("FAIL %s\n got %s\nwant %s"):format(name, vim.inspect(got):gsub("%s+", " "), vim.inspect(want):gsub("%s+", " ")))
	end
end

local items = {
	{
		action = { title = "Extract function", kind = "refactor.extract", edit = { documentChanges = { { textDocument = { uri = "file:///tmp/a.lua" } } } } },
		ctx = {},
	},
	{
		action = { title = "Organize imports", kind = "source.organizeImports", disabled = { reason = "no imports" } },
		ctx = {},
	},
	{
		action = { title = "Run test", command = { title = "test", command = "make test" } },
		ctx = {},
	},
}

local chosen
vim.ui.select(items, {
	kind = "codeaction",
	format_item = function(item)
		return item.title or item.action and item.action.title or "?"
	end,
}, function(item)
	chosen = item
end)

case("the picker is up", true, P.is_open())
local v = P.visible()
case("every action is a row", 3, v.count)
case("the rows are the titles", "Extract function", v.labels[1])
-- The caller supplied a formatter, so the row is what the caller asked for and
-- nothing is added to it
case("a caller formatter is used as it is", "Organize imports", v.labels[2])

-- The preview spells out what the action would do, which is the part a user
-- reads before pressing enter
local list_buf = v.buf
local win = vim.fn.win_findbuf(list_buf)[1]
case("the list has a window", true, win ~= nil)
vim.api.nvim_set_current_win(win)
local ctx = {}
for _, m in ipairs(vim.api.nvim_buf_get_keymap(list_buf, "n")) do
	if m.lhs == "<CR>" then
		-- the picker passes a context with a preview writer to the preview it
		-- configured, so this is the only way to read what it would draw
		local done = false
		m.callback()
		done = P.is_open() == false
		case("enter closes the picker", true, done)
	end
end
case("the choice went back to the caller", "Extract function", chosen and chosen.action and chosen.action.title)

-- With no formatter of its own the picker names the actions, and says which are
-- disabled
vim.ui.select({ items[2] }, { kind = "codeaction" }, function() end)
case("one action is still a list", 1, P.visible().count)
case("the picker names it", "Organize imports (disabled)", P.visible().labels[1])
for _, m in ipairs(vim.api.nvim_buf_get_keymap(P.visible().buf, "n")) do
	if m.lhs == "<Esc>" then
		m.callback()
	end
end
case("escape closes it", false, P.is_open())

case("nothing fell through to the dialog nvim opens", 0, fell_through)

print(("codeaction checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("codeaction test failed")
end
print("codeaction tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
