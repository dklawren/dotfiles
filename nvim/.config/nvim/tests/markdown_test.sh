#!/usr/bin/env bash
# Run: bash tests/markdown_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPT='
require("config.markdown")

local ns = vim.api.nvim_create_namespace("md-render")
local path = vim.fn.tempname() .. ".md"
vim.fn.writefile({
	"# Title",
	"",
	"- item",
	"- [ ] todo",
	"- [x] done",
	"",
	"> [!NOTE]",
	"> quoted",
	"",
	"```lua",
	"local x = 1",
	"```",
	"",
	"| **a_b** | bb |",
	"| --- | --- |",
	"| 1 | 2 |",
	"",
	"| L | C | R |",
	"| :--- | :---: | ---: |",
	"| a | b | c |",
	"| longer | x | yy |",
	"",
	"| Link | b |",
	"| --- | --- |",
	"| [label](https://example.com) | x |",
	"",
	"| Wiki | b |",
	"| --- | --- |",
	"| [[page]] | x |",
	"",
	"| URL | b |",
	"| --- | --- |",
	"| <https://x.io> | x |",
	"",
	"| Escaped | Pipe | Code |",
	"| --- | --- | --- |",
	"| \\[literal\\] | \\| | ``a`b`` |",
	"",
	"| Ref | Collapsed | Shortcut | Image |",
	"| --- | --- | --- | --- |",
	"| [full][docs] | [collapsed][] | [shortcut] | ![alt][img] |",
	"",
	"| A | B |",
	"| --- | --- |",
	"| a | b |",
	"| longer | x | y |",
	"",
	"[docs]: https://example.com",
	"[collapsed]: https://example.com",
	"[shortcut]: https://example.com",
	"[img]: pic.png",
	"",
	"---",
	"",
	"[link](https://example.com)",
	"![img](pic.png)",
	"[[wiki]]",
	"<a@b.com>",
	"<https://x.io>",
	"",
	"> | A | Longer |",
	"> | --- | --- |",
	"> | x | y |",
	"",
	"- | A | Longer |",
	"  | --- | --- |",
	"  | x | y |",
	"",
	"| Whitespace | b |",
	"| --- | --- |",
	"| a\tb | x |",
	"",
	"| Nested | b |",
	"| --- | --- |",
	"| **bold _italic_** | x |",
	"| _italic_ **bold** | x |",
	"| **bold _italic_ tail** | x |",
	"",
	"| Entity | Html | b |",
	"| --- | --- | --- |",
	"| A &amp; B | <span>text</span> | x |",
	"",
	"| Break | Html | b |",
	"| --- | --- | --- |",
	"| Line<br>Break | <span>text</span> | x |",
	"| A<!-- hidden -->B | x | x |",
	"| Alt | <img alt=\"pic\" src=\"pic.png\"> | x |",
	"",
	"| A | B |",
	"| --- | --- |",
	"| 😀 | 猫 |",
	"| 猫猫 | x |",
	"| &#65; &#x42; | x |",
	"",
	"| A | B |",
	"| --- | --- |",
	"| Nested [link](https://x.io) label | x |",
	"",
	"| Strike | Nested |",
	"| --- | --- |",
	"| ~~gone~~ | **bold** |",
	"| ~~**both**~~ | _em_ |",
	"",
	"Name | Value",
	"--- | ---:",
	"a | 1",
	"longer | 22",
	"",
	"  A | B",
	"  --- | ---",
	"  x | y",
	"",
	"  C | D",
	"  --- | ---",
	" z | w",
	"",
	"| A | B |",
	"| --- | --- |",
	"| Line<br/>Break | x |",
	"| A<BR />B | y |",
	"",
	"| A | B |",
	"| --- | --- |",
	"| `a\tb` | x |",
}, path)

vim.cmd.edit(vim.fn.fnameescape(path))
vim.bo.filetype = "markdown"
vim.wo.conceallevel = 2

assert(vim.wait(5000, function()
	return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0
end), "no extmarks rendered")

