-- LSP
local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- List+preview floating picker for multi-result LSP locations (replaces the default quickfix list).
local picker = require("config.picker")
local function on_list(list)
	picker.locations(list.items, list.title)
end

-- Route LSP code actions through the floating list+preview picker. In 0.11+,
-- vim.lsp.buf.code_action is a single-argument function that funnels results to
-- vim.ui.select with kind == 'codeaction' (snacks.nvim, fzf-lua, telescope all hook in
-- here). We override it instead of passing a handler, which buf.code_action ignores.
local ui_select = vim.ui.select
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
	if opts and opts.kind == "codeaction" then
		picker.code_actions(items, on_choice, opts and opts.format_item)
		return
	end
	return ui_select(items, opts, on_choice)
end

-- LSP native keymaps
-- stylua: ignore start
vim.keymap.set("n", "gd", function() vim.lsp.buf.definition({ on_list = on_list }) end, { desc = "Goto Definition" })
vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration({ on_list = on_list }) end, { desc = "Goto Declaration" })
vim.keymap.set("n", "gR", function() vim.lsp.buf.references(nil, { on_list = on_list }) end, { desc = "References" })
vim.keymap.set("n", "gI", function() vim.lsp.buf.implementation({ on_list = on_list }) end, { desc = "Goto Implementation" })
vim.keymap.set("n", "gy", function() vim.lsp.buf.type_definition({ on_list = on_list }) end, { desc = "Goto Type Definition" })
vim.keymap.set("n", "grt", vim.lsp.buf.type_definition, { desc = "Goto Type Definition" })
vim.keymap.set("n", "<leader>ss", function() vim.lsp.buf.document_symbol({ on_list = on_list }) end, { desc = "LSP Symbols" })
-- stylua: ignore end

-- One formatter per buffer.
-- vim.lsp.buf.format() with no filter runs *every* attached client that advertises
-- textDocument/formatting, in sequence. In a TS buffer that means oxfmt formats,
-- then vtsls re-indents the result with tsserver's own style: the file ends up in
-- neither style. Servers that format as a side job never win here, and when no
-- dedicated formatter is attached the buffer is left untouched.
local format_never = { vtsls = true, ts_ls = true, eslint = true, oxlint = true }
local format_rank = { oxfmt = 1, biome = 2, stylua = 3, taplo = 4 }

---@param bufnr integer
---@return vim.lsp.Client?
local function formatter(bufnr)
	local best
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })) do
		if not format_never[c.name] and (not best or (format_rank[c.name] or 9) < (format_rank[best.name] or 9)) then
			best = c
		end
	end
	return best
end

local default_keymaps = {
	{ keys = "<leader>ca", func = vim.lsp.buf.code_action, desc = "Code Actions" },
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
	{ keys = "<leader>cw", func = vim.lsp.buf.workspace_diagnostics, desc = "Workspace Diagnostics" },
	{
		keys = "<leader>cf",
		func = function()
			local client = formatter(0)
			if not client then
				vim.notify("No formatter for this buffer", vim.log.levels.WARN, { title = "LSP Format" })
				return
			end
			vim.lsp.buf.format({ id = client.id, async = true })
			vim.notify("Formatted with " .. client.name, vim.log.levels.INFO, { title = "LSP Format" })
		end,
		desc = "Format buffer",
	},
}

local completion = vim.g.completion_mode or "blink" -- or 'native'
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf
		if client then
			-- Built-in completion
			if completion == "native" and client:supports_method("textDocument/completion") then
				vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
			end

			if client:supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(true, { bufnr = buf })

				-- Hints are in the way of the text being written, so they go for
				-- the length of an insert session.
				if not vim.b[buf].inlay_hints_autocmd_set then
					for _, mode in ipairs({ "InsertEnter", "InsertLeave" }) do
						vim.api.nvim_create_autocmd(mode, {
							buffer = buf,
							callback = function()
								vim.lsp.inlay_hint.enable(mode == "InsertLeave", { bufnr = buf })
							end,
						})
					end
					vim.b[buf].inlay_hints_autocmd_set = true
				end
			end

			-- On-type formatting, but not from tsserver: it re-indents lines as you
			-- type `;`, `}` or newline using its own style, not the project's.
			if not format_never[client.name] and client:supports_method("textDocument/onTypeFormatting") then
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
					vim.keymap.set("n", km.keys, km.func, { buffer = buf, desc = "LSP: " .. km.desc })
					vim.b[buf].lsp_keymaps_set[km.keys] = true
				end
			end
		end
	end,
})

local ts_server = vim.g.lsp_typescript_server or "vtsls"

-- Enable LSP servers for Neovim 0.11+
vim.lsp.enable({
	ts_server,
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
	"oxfmt",
	"stylua",
	"taplo",
	"nil_ls",
	"graphql",
})

-- Load Lsp on-demand, e.g: eslint is disable by default
-- e.g: We could enable eslint by set vim.g.lsp_on_demands = {"eslint"}
if vim.g.lsp_on_demands then
	vim.lsp.enable(vim.g.lsp_on_demands)
end

-- Format on save implementation
vim.api.nvim_create_user_command("FormatDisable", function(opts)
	if opts.bang then
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
	vim.notify("Autoformat disabled" .. (opts.bang and " (buffer)" or " (global)"), vim.log.levels.WARN)
end, { desc = "Disable autoformat-on-save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
	vim.notify("Autoformat enabled", vim.log.levels.INFO)
end, { desc = "Re-enable autoformat-on-save" })

vim.keymap.set("n", "<leader>uf", function()
	if vim.g.disable_autoformat then
		vim.cmd("FormatDisable")
	else
		vim.cmd("FormatEnable")
	end
end, { desc = "Toggle Autoformat" })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("autoformat"),
	callback = function(args)
		local bufnr = args.buf
		if vim.bo[bufnr].filetype == "sql" then
			return
		end
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		if vim.api.nvim_buf_get_name(bufnr):match("/node_modules/") then
			return
		end
		-- Only format when a dedicated formatter is attached; stay silent otherwise.
		local client = formatter(bufnr)
		if not client then
			return
		end
		vim.lsp.buf.format({
			bufnr = bufnr,
			id = client.id,
			timeout_ms = 2000,
		})
	end,
})
