-- Files lazygit opens land in this nvim through its `nvim-remote` editPreset
-- (dotfiles/lazygit/config.yml), which talks to $NVIM. No EDITOR override.
vim.keymap.set("n", "<leader>gg", function()
	vim.cmd("terminal lazygit")
	vim.cmd.startinsert()
end, { desc = "LazyGit" })
