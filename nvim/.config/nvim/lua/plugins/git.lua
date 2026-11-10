vim.pack.add({
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://gitlab.com/tduyng/vdiff.nvim",
})

-- Setup gitsigns.nvim. The signs gitsigns already defaults to are left out.
require("gitsigns").setup({
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
	},
	signs_staged = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
	},
	current_line_blame = true,
	current_line_blame_opts = {
		virt_text = true,
		delay = 800,
	},
	current_line_blame_formatter = "<author>, <author_time:%R> - <summary> (<abbrev_sha>)",
	on_attach = function(buffer)
		local gs = package.loaded.gitsigns

		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
		end

		---A hunk in a buffer that has one, a difference in a diff window.
		local function hop(diff_key, direction)
			return function()
				if vim.wo.diff then
					vim.cmd.normal({ diff_key, bang = true })
				else
					gs.nav_hunk(direction)
				end
			end
		end

		map("n", "]h", hop("]c", "next"), "Next Hunk")
		map("n", "[h", hop("[c", "prev"), "Prev Hunk")

		map("n", "]H", function()
			gs.nav_hunk("last")
		end, "Last Hunk")
		map("n", "[H", function()
			gs.nav_hunk("first")
		end, "First Hunk")

		map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
		map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")

		map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
		map("n", "<leader>ghu", gs.stage_hunk, "Unstage Hunk")
		map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
		map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
		map("n", "<leader>ghb", function()
			gs.blame_line({ full = true })
		end, "Blame Line")
		map("n", "<leader>ghB", function()
			gs.blame()
		end, "Blame Buffer")
		map("n", "<leader>ghd", gs.diffthis, "Diff This")
		map("n", "<leader>ghD", function()
			gs.diffthis("~")
		end, "Diff This ~")

		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
	end,
})

-- Setup vdiff.nvim with side-by-side layout (IntelliJ style)
require("vdiff").setup({
	diff_layout = "diff2_vertical", -- side-by-side
	merge_layout = "diff3_vertical", -- 3-way side-by-side
})

local function git_lines(args)
	local out = vim.fn.systemlist(vim.list_extend({ "git", "--no-pager" }, args))
	return vim.v.shell_error == 0 and out or {}
end

