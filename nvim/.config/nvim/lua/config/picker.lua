-- Minimal list + live-preview floating picker (no fuzzy filter: navigate, preview, confirm).
local M = {}

local state = {}

-- Paths to ignore in LSP/diagnostic results. Add patterns here as needed.
-- No /nix/store here: the Neovim runtime lives there, so `gd` into core Lua
-- would be filtered out.
local IGNORE_PATTERNS = {
	"node_modules/",
	"%.pnpm%-store/",
	"%.venv/",
	"__pycache__/",
}

local function close()
	for _, win in ipairs({ state.list_win, state.preview_win }) do
		if win and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	for _, buf in ipairs({ state.list_buf, state.preview_buf }) do
		if buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "nofile" then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end
	state = {}
end

-- preview callbacks passed to opts.preview(item, ctx)
local ctx = {}

function ctx.set_lines(lines, ft)
	if not (state.preview_win and vim.api.nvim_win_is_valid(state.preview_win)) then
		return
	end
	if
		not (
			state.preview_buf
			and vim.api.nvim_buf_is_valid(state.preview_buf)
			and vim.bo[state.preview_buf].buftype == "nofile"
		)
	then
		state.preview_buf = vim.api.nvim_create_buf(false, true)
	end
	vim.api.nvim_win_set_buf(state.preview_win, state.preview_buf)
	vim.bo[state.preview_buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, lines)
	vim.bo[state.preview_buf].modifiable = false
	vim.bo[state.preview_buf].filetype = ft or ""
end

function ctx.set_cursor(lnum, col)
	if state.preview_win and vim.api.nvim_win_is_valid(state.preview_win) then
		vim.api.nvim_win_set_cursor(state.preview_win, { lnum, col or 0 })
		vim.api.nvim_win_call(state.preview_win, function()
			vim.cmd("normal! zz")
		end)
	end
end

function ctx.set_file(path, lnum, col)
	local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or { "[unreadable] " .. path }
	ctx.set_lines(lines, vim.filetype.match({ filename = path }))
	lnum = math.min(math.max(lnum or 1, 1), math.max(#lines, 1))
	vim.api.nvim_win_set_cursor(state.preview_win, { lnum, math.max((col or 1) - 1, 0) })
	vim.api.nvim_win_call(state.preview_win, function()
		vim.cmd("normal! zz")
	end)
end

---@class picker.Opts
---@field title? string
---@field skip_single? boolean Auto-confirm when there is exactly one item (default true)
---@field format fun(item: any, i: integer): string
---@field preview? fun(item: any, ctx: table)
---@field on_confirm fun(item: any)

---@param items table[] list of arbitrary entries
---@param opts picker.Opts
function M.open(items, opts)
	if not items or #items == 0 then
		vim.notify("Nothing to show", vim.log.levels.INFO)
		return
	end
	if #items == 1 and opts.skip_single ~= false then
		opts.on_confirm(items[1])
		return
	end

	close()

	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.75)
	local list_width = math.floor(width * 0.38)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	state.list_buf = vim.api.nvim_create_buf(false, true)
	local labels = {}
	for i, item in ipairs(items) do
		labels[i] = opts.format(item, i)
	end
	vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, labels)
	vim.bo[state.list_buf].modifiable = false

	state.list_win = vim.api.nvim_open_win(state.list_buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = list_width,
		height = height,
		border = "rounded",
		title = opts.title or "",
		title_pos = "center",
	})
	vim.wo[state.list_win].cursorline = true
	vim.wo[state.list_win].wrap = false

	-- Tracked in state so close() can delete it.
	state.preview_buf = vim.api.nvim_create_buf(false, true)
	state.preview_win = vim.api.nvim_open_win(state.preview_buf, false, {
		relative = "editor",
		row = row,
		col = col + list_width + 2,
		width = width - list_width - 2,
		height = height,
		border = "rounded",
		title = "preview",
		title_pos = "center",
	})
	vim.wo[state.preview_win].wrap = false
	vim.wo[state.preview_win].number = true

	local function render()
		if not opts.preview then
			return
		end
		local idx = vim.api.nvim_win_get_cursor(state.list_win)[1]
		opts.preview(items[idx], ctx)
	end

	local function confirm()
		local idx = vim.api.nvim_win_get_cursor(state.list_win)[1]
		local item = items[idx]
		close()
		opts.on_confirm(item)
	end

	vim.api.nvim_create_autocmd("CursorMoved", { buffer = state.list_buf, callback = render })
	for _, lhs in ipairs({ "<CR>", "<C-o>" }) do
		vim.keymap.set("n", lhs, confirm, { buffer = state.list_buf })
	end
	for _, lhs in ipairs({ "<Esc>", "q", "<C-c>" }) do
		vim.keymap.set("n", lhs, close, { buffer = state.list_buf })
	end

	render()
