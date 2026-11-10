-- The lists Neovim prints into a scratch buffer (marks, jumps, registers,
-- quickfix, commands, autocmds, history) as picker rows, so they can be typed
-- at, previewed, and reached with Enter.
local picker = require("config.picker")
local M = {}

local function relpath(path)
	return vim.fn.fnamemodify(path, ":.")
end

local function show(title, items, opts)
	if #items == 0 then
		return vim.notify(title .. " is empty", vim.log.levels.INFO)
	end
	picker.open(items, vim.tbl_extend("force", { title = title, skip_single = false, filter = true }, opts or {}))
end

---The buffer holding `item`, loaded, or nil when there is none.
---@param item { bufnr?: integer, path?: string }
---@return integer|nil
local function buffer_of(item)
	local buf = item.bufnr
	if not (buf and buf > 0 and vim.api.nvim_buf_is_valid(buf)) then
		buf = item.path and vim.fn.bufnr(item.path) or -1
	end
	if buf and buf > 0 and vim.api.nvim_buf_is_valid(buf) then
		vim.fn.bufload(buf)
		return buf
	end
	return nil
end

---@param item { bufnr?: integer, path?: string, lnum: integer, col?: integer }
local function preview_at(item, ctx)
	local buf = buffer_of(item)
	if buf then
		ctx.set_lines(vim.api.nvim_buf_get_lines(buf, 0, -1, false), vim.bo[buf].filetype)
		ctx.set_cursor(item.lnum, math.max((item.col or 1) - 1, 0))
	else
		ctx.set_file(item.path, item.lnum, item.col)
	end
end

---@param item { bufnr?: integer, path?: string, lnum: integer, col?: integer }
local function jump_at(item)
	local buf = buffer_of(item)
	if buf then
		vim.cmd.buffer(buf)
	else
		vim.cmd.edit(vim.fn.fnameescape(item.path))
	end
	vim.api.nvim_win_set_cursor(0, { math.max(item.lnum or 1, 1), math.max((item.col or 1) - 1, 0) })
	vim.cmd("normal! zz")
end

local function label(path, lnum, text)
	local body = vim.trim((text or ""):gsub("%s+", " "))
	return ("%s:%d  %s"):format(relpath(path), lnum, body)
end

---Every mark that still points somewhere: buffer marks of the current buffer,
---then the global marks, including the ones shada restored from other files.
---@return table[]
function M.mark_items()
	local items = {}
	local buf = vim.api.nvim_get_current_buf()
	vim.list_extend(items, vim.fn.getmarklist(buf))
	vim.list_extend(items, vim.fn.getmarklist())
	local rows, seen = {}, {}
	for _, mark in ipairs(items) do
		local bufnr, lnum, col = mark.pos[1], mark.pos[2], mark.pos[3]
		local path = mark.file
		if bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
			path = vim.api.nvim_buf_get_name(bufnr)
		end
		if path and path ~= "" and lnum > 0 and vim.fn.filereadable(path) == 1 then
			local key = mark.mark .. path
			if not seen[key] then
				seen[key] = true
				local line = ""
				if bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
					line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
				end
				rows[#rows + 1] = {
					mark = mark.mark,
					name = mark.mark:sub(2, 2),
					bufnr = bufnr > 0 and bufnr or nil,
					path = path,
					lnum = lnum,
					col = col,
					text = line,
				}
			end
		end
	end
	table.sort(rows, function(a, b)
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.path < b.path
	end)
	return rows
end

function M.marks()
	show("Marks", M.mark_items(), {
		format = function(item)
			return ("%s  %s"):format(item.mark, label(item.path, item.lnum, item.text))
		end,
		preview = preview_at,
		on_confirm = jump_at,
	})
end