local function refs_under(prefix, kind)
	local rows = {}
	local format = "%(refname)\t%(objectname:short)\t%(contents:subject)"
	local args = { "for-each-ref", "--sort=-committerdate", "--format=" .. format, "refs/" .. prefix }
	for _, line in ipairs(git_lines(args)) do
		local full, hash, subject = line:match("^(.-)\t(%x+)\t(.*)$")
		if full and not full:match("/HEAD$") then
			local ref = full:gsub("^refs/[^/]+/", "")
			rows[#rows + 1] = { ref = ref, hash = hash, kind = kind, desc = subject }
		end
	end
	return rows
end

---Branches, remote branches, tags, then the commits the head has. Typing a
---ref by hand is what this list replaces, but the list is not the only answer:
---`<leader>gF` still takes any ref `:VDiff` accepts.
local function git_refs()
	local rows = {}
	vim.list_extend(rows, refs_under("heads", "branch"))
	vim.list_extend(rows, refs_under("remotes", "remote"))
	vim.list_extend(rows, refs_under("tags", "tag"))
	for _, line in ipairs(git_lines({ "log", "--pretty=format:%h\t%cr\t%s", "-n", "40" })) do
		local hash, age, subject = line:match("^(%x+)\t(.-)\t(.*)$")
		if hash then
			rows[#rows + 1] = { ref = hash, hash = hash, kind = "commit", age = age, desc = subject }
		end
	end
	return rows
end

local function preview_ref(row, ctx)
	if row.kind == "worktree" then
		ctx.set_lines({ "Working tree", "", "The files on disk, against HEAD." }, "markdown")
	else
		ctx.git({ "log", "--oneline", "--decorate", "--no-color", "-n", "20", row.ref }, "git")
	end
end

---@param title string
---@param opts { worktree?: boolean }
---@param on_pick fun(row: table)
local function pick_ref(title, opts, on_pick)
	local rows = {}
	if opts.worktree then
		rows[#rows + 1] = { ref = "", kind = "worktree", desc = "uncommitted changes" }
	end
	rows[#rows + 1] = { ref = "HEAD", hash = "", kind = "head", desc = "the checked out commit" }
	vim.list_extend(rows, git_refs())
	require("config.picker").open(rows, {
		title = title,
		skip_single = false,
		filter = true,
		format = function(row)
			if row.kind == "worktree" then
				return "working tree  (uncommitted changes)"
			elseif row.kind == "commit" then
				return ("%s  %s  %s"):format(row.hash, row.age, row.desc)
			end
			return ("%s  %s  %s"):format(row.ref, row.hash or "", row.desc or "")
		end,
		preview = preview_ref,
		on_confirm = on_pick,
	})
end

-- Accepts any ref: branch, commit, tag, or a commit from the list. The working
-- tree row is the empty ref, which is what `:VDiffCompare` without an argument
-- already means.
vim.keymap.set("n", "<leader>gc", function()
	pick_ref("Compare with", { worktree = true }, function(row)
		vim.cmd("VDiffCompare" .. (row.ref ~= "" and (" " .. row.ref) or ""))
	end)
end, { desc = "Git: compare with a ref" })

-- COMPARE TWO REFS (branches, commits, tags)
vim.keymap.set("n", "<leader>gC", function()
	pick_ref("Compare from", {}, function(first)
		pick_ref("Compare to", {}, function(second)
			vim.cmd(("VDiffCompareRefs %s %s"):format(first.ref, second.ref))
		end)
	end)
end, { desc = "Git: compare two refs" })

-- Quick shortcuts for common comparisons
vim.keymap.set("n", "<leader>gd", "<Cmd>VDiffCompare<CR>", { desc = "Git: working tree (all files)" })
vim.keymap.set("n", "<leader>gD", "<Cmd>VDiffCompare --staged<CR>", { desc = "Git: staged (all files)" })
vim.keymap.set("n", "<leader>gV", "<Cmd>VDiffHistory<CR>", { desc = "Git: file history" })
vim.keymap.set("x", "<leader>gv", ":VDiffRange<CR>", { desc = "Git: line history" })
vim.keymap.set("n", "<leader>gx", "<Cmd>VDiffClose<CR>", { desc = "Git: close all" })
-- 3-way merge view (LOCAL | RESULT | REMOTE)
vim.keymap.set("n", "<leader>gm", "<Cmd>VMerge<CR>", { desc = "Git: merge conflicts" })

-- REVIEW: MR/PR review on top of vdiff (gitlab/github)
-- <leader>gr is a prefix only: binding it to a command too would make it wait
-- for timeoutlen on every press to see whether a longer map follows.
vim.keymap.set("n", "<leader>gro", "<Cmd>VDiffReview<CR>", { desc = "Git: review current branch MR/PR" })
vim.keymap.set("n", "<leader>gR", "<Cmd>VDiffReviewList<CR>", { desc = "Git: pick MR/PR to review" })
vim.keymap.set("n", "<leader>grr", "<Cmd>VDiffReviewReload<CR>", { desc = "Git: reload review" })
vim.keymap.set("n", "<leader>grx", "<Cmd>VDiffReviewClose<CR>", { desc = "Git: close review" })
vim.keymap.set("n", "<leader>grc", "<Cmd>VDiffReviewComment<CR>", { desc = "Git: comment on line" })
vim.keymap.set("n", "<leader>gra", "<Cmd>VDiffReviewActions<CR>", { desc = "Git: review actions" })
vim.keymap.set("n", "<leader>grs", "<Cmd>VDiffReviewSummary<CR>", { desc = "Git: review summary" })

-- Review a specific MR/PR: number, pasted URL, or a colleague's branch name
vim.keymap.set("n", "<leader>grg", function()
	vim.ui.input({ prompt = "Review (number / URL / branch): " }, function(target)
		if target and target ~= "" then
			vim.cmd("VDiffReview " .. target)
		end
	end)
end, { desc = "Git: review MR/PR by number, URL or branch" })

-- CURRENT FILE DIFF
-- Same principle: accepts any ref or empty for HEAD
vim.keymap.set("n", "<leader>gf", "<Cmd>VDiff<CR>", { desc = "Git: diff file vs HEAD" })
vim.keymap.set("n", "<leader>gF", function()
	pick_ref("Diff file with", {}, function(row)
		vim.cmd("VDiff " .. row.ref)
	end)
end, { desc = "Git: diff file (universal)" })

-- UTILITY: Compare two arbitrary files with hunk (or vimdiff fallback)
vim.keymap.set("n", "<leader>g2", function()
	vim.ui.input({ prompt = "First file: " }, function(file1)
		if not file1 or not file1:match("%S") then
			return
		end
		vim.ui.input({ prompt = "Second file: " }, function(file2)
			if file2 and file2:match("%S") then
				local abs1 = vim.fn.fnamemodify(file1, ":p")
				local abs2 = vim.fn.fnamemodify(file2, ":p")
				if vim.fn.executable("hunk") == 1 then
					vim.cmd("tabnew")
					vim.cmd.terminal(("hunk difftool %s %s"):format(vim.fn.shellescape(abs1), vim.fn.shellescape(abs2)))
					local buf = vim.api.nvim_get_current_buf()
					vim.b[buf].keep_term_on_exit = true
					for _, lhs in ipairs({ "q", "<CR>", "<Esc>" }) do
						vim.keymap.set({ "n", "t" }, lhs, "<Cmd>tabclose<CR>", { buffer = buf, silent = true })
					end
				else
					vim.cmd(
						("tabnew %s | diffthis | vsplit %s | diffthis"):format(vim.fn.fnameescape(abs1), vim.fn.fnameescape(abs2))
					)
				end
			end
		end)
	end)
end, { desc = "Git: compare 2 files (hunk or vimdiff)" })
