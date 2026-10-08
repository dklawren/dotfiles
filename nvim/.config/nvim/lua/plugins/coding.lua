-- Keep the optional tracker dormant until its first command.
vim.g.loaded_codeme = 1
vim.pack.add({
	"https://gitlab.com/tduyng/codeme.nvim",
})

local configured = false
local function setup()
	if configured then
		return
	end
	-- Stops tracking future data. The dashboard ignores are already codeme's
	-- own: the same three languages, and no projects or files.
	require("codeme").setup({
		ignores = {
			tracking = {
				projects = {},
			},
		},
	})
	configured = true
end

vim.api.nvim_create_user_command("CodeMe", function()
	setup()
	require("codeme").open_dashboard()
end, { desc = "Open CodeMe dashboard" })
vim.api.nvim_create_user_command("CodeMeToggle", function()
	setup()
	require("codeme").toggle_dashboard()
end, { desc = "Toggle CodeMe dashboard" })
vim.api.nvim_create_user_command("CodeMeTrack", function()
	setup()
	require("codeme").manual_track()
end, { desc = "Manually send heartbeat" })

vim.keymap.set("n", "<leader>cm", "<cmd>CodeMe<cr>", { desc = "Open CodeMe Dashboard" })
vim.keymap.set("n", "<leader>cM", "<cmd>CodeMeToggle<cr>", { desc = "Toggle CodeMe" })
