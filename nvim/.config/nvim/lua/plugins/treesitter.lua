vim.pack.add({
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "main",
	},
})

require("nvim-treesitter").setup({})

-- nvim-treesitter keeps its queries in runtime/, which nvim puts on the
-- runtimepath from 0.13 on. Without it, the languages nvim ships a parser for
-- (lua, c, markdown, vim, ...) get no indents query, indentexpr answers 0, and
-- = leaves the file flat.
if vim.fn.has("nvim-0.13") == 0 then
	local init = vim.api.nvim_get_runtime_file("lua/nvim-treesitter/init.lua", false)[1]
	local root = init and vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(init)))
	if root and vim.fn.isdirectory(root .. "/runtime") == 1 then
		vim.opt.rtp:prepend(root .. "/runtime")
	end
end

-- `goose` is missing from nvim-treesitter's registry: its parser comes from a
-- fork of aardappel/goose with the generated parser.c committed. TSUpdate
-- reloads the parsers table, so the entry goes back in from an autocmd.
local goose_parser = {
	install_info = {
		url = "https://github.com/RomanPro100/goose-tree-sitter",
		branch = "master",
		files = { "src/parser.c", "src/scanner.c" },
		queries = "queries",
	},
}
require("nvim-treesitter.parsers").goose = goose_parser
vim.api.nvim_create_autocmd("User", {
	desc = "Re-register the goose parser after TSUpdate reloads the parsers table",
	pattern = "TSUpdate",
	callback = function()
		require("nvim-treesitter.parsers").goose = goose_parser
	end,
})

-- The parsers nvim 0.13 ships are left out: c, diff, lua, markdown,
-- markdown_inline, query, vim and vimdoc.
require("nvim-treesitter").install({
	"bash",
	"blade",
	"comment",
	"css",
	"dockerfile",
	"fish",
	"gitcommit",
	"gitignore",
	"go",
	"goose",
	"gomod",
	"gosum",
	"gowork",
	"html",
	"ini",
	"javascript",
	"jsdoc",
	"json",
	"luadoc",
	"luap",
	"make",
	"nginx",
	"nix",
	"proto",
	"python",
	"regex",
	"rust",
	"scss",
	"sql",
	"terraform",
	"toml",
	"tsx",
	"typescript",
	"xml",
	"yaml",
	"zig",
})

vim.api.nvim_create_autocmd("PackChanged", {
	desc = "Handle nvim-treesitter updates",
	group = vim.api.nvim_create_augroup("nvim-treesitter-pack-changed-update-handler", { clear = true }),
	callback = function(event)
		if event.data.kind == "update" then
			local ok = pcall(vim.cmd.TSUpdate)
			if ok then
				vim.notify("TSUpdate completed successfully!", vim.log.levels.INFO)
			else
				vim.notify("TSUpdate command not available yet, skipping", vim.log.levels.WARN)
			end
		end
	end,
})

-- The buffers treesitter is not wanted on: nvim's own panels, the ones a
-- plugin here puts on screen, and a filetype of "". Anything not listed still
-- reaches vim.treesitter.start(), which is a no-op without a parser for it.
local SKIP_FT = {
	[""] = true,
	qf = true,
	help = true,
	man = true,
	checkhealth = true,
	gitcommit = true,
	gitrebase = true,
	["grug-far"] = true,
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "*" },
	callback = function()
		local ft = vim.bo.filetype
		if SKIP_FT[ft] then
			return
		end

		local ok = pcall(vim.treesitter.start)
		if not ok then
			return
		end

		-- Only when treesitter started. Must be per-buffer here: at module scope
		-- vim.bo/vim.wo only touch whatever buffer exists during startup.
		--
		-- The two options are set to function references, not to the "v:lua...."
		-- strings this used to hold, and that is the whole point of the lines.
		-- Both options are evaluated once per line: foldexpr for every line in
		-- the buffer, indentexpr for every line on a re-indent. A v:lua string
		-- makes nvim parse the string and look the name up in _G on each of
		-- those calls. That measured as 1.477ms against 0.518ms here, which was
		-- most of the cost of a file open when it was taken, on the path where
		-- switching between two already-loaded buffers is what the number meant.
		-- A genuine first open is 10.7ms, and these two lines are about 1ms of
		-- that, so keep them for the reason given above and not because they
		-- are the bulk of it.
		--
		-- What the bulk is, measured with the wrapper installed where it
		-- survives: nvim calls this function 5600 times for a 2800 line file,
		-- twice for every line, and 5.7ms of the open is spent inside it. One
		-- of those calls is 5.1ms, which is nvim walking the treesitter tree
		-- and building the fold levels table. The other 5599 are 0.57ms in
		-- total, 0.10 microseconds each. So the cost is one build and the
		-- per-line work is fifty thousand times cheaper than that one call,
		-- which is why setting these options earlier, or not re-setting them,
		-- measures as nothing: neither can remove the build, and the build
		-- happens once however the options arrive. Nothing in this file can
		-- change it, and the fold level is the feature rather than the
		-- plumbing.
		-- Assigning the function itself is what the runtime documents for
		-- foldexpr, and nvim calls it directly.
		--
		-- Both lines are load-bearing. With foldmethod expr and no foldexpr, no
		-- folds appear at all; with no indentexpr, nvim falls back to its own
		-- GetLuaIndent() and indentation stops coming from treesitter. Neither
		-- is caught by eyeballing a screenshot, which is why tests/fold_test.sh
		-- asserts both the levels and which function provides them.
		vim.wo[0].foldmethod = "expr"
		if vim.fn.has("nvim-0.13") == 1 then
			vim.wo[0].foldexpr = vim.treesitter.foldexpr
			-- Resolved here rather than captured at module scope, so a reload of
			-- nvim-treesitter is picked up instead of leaving a stale function in
			-- the option.
			vim.bo[0].indentexpr = require("nvim-treesitter").indentexpr
		else
			vim.wo[0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.bo[0].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