---The jump list of this window, newest first, numbered the way `:jumps` does.
---@return table[]
function M.jump_items()
	local jumps = vim.fn.getjumplist()[1]
	local rows = {}
	for i = #jumps, 1, -1 do
		local jump = jumps[i]
		local bufnr = jump.bufnr
		local path = bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) or ""
		if path ~= "" then
			local line = vim.api.nvim_buf_get_lines(bufnr, jump.lnum - 1, jump.lnum, false)[1] or ""
			rows[#rows + 1] = {
				nr = i,
				bufnr = bufnr,
				path = path,
				lnum = jump.lnum,
				col = jump.col + 1,
				text = line,
			}
		end
	end
	return rows
end

function M.jumps()
	show("Jumps", M.jump_items(), {
		format = function(item)
			return ("%3d  %s"):format(item.nr, label(item.path, item.lnum, item.text))
		end,
		preview = preview_at,
		on_confirm = jump_at,
	})
end

local REGISTERS = '"0123456789abcdefghijklmnopqrstuvwxyz-:./%#=*+'

---Every register that holds something. `_` is left out because it never does.
---@return table[]
function M.register_items()
	local rows = {}
	for reg in REGISTERS:gmatch(".") do
		local ok, info = pcall(vim.fn.getreginfo, reg)
		if ok and type(info) == "table" and type(info.regcontents) == "table" and #info.regcontents > 0 then
			rows[#rows + 1] = {
				reg = reg,
				lines = info.regcontents,
				kind = info.regtype,
				size = #info.regcontents,
			}
		end
	end
	return rows
end

local function paste(item)
	local kind = item.kind:find("\22") and "b" or item.kind:sub(1, 1) == "V" and "l" or "c"
	vim.api.nvim_put(item.lines, kind, true, true)
end

function M.registers()
	show("Registers", M.register_items(), {
		format = function(item)
			local head = table.concat(vim.list_slice(item.lines, 1, 5), "\\n"):sub(1, 400)
			return ("%s  %s"):format(item.reg, head:gsub("%s+", " "))
		end,
		preview = function(item, ctx)
			local shown = {}
			for i, line in ipairs(vim.list_slice(item.lines, 1, 500)) do
				shown[i] = line:sub(1, 500)
			end
			ctx.set_lines(shown, "text")
		end,
		keys = {
			["<C-y>"] = {
				desc = 'yank to "',
				run = function(item)
					vim.fn.setreg('"', item.lines, item.kind)
					vim.notify(("register %s is now the unnamed register"):format(item.reg), vim.log.levels.INFO)
				end,
			},
		},
		on_confirm = paste,
	})
end

---@param list { items: table[] }
local function quickfix_rows(list)
	local rows = {}
	for _, item in ipairs(list.items or {}) do
		if item.bufnr and item.bufnr > 0 and vim.api.nvim_buf_is_valid(item.bufnr) then
			rows[#rows + 1] = {
				bufnr = item.bufnr,
				path = vim.api.nvim_buf_get_name(item.bufnr),
				lnum = item.lnum,
				col = item.col,
				type = item.type,
				text = item.text,
			}
		end
	end
	return rows
end

function M.quickfix()
	local list = vim.fn.getqflist({ items = 1 })
	show("Quickfix", quickfix_rows(list), {
		format = function(item)
			local kind = item.type ~= "" and (item.type .. " ") or ""
			return kind .. label(item.path, item.lnum, item.text)
		end,
		preview = preview_at,
		on_confirm = jump_at,
	})
end

function M.location()
	local list = vim.fn.getloclist(0, { items = 1 })
	show("Location List", quickfix_rows(list), {
		format = function(item)
			local kind = item.type ~= "" and (item.type .. " ") or ""
			return kind .. label(item.path, item.lnum, item.text)
		end,
		preview = preview_at,
		on_confirm = jump_at,
	})
end

