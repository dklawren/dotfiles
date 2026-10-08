#!/usr/bin/env bash
# Run: bash tests/draw_test.sh
#
# What a user sees, read off the screen. Every other suite in this directory
# asks nvim what it drew into a buffer; this one asks what it painted, through a
# real terminal and nvim__screenshot, which is the only way to catch a render
# that is right in extmarks and wrong on the glass. The word count in the
# statusline went missing for a whole session of refactoring that way: the
# filetype test asked "markdown", the matcher asked "md", and markdown is not a
# filetype that contains md.
#
# The pty is not optional, for the reason tests/blink_test.sh gives: a headless
# nvim has no input loop, so nothing is drawn and there is no screen to read.
#
# The document goes into a scratch buffer rather than a file. Reading a file from
# the deferred callback this test drives itself blocks under the real config
# (the config's own FileType handlers run inside the read), and a file would
# also bring the per-directory session layer into it. The events a real open
# fires are fired by hand instead, which is what the other suites do too.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=$PWD
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/drive.lua" <<'LUA'
local shot = vim.env.DRAW_SHOT
local report = {}

local DOC = {
	"# Rendered headings",
	"",
	"Some prose with `code` and **bold** inside it.",
	"",
	"- first item",
	"- second item",
	"",
	"> a quote",
	"> with two lines",
	"",
	"```lua",
	"local function add(a, b)",
	"	return a + b",
	"end",
	"```",
	"",
	"| Name  | Qty | Note    |",
	"| :---- | ---: | :-----: |",
	"| widget |  12 | small  |",
	"",
	"Trailing paragraph.",
}

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

---The screen as text. nvim__screenshot writes the drawn stream: a "rows,cols"
---line, then every cursor move and colour as an escape sequence around the cell
---text. The sequences go, the rows stay, and what is left is what a person reads.
local function screen()
	-- The file lands after the call returns, and it lands by truncating first,
	-- so a second screenshot has to take the old one away: left in place it is
	-- readable, and readable means empty.
	vim.fn.delete(shot)
	vim.api.nvim__screenshot(shot)
	vim.wait(1000, function()
		return vim.fn.filereadable(shot) == 1
	end)
	local raw = table.concat(vim.fn.readfile(shot), "\n")
	local text = raw:gsub("\27%][^\7\27]*[\7\27\\]", ""):gsub("\27%[[0-9;?]*[ -/]*[@-~]", ""):gsub("\27[()][%w=>]", "")
	local rows = {}
	for row in (text .. "\n"):gmatch("([^\n]*)\n") do
		rows[#rows + 1] = (row:gsub("\r", ""))
	end
	table.remove(rows, 1) -- the "rows,cols" line is not a row of the screen
	return rows
end

local function has_row(rows, needle)
	for _, row in ipairs(rows) do
		if row:find(needle, 1, true) then
			return true
		end
	end
	return false
end

---A row that holds every one of these, so an icon drawn between two words
---cannot fail an assertion about the words.
local function row_with_all(rows, ...)
	local needles = { ... }
	for _, row in ipairs(rows) do
		local all = true
		for _, needle in ipairs(needles) do
			if not row:find(needle, 1, true) then
				all = false
				break
			end
		end
		if all then
			return true
		end
	end
	return false
end

local function check_document()
	local rows = screen()
	-- The cursor is on the prose, so every other row is drawn as rendered: a
	-- row the cursor is on is drawn as source, which is the renderer's decision
	-- and the reason the heading below still has no # on screen.
	ok(has_row(rows, "Rendered headings"), "the heading row is not on screen")
	ok(not has_row(rows, "# Rendered"), "the heading still shows its #")
	ok(row_with_all(rows, "●", "first item"), "no bullet for the first item")
	ok(row_with_all(rows, "▋", "a quote"), "no bar for the quote")
	ok(row_with_all(rows, "▄", "lua"), "no top border for the code fence")
	ok(row_with_all(rows, "▀"), "no bottom border for the code fence")
	ok(row_with_all(rows, "┌", "┬"), "no top border for the table")
	ok(row_with_all(rows, "└", "┴"), "no bottom border for the table")
	ok(row_with_all(rows, "│", "widget"), "no table cell for widget")
	ok(row_with_all(rows, "│", "Qty"), "the table header is not on screen")
	ok(row_with_all(rows, "│", "│"), "the table has no second rule on one row")
	-- the statusline is the last row of the screen
	local last = rows[#rows] or ""
	ok(last:find("%d+w  %d+m") ~= nil, "the statusline has no word count: " .. last)
	ok(last:find("NORMAL") ~= nil, "the statusline has no mode: " .. last)
	ok(last:find("markdown") ~= nil, "the statusline has no filetype: " .. last)
end

---The tabline, drawn on the first row of the screen. Twelve buffers do not fit
---in the terminal this harness gives, so the tabline hides some of them and
---says how many on each side, which is the only part of it with arithmetic in
---it. The width is left alone: narrowing it from Lua clears the grid the
---screenshot reads, and twelve buffers overflow a hundred and twenty columns
---anyway.
local function check_tabline()
	vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))
	local names, created = {}, {}
	for i = 1, 12 do
		local buf = vim.api.nvim_create_buf(true, false)
		names[i] = ("buffer_number_%02d.lua"):format(i)
		created[i] = buf
		vim.api.nvim_buf_set_name(buf, "/tmp/drawtest/" .. names[i])
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "x" })
	end
	-- The current buffer has to be in the middle of the list for the tabline to
	-- hide rows on both sides, which is the case with arithmetic on it.
	vim.api.nvim_win_set_buf(0, created[6])
	vim.cmd("redraw!")
	vim.wait(300)
	local rows = screen()
	local first = rows[1] or ""
	ok(first:find("buffer_number_06") ~= nil, "the tabline has no current buffer: " .. first)
	ok(first:find("«") ~= nil, "the tabline has no marker for what it hid: " .. first)
	ok(first:find("»") ~= nil, "the tabline has no marker on the other side: " .. first)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= "" then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end
