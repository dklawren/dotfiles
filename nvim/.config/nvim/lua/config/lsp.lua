-- LSP
local M = {}

local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- List+preview floating picker for multi-result LSP locations (replaces the default quickfix list).
-- Code actions are routed there too: in 0.11+ vim.lsp.buf.code_action funnels
-- results to vim.ui.select with kind == 'codeaction', and picker.select answers.
local picker = require("config.picker")

local function jump_to(item)
	local name = item.filename and item.filename ~= "" and item.filename or vim.api.nvim_buf_get_name(item.bufnr)
	vim.cmd.edit(vim.fn.fnameescape(name))
	vim.api.nvim_win_set_cursor(0, { item.lnum, math.max((item.col or 1) - 1, 0) })
	vim.cmd("normal! zz")
end

-- One place to go is a jump, not a choice. A picker with a single row costs a
-- keystroke on every gd and flashes a float for nothing.
local function on_list(list)
	if #list.items == 1 then
		jump_to(list.items[1])
		return
	end
	picker.locations(list.items, list.title)
end

-- An empty query lists what the server has already indexed, which is the
-- whole project after the first file opens, and the picker filters it locally.
local function workspace_symbols()
	vim.ui.input({ prompt = "Workspace symbol: " }, function(query)
		if query ~= nil then
			vim.lsp.buf.workspace_symbol(query, { on_list = on_list })
		end
	end)
end

-- `vim.lsp.buf.incoming_calls` takes no `on_list` and opens the plain quickfix
-- window, so both requests are made here and the rows go to the picker.
local function call_hierarchy(method, title)
	local bufnr = vim.api.nvim_get_current_buf()
	if not next(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/prepareCallHierarchy" })) then
		vim.notify(vim.lsp._unsupported_method(method), vim.log.levels.WARN)
		return
	end
	local function show(result)
		local items = {}
		for _, call in ipairs(result or {}) do
			local node = call.from or call.to
			local range = (call.fromRanges or {})[1] or node.selectionRange
			items[#items + 1] = {
				filename = vim.uri_to_fname(node.uri),
				lnum = range.start.line + 1,
				col = range.start.character + 1,
				text = node.name,
			}
		end
		if #items == 0 then
			vim.notify("no calls", vim.log.levels.INFO)
			return
		end
		picker.locations(items, title)
	end
	local win = vim.api.nvim_get_current_win()
	vim.lsp.buf_request_all(bufnr, "textDocument/prepareCallHierarchy", function(client)
		return vim.lsp.util.make_position_params(win, client.offset_encoding)
	end, function(results)
		local resolved = {}
		for _, res in pairs(results) do
			vim.list_extend(resolved, res.result or {})
		end
		if #resolved == 0 then
			vim.notify("no symbol under the cursor", vim.log.levels.WARN)
			return
		end
		local function fetch(item)
			vim.lsp.buf_request_all(bufnr, method, { item = item }, function(calls)
				local merged = {}
				for _, res in pairs(calls) do
					vim.list_extend(merged, res.result or {})
				end
				show(merged)
			end)
		end
		if #resolved == 1 then
			fetch(resolved[1])
		else
			vim.ui.select(resolved, {
				prompt = "Call hierarchy item:",
				format_item = function(item)
					return item.name
				end,
			}, fetch)
		end
	end)
end

-- LSP native keymaps
-- stylua: ignore start
vim.keymap.set("n", "gd", function() vim.lsp.buf.definition({ on_list = on_list }) end, { desc = "Goto Definition" })
vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration({ on_list = on_list }) end, { desc = "Goto Declaration" })
vim.keymap.set("n", "gR", function() vim.lsp.buf.references(nil, { on_list = on_list }) end, { desc = "References" })
vim.keymap.set("n", "gI", function() vim.lsp.buf.implementation({ on_list = on_list }) end, { desc = "Goto Implementation" })
vim.keymap.set("n", "gy", function() vim.lsp.buf.type_definition({ on_list = on_list }) end, { desc = "Goto Type Definition" })
vim.keymap.set("n", "grt", function() vim.lsp.buf.type_definition({ on_list = on_list }) end, { desc = "Goto Type Definition" })
vim.keymap.set("n", "grr", function() vim.lsp.buf.references(nil, { on_list = on_list }) end, { desc = "References" })
vim.keymap.set("n", "gri", function() vim.lsp.buf.implementation({ on_list = on_list }) end, { desc = "Goto Implementation" })
vim.keymap.set("n", "<leader>ss", function() vim.lsp.buf.document_symbol({ on_list = on_list }) end, { desc = "LSP Symbols" })
vim.keymap.set("n", "gO", function() vim.lsp.buf.document_symbol({ on_list = on_list }) end, { desc = "Document Symbols" })
vim.keymap.set("n", "<leader>sS", workspace_symbols, { desc = "Workspace Symbols" })
vim.keymap.set("n", "<leader>cI", function() call_hierarchy("callHierarchy/incomingCalls", "Incoming Calls") end, { desc = "Incoming Calls" })
vim.keymap.set("n", "<leader>cO", function() call_hierarchy("callHierarchy/outgoingCalls", "Outgoing Calls") end, { desc = "Outgoing Calls" })
-- stylua: ignore end

