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

-- :Oil with no argument opens the current buffer's own directory, and
-- fnamemodify(dir, ":p:h") returns that directory unchanged, so from a netrw
-- listing or a directory buffer it reopens where you already are. Resolve the
-- directory on screen first, then step up from it. For a file, nil lets oil
-- open the file's own directory with the cursor on it.
local function shown_dir()
	local name = vim.api.nvim_buf_get_name(0)
	if vim.bo.filetype == "oil" then
		return require("oil").get_current_dir()
	elseif vim.bo.filetype == "netrw" then
		return vim.b.netrw_curdir
	elseif name == "" then
		return vim.fn.getcwd()
	elseif vim.fn.isdirectory(name) == 1 then
		return name
	end
	return nil
end

vim.keymap.set("n", "-", function()
	local dir = shown_dir()
	require("oil").open(dir and vim.fs.dirname(vim.fs.normalize(dir)))
end, { desc = "Open parent directory" })
