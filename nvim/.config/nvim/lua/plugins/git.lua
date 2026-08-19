vim.pack.add({
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://gitlab.com/tduyng/vdiff.nvim",
})

-- Setup gitsigns.nvim
require("gitsigns").setup({
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "~" },
		untracked = { text = "┆" },
	},
	signs_staged = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "~" },
		untracked = { text = "┆" },
	},
	current_line_blame = true,
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "eol",
		delay = 800,
		ignore_whitespace = false,
		virt_text_priority = 100,
		use_focus = true,
	},
	current_line_blame_formatter = "<author>, <author_time:%R> - <summary> (<abbrev_sha>)",
	on_attach = function(buffer)
		local gs = package.loaded.gitsigns

		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
		end

		map("n", "]h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gs.nav_hunk("next")
			end
		end, "Next Hunk")

		map("n", "[h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gs.nav_hunk("prev")
			end
		end, "Prev Hunk")

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

-- Accepts any ref: branch, commit, tag, HEAD~N, or empty for working tree
-- Empty or nil = working tree vs HEAD
-- --staged = staged changes
-- main = compare with main branch
-- HEAD~3 = compare with 3 commits ago
-- abc123 = compare with commit hash
-- v1.0.0 = compare with tag
vim.keymap.set("n", "<leader>gc", function()
	vim.ui.input({
		prompt = "Compare with (branch/commit/tag/HEAD~N, empty=working): ",
	}, function(ref)
		if ref == nil then -- cancelled; "" means working tree
			return
		end
		vim.cmd("VDiffCompare " .. ref)
	end)
end, { desc = "Git: compare (universal)" })

-- COMPARE TWO REFS (e.g., branches, commits, tags)
vim.keymap.set("n", "<leader>gC", function()
	vim.ui.input({ prompt = "Compare ref1 (default=HEAD): " }, function(ref1)
		if not ref1 or ref1 == "" then
			ref1 = "HEAD"
		end
		vim.ui.input({ prompt = "Compare ref2: " }, function(ref2)
			if not ref2 or ref2 == "" then
				return
			end
			vim.cmd("VDiffCompareRefs " .. ref1 .. " " .. ref2)
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
	vim.ui.input({ prompt = "Diff file with (ref, empty=HEAD): " }, function(ref)
		if ref == nil then
			return
		end
		vim.cmd("VDiff " .. ref)
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
