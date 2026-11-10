-- Upstream's install recipe. This must be registered before vim.pack.add, since
-- add() fires PackChanged itself. The call blocks until the binary is written,
-- so a pack update cannot exit with a half-downloaded library.
vim.api.nvim_create_autocmd("PackChanged", {
	desc = "Download the fff.nvim binary on install and update",
	group = vim.api.nvim_create_augroup("fff-pack-changed", { clear = true }),
	callback = function(ev)
		local kind = ev.data.kind
		if ev.data.spec.name ~= "fff.nvim" or (kind ~= "install" and kind ~= "update") then
			return
		end
		if not ev.data.active then
			vim.cmd.packadd("fff.nvim")
		end
		require("fff.download").download_or_build_binary()
	end,
})

vim.pack.add({
	"https://github.com/dmtrKovalenko/fff.nvim",
})

-- Only what differs from fff's own defaults: a shell prompt, a taller picker
-- with the prompt on top, a bigger preview read, and the vim-flavoured keys.
require("fff").setup({
	prompt = "> ",
	layout = {
		height = 0.85,
		width = 0.85,
		prompt_position = "top",
		preview_size = 0.45,
	},
	preview = {
		max_size = 15 * 1024 * 1024,
		chunk_size = 16384,
	},
	keymaps = {
		close = { "<Esc>", "<C-c>" },
		select = { "<CR>", "<C-o>" },
		move_up = { "<Up>", "<C-p>", "<C-k>" },
		move_down = { "<Down>", "<C-n>", "<C-j>" },
		preview_scroll_up = { "<C-u>", "<PageUp>" },
		preview_scroll_down = { "<C-d>", "<PageDown>" },
	},
})

-- stylua: ignore start
vim.keymap.set("n", "<leader><space>", function() require("fff").find_files() end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>/", function() require("fff").live_grep() end, { desc = "Grep" })
vim.keymap.set("n", "<leader>ff", function() require("fff").find_files() end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function() require("fff").live_grep() end, { desc = "Grep" })
vim.keymap.set({ "n", "x" }, "<leader>fw", function() require("fff").live_grep_under_cursor() end, { desc = "Grep Word" })
vim.keymap.set("n", "<leader>fc", function() require("fff").find_files_in_dir(vim.fn.stdpath("config")) end, { desc = "Find Config File" })
vim.keymap.set("n", "<leader>fr", function() require("fff").find_files() end, { desc = "Recent Files" })
-- stylua: ignore end
