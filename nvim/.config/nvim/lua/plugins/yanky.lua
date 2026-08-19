vim.pack.add({
	"https://github.com/gbprod/yanky.nvim",
})

local loaded = false

local function load()
	if loaded then
		return
	end
	loaded = true

	require("yanky").setup({
		highlight = { timer = 150 },
	})
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("YankyLazy", { clear = true }),
	once = true,
	callback = load,
})

local function pick()
	local history = require("yanky.history").all()
	local picker = require("config.picker")

	picker.open(history, {
		title = "Yank History",
		skip_single = false,
		format = function(item, i)
			local first_line = vim.split(item.regcontents or "", "\n")[1] or ""
			local type_label = item.regtype == "V" and "line" or item.regtype == "\22" and "block" or "char"
			return ("[%d] %s (%s)"):format(i, first_line, type_label)
		end,
		preview = function(item, ctx)
			ctx.set_lines(vim.split(item.regcontents or "", "\n"))
		end,
		on_confirm = function(item)
			vim.fn.setreg('"', item.regcontents, item.regtype)
			if vim.tbl_contains(vim.opt.clipboard:get(), "unnamedplus") then
				vim.fn.setreg("+", item.regcontents, item.regtype)
			end
			vim.schedule(function()
				vim.cmd("normal! p")
			end)
		end,
	})
end

-- stylua: ignore start
vim.keymap.set({ "n", "x" }, "y", function() load(); return "<Plug>(YankyYank)" end, { expr = true })
vim.keymap.set({ "n", "x" }, "p", function() load(); return "<Plug>(YankyPutAfter)" end, { expr = true })
vim.keymap.set({ "n", "x" }, "P", function() load(); return "<Plug>(YankyPutBefore)" end, { expr = true })
vim.keymap.set("n", "<C-p>", function() load(); return "<Plug>(YankyCycleForward)" end, { expr = true })
vim.keymap.set("n", "<C-n>", function() load(); return "<Plug>(YankyCycleBackward)" end, { expr = true })
vim.keymap.set({ "n", "x" }, "<leader>y", function() load(); pick() end, { desc = "Yank History" })
-- stylua: ignore end
