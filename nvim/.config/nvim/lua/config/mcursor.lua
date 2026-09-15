-- Column alignment for native multicursor (`:h multicursor`). Cursors dropped on
-- ragged lines sit at different columns, so anything typed lands ragged too.
local NS = vim.api.nvim_create_namespace("nvim.multicursor")
local PRIMARY_NS = vim.api.nvim_create_namespace("config.mcursor.primary")

local M = {}

--- Pads with spaces so the n-th cursor of every line shares a column.
function M.align()
	local buf = vim.api.nvim_get_current_buf()
	local marks = vim.api.nvim_buf_get_extmarks(buf, NS, 0, -1, {})
	if #marks == 0 then
		return
	end

	-- Stale marks outlive the lines they tracked (undo/redo).
	local nlines = vim.api.nvim_buf_line_count(buf)
	local rows, depth = {}, 0
	for _, m in ipairs(marks) do
		if m[2] < nlines then
			local cols = rows[m[2]] or {}
			rows[m[2]] = cols
			if not vim.list_contains(cols, m[3]) then
				cols[#cols + 1] = m[3]
				depth = math.max(depth, #cols)
			end
		end
	end
	for _, cols in pairs(rows) do
		table.sort(cols)
	end

	-- Keep the widest gap at each depth, so no cursor ever moves left.
	local targets = {}
	for i = 1, depth do
		local gap = 0
		for _, cols in pairs(rows) do
			if cols[i] then
				gap = math.max(gap, cols[i] - (cols[i - 1] or 0))
			end
		end
		targets[i] = (targets[i - 1] or 0) + gap
	end

	local pcursor = vim.api.nvim_win_get_cursor(0)
	local pmark = vim.api.nvim_buf_set_extmark(buf, PRIMARY_NS, pcursor[1] - 1, pcursor[2], {})

	-- Right to left: each insertion shifts the cursors after it.
	for row, cols in pairs(rows) do
		for i = #cols, 1, -1 do
			local pad = (targets[i] - (targets[i - 1] or 0)) - (cols[i] - (cols[i - 1] or 0))
			if pad > 0 then
				vim.api.nvim_buf_set_text(buf, row, cols[i], row, cols[i], { (" "):rep(pad) })
			end
		end
	end

	local moved = vim.api.nvim_buf_get_extmark_by_id(buf, PRIMARY_NS, pmark, {})
	vim.api.nvim_buf_clear_namespace(buf, PRIMARY_NS, 0, -1)
	vim.api.nvim_win_set_cursor(0, { moved[1] + 1, moved[2] })
end

vim.keymap.set("n", "g<Space>", M.align, { desc = "Align multicursors into a column" })

return M
