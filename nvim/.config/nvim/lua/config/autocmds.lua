local npcall = require("config.compat")
local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- 'autoread' gets its own file watchers, so a file changed outside nvim is read
-- back without a :checktime on focus.
local resize_timer
vim.api.nvim_create_autocmd("VimResized", {
	group = augroup("resize_splits"),
	callback = function()
		if resize_timer then
			resize_timer:stop()
			resize_timer:close()
		end
		local tab = vim.fn.tabpagenr()
		resize_timer = vim.defer_fn(function()
			resize_timer = nil
			vim.cmd("tabdo wincmd =")
			vim.cmd("tabnext " .. tab)
		end, 100)
	end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(event)
		local buf = event.buf
		if vim.bo[buf].filetype == "gitcommit" or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
			npcall(vim.api.nvim_win_set_cursor, 0, mark)
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
		"checkhealth",
		"gitsigns-blame",
		"grug-far",
		"help",
		"oil",
		"qf",
		"startuptime",
		"terminal",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			-- The buffer is gone by the time this runs when the session hop
			-- closed it in between, and a keymap on it then raises E920.
			if not vim.api.nvim_buf_is_valid(event.buf) then
				return
			end
			vim.keymap.set("n", "q", function()
				local ok = pcall(vim.cmd.close)
				if not ok then
					npcall(vim.api.nvim_buf_delete, event.buf, { force = true })
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

-- Wrap the text filetypes. Spell is left off: toggle it with :set spell, and
-- pick a language with :set spelllang=fr or :set spelllang=en.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
	end,
})

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("json_conceal"),
	pattern = { "json", "jsonc", "json5" },
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})
