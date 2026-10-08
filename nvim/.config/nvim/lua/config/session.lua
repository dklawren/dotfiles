-- One session file per directory, keyed on the directory nvim is in. The
-- layout is written with `:mksession!` on the way out and read back with
-- `:source` on the way in, so a project reopens with the windows, tabs,
-- buffers, folds and cursor positions it was closed with.
local M = {}

local api = vim.api
local dir = vim.fn.stdpath("state") .. "/sessions"
vim.fn.mkdir(dir, "p")

-- buffers: every buffer the project had open, not just the ones on screen.
-- curdir: the directory the session belongs to. folds: which lines were left
-- closed up. tabpages, winsize, winpos: the layout itself.
vim.opt.sessionoptions = "buffers,curdir,folds,tabpages,winsize,winpos"

---A path as a file name: slashes encoded last, so the file still sorts and
---reads like the directory it is for. The path is resolved first, because macOS
---reports /tmp/foo as /private/tmp/foo once nvim has it open, and a session
---written under one spelling has to be found under the other.
---@param path string
---@return string
function M.file_for(path)
	path = vim.fs.normalize(vim.uv.fs_realpath(path) or path)
	return dir .. "/" .. vim.uri_encode(path):gsub("/", "%%2F") .. ".vim"
end

---The directory this nvim is in, the one the session belongs to.
---@return string
function M.cwd()
	return vim.fs.normalize(vim.fn.getcwd())
end

local function has_buffers()
	for _, buf in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_is_loaded(buf) and api.nvim_buf_get_name(buf) ~= "" then
			return true
		end
	end
	return false
end

---Write the layout to a session file, beside it and renamed over it, so a save
---that dies part way leaves the previous session whole instead of truncated.
---@param path string
---@return string|nil reason
local function write(path)
	local tmp = path .. ".tmp"
	local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(tmp))
	if ok and vim.uv.fs_rename(tmp, path) then
		return nil
	end
	vim.uv.fs_unlink(tmp)
	return ok and ("could not rename " .. path) or tostring(err)
end

---Save this layout against the directory nvim is in. An empty nvim saves
---nothing: it would overwrite a good session with one that opens no buffers,
---which is what quitting straight after opening a directory would do.
function M.save()
	if not has_buffers() then
		return
	end
	local reason = write(M.file_for(M.cwd()))
	if reason then
		vim.notify("Session not saved: " .. reason, vim.log.levels.WARN)
	end
end

---Throw a directory's session away.
---@param target string
---@return boolean removed one
function M.delete(target)
	return vim.fn.delete(M.file_for(vim.fs.normalize(target))) == 0
end

---Put a directory's layout back on screen.
---@param target string
---@return boolean loaded
---@return string|nil reason
function M.load(target)
	local file = M.file_for(vim.fs.normalize(target))
	if vim.fn.filereadable(file) == 0 then
		return false, "No session for " .. target
	end

	-- mksession writes `badd +0` for the buffer that was current when it ran,
	-- and that raises E37 whenever the buffer has unsaved changes. The flag is
	-- taken off for the length of the source and put back after, so the unsaved
	-- text is neither lost nor left unmarked.
	local unsaved = {}
	for _, buf in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_get_name(buf) ~= "" and vim.bo[buf].modified then
			unsaved[buf] = true
			vim.bo[buf].modified = false
		end
	end

	-- :source applies the winwidth mksession wrote, and 'winwidth' may never
	-- drop below 'winminwidth' (E592), so both minimums go first and the
	-- maximums come back before them.
	local keep = {
		winminwidth = vim.o.winminwidth,
		winminheight = vim.o.winminheight,
		winwidth = vim.o.winwidth,
		winheight = vim.o.winheight,
		hidden = vim.o.hidden,
	}
	vim.o.hidden = true
	vim.o.winminwidth, vim.o.winminheight = 1, 1
	vim.o.winwidth, vim.o.winheight = 1, 1
	-- magic.file = false: the encoded path holds a `%`, which Ex would
	-- otherwise expand to the current file name (E499).
	local ok, err = pcall(function()
		vim.cmd({ cmd = "source", args = { file }, magic = { file = false } })
	end)
	vim.o.winwidth, vim.o.winheight = keep.winwidth, keep.winheight
	vim.o.winminwidth, vim.o.winminheight = keep.winminwidth, keep.winminheight
	vim.o.hidden = keep.hidden
	for buf in pairs(unsaved) do
		-- The source may have wiped a buffer it laid a window over.
		if api.nvim_buf_is_valid(buf) then
			vim.bo[buf].modified = true
		end
	end
	if not ok then
		return false, tostring(err)
	end
	return true
end

---Load a directory's session, or say there is none.
---@param target string
local function restore(target)
	local ok, why = M.load(target)
	if not ok then
		vim.notify(why, vim.log.levels.WARN)
	end
	return ok
end

--------------------------------------------------------------------------
-- commands and keymaps
--------------------------------------------------------------------------

api.nvim_create_user_command("Session", function(args)
	restore(args.args ~= "" and vim.fn.expand(args.args) or M.cwd())
end, { nargs = "?", complete = "dir", desc = "Restore the session for a directory" })

vim.keymap.set("n", "<leader>qs", function()
	restore(M.cwd())
end, { desc = "Restore the session for this directory" })

vim.keymap.set("n", "<leader>qr", function()
	local cwd = M.cwd()
	if M.delete(cwd) then
		vim.notify("Deleted session for " .. vim.fn.fnamemodify(cwd, ":~"))
	else
		vim.notify("No session to delete for " .. vim.fn.fnamemodify(cwd, ":~"))
	end
end, { desc = "Delete the session for this directory" })

--------------------------------------------------------------------------
-- autocmds
--------------------------------------------------------------------------

local group = api.nvim_create_augroup("session", { clear = true })

api.nvim_create_autocmd("VimEnter", {
	group = group,
	callback = function()
		-- Files named on the command line are the layout the user asked for.
		if vim.fn.argc() == 0 then
			restore(M.cwd())
		end
	end,
})

api.nvim_create_autocmd("VimLeavePre", {
	group = group,
	callback = M.save,
})

-- The layout is written while nvim is up as well as on the way out, so a crash
-- or a `kill -9` costs the last change and not the whole layout.
-- assert, because a nil timer is a programming error and the next line says so
local save_timer = assert(vim.uv.new_timer())
save_timer:start(30000, 30000, vim.schedule_wrap(M.save))

return M
