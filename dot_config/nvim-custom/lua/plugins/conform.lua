return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			perl = { "perltidy" },
			python = { "isort", "black" },
			javascript = { "prettier" },
      typescript = { "prettier" },
		},
		format_on_save = false,
		formatters = {
			perltidy = {
				append_args = { "-pro=~/devel/github/mozilla/bmo/master/.perltidyrc" },
			},
		},
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