local function move_to(row)
	vim.api.nvim_win_set_cursor(0, { row, 0 })
	vim.cmd("doautocmd CursorMoved")
	vim.wait(100)
end

local function overlay_on(row)
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
		if mark[2] == row and mark[4].virt_text_pos == "overlay" then
			return true
		end
	end
	return false
end

--- The overlay grid on a row of a named buffer. Not overlay_on, which reads
--- buffer 0: that is the scratch buffer the cursor sits in while the markdown
--- buffer is left on the other side of the split.
local function overlay_in(buf, row)
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
		if mark[2] == row and mark[4].virt_text_pos == "overlay" then
			return true
		end
	end
	return false
end

--- The grid border drawn above or below a row.
local function border_on(row)
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
		if mark[2] == row and mark[4].virt_lines then
			return true
		end
	end
	return false
end

-- The marks of a row, as one comparable string.
local function rows_snapshot(lo, hi)
	local out = {}
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, { lo, 0 }, { hi, -1 }, { details = true })) do
		out[#out + 1] = string.format("%d:%d:%s", mark[2], mark[3], (vim.inspect(mark[4]):gsub("%s+", " ")))
	end
	table.sort(out)
	return table.concat(out, "\n")
end

-- 'concealcursor' is empty, so the cursor line keeps its raw source and the grid
-- must not be drawn on top of it
move_to(16)
assert(not overlay_on(15), "grid is drawn over a cursor row whose source stays visible")

-- once the cursor line is concealed as well, the cursor row joins the grid
vim.wo.concealcursor = "nvic"
vim.cmd("doautocmd OptionSet concealcursor")
vim.wait(100)
assert(overlay_on(15), "grid does not update when concealcursor changes")

move_to(17)
move_to(16)
assert(overlay_on(15), "grid is missing on a cursor row that is concealed")
vim.wo.concealcursor = ""
vim.cmd("doautocmd OptionSet concealcursor")
vim.wait(100)
assert(not overlay_on(15), "grid remains after concealcursor stops concealing the cursor")

-- A selection over a rendered table. A cell covered by a conceal and an overlay
-- is never given the Visual highlight, so a grid drawn on a selected row hides
-- the selection entirely: on a real terminal, before this, every cell of a
-- selected table row wore the row highlight and none wore the Visual one. The
-- rows the selection reaches are drawn as source instead, the same rule the
-- cursor row follows, and a row outside the selection keeps its grid.
--
-- Entering and leaving a selection is a mode change, so this also covers the
-- ModeChanged render that puts the grids back.
move_to(16)
vim.api.nvim_win_set_cursor(0, { 14, 0 })
vim.cmd("normal! Vj")
assert(vim.api.nvim_get_mode().mode:sub(1, 1) == "V", "the linewise selection did not start, so the checks below are vacuous")
vim.wait(100)
assert(not overlay_on(13), "grid stays on a selected table header row")
assert(not overlay_on(14), "grid stays on a selected table delimiter row")
assert(not border_on(13), "the top border of a table with a selected header is still drawn")
assert(overlay_on(17), "a table outside the selection lost its grid")
vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
vim.wait(100)
assert(overlay_on(13), "the table grid does not come back when the selection ends")

-- The same rule for a code fence border, the other place a whole row is drawn
-- as an overlay over concealed source.
vim.api.nvim_win_set_cursor(0, { 10, 0 })
vim.cmd("normal! V")
vim.wait(100)
assert(not overlay_on(9), "fence border stays on a selected fence row")
vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
vim.wait(100)
-- the cursor is left on the fence row, and a cursor row is drawn as source too,
-- so the cursor moves off it before the border is looked for
move_to(20)
assert(overlay_on(9), "the fence border does not come back when the selection ends")
move_to(1)

-- A cursor move redraws the rows the cursor left and the row it is on, and
-- nothing else, so reading a document must not add marks to it. This is the
-- check that says so, and it is here because every assertion above is about the
-- cursor row: an implementation that cleared the namespace and redrew only the
-- cursor row would pass all of them and leave the document undrawn everywhere
-- else.
--
-- It counts rather than compares row by row, because a full render legitimately
-- moves a mark between two rows: the tables here draw a different cell grid
-- depending on where the cursor is, and the same two rows differ before and
-- after on the unmodified config as well. A duplicate does not cancel out that
-- way, it adds up, and one extra copy per key pressed is the failure this is
-- for. The first version compared row by row and failed on both versions of
-- markdown.lua, which is how the table behaviour was found rather than the bug.
-- A range is a pair of (row, col) tuples and not two numbers: a bare number
-- here is read as an extmark id, so the count of a row range asked for by number
-- is an error rather than a count.
local function mark_count(lo, hi)
	if lo then
		return #vim.api.nvim_buf_get_extmarks(0, ns, { lo, 0 }, { hi, -1 }, {})
	end
	return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
end

move_to(8)
local quiet = rows_snapshot(0, 0)
assert(quiet ~= "", "the heading has no marks, so the check below is vacuous")
local total_before = mark_count()
for row = 5, 11 do
	move_to(row)
end
assert(mark_count() == total_before, "a run of one-row cursor moves left " .. (mark_count() - total_before) .. " extra marks behind")
assert(rows_snapshot(0, 0) == quiet, "a cursor move changed the heading, which is not the row it was on")

-- A jump that crosses more rows than a cursor move redraws has to take the long
-- way round, or the rows it skipped are cleared and never drawn again.
local skipped_before = mark_count(3, 9)
assert(skipped_before > 0, "rows 3 to 9 have no marks to compare after the one-row moves")
move_to(70)
assert(mark_count(3, 9) > 0, "a jump cleared the rows it skipped and did not draw them again")
assert(rows_snapshot(0, 0) == quiet, "a jump changed the heading, which is not the row it was on")

-- Leaving a markdown buffer and coming back to it. The cursor row is drawn as
-- source text, so the row the cursor is on has to lose its grid on the way back
-- in. Without the WinEnter render the row keeps the grid it was drawn with, and
-- the cursor lands on a row of raw pipes inside an otherwise rendered table.
move_to(16)
assert(not overlay_on(15), "grid is drawn over a cursor row before leaving the buffer")
local md_win = vim.api.nvim_get_current_win()
local md_buf = vim.api.nvim_get_current_buf()
vim.cmd("vnew")
vim.cmd("enew")
vim.wait(100)
assert(overlay_in(md_buf, 15), "the row the cursor left is not drawn as a grid while the buffer has no cursor")
vim.api.nvim_set_current_win(md_win)
vim.wait(200)
assert(not overlay_in(md_buf, 15), "grid stays over the cursor row after coming back to the buffer")
move_to(1)

local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })

