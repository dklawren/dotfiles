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
		map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
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

-- The ref list, its sections and its diffstat preview live in vdiff.
vim.keymap.set("n", "<leader>gc", "<Cmd>VDiffComparePick<CR>", { desc = "Git: compare with a ref" })

-- COMPARE TWO REFS (branches, commits, tags)
vim.keymap.set("n", "<leader>gC", "<Cmd>VDiffCompareRefsPick<CR>", { desc = "Git: compare two refs" })

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
vim.keymap.set("n", "<leader>gF", "<Cmd>VDiffPick<CR>", { desc = "Git: diff file (universal)" })

-- UTILITY: compare two arbitrary files
vim.keymap.set("n", "<leader>g2", "<Cmd>VDiffFiles<CR>", { desc = "Git: compare 2 files" })
vim.keymap.set("n", "<leader>gy", "<Cmd>VDiffClipboard<CR>", { desc = "Git: diff clipboard vs file" })
