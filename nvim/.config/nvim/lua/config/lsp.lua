-- LSP
local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- List+preview floating picker for multi-result LSP locations (replaces the default quickfix list).
-- Code actions are routed there too: in 0.11+ vim.lsp.buf.code_action funnels
-- results to vim.ui.select with kind == 'codeaction', and picker.select answers.
local picker = require("config.picker")
local function on_list(list)
	picker.locations(list.items, list.title)
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
	"taplo",
	"nil_ls",
	"graphql",
})

-- Load Lsp on-demand, e.g: eslint is disable by default
-- e.g: We could enable eslint by set vim.g.lsp_on_demands = {"eslint"}
if vim.g.lsp_on_demands then
	vim.lsp.enable(vim.g.lsp_on_demands)
end

-- Autoformat toggles, honoured by conform's format_on_save.
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
