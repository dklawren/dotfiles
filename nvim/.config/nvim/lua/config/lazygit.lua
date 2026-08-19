-- Git
vim.keymap.set("n", "<leader>gg", function()
	-- Set EDITOR to use nvim-remote so lazygit opens files in current instance
	local old_editor = vim.env.EDITOR
	local old_visual = vim.env.VISUAL
	vim.env.EDITOR = "nvim-remote"
	vim.env.VISUAL = "nvim-remote"
	vim.cmd("terminal lazygit")
	vim.cmd("startinsert")

	-- Restore original EDITOR/VISUAL after terminal closes
	vim.api.nvim_create_autocmd("TermClose", {
		pattern = "*",
		callback = function()
			vim.env.EDITOR = old_editor
			vim.env.VISUAL = old_visual
		end,
		once = true,
	})
end, { desc = "LazyGit" })