---User commands of this buffer and of the editor, one row each.
---@return table[]
function M.command_items()
	local cmds = vim.api.nvim_get_commands({})
	for name, def in pairs(vim.api.nvim_buf_get_commands(0, {})) do
		if type(name) == "string" then
			cmds[name] = def
		end
	end
	local rows = {}
	for name, def in pairs(cmds) do
		rows[#rows + 1] = { name = name, def = def }
	end
	table.sort(rows, function(a, b)
		return a.name < b.name
	end)
	return rows
end

---@param item { name: string, def: table }
---@param ctx table
local function preview_command(item, ctx)
	local def = item.def
	local lines = { ":" .. item.name }
	if def.desc and def.desc ~= "" then
		lines[#lines + 1] = def.desc
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "definition: " .. (def.definition or "")
	lines[#lines + 1] = ("nargs: %s   range: %s   bang: %s"):format(
		tostring(def.nargs ~= "" and def.nargs or "0"),
		tostring(def.range),
		tostring(def.bang)
	)
	if def.complete and def.complete ~= "" then
		lines[#lines + 1] = "complete: " .. tostring(def.complete)
	end
	ctx.set_lines(lines, "markdown")
end

local function prefill(text)
	vim.cmd.stopinsert()
	vim.schedule(function()
		vim.api.nvim_feedkeys(":" .. text, "n", false)
	end)
end

function M.commands()
	show("Commands", M.command_items(), {
		format = function(item)
			local desc = vim.trim((item.def.desc or item.def.definition or ""):gsub("%s+", " "))
			return (":%s  %s"):format(item.name, desc:sub(1, 100))
		end,
		preview = preview_command,
		on_confirm = function(item)
			prefill(item.name .. " ")
		end,
	})
end

---@return table[]
function M.autocmd_items()
	local rows = {}
	for _, au in ipairs(vim.api.nvim_get_autocmds({})) do
		local row = {
			event = au.event,
			group = au.group_name or "",
			pattern = au.pattern or "",
			desc = au.desc or "",
			command = au.command,
		}
		if au.callback then
			local info = debug.getinfo(au.callback, "S")
			if info and info.source:sub(1, 1) == "@" then
				row.path = info.source:sub(2)
				row.lnum = info.linedefined
			end
		end
		rows[#rows + 1] = row
	end
	table.sort(rows, function(a, b)
		if a.event ~= b.event then
			return a.event < b.event
		end
		return a.group < b.group
	end)
	return rows
end

function M.autocmds()
	show("Autocmds", M.autocmd_items(), {
		format = function(item)
			local what = item.desc ~= "" and item.desc or (item.command or "lua callback")
			return ("%s  %s  %s  %s"):format(
				item.event,
				item.group,
				item.pattern,
				vim.trim(what:gsub("%s+", " ")):sub(1, 100)
			)
		end,
		preview = function(item, ctx)
			if item.path then
				ctx.set_file(item.path, item.lnum or 1, 1)
			else
				local lines = { item.event .. "  " .. item.group .. "  " .. item.pattern }
				if item.desc ~= "" then
					lines[#lines + 1] = item.desc
				end
				lines[#lines + 1] = ""
				vim.list_extend(lines, vim.split(item.command or "", "\n", { plain = true }))
				ctx.set_lines(lines, "vim")
			end
		end,
		on_confirm = function(item)
			if item.path then
				jump_at({ path = item.path, lnum = item.lnum or 1, col = 1 })
			end
		end,
	})
end

---@param name string ":","/","=" or "?"
---@return table[]
function M.history_items(name)
	local rows = {}
	for i = vim.fn.histnr(name), 1, -1 do
		local entry = vim.fn.histget(name, i)
		if entry and not entry:match("^%s*$") then
			rows[#rows + 1] = { nr = i, entry = entry, name = name }
		end
	end
	return rows
end

function M.history(name)
	local title = name == "/" and "Search History" or "Command History"
	show(title, M.history_items(name), {
		format = function(item)
			return ("%3d  %s"):format(item.nr, item.entry)
		end,
		preview = function(item, ctx)
			ctx.set_lines({ item.entry }, "text")
		end,
		on_confirm = function(item)
			vim.cmd.stopinsert()
			vim.schedule(function()
				vim.api.nvim_feedkeys(item.name .. item.entry, "n", false)
			end)
		end,
	})
end

return M