local function virt_has(d, key, s)
	for _, line in ipairs(key == "virt_text" and { d.virt_text or {} } or d.virt_lines or {}) do
		for _, chunk in ipairs(line) do
			if tostring(chunk[1]):find(s, 1, true) then
				return true
			end
		end
	end
	return false
end

local function has(pred, what)
	for _, m in ipairs(marks) do
		if pred(m[4], m[2]) then
			return m
		end
	end
	error("no extmark: " .. what)
end

has(function(d)
	return d.conceal == "󰲡" and d.line_hl_group == "RenderMarkdownH1Bg" and d.sign_text ~= nil
end, "heading icon + background + sign")
has(function(d)
	return d.conceal == "●"
end, "bullet")
has(function(d)
	return d.conceal == "󰄱" and d.end_col == 5
end, "unchecked checkbox")
has(function(d)
	return d.conceal == "󰱒" and d.end_col == 5
end, "checked checkbox")
has(function(d)
	return d.conceal == "▋"
end, "quote bar")
has(function(d)
	return virt_has(d, "virt_text", "Note")
end, "callout title")
has(function(d, row)
	return row == 10 and d.line_hl_group == "RenderMarkdownCode"
end, "code line background")
has(function(d, row)
	return row == 9 and d.virt_text_pos == "overlay" and virt_has(d, "virt_text", "lua")
end, "code language label")
has(function(d, row)
	return row == 11 and d.virt_text_pos == "overlay" and virt_has(d, "virt_text", "▀")
end, "code bottom border")
for _, m in ipairs(marks) do
	if m[2] >= 9 and m[2] <= 11 then
		assert(m[4].virt_lines == nil, "code fences must not add virtual lines")
	end
