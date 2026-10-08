vim.pack.add({
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
})

require("oil").setup({
	default_file_explorer = false,
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
	view_options = {
		show_hidden = true,
		natural_order = true,
		is_always_hidden = function(name, _)
			return name == ".." or name == ".git"
		end,
	},
	float = {
		padding = 4,
		max_width = 80,
		max_height = 30,
	},
	-- oil binds all of these already. The three splits restate the default with
	-- the deprecated action that names the split in its description, and ~ is
	-- ours: oil's own is g~, a tab-scoped cd.
	keymaps = {
		["<C-s>"] = "actions.select_vsplit",
		["<C-h>"] = "actions.select_split",
		["<C-t>"] = "actions.select_tab",
		["~"] = "actions.tcd",
	},
})

vim.keymap.set("n", "<leader>e", function()
	if vim.bo.filetype == "oil" then
		require("oil").close()
	else
		require("oil").open()
	end
end, { desc = "File Explorer" })

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
