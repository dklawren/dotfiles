-- https://oxc.rs/docs/guide/usage/formatter/config.html
-- Install with: pnpm add -g oxfmt
--
-- oxfmt's own auto-discovery never crosses into $HOME (a ~/.oxfmtrc.json there
-- is silently ignored, even run directly from $HOME), and its `-c` CLI flag is
-- ignored entirely in --lsp mode. The only thing that reaches the LSP server is
-- the `fmt.configPath` setting it pulls via workspace/configuration under the
-- "oxc_language_server" section - and that's a hard override, not a fallback:
-- it wins even over a real project config. So to make oxfmt a universal
-- fallback formatter, nvim has to detect the no-project-config case itself and
-- push the global config path only then.
local CONFIG_FILES = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts", "oxfmt.config.mts" }
local GLOBAL_CONFIG = vim.fs.joinpath(vim.uv.os_homedir(), ".oxfmtrc.json")

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
	-- Always attach: project config wins when present (nearest wins, up to
	-- $HOME), otherwise fall back to the git root (or the file's own directory
	-- for a lone file) so unrelated projects don't share one oxfmt process.
	root_dir = function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		if fname == "" then
			return
		end
		local marker = vim.fs.find(CONFIG_FILES, { path = fname, upward = true, stop = vim.uv.os_homedir() })[1]
		on_dir(marker and vim.fs.dirname(marker) or vim.fs.root(bufnr, ".git") or vim.fs.dirname(fname))
	end,
	on_init = function(client)
		-- root_dir only ever equals a marker's own directory when one was found
		-- (the search above already covers every directory in between), so
		-- checking directly inside it tells "found" from "fell back" without
		-- redoing the upward walk.
		local has_project_config = vim.iter(CONFIG_FILES):any(function(f)
			return vim.uv.fs_stat(vim.fs.joinpath(client.root_dir, f)) ~= nil
		end)
		if not has_project_config and vim.uv.fs_stat(GLOBAL_CONFIG) then
			client.settings = { oxc_language_server = { ["fmt.configPath"] = GLOBAL_CONFIG } }
		end
	end,
}