end
has(function(d, row)
	return row == 52 and d.virt_text_pos == "overlay" and virt_has(d, "virt_text", "─")
end, "horizontal rule")
local function row_text(row)
	for _, m in ipairs(marks) do
		local d = m[4]
		if m[2] == row and d.virt_text_pos == "overlay" and d.virt_text then
			return d.virt_text[1][1]
		end
	end
end
assert(row_text(14) == "├─────┼────┤", "table columns are not aligned")
assert(row_text(15) == "│ 1   │ 2  │", "table row is not aligned")
assert(row_text(13) == "│ a_b │ bb │", "table header is not aligned")
assert(row_text(18) == "├────────┼───┼────┤", "table alignment markers are not aligned")
assert(row_text(19) == "│ a      │ b │  c │", "table alignment is not applied")
assert(row_text(20) == "│ longer │ x │ yy │", "table alignment row is not aligned")
assert(row_text(24) == "│ label │ x │", "link cell is not aligned")
for _, m in ipairs(marks) do
	assert(m[2] ~= 24 or not virt_has(m[4], "virt_text", "󰖟"), "link icon overlaps table row")
end
assert(row_text(28) == "│ page │ x │", "wiki cell is not aligned")
for _, m in ipairs(marks) do
	assert(m[2] ~= 28 or not virt_has(m[4], "virt_text", "󱗖"), "wiki icon overlaps table row")
end
assert(row_text(32) == "│ https://x.io │ x │", "autolink cell is not aligned")
for _, m in ipairs(marks) do
	assert(m[2] ~= 32 or not virt_has(m[4], "virt_text", "󰖟"), "autolink icon overlaps table row")
end
assert(row_text(36) == "│ [literal] │ |    │ a`b  │", "escaped or code-span syntax is not rendered as plain text")
assert(row_text(40) == "│ full │ collapsed │ shortcut │ alt   │", "reference link cells are not aligned")
assert(row_text(44) == "│ a      │ b │", "ragged row is not aligned")
assert(row_text(45) == "│ longer │ x │", "ragged row is not aligned")
assert(row_text(61) == "├───┼────────┤", "nested table delimiter is not aligned")
assert(row_text(62) == "│ x │ y      │", "nested table row is not aligned")
assert(row_text(70) == "│ a b        │ x │", "tab whitespace shifts table cell")
assert(row_text(74) == "│ bold italic      │ x │", "nested emphasis markers remain visible")
assert(row_text(75) == "│ italic bold      │ x │", "leading nested emphasis is not rendered")
assert(row_text(76) == "│ bold italic tail │ x │", "nested emphasis with tail is not rendered")
assert(row_text(80) == "│ A & B  │ text │ x │", "HTML entity or tag is not rendered as table text")
assert(row_text(84) == "│ Line Break │ text │ x │", "HTML line break joins cell text")
assert(row_text(85) == "│ A B        │ x    │ x │", "HTML comment remains visible")
assert(row_text(86) == "│ Alt        │ pic  │ x │", "HTML image alt text is missing")
assert(row_text(89) == "├──────┼────┤", "wide Unicode table delimiter is not aligned")
assert(row_text(90) == "│ 😀   │ 猫 │", "emoji cell is not aligned")
assert(row_text(91) == "│ 猫猫 │ x  │", "double-width cell is not aligned")
assert(row_text(92) == "│ A B  │ x  │", "decimal or hexadecimal HTML entity is decoded incorrectly")
assert(row_text(96) == "│ Nested link label │ x │", "nested brackets remain visible in a link label")
assert(row_text(100) == "│ gone   │ bold   │", "strikethrough or emphasis markers remain visible")
assert(row_text(101) == "│ both   │ em     │", "nested strikethrough markers remain visible")
assert(row_text(103) == "│ Name   │ Value │", "borderless table header is not aligned")
assert(row_text(104) == "├────────┼───────┤", "borderless table delimiter is not aligned")
assert(row_text(105) == "│ a      │     1 │", "borderless table row is not aligned")
assert(row_text(106) == "│ longer │    22 │", "borderless table alignment is not applied")
assert(row_text(109) == "├───┼───┤", "indented table delimiter is not aligned")
assert(row_text(110) == "│ x │ y │", "indented table row is not aligned")
assert(row_text(114) == "│ z │ w │", "table row with less indentation is not aligned")
assert(row_text(118) == "│ Line Break │ x │", "self-closing HTML break joins cell text")
assert(row_text(119) == "│ A B        │ y │", "uppercase spaced HTML break joins cell text")
assert(row_text(123) == "│ a b │ x │", "tab in code span shifts table cell")
for _, m in ipairs(marks) do
	local d = m[4]
	local table_mark = d.virt_lines ~= nil
		or (d.virt_text ~= nil and d.virt_text_pos == "overlay")
		or (d.conceal == "" and d.hl_group:match("^RenderMarkdownTable"))
	if table_mark and (m[2] == 113 or m[2] == 114) then
		assert(m[3] == 2, "table rows use inconsistent indentation anchors")
	end
