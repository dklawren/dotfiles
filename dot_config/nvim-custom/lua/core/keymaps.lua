-- Set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap

-- General keymaps
keymap.set("i", "jk", "<ESC>") -- exit insert mode with jk
keymap.set("i", "ii", "<ESC>") -- exit insert mode with ii
keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "Save and quit" })
keymap.set("n", "<leader>qq", ":q!<CR>", { desc = "Quit without saving" })
keymap.set("n", "<leader>ww", ":w<CR>", { desc = "Save" })
keymap.set("n", "gx", ":!open <c-r><c-a><CR>", { desc = "Open URL under cursor" })

-- Split window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make split windows equal width" })
keymap.set("n", "<leader>sx", ":close<CR>", { desc = "Close split window" })
keymap.set("n", "<leader>sj", "<C-w>-", { desc = "Make split window height shorter" })
keymap.set("n", "<leader>sk", "<C-w>+", { desc = "Make split windows height smaller" })
keymap.set("n", "<leader>sl", "<C-w>>5", { desc = "Make split windows width bigger" })
keymap.set("n", "<leader>sh", "<C-w><5", { desc = "Make split windows width smaller" })

-- Tab management
keymap.set("n", "<leader>to", ":tabnew<CR>", { desc = "Open a new tab" })
keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close a tab" })
keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "Next tab" })
keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "Previous tab" })

-- Diff keymaps
keymap.set("n", "<leader>cc", ":diffput<CR>", { desc = "Put diff from current to other during diff" })
keymap.set("n", "<leader>cj", ":diffget 1<CR>", { desc = "Get diff from left (local) during merge" })
keymap.set("n", "<leader>ck", ":diffget 3<CR>", { desc = "Get diff from right (remote) during merge" })
keymap.set("n", "<leader>cn", "]c", { desc = "Next diff hunk" })
keymap.set("n", "<leader>cp", "[c", { desc = "Previous diff hunk" }) --

-- Quickfix keymaps
keymap.set("n", "<leader>qo", ":copen<CR>", { desc = "Open quickfix list" })
keymap.set("n", "<leader>qf", ":cfirst<CR>", { desc = "Jump to first quickfix list item" })
keymap.set("n", "<leader>qn", ":cnext<CR>", { desc = "Jump to next quickfix list item" })
keymap.set("n", "<leader>qp", ":cprev<CR>", { desc = "Jump to prev quickfix list item" })
keymap.set("n", "<leader>ql", ":clast<CR>", { desc = "Jump to last quickfix list item" })
keymap.set("n", "<leader>qc", ":cclose<CR>", { desc = "Close quickfix list" })

-- Vim-maximizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>", { desc = "Toggle maximize tab" })

-- Neotree
keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
keymap.set("n", "<leader>er", ":Neotree focus<CR>", { desc = "Toggle focus to file explorer" })

-- Telescope
keymap.set("n", "<leader><leader>", require("telescope.builtin").find_files, {})
keymap.set("n", "<leader>/", require("telescope.builtin").live_grep, {})
keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, {})
keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, {})
keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, {})
keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, {})
keymap.set("n", "<leader>fr", require("telescope").extensions.recent_files.pick, {})
keymap.set("n", "<leader>fs", require("telescope.builtin").current_buffer_fuzzy_find, {})
keymap.set("n", "<leader>fo", require("telescope.builtin").lsp_document_symbols, {})
keymap.set("n", "<leader>fi", require("telescope.builtin").lsp_incoming_calls, {})
keymap.set("n", "<leader>fm", function()
	require("telescope.builtin").treesitter({ default_text = ":method:" })
end)

-- Navigate buffers
keymap.set("n", "<S-l>", ":bnext<CR>", { desc = "Buffer next" })
keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = "Buffer previos" })

-- Git-blame
keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>", { desc = "Toggle git blame" })

-- Vim REST Console
keymap.set("n", "<leader>xr", ":call VrcQuery()<CR>", { desc = "Run REST query" })

-- LSP
keymap.set("n", "<leader>gg", "<cmd>lua vim.lsp.buf.hover()<CR>")
keymap.set("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
keymap.set("n", "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
keymap.set("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
keymap.set("n", "<leader>gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
keymap.set("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>")
keymap.set("n", "<leader>gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
keymap.set("n", "<leader>rr", "<cmd>lua vim.lsp.buf.rename()<CR>")
keymap.set("n", "<leader>gf", "<cmd>lua vim.lsp.buf.format({async = true})<CR>")
keymap.set("v", "<leader>gf", "<cmd>lua vim.lsp.buf.format({async = true})<CR>")
keymap.set("n", "<leader>ga", "<cmd>lua vim.lsp.buf.code_action()<CR>")
keymap.set("n", "<leader>gl", "<cmd>lua vim.diagnostic.open_float()<CR>")
keymap.set("n", "<leader>gp", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
keymap.set("n", "<leader>gn", "<cmd>lua vim.diagnostic.goto_next()<CR>")
keymap.set("n", "<leader>tr", "<cmd>lua vim.lsp.buf.document_symbol()<CR>")
keymap.set("i", "<C-Space>", "<cmd>lua vim.lsp.buf.completion()<CR>")

-- Git worktrees
keymap.set("n", "<leader>wt", "<cmd>Telescope git_worktree<CR>", { desc = "List Git Worktrees" })
keymap.set(
	"n",
	"<leader>wn",
	"<cmd>:lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
	{ desc = "Create New Git Worktree" }
)

-- -- Obsidian
-- keymap.set(
-- 	"n",
-- 	"<leader>oc",
-- 	"<cmd>lua require('obsidian').util.toggle_checkbox()<CR>",
-- 	{ desc = "Obsidian Check Checkbox" }
-- )
-- keymap.set("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>", { desc = "Insert Obsidian Template" })
-- keymap.set("n", "<leader>oo", "<cmd>ObsidianOpen<CR>", { desc = "Open in Obsidian App" })
-- keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Show ObsidianBacklinks" })
-- keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<CR>", { desc = "Show ObsidianLinks" })
-- keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "Create New Note" })
-- keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<CR>", { desc = "Search Obsidian" })
-- keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Quick Switch" })

-- Telekasten
keymap.set("n", "<leader>zp", "<cmd>Telekasten panel<CR>", {desc = "Menu panel"})
keymap.set("n", "<leader>zf", "<cmd>Telekasten find_notes<CR>", {desc = "Find notes"})
keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>", {desc = "Search notes"})
keymap.set("n", "<leader>zd", "<cmd>Telekasten goto_today<CR>", {desc = "Go to today"})
keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<CR>", {desc = "Follow link"})
keymap.set("n", "<leader>zn", "<cmd>Telekasten new_note<CR>", {desc = "New note"})
keymap.set("n", "<leader>zc", "<cmd>Telekasten show_calendar<CR>", {desc = "Show calendar"})
keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>", {desc = "Show backlinks"})
keymap.set("n", "<leader>zI", "<cmd>Telekasten insert_img_link<CR>", {desc = "Insert image link"})
keymap.set("i", "[[", "<cmd>Telekasten insert_link<CR>", {desc = "Insert link"})

-- Undotree
keymap.set("n", "<leader>ut", "<cmd>UndotreeToggle<CR>", {desc = "Undotree Toggle"})
