local api = vim.api
local npcall = require("config.compat")
local ns = api.nvim_create_namespace("md-render")
local enabled = true

local hl_links = {
	H1 = "@markup.heading.1.markdown",
	H2 = "@markup.heading.2.markdown",
	H3 = "@markup.heading.3.markdown",
	H4 = "@markup.heading.4.markdown",
	H5 = "@markup.heading.5.markdown",
	H6 = "@markup.heading.6.markdown",
	H1Bg = "DiffText",
	H2Bg = "DiffAdd",
	H3Bg = "DiffChange",
	H4Bg = "DiffDelete",
	H5Bg = "Visual",
	H6Bg = "CursorColumn",
	Code = "ColorColumn",
	CodeInfo = "@label",
	Bullet = "Normal",
	Dash = "LineNr",
	Quote = "@markup.quote",
	Link = "@markup.link.label.markdown_inline",
	WikiLink = "RenderMarkdownLink",
	Unchecked = "@markup.list.unchecked",
	Checked = "@markup.list.checked",
	Todo = "@markup.raw",
	TableHead = "@markup.heading",
	TableRow = "Normal",
	Success = "DiagnosticOk",
	Info = "DiagnosticInfo",
	Hint = "DiagnosticHint",
	Warn = "DiagnosticWarn",
	Error = "DiagnosticError",
}

local function set_hls()
	for name, link in pairs(hl_links) do
		api.nvim_set_hl(0, "RenderMarkdown" .. name, { link = link, default = true })
	end
	-- borders are drawn with half blocks in the code background color
	local code = api.nvim_get_hl(0, { name = "RenderMarkdownCode", link = false })
	api.nvim_set_hl(0, "RenderMarkdownCodeBorder", { fg = code.bg })
end

local heading_icons = { "󰲡", "󰲣", "󰲥", "󰲧", "󰲩", "󰲫" }
local heading_sign = "󰫎"
local bullets = { "●", "○", "◆", "◇" }
local checkboxes = {
	[" "] = { "󰄱", "RenderMarkdownUnchecked" },
	x = { "󰱒", "RenderMarkdownChecked" },
	X = { "󰱒", "RenderMarkdownChecked" },
	["-"] = { "󰥔", "RenderMarkdownTodo" },
}
-- key -> { icon, highlight suffix }, the title is the capitalized key
local callouts = {
	note = { "󰋽", "Info" },
	tip = { "󰌶", "Success" },
	important = { "󰅾", "Hint" },
	warning = { "󰀪", "Warn" },
	caution = { "󰳦", "Error" },
	abstract = { "󰨸", "Info" },
	summary = { "󰨸", "Info" },
	tldr = { "󰨸", "Info" },
	info = { "󰋽", "Info" },
	todo = { "󰗡", "Info" },
	hint = { "󰌶", "Success" },
	success = { "󰄬", "Success" },
	check = { "󰄬", "Success" },
	done = { "󰄬", "Success" },
	question = { "󰘥", "Warn" },
	help = { "󰘥", "Warn" },
	faq = { "󰘥", "Warn" },
	attention = { "󰀪", "Warn" },
	failure = { "󰅖", "Error" },
	fail = { "󰅖", "Error" },
	missing = { "󰅖", "Error" },
	danger = { "󱐌", "Error" },
	error = { "󱐌", "Error" },
	bug = { "󰨰", "Error" },
	example = { "󰉹", "Hint" },
	quote = { "󱆨", "Quote" },
	cite = { "󱆨", "Quote" },
}
-- first match on the link destination wins
local link_icons = {
	{ "youtube%.com", "󰗃 " },
	{ "github%.com", "󰊤 " },
	{ "neovim%.io", "NEOVIM_ICON" },
	{ "stackoverflow%.com", "󰓌 " },
	{ "discord%.com", "󰙯 " },
	{ "reddit%.com", "󰑍 " },
	{ "^http", "󰖟 " },
}
local link_default = "󰌹 "
local link_image = "󰥶 "
local link_email = "󰀓 "
local link_wiki = "󱗖 "

local queries = nil
local function get_queries()
	if queries == nil then
		local ok_md, md = pcall(
			vim.treesitter.query.parse,
			"markdown",
			[[
			(atx_heading) @heading
			(fenced_code_block) @code
			(thematic_break) @dash
			[(list_marker_minus) (list_marker_plus) (list_marker_star)] @bullet
			(block_quote) @quote
			(pipe_table) @table
			]]
		)
		local ok_inline, inline = pcall(
			vim.treesitter.query.parse,
			"markdown_inline",
			[[
			[(inline_link) (full_reference_link) (image) (email_autolink) (uri_autolink)] @link
			(shortcut_link) @wiki
			]]
		)
		queries = { markdown = ok_md and md or nil, markdown_inline = ok_inline and inline or nil }
	end
	return queries