end
for _, m in ipairs(marks) do
	local d = m[4]
	local table_mark = d.virt_lines ~= nil
		or (d.virt_text ~= nil and d.virt_text_pos == "overlay")
		or (d.conceal == "" and d.hl_group:match("^RenderMarkdownTable"))
	if table_mark and (m[2] == 108 or m[2] == 109 or m[2] == 110) then
		assert(m[3] == 2, "indented table overlay replaces source indentation")
	end
end
for _, m in ipairs(marks) do
	local d = m[4]
	local table_mark = d.virt_lines ~= nil
		or (d.virt_text ~= nil and d.virt_text_pos == "overlay")
		or (d.conceal == "" and d.hl_group:match("^RenderMarkdownTable"))
	if table_mark and (m[2] == 60 or m[2] == 61 or m[2] == 62) then
		assert(m[3] == 2, "nested table extmark replaces quote prefix")
	end
end
assert(row_text(65) == "├───┼────────┤", "list table delimiter is not aligned")
assert(row_text(66) == "│ x │ y      │", "list table row is not aligned")
for _, m in ipairs(marks) do
	local d = m[4]
	local table_mark = d.virt_lines ~= nil
		or (d.virt_text ~= nil and d.virt_text_pos == "overlay")
		or (d.conceal == "" and d.hl_group:match("^RenderMarkdownTable"))
	if table_mark and (m[2] == 64 or m[2] == 65 or m[2] == 66) then
		assert(m[3] == 2, "list table extmark replaces list prefix")
	end
end

has(function(d)
	return d.virt_lines_above and virt_has(d, "virt_lines", "┌")
end, "table top border")
has(function(d)
	return not d.virt_lines_above and virt_has(d, "virt_lines", "└")
end, "table bottom border")
has(function(d)
	return virt_has(d, "virt_text", "󰖟")
end, "http link icon")
has(function(d)
	return virt_has(d, "virt_text", "󰥶")
end, "image link icon")
has(function(d)
	return virt_has(d, "virt_text", "󱗖")
end, "wiki link icon")
has(function(d)
	return virt_has(d, "virt_text", "󰀓")
end, "email link icon")

for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
	if map.desc == "Toggle render markdown" and map.callback then
		map.callback()
		break
	end
end
assert(#vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) == 0, "toggle did not clear marks")

print("markdown tests passed")
'

output=$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$PWD" -c "lua $SCRIPT" -c 'qa!' 2>&1) || {
	printf '%s\n' "$output"
	exit 1
}
printf '%s\n' "$output"
if [[ "$output" == *"Error in command line:"* || "$output" == *"E5108:"* ]]; then
	exit 1
fi