end

---@param items table[] list of diagnostics (with .bufnr, .lnum, .col, .text, .severity, .source)
---@param title string
---@param opts? { scope?: "buffer"|"workspace" }
function M.diagnostics(items, title, opts)
	opts = opts or {}
	items = M.filter_ignored(items)
	local function confirm(item)
		if opts.scope ~= "buffer" then
			vim.cmd.buffer(item.bufnr)
		end
		vim.api.nvim_win_set_cursor(0, { item.lnum + 1, item.col })
		vim.cmd("normal! zz")
	end
	M.open(items, {
		title = title,
		format = function(item)
			local sev = ({ "Err", "Warn", "Info", "Hint" })[item.severity] or "?"
			local name = vim.api.nvim_buf_get_name(item.bufnr)
			return ("[%s] %s:%d: %s"):format(sev, vim.fn.fnamemodify(name, ":."), item.lnum + 1, item.text)
		end,
		preview = function(item, ctx)
			local lines = vim.api.nvim_buf_get_lines(item.bufnr, 0, -1, false)
			ctx.set_lines(lines, vim.bo[item.bufnr].filetype)
			ctx.set_cursor(item.lnum + 1, item.col)
		end,
		on_confirm = confirm,
	})
end

---@param items table[] list of LSP locations (with .filename or .bufnr, .lnum, .col, .text)
---@param title string
function M.locations(items, title)
	items = M.filter_ignored(items)
	M.open(items, {
		title = title,
		format = function(item)
			local fname = item.filename or vim.api.nvim_buf_get_name(item.bufnr)
			return ("%s:%d: %s"):format(vim.fn.fnamemodify(fname, ":."), item.lnum, vim.trim(item.text or ""))
		end,
		preview = function(item, ctx)
			local fname = item.filename or vim.api.nvim_buf_get_name(item.bufnr)
			ctx.set_file(fname, item.lnum, item.col)
		end,
		on_confirm = function(item)
			local fname = item.filename or vim.api.nvim_buf_get_name(item.bufnr)
			vim.cmd.edit(vim.fn.fnameescape(fname))
			vim.api.nvim_win_set_cursor(0, { item.lnum, math.max((item.col or 1) - 1, 0) })
			vim.cmd("normal! zz")
		end,
	})
end

---LSP code actions, fed from `vim.ui.select` with `kind == 'codeaction'`.
---`items` are `{ action: lsp.CodeAction|lsp.Command, ctx: lsp.HandlerContext }`;
---`on_choice` is Neovim's own callback, which resolves (codeAction/resolve) and applies the edit.
---@param items table[]
---@param on_choice fun(choice:any) Neovim code_action callback
---@param format_item? fun(item:any):string label from vim.ui.select opts
function M.code_actions(items, on_choice, format_item)
	format_item = format_item
		or function(item)
			local title = item.action and item.action.title or "(unnamed)"
			return item.action and item.action.disabled and (title .. " (disabled)") or title
		end
	M.open(items, {
		title = "Code Actions",
		skip_single = false,
		format = function(item)
			return format_item(item)
		end,
		preview = function(item, ctx)
			local action = item.action or item
			local lines = { "Title: " .. (action.title or "") }
			if action.kind then
				table.insert(lines, "Kind:  " .. action.kind)
			end
			if action.command then
				local cmd = type(action.command) == "table" and action.command.command or tostring(action.command)
				table.insert(lines, "Command: " .. cmd)
			end
			if action.edit then
				local uris = {}
				if action.edit.documentChanges then
					for _, ch in ipairs(action.edit.documentChanges) do
						if ch.textDocument then
							table.insert(uris, ch.textDocument.uri)
						end
					end
				elseif action.edit.changes then
					for uri, _ in pairs(action.edit.changes) do
						table.insert(uris, uri)
					end
				end
				if #uris > 0 then
					table.insert(lines, "")
					table.insert(lines, ("Edits %d file(s):"):format(#uris))
					for _, uri in ipairs(uris) do
						table.insert(lines, "  " .. vim.uri_to_fname(uri))
					end
				end
			end
			if action.disabled then
				table.insert(lines, "")
				table.insert(lines, "Disabled: " .. (action.disabled.reason or "yes"))
			end
			ctx.set_lines(lines, "markdown")
		end,
		on_confirm = function(item)
			if on_choice then
				on_choice(item)
			end
		end,
	})
end

---Filter out ignored paths (nix/store, node_modules, .venv, etc.).
---@param items table[]
---@return table[]
function M.filter_ignored(items)
	return vim.tbl_filter(function(item)
		local fname = item.filename or vim.api.nvim_buf_get_name(item.bufnr)
		for _, pattern in ipairs(IGNORE_PATTERNS) do
			if fname:match(pattern) then
				return false
			end
		end
		return true
	end, items)
end

return M