end

-- Disabling the query patterns that set `conceal_lines` keeps the fence rows
-- addressable while their borders are drawn in place.
--
-- Compiling the markdown highlights query costs 4.3ms on this machine, which
-- is a tenth of the whole startup of this config, and none of it is wanted
-- until a markdown buffer exists. So it is compiled on the first markdown
-- FileType instead of at load, and that is early enough to matter: config is
-- required before plugins in init.lua, so this handler runs before
-- plugins.treesitter's own FileType handler creates the highlighter for the
-- same buffer, and a disabled pattern only takes effect for a highlighter that
-- has not read the query yet.
--
-- The result is remembered because the query object is shared, so a second
-- walk would find nothing left to disable and report false.
local fence_conceal_disabled

local function fence_conceal_off()
	if fence_conceal_disabled ~= nil then
		return fence_conceal_disabled
	end
	local ok, query = pcall(vim.treesitter.query.get, "markdown", "highlights")
	if not ok or not query then
		return false
	end
	local total = 0
	for pattern, directives in pairs(query.info.patterns) do
		if vim.iter(directives):any(function(meta)
			return meta[1] == "set!" and meta[2] == "conceal_lines"
		end) then
			total = total + 1
			npcall(query.query.disable_pattern, query.query, pattern)
		end
	end
	fence_conceal_disabled = total > 0
	return fence_conceal_disabled
end

local function line(ctx, row)
	local text = ctx.lines[row]
	if not text then
		text = api.nvim_buf_get_lines(ctx.buf, row, row + 1, false)[1] or ""
		ctx.lines[row] = text
	end
	return text
end

local function mark(ctx, row, col, opts)
	-- A span render repaints the rows it was asked about and no others, so a mark
	-- outside them is dropped rather than written. Without this a block quote
	-- that starts on the cursor row is handed back whole and redraws its bar
	-- down all twenty rows it spans, once per cursor move, and extmarks are not
	-- deduplicated: reading a document would grow a copy of it per key pressed.
	-- The rows outside the span keep what the last full render gave them, which
	-- is right, because what a handler draws on a row comes from that row's own
	-- nodes and does not depend on where the cursor is.
	if ctx.top and (row < ctx.top or row > ctx.bot) then
		return
	end
	opts.strict = false
	npcall(api.nvim_buf_set_extmark, ctx.buf, ns, row, col, opts)
end

local function conceal(ctx, row, col, len, char, hl)
	mark(ctx, row, col, { end_col = col + len, conceal = char, hl_group = hl })
end

---@return boolean selected true when the selection reaches this row
local function row_is_selected(ctx, row)
	return ctx.selection ~= nil and row >= ctx.selection[1] and row <= ctx.selection[2]
end

-- Last row a block node covers: block nodes end at column 0 of the next row.
local function last_row(node)
	local _, _, erow, ecol = node:range()
	return ecol == 0 and erow - 1 or erow
end

local function depth(node, type)
	local n, p = 0, node:parent()
	while p do
		if p:type() == type then
			n = n + 1
		end
		p = p:parent()
	end
	return n
end

---The icon for a language, and nil when the plugin is not loaded yet.
local function devicon(lang)
	local devicons = npcall(require, "nvim-web-devicons")
	return devicons and devicons.get_icon_by_filetype(vim.filetype.match({ filename = "a." .. lang }) or lang)
end

local handlers = {}

function handlers.heading(ctx, node)
	local row, col = node:start()
	local marker = node:child(0)
	local level = marker and tonumber(marker:type():match("^atx_h(%d)_marker$"))
	if not level then
		return
	end
	local hl = "RenderMarkdownH" .. level
	mark(ctx, row, col, {
		end_col = col + level,
		conceal = heading_icons[level],
		hl_group = hl,
		line_hl_group = hl .. "Bg",
		sign_text = heading_sign,
		sign_hl_group = hl,
	})
end

