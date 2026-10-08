local M = {}
local npcall = require("config.compat")

local NONE = "NONE"
local c = require("config.palette")
local palette = {
	dark_cyan = "#2a303c",
	dark_sienna = "#4a2e2a",
	soft_violet = "#4c4567",
	teal = "#458588",
	green = c.teal,
	dark_gray = c.base,
	light_gray = c.text,
	light_green = c.green,
	sky_blue = c.blue,
	pink = c.pink,
	red = c.red,
	yellow = c.yellow,
}

local groups = {
	StatusLine = { bg = NONE, fg = NONE },
	StatusLineNC = { bg = NONE, fg = NONE },
	StatusMode = { bg = palette.green, fg = palette.dark_gray, bold = true },
	StatusModeToNorm = { bg = NONE, fg = palette.green },
	StatusGit = { bg = palette.dark_sienna, fg = palette.light_gray, bold = true },
	StatusGitToNorm = { bg = NONE, fg = palette.pink },
	StatusDiffAdd = { bg = NONE, fg = palette.light_green, bold = true },
	StatusDiffChange = { bg = NONE, fg = palette.yellow, bold = true },
	StatusDiffDelete = { bg = NONE, fg = palette.red, bold = true },
	StatusFile = { bg = NONE, fg = NONE, bold = true },
	StatusFileToNorm = { bg = NONE, fg = NONE },
	StatusLSP = { bg = NONE, fg = NONE, bold = true },
	StatusLSPToNorm = { bg = NONE, fg = NONE },
	StatusErrorIcon = { bg = NONE, fg = palette.red, bold = true },
	StatusWarnIcon = { bg = NONE, fg = palette.yellow, bold = true },
	StatusInfoIcon = { bg = NONE, fg = palette.sky_blue, bold = true },
	StatusHintIcon = { bg = NONE, fg = palette.light_green },
	StatusBuffer = { bg = palette.dark_cyan, fg = palette.light_gray },
	StatusType = { bg = palette.dark_cyan, fg = palette.light_gray },
	StatusTypeToNorm = { bg = NONE, fg = NONE },
	StatusNorm = { bg = NONE, fg = NONE },
	StatusLocation = { bg = palette.soft_violet, fg = palette.light_gray },
	StatusPercent = { bg = palette.teal, fg = palette.dark_gray, bold = true },
}

-- `:colorscheme` runs `hi clear`, so re-apply on every ColorScheme.
local function set_highlights()
	for group, opts in pairs(groups) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("MyStatuslineHighlights", { clear = true }),
	callback = set_highlights,
})

local fn = vim.fn

local _diag_cache = {} -- [bufnr] -> the fragment build() paints, made when they change

-- Diagnostics symbols, one entry per |diagnostic-severity| in order.
local DIAG = {
	{ "StatusErrorIcon", " " },
	{ "StatusWarnIcon", " " },
	{ "StatusInfoIcon", " " },
	{ "StatusHintIcon", " " },
}

vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function(args)
		local counts = vim.diagnostic.count(args.buf)
		local s = ""
		for severity, icon in ipairs(DIAG) do
			local n = counts[severity] or 0
			if n > 0 then
				s = s .. ("%%#%s#%s%d "):format(icon[1], icon[2], n)
			end
		end
		-- reset to StatusLine for the text that follows
		_diag_cache[args.buf] = s .. "%#StatusLine#"
	end,
})

-- A devicon lookup is 0.57ms and the two fnamemodify() calls around it another
-- 0.40ms, which every redraw would pay for on its own.
local _icon_cache = {} -- [bufnr] -> icon string

---@type { words: table<integer, integer>, timers: table<integer, uv.uv_timer_t> }
local _wc_state = { words = {}, timers = {} }

---The buffers whose word count the statusline shows. "md" catches mdx and
---friends but not markdown itself, which is why both are asked for.
---@param ft string
---@return string|nil
local function prose(ft)
	return ft:match("md") or ft:match("markdown") or (ft == "text" and ft or nil)
end

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter" }, {
	callback = function(event)
		local buf = event.buf
		if not prose(vim.bo[buf].filetype) then
			return
		end
		local timer = _wc_state.timers[buf]
		if timer then
			timer:stop()
			timer:close()
		end
		_wc_state.timers[buf] = vim.defer_fn(function()
			_wc_state.timers[buf] = nil
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			_wc_state.words[buf] = vim.api.nvim_buf_call(buf, function()
				return fn.wordcount().words or 0
			end)
		end, 500)
	end,
})
---@type { words: table<integer, integer>, timers: table<integer, uv.uv_timer_t> }

vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
	callback = function(args)
		_icon_cache[args.buf] = nil
		_diag_cache[args.buf] = nil
		_wc_state.words[args.buf] = nil
		local timer = _wc_state.timers[args.buf]
		if timer then
			timer:stop()
			timer:close()
			_wc_state.timers[args.buf] = nil
		end
	end,
})

-- Git repo, branch and the counts gitsigns keeps for the buffer. Empty when
-- the buffer is not in a repo, and the same string every redraw, since
-- gitsigns publishes both on the buffer.
local GIT_DIFF = {
	{ "added", "StatusDiffAdd", " " },
	{ "changed", "StatusDiffChange", " " },
	{ "removed", "StatusDiffDelete", " " },
}

local function git_fragment()
	local branch = vim.b.gitsigns_head
	if not branch or branch == "" then
		return ""
	end
	local gs = vim.b.gitsigns_status_dict or {}
	if gs.root then
		branch = vim.fn.fnamemodify(gs.root, ":t") .. "/" .. branch
	end
	-- "%#" is not a valid string.format conversion, so the groups are pasted
	local s = "%#StatusGit#  " .. branch .. " %#StatusGitToNorm#"
	for _, d in ipairs(GIT_DIFF) do
		local n = gs[d[1]] or 0
		if n > 0 then
			s = s .. "%#" .. d[2] .. "#" .. d[3] .. n .. " "
		end
	end
	-- back to StatusLine for what follows, and to the git colour after that
	return s .. "%#StatusLine#%#StatusGitToNorm#"
end

-- Diagnostics, already spelled out above
local function get_diagnostics()
	return _diag_cache[vim.api.nvim_get_current_buf()] or "%#StatusLine#"
end

-- File icon
local function get_file_icon()
	local bufnr = vim.api.nvim_get_current_buf()
	if _icon_cache[bufnr] ~= nil then
		return _icon_cache[bufnr]
	end

	-- Not cached on failure: the first render happens before plugins load.
	local icons = npcall(require, "nvim-web-devicons")
	if not icons then
		return ""
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	local f = fn.fnamemodify(name, ":t")
	local e = fn.fnamemodify(name, ":e")
	local icon = icons.get_icon(f, e, { default = true })
	local result = icon and icon .. " " or ""
	_icon_cache[bufnr] = result
	return result
end

-- Word count & reading time
local function word_reading()
	if not prose(vim.bo.filetype) then
		return ""
	end
	local w = _wc_state.words[vim.api.nvim_get_current_buf()] or 0
	return w > 0 and ("%dw  %dm"):format(w, math.ceil(w / 200)) or ""
end

-- Mode icons
local mode_icons = {
	n = " NORMAL",
	c = " COMMAND",
	t = " TERMINAL",
	i = " INSERT",
	R = " REPLACE",
	V = " V-LINE",
	[""] = " V-BLOCK", -- Visual Block
	r = " R-PENDING",
	v = " VISUAL",
}

-- 4) Build statusline
function M.build()
	local st = ""

	-- A: mode
	local m = fn.mode()
	st = st .. "%#StatusMode# " .. (mode_icons[m] or m) .. " " .. "%#StatusModeToNorm#"

	-- B: git
	st = st .. git_fragment()

	-- C: filename
	local fnm = fn.expand("%:.")
	if fnm ~= "" then
		st = st .. "%#StatusFile# " .. fnm .. " " .. (vim.bo.modified and " " or "") .. "%#StatusFileToNorm#"
	end

	st = st .. "%#StatusLSP# " .. get_diagnostics() .. " %#StatusLSPToNorm#"

	-- right align
	st = st .. "%="

	-- LSP progress (e.g. "indexing…" from language servers)
	local progress = vim.ui.progress_status()
	if progress ~= "" then
		st = st .. "%#StatusLSP# " .. progress .. " %#StatusLine#"
	end

	-- X: filetype
	local ft = vim.bo.filetype
	if ft ~= "" then
		st = st .. "%#StatusType# " .. get_file_icon() .. ft .. "%#StatusTypeToNorm#"
	end

	-- Y: word/reading
	local wr = word_reading()
	if wr ~= "" then
		st = st .. "%#StatusBuffer# " .. " " .. wr
	end

	-- Z: encoding, format, location, percent
	st = st
		.. "%#StatusBuffer# "
		.. vim.bo.fileencoding
		.. " "
		.. vim.bo.fileformat
		.. " "
		.. "%#StatusLocation# %l:%c "
		.. "%#StatusPercent# %p%% "

	return st
end

-- 'laststatus' and 'showmode' are set in config/options.lua
vim.o.statusline = "%!v:lua.require('config.statusline').build()"

return M
