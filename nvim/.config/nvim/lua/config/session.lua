vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"

-- Create sessions directory if it doesn't exist
local session_dir = vim.fn.stdpath("state") .. "/sessions/"
if vim.fn.isdirectory(session_dir) == 0 then
	vim.fn.mkdir(session_dir, "p")
end

local function get_session_file()
	local cwd = vim.fn.getcwd()
	local session_name = cwd:gsub("/", "%%")
	return session_dir .. session_name .. ".vim"
end

local function get_last_session_file()
	return session_dir .. "last_session.vim"
end

-- Relax the size minimums so :source lays windows out as saved, then restore
-- them: leaving winwidth=1 stops windows auto-expanding afterwards.
-- Order matters both ways: 'winwidth' may never be below 'winminwidth' (E592),
-- so lower the minimums first and raise the maximums first.
local function load_session(file)
	local minw, w = vim.o.winminwidth, vim.o.winwidth
	local minh, h = vim.o.winminheight, vim.o.winheight

	vim.o.winminwidth, vim.o.winminheight = 1, 1
	vim.o.winwidth, vim.o.winheight = 1, 1

	-- magic.file = false: session names come from cwd:gsub("/", "%%"), so they are
	-- full of `%`, which Ex would otherwise expand to the current file name (E499).
	local ok, err = pcall(function()
		vim.cmd({ cmd = "source", args = { file }, magic = { file = false } })
	end)

	vim.o.winwidth, vim.o.winheight = w, h
	vim.o.winminwidth, vim.o.winminheight = minw, minh

	if not ok then
		vim.notify("Session load failed: " .. tostring(err), vim.log.levels.ERROR)
	end
end

-- SessionLoadPre — close stale plugin floats before session restore.
-- Skip ui2 internal windows (filetype: cmd/msg/pager/dialog) or LSP floats.
local _ui2_ft = { cmd = true, msg = true, pager = true, dialog = true }
vim.api.nvim_create_autocmd("SessionLoadPre", {
	callback = function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
				if not _ui2_ft[ft] then
					pcall(vim.api.nvim_win_close, win, true)
				end
			end
		end
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		-- Only restore if no files were specified
		if vim.fn.argc() == 0 then
			local session_file = get_session_file()
			if vim.fn.filereadable(session_file) == 1 then
				load_session(session_file)
			end
		end
	end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		local stop_file = session_dir .. ".stop_saving"
		if vim.fn.filereadable(stop_file) == 1 then
			vim.fn.delete(stop_file) -- Remove stop file for next time
			return
		end

		-- Only save if we have actual file buffers (like persistence.nvim)
		local buf_count = 0
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
				buf_count = buf_count + 1
			end
		end

		if buf_count >= 1 then -- Minimum 1 buffer (like persistence default)
			local session_file = get_session_file()
			vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
			vim.cmd("mksession! " .. vim.fn.fnameescape(get_last_session_file()))
		end
	end,
})

-- Load session for current directory
vim.keymap.set("n", "<leader>qs", function()
	local session_file = get_session_file()
	if vim.fn.filereadable(session_file) == 1 then
		load_session(session_file)
	else
		vim.notify("No session found for current directory", vim.log.levels.WARN)
	end
end, { desc = "Load session for current directory" })

-- Load last session
vim.keymap.set("n", "<leader>ql", function()
	local last_session = get_last_session_file()
	if vim.fn.filereadable(last_session) == 1 then
		load_session(last_session)
	else
		vim.notify("No last session found", vim.log.levels.WARN)
	end
end, { desc = "Load last session" })

-- Select and load a session
vim.keymap.set("n", "<leader>qS", function()
	local sessions = {}
	local session_files = vim.fn.glob(session_dir .. "*.vim", false, true)

	for _, file in ipairs(session_files) do
		local name = vim.fn.fnamemodify(file, ":t:r")
		name = name:gsub("%%", "/") -- Convert back from escaped path
		table.insert(sessions, name)
	end

	if #sessions == 0 then
		vim.notify("No sessions found", vim.log.levels.WARN)
		return
	end

	require("config.picker").open(sessions, {
		title = "Sessions",
		skip_single = false,
		format = function(name)
			return name
		end,
		on_confirm = function(name)
			local session_file = session_dir .. name:gsub("/", "%%") .. ".vim"
			load_session(session_file)
		end,
	})
end, { desc = "Select session to load" })

-- Stop session saving (create a flag file)
vim.keymap.set("n", "<leader>qd", function()
	local stop_file = session_dir .. ".stop_saving"
	vim.fn.writefile({}, stop_file)
	vim.notify("Session saving stopped")
end, { desc = "Stop session saving" })

-- Delete current session file (fresh start on next open)
vim.keymap.set("n", "<leader>qr", function()
	local session_file = get_session_file()
	if vim.fn.filereadable(session_file) == 1 then
		vim.fn.delete(session_file)
		vim.notify("Deleted: " .. session_file)
	else
		vim.notify("No session to delete for current directory", vim.log.levels.WARN)
	end
end, { desc = "Delete current session" })