function handlers.code(ctx, node)
	local srow = node:start()
	local erow = last_row(node)
	local lang
	for child in node:iter_children() do
		if child:type() == "info_string" and child:named_child(0) then
			lang = vim.treesitter.get_node_text(child:named_child(0), ctx.buf)
		end
	end
	local last = node:named_child(node:named_child_count() - 1)
	local closed = last ~= nil and last:type() == "fenced_code_block_delimiter" and last:start() > srow
	if lang ~= "diff" then
		for row = srow, erow do
			mark(ctx, row, 0, { line_hl_group = "RenderMarkdownCode" })
		end
	end
	if not ctx.conceal or not fence_conceal_off() then
		return
	end

	local width = math.max(ctx.width, 0)
	if width == 0 then
		return
	end
	local function border(row, chunks)
		if ctx.cur == row or row_is_selected(ctx, row) then
			return
		end
		conceal(ctx, row, 0, #line(ctx, row), "", "RenderMarkdownCode")
		mark(ctx, row, 0, { virt_text = chunks, virt_text_pos = "overlay", hl_mode = "replace" })
	end

	if ctx.cur ~= srow then
		local chunks
		if lang then
			local icon, icon_hl = devicon(lang)
			local label = " " .. (icon and icon .. " " or "") .. lang
			chunks = {
				{ "▄", "RenderMarkdownCodeBorder" },
				{ label, { "RenderMarkdownCode", icon_hl or "RenderMarkdownCodeInfo" } },
				{
					string.rep("▄", math.max(width - 1 - vim.fn.strdisplaywidth(label), 0)),
					"RenderMarkdownCodeBorder",
				},
			}
		else
			chunks = { { string.rep("▄", width), "RenderMarkdownCodeBorder" } }
		end
		border(srow, chunks)
	end
	if closed and ctx.cur ~= erow then
		border(erow, { { string.rep("▀", width), "RenderMarkdownCodeBorder" } })
	end
end

function handlers.dash(ctx, node)
	local row, col = node:start()
	if row == ctx.cur then
		return
	end
	mark(ctx, row, col, {
		virt_text = { { string.rep("─", ctx.width - col), "RenderMarkdownDash" } },
		virt_text_pos = "overlay",
	})
end

function handlers.bullet(ctx, node)
	local row, col = node:start()
	local _, mend = node:end_()
	local text = line(ctx, row)
	-- task box right after the marker: "- [ ] ", "- [x] ", "- [-] ";
	-- the marker node can include trailing spaces
	local rest = text:sub(mend + 1)
	local bs, be, key = rest:find("%[(.)%]")
	local box = checkboxes[key or ""]
	local after = be and rest:sub(be + 1, be + 1)
	if box and bs and rest:sub(1, bs - 1):match("^%s*$") and (after == "" or after == " ") then
		return conceal(ctx, row, col, mend + be - col, box[1], box[2])
	end
	local level = depth(node, "list")
	conceal(ctx, row, col, 1, bullets[(level - 1) % #bullets + 1], "RenderMarkdownBullet")
end

function handlers.quote(ctx, node)
	local srow, erow = node:start(), last_row(node)
	local level = depth(node, "block_quote") + 1
	local hl = "RenderMarkdownQuote"
	local first = line(ctx, srow)
	local prefix, key = first:match("^([%s>]*)%[!(%a+)%]")
	local callout = key and callouts[key:lower()]
	if callout then
		hl = "RenderMarkdown" .. callout[2]
		conceal(ctx, srow, #prefix, #key + 3, "", hl)
		if srow ~= ctx.cur then
			local title = key:sub(1, 1):upper() .. key:sub(2):lower()
			mark(ctx, srow, #prefix, { virt_text = { { callout[1] .. " " .. title, hl } }, virt_text_pos = "inline" })
		end
	end
	-- replace the ">" belonging to this quote level on every row
	for row = srow, erow do
		local n = 0
		for col in line(ctx, row):match("^[%s>]*"):gmatch("()>") do
			n = n + 1
			if n == level then
				conceal(ctx, row, col - 1, 1, "▋", hl)
				break
			end
		end
	end
end

local function strip_boundary_marker(s, marker)
	while s:sub(1, #marker) == marker do
		s = s:sub(#marker + 1)
	end
	while #s >= #marker and s:sub(-#marker) == marker do
		s = s:sub(1, -#marker - 1)
	end
	return s
end

local function strip_paired_marker(s, marker)
	local pattern = vim.pesc(marker)
	local previous
	repeat
		previous = s
		s = s:gsub(pattern .. "([^%s].-)" .. pattern, "%1")
	until s == previous
	return s
end

local function protect_code_spans(s, escaped)
	local parts, pos = {}, 1
	while true do
		local first, last = s:find("`+", pos)
		if not first then
			parts[#parts + 1] = s:sub(pos)
			break
		end
		parts[#parts + 1] = s:sub(pos, first - 1)
		local fence = s:sub(first, last)
		local close_start, close_end = s:find(fence, last + 1, true)
		if not close_start then
			parts[#parts + 1] = s:sub(first)
			break
		end
		escaped[#escaped + 1] = s:sub(last + 1, close_start - 1)
		parts[#parts + 1] = "\1" .. #escaped .. "\2"
		pos = close_end + 1
	end
	return table.concat(parts)
end

local function decode_html_entities(s)
	local named = {
		amp = "&",
		apos = "'",
		gt = ">",
		lt = "<",
		nbsp = " ",
		quot = '"',
	}
	return (
		s:gsub("&([^;]+);", function(entity)
			local hex = entity:match("^#[xX](%x+)$")
			local decimal = entity:match("^#(%d+)$")
			local code = hex and tonumber(hex, 16) or decimal and tonumber(decimal, 10)
			if code then
				local ok, char = pcall(vim.fn.nr2char, code, 1)
				return ok and char or "&" .. entity .. ";"
			end
			return named[entity] or ("&" .. entity .. ";")
		end)
	)
end

-- Convert a Markdown cell to the text shown by the renderer.
local function plain_text(s)
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	local escaped = {}
	local escape_count = 0
	s = s:gsub("\\(.)", function(char)
		escape_count = escape_count + 1
		escaped[escape_count] = char
		return "\1" .. escape_count .. "\2"
	end)
	s = protect_code_spans(s, escaped)
	s = s:gsub("%s+", " ")
	s = s:gsub("!?%[([^%]]*)%]%b()", "%1")
	s = s:gsub("%[%[([^%]]+)%]%]", "%1")
	s = s:gsub("!?%[([^%]]*)%]%[([^%]]*)%]", "%1")
	s = s:gsub("!?%[([^%]]*)%]", "%1")
	s = s:gsub("<!--.-%-%->", " ")
	s = s:gsub("<([^<>]+)>", function(inner)
		if inner:match("^%a[%w+.-]*://") or inner:match("^[^%s@]+@[^%s@]+$") then
			return inner
		end
		if inner:match("^%s*img%s") then
			return inner:match('^%s*img%s+.-alt%s*=%s*"([^"]*)"') or inner:match("^%s*img%s+.-alt%s*=%s*'([^']*)'") or ""
		end
		return inner:lower():match("^%s*br%s*/?%s*$") and " " or ""
	end)
	s = decode_html_entities(s)
	for _, marker in ipairs({ "*", "_", "~~" }) do
		s = strip_paired_marker(s, marker)
		s = strip_boundary_marker(s, marker)
	end
	s = s:gsub("\1(%d+)\2", function(index)
		return escaped[tonumber(index)]
	end)
	return (s:gsub("\t", " "))
end

local function visible_width(s)
	return vim.fn.strdisplaywidth(plain_text(s))
end

local function cell_alignment(cell, buf)
	local text = vim.treesitter.get_node_text(cell, buf)
	if text:match(":%s*$") then
		return text:match("^%s*:") and "center" or "right"
	end
	return "left"
end

---A cell padded to its column width. The rendered text is made once and
---measured from that, rather than stripping the markers a second time to measure
---what was just stripped.
local function pad_cell(text, width, alignment)
	local cell = plain_text(text)
	local pad = math.max(width - vim.fn.strdisplaywidth(cell), 0)
	local left, right
	if alignment == "right" then
		left, right = pad, 0
	elseif alignment == "center" then
		left = math.floor(pad / 2)
		right = pad - left
	else
		left, right = 0, pad
	end
	return (" "):rep(left) .. cell .. (" "):rep(right)
end

function handlers.table(ctx, node)
	local rows = {}
	for child in node:iter_children() do
		local type = child:type()
		if type == "pipe_table_header" or type == "pipe_table_delimiter_row" or type == "pipe_table_row" then
			local cells, alignments = {}, {}
			for cell in child:iter_children() do
				if cell:type() == "pipe_table_cell" or cell:type() == "pipe_table_delimiter_cell" then
					cells[#cells + 1] = vim.treesitter.get_node_text(cell, ctx.buf)
					if type == "pipe_table_delimiter_row" then
						alignments[#alignments + 1] = cell_alignment(cell, ctx.buf)
					end
				end
			end
			local row, col = child:start()
			col = math.max(col, line(ctx, row):match("^%s*"):len())
			rows[#rows + 1] = { row = row, col = col, type = type, cells = cells, alignments = alignments }
		end
	end
	if #rows == 0 then
		return
	end

	-- A table is renderable when its header has at least one cell. Outer pipes are
	-- optional in Markdown, so they must not decide whether columns can align.
	local column_count = #rows[1].cells
	local widths = {}
	for _, r in ipairs(rows) do
		if r.type ~= "pipe_table_delimiter_row" then
			for i, cell in ipairs(r.cells) do
				if i <= column_count then
					widths[i] = math.max(widths[i] or 0, visible_width(cell))
				end
			end
		end
	end
	if column_count == 0 or not ctx.conceal then
		return
	end
	local table_col = rows[1].col
	---The first row that says how its columns line up decides for the table.
	local alignments = {}
	for _, r in ipairs(rows) do
		if r.alignments[1] then
			alignments = r.alignments
			break
		end
	end
	ctx.table_rows = ctx.table_rows or {}
	for _, r in ipairs(rows) do
		ctx.table_rows[r.row] = true
	end
	---A ruled line of box drawing: a piece, the run of every column, a closing piece.
	local function ruled(left, mid, right)
		local parts = {}
		for i, width in ipairs(widths) do
			parts[i] = string.rep("─", width + 2)
		end
		return left .. table.concat(parts, mid) .. right
	end

	---The grid line that replaces one row of the table.
	local function row_text(r)
		if r.type == "pipe_table_delimiter_row" then
			return ruled("├", "┼", "┤")
		end
		local pieces = { "│" }
		for i, width in ipairs(widths) do
			pieces[#pieces + 1] = " " .. pad_cell(r.cells[i] or "", width, alignments[i] or "left") .. " │"
		end
		return table.concat(pieces)
	end

	for _, r in ipairs(rows) do
		-- the grid replaces the source text, so it is only safe on the cursor line
		-- when 'concealcursor' hides that line as well, and never on a line a
		-- selection reaches, because the grid would hide the selection
		if ctx.conceal and (r.row ~= ctx.cur or ctx.conceal_cur) and not row_is_selected(ctx, r.row) then
			local group = r.type == "pipe_table_row" and "RenderMarkdownTableRow" or "RenderMarkdownTableHead"
			local text = line(ctx, r.row)
			conceal(ctx, r.row, table_col, #text - table_col, "", group)
			mark(ctx, r.row, table_col, {
				virt_text = { { row_text(r), group } },
				virt_text_pos = "overlay",
				hl_mode = "replace",
			})
		end
	end

	-- the border belongs to the row it is drawn against, so a selected row
	-- takes its border with it rather than framing a line of source text
	if not row_is_selected(ctx, rows[1].row) then
		mark(
			ctx,
			rows[1].row,
			table_col,
			{ virt_lines = { { { ruled("┌", "┬", "┐"), "RenderMarkdownTableHead" } } }, virt_lines_above = true }
		)
	end
	if not row_is_selected(ctx, rows[#rows].row) then
		mark(
			ctx,
			rows[#rows].row,
			table_col,
			{ virt_lines = { { { ruled("└", "┴", "┘"), "RenderMarkdownTableRow" } } } }
		)
	end
end

function handlers.link(ctx, node)
	local row, col = node:start()
	if row == ctx.cur or (ctx.table_rows and ctx.table_rows[row]) then
		return
	end
	local type, icon = node:type(), link_default
	if type == "image" then
		icon = link_image
	elseif type == "email_autolink" then
		icon = link_email
	else
		local dest = node
		for child in node:iter_children() do
			if child:type() == "link_destination" then
				dest = child
			end
		end
		local url = vim.treesitter.get_node_text(dest, ctx.buf):gsub("^<", "")
		for _, custom in ipairs(link_icons) do
			if url:find(custom[1]) then
				icon = custom[2]
				break
			end
		end
	end
	mark(ctx, row, col, { virt_text = { { icon, "RenderMarkdownLink" } }, virt_text_pos = "inline" })
end

-- [[page]] parses as a shortcut link wrapped in one more pair of brackets
function handlers.wiki(ctx, node)
	local row, col = node:start()
	if ctx.table_rows and ctx.table_rows[row] then
		return
	end
	local _, ecol = node:end_()
	local text = line(ctx, row)
	if col == 0 or text:sub(col, col) ~= "[" or text:sub(ecol + 1, ecol + 1) ~= "]" then
		return
	end
	conceal(ctx, row, col - 1, 1, "", "RenderMarkdownWikiLink")
	conceal(ctx, row, ecol, 1, "", "RenderMarkdownWikiLink")
	if row ~= ctx.cur then
		mark(ctx, row, col - 1, { virt_text = { { link_wiki, "RenderMarkdownWikiLink" } }, virt_text_pos = "inline" })
	end
end

---The letter 'concealcursor' and the renderer both spell a selection with: all
---four selection modes share "v", and select mode (^S, ^O) is a selection too.
---@return string|nil the letter, or nil when the mode is not a selection
local function selection_mode()
	local mode = api.nvim_get_mode().mode
	if mode == "\19" or mode == "\20" then
		return "v"
	end
	local first = mode:sub(1, 1)
	return first:find("[vV\22sS]") and "v" or nil
end

-- The rows a visual or select mode selection covers, 0 indexed, or nil when no
-- selection is active. A selection is anchored at the 'v mark and ends at the
-- cursor, whichever order they are in; 'v' is unset outside a selection, and
-- then line() answers 0.
--
-- This is what makes a selection visible at all: a cell covered by a conceal
-- extmark and an overlay is never given the Visual highlight, so a rendered
-- row hides the selection drawn over it. Measured on a table, every cell of a
-- selected row wore the row highlight and none the Visual one, while the plain
-- lines around it showed the selection. Nothing on the extmark recovers it:
-- hl_mode = "combine" on the overlay and dropping the highlight from the
-- conceal both leave the row exactly as it was. The row has to be drawn as
-- source, which is what the cursor row already does.
---@return integer[]? rows the first and last selected row, 0 indexed
local function selected_rows()
	if not selection_mode() then
		return nil
	end
	local anchor = vim.fn.line("v")
	if anchor == 0 then
		return nil
	end
	local cur = api.nvim_win_get_cursor(0)[1]
	return { math.min(anchor, cur) - 1, math.max(anchor, cur) - 1 }
end

-- 'concealcursor' lists the modes in which the cursor line is concealed too
local function conceals_cursor_line(win)
	local cocu = vim.wo[win].concealcursor
	if cocu == "" then
		return false
	end
	local selected = selection_mode()
	local mode = selected or api.nvim_get_mode().mode:sub(1, 1)
	return cocu:find(mode, 1, true) ~= nil
end

-- A cursor move changes the drawing of the two rows the cursor was on and is on,
-- and of no other row: every handler here decides what to draw on a row from
-- that row's own nodes, and from whether the row is the cursor row (ctx.cur).
-- Everything else in the window is already drawn the way it should be, so
-- clearing the namespace and walking the whole visible range again is work for
-- nothing. Measured in .auto/md_render_shape.lua, a cursor move in a document
-- costs 2.2 to 3.0ms and almost all of it is the capture iteration
-- (.auto/md_render_parts.lua: iter_captures 2.17ms, parse 0.03ms, getwininfo
-- 0.08ms, clear_namespace 0.002ms), over a range of about 220 rows.
--
-- So the range and the cleared rows are both the span the cursor crossed, which
-- is one row for a key held down and whatever :from and % the user typed for a
-- jump. A jump that crosses more rows than this goes the long way round, because
-- clearing a hundred rows and redrawing only the two ends of them would leave
-- the hundred unmarked.
local CURSOR_RENDER_SPAN = 8

-- The two halves of a render, so both callers walk the tree the same way: build
-- the context for the window showing the buffer, then run every handler over
-- the captures that touch [top, bot].
local function draw(parser, buf, top, bot, ctx)
	local qs = get_queries()
	parser:for_each_tree(function(tree, ltree)
		local query = qs[ltree:lang()]
		local root = tree:root()
		local srow, _, erow = root:range()
		if not query or erow < top or srow > bot then
			return
		end
		for id, node in query:iter_captures(root, buf, top, bot) do
			npcall(handlers[query.captures[id]], ctx, node)
		end
	end)
end

---@return integer? win the window the cursor row is read from, or nil when the
---buffer is not on screen
---@return integer[] wins every window the buffer is on screen in, empty when
---there is no win
local function window_of(buf)
	local wins = vim.fn.win_findbuf(buf)
	if not enabled or #wins == 0 then
		return nil, {}
	end
	local cur_win = api.nvim_get_current_win()
	return vim.tbl_contains(wins, cur_win) and cur_win or wins[1], wins
end

local function context(buf, win)
	local info = vim.fn.getwininfo(win)[1]
	local cur_win = api.nvim_get_current_win()
	return {
		buf = buf,
		lines = {},
		cur = win == cur_win and api.nvim_win_get_cursor(win)[1] - 1 or -1,
		selection = win == cur_win and selected_rows() or nil,
		width = info.width - info.textoff,
		conceal = vim.wo[win].conceallevel > 0,
		conceal_cur = win == cur_win and conceals_cursor_line(win),
	}
end

local function render(buf)
	if not api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
		return
	end
	api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local win, wins = window_of(buf)
	if not win then
		return
	end
	local parser = vim.treesitter.get_parser(buf, "markdown", { error = false })
	if not parser then
		return
	end
	-- only the visible rows of every window showing the buffer, plus a margin
	local top, bot = math.huge, 0
	for _, w in ipairs(wins) do
		local info = vim.fn.getwininfo(w)[1]
		top, bot = math.min(top, info.topline - 1), math.max(bot, info.botline)
	end
	top, bot = math.max(top - 100, 0), bot + 100
	parser:parse({ top, bot })
	draw(parser, buf, top, bot, context(buf, win))
end

-- The rows between the two cursor positions, drawn again, and nothing else.
--
-- Cleared and drawn directly rather than through a scratch namespace: the clip in
-- mark() is what keeps a handler from writing outside the span, and the
-- alternative (draw into a scratch namespace, read the marks back and copy them
-- over) needs the read-back details to be valid set_extmark options, and they
-- are not: get_extmarks returns ns_id, virt_text_hide and virt_text_repeat_linebreak,
-- which set_extmark rejects, and the pcall that hid that from the first version
-- is why it looked like nothing was drawn.
local function render_span(buf, from, to)
	local win = window_of(buf)
	if not win then
		return
	end
	local parser = vim.treesitter.get_parser(buf, "markdown", { error = false })
	if not parser then
		return
	end
	local lo, hi = math.min(from, to), math.max(from, to)
	local ctx = context(buf, win)
	ctx.top, ctx.bot = lo, hi
	api.nvim_buf_clear_namespace(buf, ns, lo, hi + 1)
	draw(parser, buf, lo, hi, ctx)
end

local pending_timers = {}
local pending_scheduled = {}
local pending_spans = {}

-- A cursor move that crossed only a few rows, held until the next tick like a
-- full render is, so a key held down does one render per tick rather than one
-- per row. Spans that arrive before it runs are merged into one, because two
-- adjacent cursor moves are one redraw of the rows between them.
--
-- A pending full render makes this one unnecessary and a pending span is
-- dropped when a full render is asked for, so the two never draw over each
-- other in an order neither was queued in.
local function schedule_span(buf, from, to)
	-- A full render that is already queued makes this one unnecessary: it covers
	-- the span and everything else, and two of them in one tick can only fight
	-- over the same rows.
	if pending_scheduled[buf] or pending_timers[buf] then
		return
	end
	local span = pending_spans[buf]
	if span then
		pending_spans[buf] = { math.min(span[1], from, to), math.max(span[2], from, to) }
		return
	end
	pending_spans[buf] = { from, to }
	vim.schedule(function()
		local s = pending_spans[buf]
		if not s then
			return
		end
		pending_spans[buf] = nil
		if not api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" or pending_scheduled[buf] then
			return
		end
		render_span(buf, s[1], s[2])
	end)
end

local function schedule(buf, delay)
	if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
		return
	end
	local timer = pending_timers[buf]
	if timer then
		timer:stop()
		timer:close()
		pending_timers[buf] = nil
	end
	pending_spans[buf] = nil
	if delay == 0 then
		pending_scheduled[buf] = true
		vim.schedule(function()
			if pending_scheduled[buf] then
				pending_scheduled[buf] = nil
				render(buf)
			end
		end)
		return
	end

	pending_scheduled[buf] = nil
	pending_timers[buf] = vim.defer_fn(function()
		pending_timers[buf] = nil
		render(buf)
	end, delay or 150)
end

local render_group = api.nvim_create_augroup("md-render", { clear = true })
local cursor_rows = {}

set_hls()
api.nvim_create_autocmd("ColorScheme", { group = render_group, callback = set_hls })

-- WinEnter is here with FileType and BufWinEnter because entering a window is
-- the only event that makes this buffer the one with the cursor, and the cursor
-- row is drawn as source text: the render that ran while the cursor was in
-- another buffer drew it as a rendered row, so the row recorded in cursor_rows
-- is the row that is now raw, not the row that is now the cursor row.
api.nvim_create_autocmd({ "FileType", "BufWinEnter", "InsertLeave", "WinEnter" }, {
	group = render_group,
	callback = function(ev)
		-- The empty buffer that nvim starts with raises BufWinEnter before any
		-- file has been read, so the filetype is what says there is a markdown
		-- buffer to compile a query for.
		if vim.bo[ev.buf].filetype == "markdown" then
			fence_conceal_off()
			cursor_rows[ev.buf] = nil
		end
		schedule(ev.buf, 0)
	end,
})

api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = render_group,
	callback = function(ev)
		schedule(ev.buf, 150)
	end,
})

api.nvim_create_autocmd({ "WinScrolled", "WinResized", "OptionSet" }, {
	group = render_group,
	callback = function(ev)
		if ev.event == "OptionSet" then
			if ev.match ~= "conceallevel" and ev.match ~= "concealcursor" then
				return
			end
		elseif ev.event == "WinScrolled" then
			-- Only the window that scrolled can be showing different rows now.
			-- WinScrolled names it: <amatch> and <afile> are both the window id
			-- and the pattern is matched against it. Rendering every other
			-- window's buffer here repaints a document nobody moved, and the
			-- picture is thrown away before it is seen: measured at 1.98ms a
			-- scroll of one line in the code file with a document open above it,
			-- against 0.02ms for the same scroll with the document in another
			-- tabpage. Only md-render/WinScrolled's own 0.006ms of that is the
			-- handler, the rest is the render it asked for.
			--
			-- A window id that is not in this tabpage means nothing here
			-- changed, so that is the end of it rather than a fallback to every
			-- window: a scroll in another tabpage cannot move a row in this one.
			local id = tonumber(ev.match)
			local win = id and api.nvim_win_is_valid(id) and id or nil
			if not win or vim.fn.win_id2win(win) == 0 then
				return
			end
			schedule(api.nvim_win_get_buf(win), 0)
			return
		end
		-- WinResized and a change to conceallevel or concealcursor: every window
		-- is a different size or every row is drawn differently, so all of them.
		for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
			schedule(api.nvim_win_get_buf(win), 0)
		end
	end,
})

-- Re-render when the cursor changes row, to reveal the new cursor line. Two rows
-- are what changes: the one the cursor left and the one it is on, and only
-- those. See CURSOR_RENDER_SPAN above for why a jump goes the long way round.
api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	group = render_group,
	callback = function(ev)
		if vim.bo[ev.buf].filetype ~= "markdown" then
			return
		end
		local row = api.nvim_win_get_cursor(0)[1] - 1
		local prev = cursor_rows[ev.buf]
		if prev == row then
			return
		end
		cursor_rows[ev.buf] = row
		if prev == nil or math.abs(row - prev) > CURSOR_RENDER_SPAN then
			schedule(ev.buf, 0)
			return
		end
		schedule_span(ev.buf, prev, row)
	end,
})

-- A mode change is what starts and ends a selection, and a selected row is
-- drawn as source text where every other row is a grid, so every row that was
-- drawn one way has to be drawn the other: the whole buffer, not the two rows a
-- cursor move redraws. render-markdown registers ModeChanged for the same
-- reason. The recorded row is dropped with it, so the next cursor move takes
-- the long way round rather than a two row span from a row this render no
-- longer drew.
api.nvim_create_autocmd("ModeChanged", {
	group = render_group,
	callback = function(ev)
		if vim.bo[ev.buf].filetype ~= "markdown" then
			return
		end
		cursor_rows[ev.buf] = nil
		schedule(ev.buf, 0)
	end,
})

api.nvim_create_autocmd("BufWipeout", {
	group = render_group,
	callback = function(ev)
		cursor_rows[ev.buf] = nil
		pending_scheduled[ev.buf] = nil
		pending_spans[ev.buf] = nil
		local timer = pending_timers[ev.buf]
		if timer then
			timer:stop()
			timer:close()
			pending_timers[ev.buf] = nil
		end
	end,
})

-- Markdown preview use cli mdserve
local mdserve_job = nil
vim.keymap.set("n", "<leader>mp", function()
	if mdserve_job then
		vim.fn.jobstop(mdserve_job) -- stop previous mdserve
	end

	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("No file to preview", vim.log.levels.WARN)
		return
	end
	mdserve_job = vim.fn.jobstart({ "mdserve", file, "--port", "1337", "--open" }, { detach = true })
end, { desc = "Markdown preview (mdserve)" })

-- Clean up mdserve process when exiting nvim
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		if mdserve_job then
			vim.fn.jobstop(mdserve_job)
		end
	end,
})

vim.keymap.set("n", "<leader>um", function()
	enabled = not enabled
	for _, buf in ipairs(api.nvim_list_bufs()) do
		api.nvim_buf_clear_namespace(buf, ns, 0, -1)
		schedule(buf)
	end
	vim.notify("Markdown rendering " .. (enabled and "on" or "off"))
end, { desc = "Toggle render markdown" })