end

local function finish()
	note("draw checks=" .. checks)
	note("failures=" .. failures)
	vim.fn.writefile(report, vim.env.PICKER_RESULT)
	vim.cmd("qa!")
end

---A phase that cannot be read is a failure to report, not a reason to stop the
---run: the next screen is still worth taking.
local function guarded(name, check)
	local okc, err = pcall(check)
	if not okc then
		failures = failures + 1
		note("FAIL the " .. name .. " screen could not be read: " .. tostring(err))
	end
end

---The row the cursor is on, drawn. A rendered row is a picture laid over the
---text, so the row the cursor is on is drawn as the text it is: the renderer
---gives up its own drawing for that row so the cursor has something to sit on.
---This is the rule the whole window is built around, and nothing else in the
---directory checks it.
local function check_cursor_row()
	vim.api.nvim_win_set_cursor(0, { 18, 0 })
	vim.cmd("redraw!")
	vim.wait(200)
	vim.cmd("redraw!")
	vim.wait(200)
	local rows = screen()
	ok(has_row(rows, "| :---- |"), "the row under the cursor is not drawn as source")
	ok(row_with_all(rows, "│", "widget"), "the rows around the cursor lost their drawing")
	ok(row_with_all(rows, "┌", "┬"), "the table lost its top border")
	local last = rows[#rows] or ""
	ok(last:find("18:1") ~= nil, "the statusline does not have the cursor position: " .. last)
end

---Diagnostics, drawn: the virtual text after the line, with the prefix and the
---source the config asks for, and a sign in the column. The counts in the
---statusline are covered by tests/statusline_test.sh, which can read them
---without a terminal in the way.
local function check_diagnostics()
	local rows = screen()
	-- The virtual text is the prefix, the source and the message, and "if_many"
	-- draws the source because the buffer has more than one.
	ok(row_with_all(rows, "●", "lua_ls: unused variable a"), "no virtual text for the error")
	ok(row_with_all(rows, "●", "selene: shadowing c"), "no virtual text for the second source")
	ok(row_with_all(rows, "●", "consider local d"), "no virtual text for the hint")
	-- and it rides on the row of the line it belongs to rather than a row of
	-- its own, so four lines are still four rows
	ok(row_with_all(rows, "local a = 1", "lua_ls"), "the virtual text is not on its line's row")
end

local function show_diagnostics()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local a = 1", "local b = 2", "local c = 3", "local d = 4" })
	vim.bo[buf].filetype = "lua"
	vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
	vim.api.nvim_exec_autocmds("BufEnter", { buffer = buf })
	local sev = vim.diagnostic.severity
	vim.diagnostic.set(vim.api.nvim_create_namespace("probe"), buf, {
		{ lnum = 0, col = 6, end_lnum = 0, end_col = 7, message = "unused variable a", severity = sev.ERROR, source = "lua_ls" },
		{ lnum = 1, col = 6, end_lnum = 1, end_col = 7, message = "unused variable b", severity = sev.WARN, source = "lua_ls" },
		{ lnum = 2, col = 6, end_lnum = 2, end_col = 7, message = "shadowing c", severity = sev.INFO, source = "selene" },
		{ lnum = 3, col = 6, end_lnum = 3, end_col = 7, message = "consider local d", severity = sev.HINT, source = "selene" },
	})
	vim.api.nvim_exec_autocmds("DiagnosticChanged", { buffer = buf })
	vim.cmd("redraw!")
	vim.wait(300)
	vim.cmd("redraw!")
	vim.wait(200)
end

---The picker, drawn. The needle has to be typed rather than set, because that
---is the only way the filter line gets one, and a real terminal is the only way
---to type at nvim: the harness sends these bytes when the step is announced
---below, not from here.
local function check_picker()
	local rows = screen()
	local P = require("config.picker")
	local v = P.visible()
	ok(has_row(rows, "shapes"), "the picker has no title")
	-- "mod" is in every module_NN.lua and in no other name, so one of the forty
	-- drops out and the count says so
	ok(row_with_all(rows, " of 40"), "the filter line has no count")
	ok(row_with_all(rows, "config", "module_1"), "no row among the survivors")
	ok(not has_row(rows, "markdown"), "the row that does not match is still listed")
	ok(v.count == 39, "the wrong number of rows survived: " .. tostring(v.count))
	ok(row_with_all(rows, "one"), "the preview has no content")
	ok(v.needle == "mod", "the needle is not what was typed: " .. tostring(v.needle))
end

local function open_picker()
	local items = {}
	for i = 1, 40 do
		items[i] = { name = ("lua/config/module_%02d.lua"):format(i) }
	end
	items[7] = { name = "lua/config/markdown.lua" }
	require("config.picker").open(items, {
		title = "shapes",
		skip_single = false,
		filter = true,
		format = function(item)
			return item.name
		end,
		preview = function(_, ctx)
			ctx.set_lines({ "one", "two", "three" }, "lua")
		end,
		on_confirm = function() end,
	})
	local f = io.open(vim.env.PICKER_STATUS, "a")
	f:write("needle\n")
	f:close()
end

---Wait for what the harness typed to narrow the list, then draw it.
local function await_picker(deadline)
	local P = require("config.picker")
	local v = P.visible()
	if v.needle == "mod" and v.count > 0 and v.count < 40 then
		vim.cmd("redraw!")
		vim.wait(200)
		guarded("picker", check_picker)
		finish()
		return true
	end
	if vim.uv.hrtime() > deadline then
		note("the needle never narrowed the list: needle=" .. tostring(v.needle) .. " count=" .. tostring(v.count))
		finish()
		return true
	end
	vim.defer_fn(function()
		await_picker(deadline)
	end, 100)
	return false
end

local phases = { "document", "cursor", "tabline", "diagnostics", "picker" }
local phase = 1
local started = vim.uv.hrtime()

local function step()
	local name = phases[phase]
	phase = phase + 1
	if name == "document" then
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(0, buf)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, DOC)
		vim.bo[buf].filetype = "markdown"
		-- what an :edit of a .md file fires, in the order it fires them
		vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
		vim.api.nvim_exec_autocmds("BufEnter", { buffer = buf })
		vim.api.nvim_exec_autocmds("WinScrolled", { buffer = buf })
		vim.api.nvim_win_set_cursor(0, { 3, 0 })
		vim.cmd("redraw!")
		-- The word count in the statusline is debounced by half a second, and
		-- Neovim only redraws the line when something asks it to, so there is a
		-- draw after the wait as well as before it.
		vim.wait(1200)
		vim.cmd("redraw!")
		vim.wait(200)
		guarded("document", check_document)
	elseif name == "cursor" then
		guarded("cursor", check_cursor_row)
	elseif name == "tabline" then
		guarded("tabline", check_tabline)
	elseif name == "diagnostics" then
		show_diagnostics()
		guarded("diagnostics", check_diagnostics)
	elseif name == "picker" then
		open_picker()
		await_picker(started + 25000 * 1e6)
		return
	end
	if phase > #phases then
		finish()
	else
		-- one phase per turn of the loop, so the screen after a check is drawn
		-- by the same main loop the check ran in
		vim.defer_fn(step, 150)
	end
end

-- After the UI is attached, and from a deferred callback: the main loop has to
-- be free for the document to draw at all, and a file read from inside UIEnter
-- is asking for trouble.
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		vim.defer_fn(step, 150)
	end,
})
LUA

# One step, the needle for the picker's filter line. The script announces it
# when the picker is open, and the harness writes these bytes into the pty.
: >"$tmp/keys"
printf 'needle\t%s\n' "$(printf 'mod' | xxd -p | tr -d '\n')" >>"$tmp/keys"

DRAW_SHOT="$tmp/shot" PTY_DEADLINE=50 \
	python3 "$repo/tests/pty_drive.py" "$tmp/keys" "$tmp/draw.status" "$tmp/draw.out" -- \
	nvim -c "luafile $tmp/drive.lua" >/dev/null 2>&1 || true

if [ ! -f "$tmp/draw.out" ]; then
	echo "draw tests: the pty run wrote no result" >&2
	exit 1
fi
cat "$tmp/draw.out"
grep -q '^failures=0$' "$tmp/draw.out"
