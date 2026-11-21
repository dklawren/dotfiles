#!/usr/bin/env bash
# Run: bash tests/lsp_test.sh
# tsserver omits the extension on a relative auto-import when the tsconfig
# resolves like a bundler, and Node ESM then refuses the import at runtime. The
# client has to ask for it, and whichever TypeScript server a project runs has
# to ask for it, or the project pays for the swap.
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

SCRIPT='
local failures, checks = 0, 0
local function check(ok, msg)
	checks = checks + 1
	if not ok then
		failures = failures + 1
		print("FAIL: " .. msg)
	end
end

-- Both TypeScript servers carry the same settings, so a project that swaps one
-- for the other keeps the auto-import shape.
for _, name in ipairs({ "vtsls", "ts_ls" }) do
	local conf = vim.lsp.config[name] or {}
	local settings = conf.settings or {}
	local function ending(kind)
		local section = settings[kind] or {}
		local preferences = section.preferences or {}
		return preferences.importModuleSpecifierEnding, preferences.preferTypeOnlyAutoImports
	end
	check(ending("typescript") == "js", name .. " auto-imports end in .js, got " .. vim.inspect(settings.typescript))
	check(ending("javascript") == "js", name .. " javascript auto-imports end in .js, got " .. vim.inspect(settings.javascript))
	local _, type_only = ending("typescript")
	check(type_only == true, name .. " an auto-import used as a type is written import type, got " .. tostring(type_only))
	local hints = (settings.typescript or {}).inlayHints or {}
	check(
		hints.parameterTypes and hints.parameterTypes.enabled == true and hints.variableTypes.enabled == true,
		name .. " tsserver sends inlay hints, so the toggle has something to show, got " .. vim.inspect(hints)
	)
	check(#(conf.cmd or {}) > 0, name .. " has a command to spawn")
end

-- tsserver has no pull-based workspace diagnostic. The list has to be built
-- from what the buffers reported, or the mapping looks like a clean project.
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x" })
local ns = vim.api.nvim_create_namespace("lsp_test")
vim.diagnostic.set(ns, 0, { { lnum = 0, col = 0, message = "boom", severity = vim.diagnostic.severity.ERROR } })
vim.fn.setqflist({})
local lsp = require("config.lsp")
local cw = type(lsp) == "table" and lsp.workspace_diagnostics or nil
check(type(cw) == "function", "config.lsp exposes the workspace diagnostic listing")
if type(cw) == "function" then
	cw()
end
local shown = vim.fn.getqflist()
check(#shown == 1, "a reported diagnostic reaches quickfix, got " .. #shown)
check(#shown == 1 and shown[1].text:find("boom", 1, true) ~= nil, "the quickfix item carries the message")

-- One place to go is a jump, not a choice. A picker with a single row costs a
-- keystroke on every gd.
local on_list = type(lsp) == "table" and lsp.on_list or nil
check(type(on_list) == "function", "config.lsp exposes the LSP location handler")
if type(on_list) == "function" then
	local target = vim.fn.tempname() .. ".lua"
	vim.fn.writefile({ "one", "two", "three" }, target)
	on_list({ title = "Definitions", items = { { filename = target, lnum = 2, col = 3, text = "sym" } } })
	check(
		vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0)) == vim.uv.fs_realpath(target),
		"a single location jumps to its file, got " .. vim.api.nvim_buf_get_name(0)
	)
	check(vim.api.nvim_win_get_cursor(0)[1] == 2, "a single location lands on its line")
	local picker = require("config.picker")
	local opened = 0
	picker.locations = function()
		opened = opened + 1
	end
	on_list({ title = "References", items = { { filename = target, lnum = 1 }, { filename = target, lnum = 2 } } })
	check(opened == 1, "two locations go to the picker, got " .. opened)
end

print(("lsp checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("lsp test failed")
end
print("lsp tests passed")
'

run_lua_full "$SCRIPT"
