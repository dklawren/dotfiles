-- Git worktrees
--
-- gwt reports where it went by writing the path to $GWT_CD_FILE, the same
-- protocol the fish wrapper uses. The command has to be a list, not a string:
-- a string goes through $SHELL, which loads the gwt shell function, and that
-- function sets GWT_CD_FILE to a temp file of its own and deletes it.
local function run(args, on_dest)
	local cd_file = vim.fn.tempname()
	local prev = vim.api.nvim_get_current_buf()

	vim.cmd.enew()
	local term = vim.api.nvim_get_current_buf()

	vim.fn.jobstart(vim.list_extend({ "gwt" }, args), {
		term = true,
		env = { GWT_CD_FILE = cd_file },
		on_exit = function()
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(prev) then
					vim.api.nvim_set_current_buf(prev)
				end
				if vim.api.nvim_buf_is_valid(term) then
					vim.api.nvim_buf_delete(term, { force = true })
				end
				if vim.fn.filereadable(cd_file) == 1 then
					on_dest(vim.fn.readfile(cd_file)[1])
				end
			end)
		end,
	})
	vim.cmd.startinsert()
end

-- Point this tab at the worktree. Buffers already open still hold files from
-- the old one, so pick the tab variant when you want a clean slate.
local function switch_here(dest)
	vim.cmd.tcd(dest)
	vim.notify("worktree: " .. vim.fn.fnamemodify(dest, ":~"))
end

vim.keymap.set("n", "<leader>gw", function()
	run({}, switch_here)
end, { desc = "Worktree switch" })

vim.keymap.set("n", "<leader>gW", function()
	run({}, function(dest)
		vim.cmd.tabnew()
		vim.cmd.tcd(dest)
		vim.cmd.enew()
		vim.notify("worktree tab: " .. vim.fn.fnamemodify(dest, ":~"))
	end)
end, { desc = "Worktree switch (new tab)" })

vim.keymap.set("n", "<leader>gs", function()
	run({ "status" }, switch_here)
end, { desc = "Worktree status" })

-- :Gwt with no arguments is the picker; :Gwt switch -c feat/x, :Gwt ls -a, etc.
vim.api.nvim_create_user_command("Gwt", function(opts)
	run(opts.fargs, switch_here)
end, { nargs = "*", desc = "Run gwt" })
