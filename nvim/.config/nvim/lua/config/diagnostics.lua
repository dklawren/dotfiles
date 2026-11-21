local map = vim.keymap.set

-- Colours for both live in config/theme.lua, which reapplies them after a
-- colorscheme reload clears every group.
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })

local sev = vim.diagnostic.severity

vim.diagnostic.config({
	-- underline and update_in_insert are what nvim already does
	severity_sort = true, -- orders the sign column

	float = {
		border = "rounded",
		source = true,
	},

	-- keep signs & virtual text, but tune them as you like
	signs = {
		linehl = {
			[sev.ERROR] = "DiagnosticErrorLine",
		},
		text = {
			[sev.ERROR] = " ",
			[sev.WARN] = " ",
			[sev.INFO] = " ",
			[sev.HINT] = "󰌵 ",
		},
	},
	virtual_text = {
		source = "if_many",
		prefix = "●",
	},
})

-- diagnostic keymaps
local diagnostic_goto = function(next, severity)
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		vim.diagnostic.jump({ count = next and 1 or -1, float = true, severity = severity })
	end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

map("n", "<leader>ud", function()
	local on = not vim.diagnostic.is_enabled()
	vim.diagnostic.enable(on)
	vim.notify(on and "on" or "off", vim.log.levels.INFO, { title = "diagnostics" })
end, { desc = "Toggle Diagnostics" })

map("n", "<leader>sd", function()
	require("config.picker").diagnostics(vim.diagnostic.get(0), "Document Diagnostics", { scope = "buffer" })
end, { desc = "Document Diagnostics" })
map("n", "<leader>cD", function()
	require("config.picker").diagnostics(vim.diagnostic.get(), "Workspace Diagnostics")
end, { desc = "Workspace Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
