vim.pack.add({
	"https://gitlab.com/tduyng/codeme.nvim",
})

require("codeme").setup({
	ignores = {
		-- Stops tracking future data
		tracking = {
			projects = {},
		},
		-- Hides existing data from the UI immediately
		dashboard = {
			projects = {},
			files = {},
			languages = { "gitignore", "gitconfig", "sshconfig" },
		},
	},
})

vim.keymap.set("n", "<leader>cm", "<cmd>CodeMe<cr>", { desc = "Open CodeMe Dashboard" })
vim.keymap.set("n", "<leader>cM", "<cmd>CodeMeToggle<cr>", { desc = "Toggle CodeMe" })
