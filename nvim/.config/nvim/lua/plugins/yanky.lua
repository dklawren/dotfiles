vim.pack.add({
	"https://github.com/gbprod/yanky.nvim",
})

-- Loaded here rather than on the first yank: setup inside a key mapping puts
-- plugin work in the keypress path, where it is felt as a lag on `yy`.
require("yanky").setup({
	highlight = { timer = 150 },
	-- Off: this reads the clipboard on every focus change, one blocking
	-- clipboard command each time the terminal comes back.
	system_clipboard = { sync_with_ring = false },
})

local function pick()
	local history = require("yanky.history").all()
	local picker = require("config.picker")

	picker.open(history, {
		title = "Yank History",
		skip_single = false,
		filter = true,
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
			if vim.o.clipboard:find("unnamedplus", 1, true) then
				vim.fn.setreg("+", item.regcontents, item.regtype)
			end
			vim.schedule(function()
				vim.cmd("normal! p")
			end)
		end,
	})
end

-- stylua: ignore start
vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)")
vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
vim.keymap.set("n", "<C-p>", "<Plug>(YankyCycleForward)")
vim.keymap.set("n", "<C-n>", "<Plug>(YankyCycleBackward)")
vim.keymap.set({ "n", "x" }, "<leader>y", pick, { desc = "Yank History" })
-- stylua: ignore end
