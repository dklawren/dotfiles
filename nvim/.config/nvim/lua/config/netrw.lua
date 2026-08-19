vim.g.netrw_liststyle = 3 -- tree view
vim.g.netrw_banner = 0 -- hide the top banner
vim.g.netrw_winsize = 25 -- fix the left split width
vim.g.netrw_browse_split = 0 -- open files in the previous window
vim.g.netrw_altfile = 1 -- keep the alternate file correct

vim.keymap.set("n", "<leader>E", ":Lexplore<cr>", { silent = true, desc = "File Explorer (tree)" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function(args)
		local opts = { buffer = args.buf, silent = true }
		vim.keymap.set("n", "q", ":Lexplore<cr>", opts)
		vim.keymap.set("n", "<esc>", ":Lexplore<cr>", opts)
	end,
})
