--- diagnostic settings
local map = vim.keymap.set
local palette = {
	err = "#51202A",
	warn = "#3B3B1B",
	info = "#1F3342",
	hint = "#1E2E1E",
}

vim.api.nvim_set_hl(0, "DiagnosticErrorLine", { bg = palette.err, blend = 20 })
vim.api.nvim_set_hl(0, "DiagnosticWarnLine", { bg = palette.warn, blend = 15 })
vim.api.nvim_set_hl(0, "DiagnosticInfoLine", { bg = palette.info, blend = 10 })
vim.api.nvim_set_hl(0, "DiagnosticHintLine", { bg = palette.hint, blend = 10 })
vim.api.nvim_set_hl(0, "DapBreakpointSign", { fg = "#FF0000", bg = nil, bold = true })
vim.fn.sign_define("DapBreakpoint", {
	text = "●", -- a large dot; change as desired
	texthl = "DapBreakpointSign", -- the highlight group you just defined
	linehl = "", -- no full-line highlight
	numhl = "", -- no number-column highlight
})

local sev = vim.diagnostic.severity

vim.diagnostic.config({
	-- keep underline & severity_sort on for quick scanning
	underline = true,
	severity_sort = true,
	update_in_insert = false, -- less flicker

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
		spacing = 4,
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
local function to_items(diagnostics)
	local items = {}
	for _, d in ipairs(diagnostics) do
		table.insert(items, {
			text = d.message,
			lnum = d.lnum,
			col = d.col,
			severity = d.severity,
			bufnr = d.bufnr,
			source = d.source or "",
		})
	end
	return items
end

map("n", "<leader>sd", function()
	require("config.picker").diagnostics(to_items(vim.diagnostic.get(0)), "Document Diagnostics", { scope = "buffer" })
end, { desc = "Document Diagnostics" })
map("n", "<leader>cD", function()
	require("config.picker").diagnostics(to_items(vim.diagnostic.get(nil)), "Workspace Diagnostics")
end, { desc = "Workspace Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
