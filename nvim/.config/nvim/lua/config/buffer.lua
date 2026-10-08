local M = {}
local npcall = require("config.compat")

-- A plain loop rather than an iterator chain: nvim_list_bufs gives the checker
-- a generic element, and a loop says what an element is without a cast.
local function listed()
	local out = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= "" then
			out[#out + 1] = buf
		end
	end
	return out
end

-- Terminals report themselves as modified forever but have nothing to save.
local function unsaved(buf)
	return vim.bo[buf].modified and vim.bo[buf].buftype == ""
end

local function survivor(doomed)
	local cur = vim.api.nvim_get_current_buf()
	if not doomed[cur] and vim.bo[cur].buflisted then
		return cur
	end
	local alt = vim.fn.bufnr("#")
	if alt > 0 and vim.api.nvim_buf_is_valid(alt) and not doomed[alt] and vim.bo[alt].buflisted then
		return alt
	end
	for _, buf in ipairs(listed()) do
		if not doomed[buf] then
			return buf
		end
	end
	return vim.api.nvim_create_buf(true, false)
end

---@param targets integer[]
---@param force boolean? discard unsaved changes instead of keeping the buffer
function M.close(targets, force)
	local doomed, kept = {}, 0
	for _, buf in ipairs(targets) do
		if vim.api.nvim_buf_is_valid(buf) then
			if force or not unsaved(buf) then
				doomed[buf] = true
			else
				kept = kept + 1
			end
		end
	end

	if next(doomed) then
		-- Windows have to move off the doomed buffers first: otherwise Neovim
		-- picks each replacement itself and reads a file from disk that the next
		-- iteration deletes again.
		local keep = survivor(doomed)
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if doomed[vim.api.nvim_win_get_buf(win)] then
				vim.api.nvim_win_set_buf(win, keep)
			end
		end
		for buf in pairs(doomed) do
			npcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
	end

	if kept > 0 then
		vim.notify(kept .. " buffer(s) with unsaved changes kept", vim.log.levels.WARN)
	end
end

---@param side "left"|"right"|"other"
local function relative(side)
	local bufs = listed()
	local cur = vim.api.nvim_get_current_buf()
	-- Not vim.fn.index(): it answers 0-based with -1 for a miss.
	local idx = 0
	for i, buf in ipairs(bufs) do
		if buf == cur then
			idx = i
			break
		end
	end
	if idx == 0 then
		return side == "other" and bufs or {}
	end
	if side == "left" then
		return vim.list_slice(bufs, 1, idx - 1)
	end
	if side == "right" then
		return vim.list_slice(bufs, idx + 1)
	end
	return vim.list_extend(vim.list_slice(bufs, 1, idx - 1), vim.list_slice(bufs, idx + 1))
end

local map = vim.keymap.set

map("n", "<Tab>", "<Cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<Cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<Cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", "<Cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "]b", "<Cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "[b", "<Cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<leader>bb", "<Cmd>buffer #<CR>", { desc = "Other buffer" })

map("n", "<leader>bd", function()
	M.close({ vim.api.nvim_get_current_buf() })
end, { desc = "Close buffer" })

map("n", "<leader>bD", function()
	M.close({ vim.api.nvim_get_current_buf() }, true)
end, { desc = "Close buffer (force)" })

map("n", "<leader>bo", function()
	M.close(relative("other"))
end, { desc = "Close other buffers" })

map("n", "<leader>bl", function()
	M.close(relative("left"))
end, { desc = "Close left buffers" })

map("n", "<leader>br", function()
	M.close(relative("right"))
end, { desc = "Close right buffers" })

map("n", "<leader>ba", function()
	M.close(listed())
end, { desc = "Close all buffers" })

-- Buffers (floating picker with preview)
map("n", "<leader>fb", function()
	-- No bufloaded: a restored session brings its buffers back with `badd`, and
	-- those stay unloaded until a window shows them, so the tabline lists what
	-- this used to hide.
	require("config.picker").open(vim.fn.getbufinfo({ buflisted = 1 }), {
		title = "Buffers",
		skip_single = false,
		format = function(item)
			-- bufname, not the getbufinfo field: that one is the resolved path
			local name = vim.fn.bufname(item.bufnr)
			return name ~= "" and name or "[No Name]"
		end,
		preview = function(item, ctx)
			vim.fn.bufload(item.bufnr)
			ctx.set_lines(vim.api.nvim_buf_get_lines(item.bufnr, 0, -1, false), vim.bo[item.bufnr].filetype)
		end,
		on_confirm = function(item)
			vim.cmd("buffer " .. item.bufnr)
		end,
	})
end, { desc = "Buffers" })

return M
