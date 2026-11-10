local api = vim.api

local M = {}

local state = {
	buf = nil,
	win = nil,
	target = nil,
	root = nil,
	expanded = {},
	index = {},
	current = nil,
}

local function under(path, root)
	return root == "/" or path:sub(1, #root + 1) == root .. "/"
end

local function root_for(path)
	return vim.fs.root(path, ".git") or (under(path, vim.fn.getcwd()) and vim.fn.getcwd()) or vim.fs.dirname(path)
end

local function children(dir)
	local out = {}
	for name, kind in vim.fs.dir(dir) do
		if name ~= ".git" then
			local path = vim.fs.joinpath(dir, name)
			local is_dir = kind == "directory" or (kind == "link" and vim.fn.isdirectory(path) == 1)
			out[#out + 1] = { name = name, path = path, dir = is_dir }
		end
	end
	table.sort(out, function(a, b)
		if a.dir ~= b.dir then
			return a.dir
		end
		return a.name:lower() < b.name:lower()
	end)
	return out
end

local ns = api.nvim_create_namespace("config-tree")
local FOLDER = { open = "\u{e5fe}", closed = "\u{e5ff}" }
local devicons = nil
api.nvim_set_hl(0, "TreeCurrentFile", { bold = true, default = true })

local function icons()
	if devicons == nil then
		local ok, mod = pcall(require, "nvim-web-devicons")
		devicons = ok and mod or false
	end
	return devicons
end

local function render()
	local lines, index, marks = {}, {}, {}
	local dev = icons()

	local function walk(dir, depth)
		for _, entry in ipairs(children(dir)) do
			local icon, group = " ", nil
			if entry.dir then
				icon = state.expanded[entry.path] and FOLDER.open or FOLDER.closed
				group = "Directory"
			elseif dev then
				icon, group = dev.get_icon(entry.name, entry.name:match("%.([^.]+)$"), { default = true })
				icon = icon or " "
			end

			local indent = ("  "):rep(depth)
			local arrow = entry.dir and (state.expanded[entry.path] and "▾" or "▸") or " "
			local suffix = entry.dir and "/" or ""
			local row = #lines
			lines[row + 1] = indent .. arrow .. " " .. icon .. " " .. entry.name .. suffix
			index[row + 1] = entry

			local icon_start = #indent + #arrow + 1
			local name_start = icon_start + #icon + 1
			marks[#marks + 1] = { row, icon_start, name_start - 1, group }
			if entry.dir then
				marks[#marks + 1] = { row, name_start, name_start + #entry.name + 1, "Directory" }
			elseif entry.path == state.current then
				marks[#marks + 1] = { row, name_start, name_start + #entry.name, "TreeCurrentFile" }
			end

			if entry.dir and state.expanded[entry.path] then
				walk(entry.path, depth + 1)
			end
		end
	end

	walk(state.root, 0)
	state.index = index
	vim.bo[state.buf].modifiable = true
	api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
	for _, mark in ipairs(marks) do
		if mark[4] then
			api.nvim_buf_set_extmark(state.buf, ns, mark[1], mark[2], { end_col = mark[3], hl_group = mark[4] })
		end
	end
end

local function cursor_to(path)
	for line, entry in pairs(state.index) do
		if entry.path == path then
			api.nvim_win_set_cursor(state.win, { line, 0 })
			return
		end
	end
end

local function expand_to(path)
	if not under(path, state.root) then
		state.root = root_for(path)
	end
	state.expanded[state.root] = true
	local dir = state.root
	for part in path:sub(#state.root + 1):gmatch("[^/]+") do
		dir = vim.fs.joinpath(dir, part)
		if dir ~= path then
			state.expanded[dir] = true
		end
	end
end

local function visible()
	return state.win and api.nvim_win_is_valid(state.win) and state.buf and api.nvim_buf_is_valid(state.buf)
end

local function entry_at_cursor()
	return state.index[api.nvim_win_get_cursor(state.win)[1]]
end

local function open_file(path)
	local target = state.target
	if not (target and api.nvim_win_is_valid(target)) then
		for _, win in ipairs(api.nvim_list_wins()) do
			if win ~= state.win then
				target = win
				break
			end
		end
	end
	if not target then
		return
	end
	api.nvim_set_current_win(target)
	vim.cmd.edit(vim.fn.fnameescape(path))
end

local function select()
	local entry = entry_at_cursor()
	if not entry then
		return
	end
	if entry.dir then
		state.expanded[entry.path] = not state.expanded[entry.path]
		render()
		cursor_to(entry.path)
	else
		open_file(entry.path)
	end
end

local function collapse()
	local entry = entry_at_cursor()
	if not entry then
		return
	end
	if entry.dir and state.expanded[entry.path] then
		state.expanded[entry.path] = nil
		render()
		cursor_to(entry.path)
		return
	end
	local parent = vim.fs.dirname(entry.path)
	if not under(parent, state.root) or parent == state.root then
		return
	end
	state.expanded[parent] = nil
	render()
	cursor_to(parent)
end

local function open_win()
	if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
		state.buf = api.nvim_create_buf(false, true)
		vim.bo[state.buf].filetype = "tree"
		vim.bo[state.buf].bufhidden = "wipe"
		vim.bo[state.buf].modifiable = false

		local opts = { buffer = state.buf, silent = true, nowait = true }
		vim.keymap.set({ "n", "x" }, "<CR>", select, opts)
		vim.keymap.set({ "n", "x" }, "o", select, opts)
		vim.keymap.set({ "n", "x" }, "l", select, opts)
		vim.keymap.set({ "n", "x" }, "h", collapse, opts)
		vim.keymap.set("n", "R", render, opts)
		vim.keymap.set("n", "q", M.close, opts)
		vim.keymap.set("n", "<Esc>", M.close, opts)
	end

	state.win = api.nvim_open_win(state.buf, false, { split = "left", width = 32 })
	vim.wo[state.win].number = false
	vim.wo[state.win].relativenumber = false
	vim.wo[state.win].signcolumn = "no"
	vim.wo[state.win].foldcolumn = "0"
	vim.wo[state.win].wrap = false
	vim.wo[state.win].winfixwidth = true
	vim.wo[state.win].cursorline = true
end

function M.close()
	if visible() then
		api.nvim_win_close(state.win, true)
	end
	state.win = nil
end

function M.toggle()
	if visible() then
		M.close()
		return
	end

	local name = api.nvim_buf_get_name(0)
	local file = name ~= "" and vim.bo.buftype == "" and vim.fn.isdirectory(name) == 0

	state.target = api.nvim_get_current_win()
	state.root = file and root_for(name) or (vim.fn.isdirectory(name) == 1 and name or vim.fn.getcwd())

	state.current = file and name or nil
	open_win()
	expand_to(file and name or state.root)
	render()
	if file then
		cursor_to(name)
	end
end

local function follow(buf)
	if not visible() or buf == state.buf then
		return
	end
	local name = api.nvim_buf_get_name(buf)
	if name == "" or vim.bo[buf].buftype ~= "" or vim.fn.isdirectory(name) == 1 then
		return
	end
	state.current = name
	expand_to(name)
	render()
	cursor_to(name)
end

local group = api.nvim_create_augroup("config-tree", { clear = true })
api.nvim_create_autocmd("BufEnter", {
	group = group,
	callback = function(ev)
		follow(ev.buf)
	end,
})
api.nvim_create_autocmd("BufWritePost", {
	group = group,
	callback = function(ev)
		follow(ev.buf)
	end,
})
api.nvim_create_autocmd("WinClosed", {
	group = group,
	callback = function(ev)
		if state.win and tonumber(ev.match) == state.win then
			state.win = nil
		end
	end,
})

vim.keymap.set("n", "<leader>E", M.toggle, { desc = "File Explorer (tree)" })

return M
