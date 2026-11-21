local typescript = require("config.typescript")

-- The other TypeScript server: a project that wants typescript-language-server
-- instead of vtsls enables it with vim.lsp.enable("ts_ls") in its .nvim.lua.
-- Nothing bundled this machine ships a config for it, so without a cmd the
-- client had nothing to spawn and quietly never started.
return {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_dir = function(bufnr, on_dir)
		on_dir(vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json", "package.json", ".git" }) or vim.fn.getcwd())
	end,
	settings = {
		typescript = typescript.settings(),
		javascript = typescript.settings(),
	},
}
