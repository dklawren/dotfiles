vim.pack.add({ "https://github.com/eyko139/silverbullet.nvim" })

require("silverbullet").setup({
	default_space = "personal",
	spaces = {
		personal = {
			url = "https://pkms.davidklawrence.com",
			auth = {
				token_env = "SB_AUTH_TOKEN",
			},
		},
	},
})

vim.keymap.set("n", "<leader>zf", "<Plug>(SilverBulletFind)", { desc = "Find SilverBullet page" })
vim.keymap.set("n", "<leader>zk", "<Plug>(SilverBulletSetToken)", { desc = "Set SilverBullet token" })
vim.keymap.set("n", "<leader>zs", "<Plug>(SilverBulletSearch)", { desc = "Search SilverBullet pages" })
vim.keymap.set("n", "<leader>zb", "<Plug>(SilverBulletBacklinks)", { desc = "Show SilverBullet backlinks" })
vim.keymap.set("n", "<CR>", "<Plug>(SilverBulletFollowLink)", { desc = "Follow SilverBullet link" })
vim.keymap.set("n", "<leader>zo", "<Plug>(SilverBulletOpenWeb)", { desc = "Open SilverBullet page in browser" })
