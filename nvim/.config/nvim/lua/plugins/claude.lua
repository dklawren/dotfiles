vim.pack.add({
	"https://github.com/greggh/claude-code.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
})

require("claude-code").setup({
	window = {
		position = "botright vsplit", -- right-hand vertical split
		split_ratio = 0.35, -- fraction of total columns
	},
	keymaps = {
		toggle = {
			normal = "<leader>ac",
			terminal = "<C-g>",
			variants = {
				continue = "<leader>aC",
				verbose = "<leader>aV",
			},
		},
		-- Keep the tmux-aware <C-h/j/k/l> maps from config/keymaps.lua
		window_navigation = false,
		scrolling = true,
	},
})

vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCodeResume<cr>", { desc = "Claude Code (resume picker)" })

-- Upstream bug (greggh/claude-code.nvim @ 55c0cb5): its TermClose handler calls
-- nvim_buf_get_name(args.buf) unguarded, but the terminal buffer is often already
-- wiped by then -> "Invalid buffer id". Swap in a guarded handler that identifies
-- the buffer via the instance table first and only falls back to the name check.
pcall(function()
	for _, au in ipairs(vim.api.nvim_get_autocmds({ group = "ClaudeCodeFileRefresh", event = "TermClose" })) do
		vim.api.nvim_del_autocmd(au.id)
	end
end)

vim.api.nvim_create_autocmd("TermClose", {
	group = vim.api.nvim_create_augroup("ClaudeCodeFileRefresh", { clear = false }),
	pattern = "*",
	callback = function(args)
		local state = require("claude-code").claude_code
		local tracked = false
		for id, bufnr in pairs(state.instances or {}) do
			if bufnr == args.buf then
				state.instances[id] = nil
				tracked = true
				break
			end
		end
		if not tracked then
			local ok, name = pcall(vim.api.nvim_buf_get_name, args.buf)
			if not (ok and name:match("claude%-code")) then
				return
			end
		end
		vim.o.updatetime = state.saved_updatetime or vim.o.updatetime
		vim.schedule(function()
			for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
				pcall(vim.api.nvim_win_close, win, true)
			end
			pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
		end)
	end,
	desc = "Clean up when Claude Code terminal closes (guarded)",
})
