local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

local _checktime_timer = nil
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	callback = function()
		if _checktime_timer then
			_checktime_timer:stop()
			_checktime_timer:close()
			_checktime_timer = nil
		end
		_checktime_timer = vim.defer_fn(function()
			_checktime_timer = nil
			if vim.o.buftype ~= "nofile" then
				vim.cmd("checktime")
			end
		end, 200) -- 200ms debounce
	end,
})

local _resize_timer = nil
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		if _resize_timer then
			_resize_timer:stop()
			_resize_timer:close()
			_resize_timer = nil
		end
		local current_tab = vim.fn.tabpagenr()
		_resize_timer = vim.defer_fn(function()
			_resize_timer = nil
			vim.cmd("tabdo wincmd =")
			vim.cmd("tabnext " .. current_tab)
		end, 100)
	end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup("iskeyword_kebab"),
	pattern = { "css", "scss", "less", "html", "htmldjango", "blade", "typescriptreact", "javascriptreact" },
	callback = function()
		vim.opt_local.iskeyword:append("-")
	end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
	group = augroup("insert_ui_perf"),
	callback = function()
		vim.wo.cursorline = false
		vim.wo.relativenumber = false
		vim.wo.number = true -- keep absolute numbers
	end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
	group = augroup("insert_ui_perf"),
	callback = function()
		vim.wo.cursorline = true
		vim.wo.relativenumber = true
	end,
})

-- make it easier to close man-files when opened inline
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("man_unlisted"),
	pattern = { "man" },
	callback = function(event)
		vim.bo[event.buf].buflisted = false
	end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"checkhealth",
		"dbout",
		"gitsigns-blame",
		"grug-far",
		"help",
		"lspinfo",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"oil",
		"qf",
		"spectre_panel",
		"startuptime",
		"terminal",
		"tsplayground",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				local ok = pcall(vim.cmd.close)
				if not ok then
					pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
				end
			end, {
				buffer = event.buf,
				silent = true,
				desc = "Quit buffer",
			})
		end)
	end,
})

-- auto-delete terminal buffers when process exits to suppress "process exit N" message
-- (callers that want the output to stick around, e.g. a one-shot diff command,
-- set vim.b.keep_term_on_exit to opt out)
vim.api.nvim_create_autocmd("TermClose", {
	group = augroup("terminal_close"),
	callback = function(event)
		if vim.b[event.buf].keep_term_on_exit then
			return
		end
		vim.cmd("silent! bdelete! " .. event.buf)
	end,
})

-- wrap text filetypes (spell disabled by default, toggle manually with :set spell / :set spelllang=...)
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		-- vim.opt_local.spell = true -- toggle manually: :set spell | :set nospell | :set spelllang=fr | :set spelllang=en
	end,
})

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ "FileType" }, {
	group = augroup("json_conceal"),
	pattern = { "json", "jsonc", "json5" },
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})
