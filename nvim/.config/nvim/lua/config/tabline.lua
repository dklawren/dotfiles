local M = {}
local npcall = require("config.compat")

local SEP = "" -- separator glyph at buffer boundary
local CLOSE = "" -- close icon shown on active buffer
local NO_NAME = "[NO NAME]"
local OVERFLOW_LEFT = "«"
local OVERFLOW_RIGHT = "»"

local _tab_cache = nil -- cached rendered string
local _tab_cache_key = nil -- cache key: bufnr + columns + buffer-list signature

---The last line rendered, under the key that says what it was rendered from.
---@param key string
---@param line string
local function remember(key, line)
	_tab_cache, _tab_cache_key = line, key
	return line
end

local _tab_invalidate_events = {
	"BufAdd",
	"BufDelete",
	"BufWipeout",
	"BufFilePost", -- buffer renamed
	"BufWritePost", -- save clears the modified flag
	"FileType", -- filetypes can change buflisted
	"TextChanged", -- normal-mode edit sets modified flag
	"TextChangedI", -- insert-mode edit sets modified flag
	"VimResized", -- terminal resize changes layout
	"TabEnter", -- tabpage switch may change active buffer set
}

vim.api.nvim_create_autocmd(_tab_invalidate_events, {
	group = vim.api.nvim_create_augroup("MyTablineCache", { clear = true }),
	callback = function()
		_tab_cache = nil
	end,
})

function M.set_highlights()
	vim.api.nvim_set_hl(0, "MyBufInactive", { fg = "#ABB2BF", bg = "#282C34" })
	vim.api.nvim_set_hl(0, "MyBufActive", { fg = "#ECEFF4", bg = "#3E4451", bold = true })
	vim.api.nvim_set_hl(0, "MyBufSeparator", { fg = "#21252B", bg = "#282C34" })
	vim.api.nvim_set_hl(0, "MyBufClose", { fg = "#BF616A", bg = "#3E4451" })
end

-- Resolved on first success then cached, not required per buffer per redraw.
-- Cannot resolve at module scope: this file loads before plugins/oil.lua adds
-- nvim-web-devicons to the runtimepath.
local devicons

---The icon for a file and a space after it, or "" when there is none.
---@param name string
local function icon_for(name)
	if name == "" then
		return ""
	end
	if not devicons then
		devicons = npcall(require, "nvim-web-devicons")
		if not devicons then
			return ""
		end
	end
	local icon = devicons.get_icon(vim.fn.fnamemodify(name, ":t"), vim.fn.fnamemodify(name, ":e"), { default = true })
	return icon and (icon .. " ") or ""
end

-- Extract parent folders + filename (e.g., "parent/config/tabline.lua")
local function get_display_name(path)
	if path == "" then
		return NO_NAME
	end
	local parts = vim.split(path, "/", { plain = true })
	return table.concat(vim.list_slice(parts, math.max(#parts - 2, 1)), "/")
end

-- Render a single buffer chunk
local function render_buf(bufnr, current)
	-- A session restores the buffers it listed but did not show with `badd`,
	-- and those stay unloaded until something puts them in a window. An
	-- unloaded buffer has everything this needs -- a name, a modified flag --
	-- so skipping them here is what kept the tabline from showing a whole
	-- session's files.
	if not vim.bo[bufnr].buflisted then
		return ""
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	local content = icon_for(name) .. get_display_name(name)
	local active = bufnr == current
	return ("%%#%s# %s%s%%#MyBufSeparator#"):format(
		active and "MyBufActive" or "MyBufInactive",
		content,
		active and (" %#MyBufClose#" .. CLOSE .. " ") or "  "
	) .. SEP
end

-- Strip statusline highlight groups (%#...#) to measure real display width
local function display_width(s)
	local stripped = s:gsub("%%#[^#]*#", ""):gsub("%%%%", "%%")
	return vim.api.nvim_strwidth(stripped)
end

function M.build()
	local current = vim.api.nvim_get_current_buf()
	local columns = vim.o.columns

	-- Render every listed buffer; remember which index is the active one.
	-- We must build chunks before the cache check, because the cache key
	-- includes the buffer-list signature.
	local chunks = {}
	local active_idx = nil
	local sig = {} -- signature pieces for the cache key
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		local chunk = render_buf(bufnr, current)
		if chunk ~= "" then
			table.insert(chunks, chunk)
			sig[#sig + 1] = bufnr .. ":" .. (vim.bo[bufnr].modified and "1" or "0")
			if bufnr == current then
				active_idx = #chunks
			end
		end
	end

	local key = current .. "|" .. columns .. "|" .. table.concat(sig, ",")
	if _tab_cache and _tab_cache_key == key then
		return _tab_cache
	end

	if #chunks == 0 then
		return remember(key, "")
	end

	local widths = {}
	local total = 0
	for i, c in ipairs(chunks) do
		widths[i] = display_width(c)
		total = total + widths[i]
	end

	-- Fast path: everything fits
	if total <= columns then
		return remember(key, table.concat(chunks):gsub(vim.pesc(SEP) .. "$", ""))
	end

	-- Sliding window: keep the active buffer visible, then expand outward
	-- (alternating sides) until we run out of room. Reserve space for
	-- overflow markers only on sides where buffers are actually hidden.
	-- Markers include a count, like " 3 « ... » 5 ".
	active_idx = active_idx or 1

	local function marker_width(count, glyph)
		-- e.g. " 12 « " = 6, " » 3 " = 5
		return count > 0 and (vim.api.nvim_strwidth(glyph) + #tostring(count) + 3) or 0
	end

	local first, last = active_idx, active_idx
	local used = widths[active_idx]

	while true do
		local left_count = first - 1
		local right_count = #chunks - last
		local reserved = marker_width(left_count, OVERFLOW_LEFT) + marker_width(right_count, OVERFLOW_RIGHT)
		local budget = columns - reserved

		local grew = false
		-- Alternate: prefer extending right (more natural reading order)
		if last < #chunks and used + widths[last + 1] <= budget then
			last = last + 1
			used = used + widths[last]
			grew = true
		elseif first > 1 and used + widths[first - 1] <= budget then
			first = first - 1
			used = used + widths[first]
			grew = true
		end
		if not grew then
			break
		end
	end

	local visible = {}
	local left_count = first - 1
	local right_count = #chunks - last
	if left_count > 0 then
		table.insert(visible, "%#MyBufInactive# " .. left_count .. " " .. OVERFLOW_LEFT .. " ")
	end
	for i = first, last do
		table.insert(visible, chunks[i])
	end
	if right_count > 0 then
		table.insert(visible, "%#MyBufInactive# " .. OVERFLOW_RIGHT .. " " .. right_count .. " ")
	end

	return remember(key, table.concat(visible):gsub(vim.pesc(SEP) .. "$", ""))
end

M.set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("MyTabline", { clear = true }),
	callback = M.set_highlights,
})

vim.opt.showtabline = 2
vim.o.tabline = "%!v:lua.require('config.tabline').build()"

return M
