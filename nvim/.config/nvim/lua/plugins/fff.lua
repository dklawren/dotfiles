-- Before vim.pack.add: PackChanged fires inside add(), so a later handler never
-- sees "install" and the Rust binary is never built. See |vim.pack-events|.
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("fff-pack-changed", { clear = true }),
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "fff.nvim" and (kind == "install" or kind == "update") then
			if not ev.data.active then
				vim.cmd.packadd("fff.nvim")
			end
			require("fff.download").download_or_build_binary()
		end
	end,
})

vim.pack.add({
	"https://github.com/dmtrKovalenko/fff.nvim",
})

require("fff").setup({
	lazy_sync = true,
	prompt = "> ",
	max_results = 100,
	max_threads = 4,
	frecency = {
		enabled = true,
		recency_weight = 1.5,
		frequency_weight = 1.0,
	},
	history = {
		enabled = true,
		max_items = 500,
	},
	layout = {
		height = 0.85,
		width = 0.85,
		prompt_position = "top",
		preview_position = "right",
		preview_size = 0.45,
	},
	preview = {
		enabled = true,
		max_size = 15 * 1024 * 1024,
		chunk_size = 16384,
		syntax = true,
	},
	keymaps = {
		close = { "<Esc>", "<C-c>" },
		select = { "<CR>", "<C-o>" },
		select_split = "<C-s>",
		select_vsplit = "<C-v>",
		select_tab = "<C-t>",
		move_up = { "<Up>", "<C-p>", "<C-k>" },
		move_down = { "<Down>", "<C-n>", "<C-j>" },
		preview_scroll_up = { "<C-u>", "<PageUp>" },
		preview_scroll_down = { "<C-d>", "<PageDown>" },
		toggle_select = "<Tab>",
		send_to_quickfix = "<C-q>",
		toggle_preview = "<C-y>",
		refresh = "<C-r>",
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
