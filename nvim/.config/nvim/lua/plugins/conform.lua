vim.pack.add({
	"https://github.com/stevearc/conform.nvim",
})

local conform = require("conform")
local util = require("conform.util")

-- A config in $HOME is this machine's default, not a project's decision, so
-- every search below stops before it.
local HOME = vim.uv.os_homedir()
local GLOBAL_OXFMT = vim.fs.joinpath(HOME, ".oxfmtrc.json")

local PRETTIER_FILES = {
	".prettierrc",
	".prettierrc.json",
	".prettierrc.yml",
	".prettierrc.yaml",
	".prettierrc.json5",
	".prettierrc.js",
	".prettierrc.cjs",
	".prettierrc.mjs",
	".prettierrc.ts",
	".prettierrc.cts",
	".prettierrc.mts",
	".prettierrc.toml",
	"prettier.config.js",
	"prettier.config.cjs",
	"prettier.config.mjs",
	"prettier.config.ts",
	"prettier.config.cts",
	"prettier.config.mts",
}
local OXFMT_FILES = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts", "oxfmt.config.mts" }
local BIOME_FILES = { "biome.json", "biome.jsonc" }

---@param names string[]
---@param dirname string
---@return string|nil
local function nearest(names, dirname)
	return vim.fs.find(names, { path = dirname, upward = true, stop = HOME })[1]
end

---@param dirname string
---@return boolean
local function has_prettier_config(dirname)
	local names = vim.list_extend({ "package.json" }, PRETTIER_FILES)
	for _, path in ipairs(vim.fs.find(names, { path = dirname, upward = true, stop = HOME, limit = math.huge })) do
		if vim.fs.basename(path) ~= "package.json" then
			return true
		end
		local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
		if ok and type(decoded) == "table" and decoded.prettier ~= nil then
			return true
		end
	end
	return false
end

---@param dirname string
---@return boolean
local function has_bunfmt_config(dirname)
	local bunfig = nearest({ "bunfig.toml" }, dirname)
	if not bunfig then
		return false
	end
	local ok, lines = pcall(vim.fn.readfile, bunfig)
	return ok and vim.iter(lines):any(function(line)
		return line:match("^%s*%[fmt%]") ~= nil
	end)
end

local function override(name, opts)
	conform.formatters[name] = vim.tbl_deep_extend("force", require("conform.formatters." .. name), opts)
end

override("prettier", {
	condition = function(_, ctx)
		return has_prettier_config(ctx.dirname)
	end,
})

override("biome", {
	condition = function(_, ctx)
		return nearest(BIOME_FILES, ctx.dirname) ~= nil
	end,
})

conform.formatters.oxfmt = {
	command = util.from_node_modules("oxfmt"),
	-- oxfmt's own discovery never looks in $HOME, so the machine config has to be
	-- passed by hand when the project has none.
	args = function(_, ctx)
		local config = nearest(OXFMT_FILES, ctx.dirname) or (vim.uv.fs_stat(GLOBAL_OXFMT) and GLOBAL_OXFMT)
		if config then
			return { "-c", config, "--stdin-filepath", "$FILENAME" }
		end
		return { "--stdin-filepath", "$FILENAME" }
	end,
	stdin = true,
}

conform.formatters.bun_fmt = {
	command = "bun",
	-- Without --no-script, `bun fmt` runs the project's own `fmt` script and
	-- hands it these arguments, so a save could run arbitrary repo code.
	args = { "fmt", "--no-script", "--stdin-filepath", "$FILENAME" },
	stdin = true,
	cwd = util.root_file({ "bunfig.toml", "package.json" }),
	-- bun fmt reads .prettierrc, so it stands in for a repo that ships a prettier
	-- config but not the prettier binary.
	condition = function(_, ctx)
		return has_bunfmt_config(ctx.dirname) or has_prettier_config(ctx.dirname)
	end,
}

local web = { "prettier", "biome", "bun_fmt", "oxfmt", stop_after_first = true }

-- prisma format only writes files, so conform runs it on a temp copy next to the
-- schema and reads that back.
conform.formatters.prisma_format = {
	command = util.from_node_modules("prisma"),
	args = { "format", "--schema", "$FILENAME" },
	stdin = false,
	cwd = util.root_file({ "schema.prisma" }),
}

conform.setup({
	notify_no_formatters = false,
	default_format_opts = { lsp_format = "never", timeout_ms = 2000 },
	formatters_by_ft = {
		lua = { "stylua" },
		nix = { "nixfmt" },
		-- goimports walks the whole module on a cold run (7s in gowrap/gozzi) and
		-- misses the save timeout; sorting imports is gopls' code action.
		go = { "gofmt" },
		rust = { "rustfmt" },
		python = { "ruff_format", "black", stop_after_first = true },
		toml = { "taplo" },
		prisma = { "prisma_format" },
		javascript = web,
		javascriptreact = web,
		typescript = web,
		typescriptreact = web,
		vue = web,
		svelte = web,
		astro = web,
		css = web,
		scss = web,
		less = web,
		html = web,
		handlebars = web,
		json = web,
		jsonc = web,
		json5 = web,
		yaml = web,
		markdown = web,
		["markdown.mdx"] = web,
		graphql = web,
	},
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		if vim.bo[bufnr].filetype == "sql" then
			return
		end
		if vim.api.nvim_buf_get_name(bufnr):match("/node_modules/") then
			return
		end
		return {}
	end,
})

-- The flag conform's format_on_save reads, so the toggle lives here and not in
-- the LSP layer.
vim.api.nvim_create_user_command("FormatDisable", function(opts)
	if opts.bang then
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
	vim.notify("off" .. (opts.bang and " (buffer)" or " (global)"), vim.log.levels.WARN, { title = "autoformat" })
end, { desc = "Disable autoformat-on-save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
	vim.notify("on", vim.log.levels.INFO, { title = "autoformat" })
end, { desc = "Re-enable autoformat-on-save" })

vim.keymap.set("n", "<leader>uf", function()
	if vim.g.disable_autoformat or vim.b[0].disable_autoformat then
		vim.cmd("FormatEnable")
	else
		vim.cmd("FormatDisable")
	end
end, { desc = "Toggle Autoformat" })

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	local bufnr = require("config.buffer").target()
	-- sql is left out of format_on_save so a save stays instant, and the plan for
	-- it has always been the LSP formatter. Asking conform for a file it has no
	-- formatter for would only answer "no formatters available".
	if #conform.list_formatters(bufnr) == 0 then
		local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
		if #clients == 0 then
			vim.notify("No formatter for " .. vim.bo[bufnr].filetype, vim.log.levels.WARN, { title = "format" })
			return
		end
		vim.lsp.buf.format({ bufnr = bufnr, async = true, timeout_ms = 2000 })
		return
	end
	conform.format({ async = true, bufnr = bufnr }, function(err)
		if err then
			vim.notify(err, vim.log.levels.ERROR, { title = "format" })
		end
	end)
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>cF", "<cmd>ConformInfo<cr>", { desc = "Conform Info" })