-- A pull-based workspace diagnostic exists only on some servers. tsserver
-- publishes per file instead, and its silence on workspace/diagnostic is
-- indistinguishable from a clean project, so the list is built from what the
-- buffers have reported.
local function workspace_diagnostics()
	if #vim.lsp.get_clients({ bufnr = 0, method = "workspace/diagnostic" }) > 0 then
		vim.lsp.buf.workspace_diagnostics()
		return
	end
	local reported = vim.diagnostic.get(nil)
	if #reported == 0 then
		vim.notify("none reported", vim.log.levels.INFO, { title = "diagnostics" })
		return
	end
	vim.diagnostic.setqflist({ items = reported })
	picker.diagnostics(reported, "Workspace Diagnostics")
end

M.on_list = on_list
M.workspace_diagnostics = workspace_diagnostics

-- nvim sends only the diagnostics under the cursor, so off the error tsserver
-- offers no fix for it. Aim at the nearest diagnostic on the line, as VSCode does.
-- tsserver answers every refactor it knows, most disabled with a reason, and
-- VSCode keeps those out of the quick fix menu too.
-- A selection is its own range, for extracting the selected code.
local function code_action()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local target
	local selecting = vim.api.nvim_get_mode().mode:find("^[vV]") ~= nil
	for _, d in ipairs(selecting and {} or vim.diagnostic.get(0, { lnum = row - 1 })) do
		local stop = d.end_lnum > d.lnum and math.huge or d.end_col
		if d.col <= col and col < stop then
			target = nil
			break
		end
		if not target or math.abs(d.col - col) < math.abs(target - col) then
			target = d.col
		end
	end
	vim.lsp.buf.code_action({
		range = target and { start = { row, target }, ["end"] = { row, target } } or nil,
		filter = function(action)
			return not action.disabled
		end,
	})
end

M.code_action = code_action

local default_keymaps = {
	{ keys = "<leader>ca", func = code_action, desc = "Code Actions", mode = { "n", "x" } },
	{ keys = "gra", func = code_action, desc = "Code Actions", mode = { "n", "x" } },
	{
		keys = "<leader>cl",
		func = function()
			if vim.fn.exists(":LspOxlintFixAll") > 0 then
				vim.cmd("LspOxlintFixAll")
			elseif vim.fn.exists(":LspEslintFixAll") > 0 then
				vim.cmd("LspEslintFixAll")
			else
				vim.lsp.buf.code_action({
					apply = true,
					context = { only = { "source.fixAll" }, diagnostics = {} },
				})
			end
		end,
		desc = "LSP Fix All",
	},
	{ keys = "<leader>cr", func = vim.lsp.buf.rename, desc = "Code Rename" },
	{ keys = "<leader>k", func = vim.lsp.buf.hover, desc = "Hover Documentation", has = "hoverProvider" },
	{ keys = "K", func = vim.lsp.buf.hover, desc = "Hover (alt)", has = "hoverProvider" },
	{ keys = "grx", func = vim.lsp.codelens.run, desc = "Run Codelens", has = "codeLensProvider" },
	{ keys = "<leader>cw", func = M.workspace_diagnostics, desc = "Workspace Diagnostics" },
	{
		keys = "<leader>cR",
		func = function()
			vim.cmd("lsp restart")
		end,
		desc = "Restart LSP",
	},
}

vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf
		if client then
			if client:supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(not vim.b[buf].inlay_hints_off, { bufnr = buf })

				-- Hints are in the way of the text being written, so they go for
				-- the length of an insert session. <leader>uh is why InsertLeave
				-- asks the buffer instead of turning them back on outright.
				if not vim.b[buf].inlay_hints_autocmd_set then
					for _, mode in ipairs({ "InsertEnter", "InsertLeave" }) do
						vim.api.nvim_create_autocmd(mode, {
							buffer = buf,
							callback = function()
								local on = mode == "InsertLeave" and not vim.b[buf].inlay_hints_off
								vim.lsp.inlay_hint.enable(on, { bufnr = buf })
							end,
						})
					end
					vim.b[buf].inlay_hints_autocmd_set = true
				end
			end

			if client:supports_method("textDocument/linkedEditingRange") then
				vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
			end

			if client:supports_method("textDocument/onTypeFormatting") then
				vim.lsp.on_type_formatting.enable(true, { client_id = client.id })
			end

			if client:supports_method("textDocument/documentColor") then
				vim.lsp.document_color.enable(true, { bufnr = buf }, {
					style = "virtual",
				})
			end

			vim.b[buf].lsp_keymaps_set = vim.b[buf].lsp_keymaps_set or {}
			for _, km in ipairs(default_keymaps) do
				-- Only bind if there's no `has` requirement, or the server supports it.
				-- A buffer can attach several clients, so keep one binding per key.
				if (not km.has or client.server_capabilities[km.has]) and not vim.b[buf].lsp_keymaps_set[km.keys] then
					vim.keymap.set(km.mode or "n", km.keys, km.func, { buffer = buf, desc = "LSP: " .. km.desc })
					vim.b[buf].lsp_keymaps_set[km.keys] = true
				end
			end
		end
	end,
})

-- Enable LSP servers for Neovim 0.11+
--
-- A server whose binary this machine does not have fails to spawn once per
-- buffer it tries to attach to, which is a notification on every file. The
-- list is filtered instead, so a server that is not installed is silent.
local needs_binary = { biome = "biome", graphql = "graphql-lsp" }
local servers = {
	"vtsls",
	"oxlint",
	"eslint",
	"lua_ls",
	"gopls",
	"rust_analyzer",
	"cssls",
	"html",
	"jsonls",
	"yamlls",
	"dockerls",
	"bashls",
	"biome",
	"taplo",
	"nil_ls",
	"graphql",
}

---@param name string
---@return boolean
local function spawnable(name)
	local binary = needs_binary[name]
	if binary then
		return vim.fn.executable(binary) == 1
	end
	-- oxlint and eslint resolve their command against the project, so there is
	-- no fixed binary to look for and nvim decides.
	local cmd = vim.lsp.config[name].cmd
	return type(cmd) ~= "table" or vim.fn.executable(cmd[1]) == 1
end

vim.lsp.enable(vim.tbl_filter(spawnable, servers))

vim.keymap.set("n", "<leader>uh", function()
	local off = not vim.b[0].inlay_hints_off
	vim.b[0].inlay_hints_off = off
	vim.lsp.inlay_hint.enable(not off, { bufnr = 0 })
	vim.notify(off and "off" or "on", vim.log.levels.INFO, { title = "inlay hints" })
end, { desc = "Toggle Inlay Hints" })

return M
