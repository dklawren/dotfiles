-- vim.fs.root checks markers in order, not by proximity: it searches upward for
-- marker[1] anywhere above, only falling to marker[2] if marker[1] is found nowhere.
-- tsconfig/package.json must come first so a project nested under a plain folder
-- (no .git or lockfile of its own) roots at the project, not at an outer .git.
local root_markers = {
	"tsconfig.json",
	"jsconfig.json",
	"package.json",
	"package-lock.json",
	"yarn.lock",
	"pnpm-lock.yaml",
	"bun.lockb",
	"bun.lock",
	".git",
}

return {
	cmd = { "vtsls", "--stdio" },
	init_options = { hostInfo = "neovim" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_dir = function(bufnr, on_dir)
		local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
		local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
		local project_root = vim.fs.root(bufnr, root_markers)
		if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
			return
		end
		if deno_root and (not project_root or #deno_root >= #project_root) then
			return
		end
		on_dir(project_root or vim.fn.getcwd())
	end,
	settings = {
		typescript = {
			tsserver = {
				maxTsServerMemory = 4096,
			},
		},
		vtsls = {
			autoUseWorkspaceTsdk = true,
		},
	},
}
