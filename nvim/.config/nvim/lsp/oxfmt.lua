-- https://oxc.rs/docs/guide/usage/formatter/config.html
-- Install with: pnpm add -g oxfmt
--
-- oxfmt resolves its own config per file, walking up from that file's directory
-- (nearest config wins), independent of the server's cwd. So root_dir here only
-- decides *whether* to attach, never which config is used.
local CONFIG_FILES = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts", "oxfmt.config.mts" }

return {
	cmd = { "oxfmt", "--lsp" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"jsonc",
		"json5",
		"toml",
		"yaml",
		"css",
		"scss",
		"less",
		"graphql",
		"markdown",
		"html",
		"vue",
		"handlebars",
	},
	-- No project config, no formatting: same contract as conform.nvim + prettier.
	root_dir = function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		if fname == "" then
			return
		end
		-- Stop at $HOME so a global ~/.oxfmtrc.json never counts as project config.
		local marker = vim.fs.find(CONFIG_FILES, { path = fname, upward = true, stop = vim.uv.os_homedir() })[1]
		if marker then
			on_dir(vim.fs.dirname(marker))
		end
	end,
	workspace_required = true,
}
