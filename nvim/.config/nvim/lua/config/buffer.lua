-- Tab switching
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

-- buffers
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

-- Buffers (floating picker with preview)
vim.keymap.set("n", "<leader>fb", function()
	local bufs = vim.fn.getbufinfo({ buflisted = 1, bufloaded = 1 })
	local items = {}
	for _, buf in ipairs(bufs) do
		table.insert(items, { name = vim.fn.bufname(buf.bufnr), bufnr = buf.bufnr })
	end
	require("config.picker").open(items, {
		title = "Buffers",
		skip_single = false,
		format = function(item)
			return item.name ~= "" and item.name or "[No Name]"
		end,
		preview = function(item, ctx)
			local lines = vim.api.nvim_buf_get_lines(item.bufnr, 0, -1, false)
			ctx.set_lines(lines, vim.bo[item.bufnr].filetype)
		end,
		on_confirm = function(item)
			vim.cmd("buffer " .. item.bufnr)
		end,
	})
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bo", function()
	local current = vim.fn.bufnr()
	local bufs = vim.fn.getbufinfo({ buflisted = 1 })
	local targets = {}
	for _, buf in ipairs(bufs) do
		if buf.bufnr ~= current then
			table.insert(targets, buf.bufnr)
		end
	end
	for _, bufnr in ipairs(targets) do
		vim.cmd("bdelete! " .. bufnr)
	end
end, { desc = "Delete other buffers" })
