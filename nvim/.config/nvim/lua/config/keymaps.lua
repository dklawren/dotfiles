local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Go to different windows, and hand off to herdr at the edge of the vim
-- split layout so ctrl+h/j/k/l seamlessly crosses into herdr panes too.
local function navigate_win_or_pane(wincmd_key, herdr_dir)
	local win_before = vim.fn.winnr()
	vim.cmd("wincmd " .. wincmd_key)
	if vim.fn.winnr() == win_before and vim.env.HERDR_ENV == "1" then
		vim.fn.system("herdr pane focus --direction " .. herdr_dir .. " --current")
	end
end

-- stylua: ignore start
map("n", "<C-h>", function() navigate_win_or_pane("h", "left") end, { desc = "Go to Left Window/Pane" })
map("n", "<C-j>", function() navigate_win_or_pane("j", "down") end, { desc = "Go to Lower Window/Pane" })
map("n", "<C-k>", function() navigate_win_or_pane("k", "up") end, { desc = "Go to Upper Window/Pane" })
map("n", "<C-l>", function() navigate_win_or_pane("l", "right") end, { desc = "Go to Right Window/Pane" })
-- stylua: ignore end

-- Resize windows/buffers with Ctrl+Cmd+arrow keys (macOS)
map("n", "<C-S-Up>", "<cmd>resize +5<CR>", opts)
map("n", "<C-S-Down>", "<cmd>resize -5<CR>", opts)
map("n", "<C-S-Left>", "<cmd>vertical resize -5<CR>", opts)
map("n", "<C-S-Right>", "<cmd>vertical resize +5<CR>", opts)

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("x", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("x", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
map("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move Block Down" })
map("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move Block Up" })

-- Goto
map("n", "==", "gg<S-v>G")
map("n", "gl", "$", { desc = "Go to end of line" })
map("n", "gh", "^", { desc = "Go to start of line" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
map(
	"n",
	"<leader>ur",
	"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
	{ desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- Saner behavior of n and N
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- location list
map("n", "<leader>xl", function()
	local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Location List" })

-- quickfix list
map("n", "<leader>xq", function()
	local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- highlights under cursor
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", "<cmd>InspectTree<cr>", { desc = "Inspect Tree" })

-- Terminal Mappings
-- stylua: ignore start
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
map("t", "<C-h>", function() navigate_win_or_pane("h", "left") end, { desc = "Go to Left Window/Pane" })
map("t", "<C-j>", function() navigate_win_or_pane("j", "down") end, { desc = "Go to Lower Window/Pane" })
map("t", "<C-k>", function() navigate_win_or_pane("k", "up") end, { desc = "Go to Upper Window/Pane" })
map("t", "<C-l>", function() navigate_win_or_pane("l", "right") end, { desc = "Go to Right Window/Pane" })
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<c-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })
-- stylua: ignore end

-- windows
map("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
map("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>sh", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>`", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>sv", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize window sizes" })
map("n", "<leader>wH", "<C-w>H", { desc = "Move window far left" })
map("n", "<leader>wJ", "<C-w>J", { desc = "Move window to bottom" })
map("n", "<leader>wK", "<C-w>K", { desc = "Move window to top" })
map("n", "<leader>wL", "<C-w>L", { desc = "Move window far right" })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "<leader><tab>n", "<cmd>tabnew %<cr>", { desc = "New Tab with Current Buffer" })
map("n", "<leader><tab>m", "<cmd>tabmove", { desc = "Move Tab" })

-- Close all fold except the current one.
map("n", "zv", "zMzvzz", { desc = "Close all folds except the current one" })

-- Close current fold when open. Always open next fold.
map("n", "zj", "zcjzOzz", { desc = "Close current fold when open. Always open next fold." })

-- Close current fold when open. Always open previous fold.
map("n", "zk", "zckzOzz", { desc = "Close current fold when open. Always open previous fold." })

-- Better paste
map("x", "p", '"_dP', opts)

-- Copy whole file content to clipboard with C-c
map("n", "<C-c>", ":%y+<CR>", opts)

-- Select all text in buffer with Alt-a
map("n", "<A-a>", "ggVG", { noremap = true, silent = true, desc = "Select all" })

-- Toggle wrap
map("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle Wrap", silent = true })

map("n", "<leader>us", function()
	vim.o.spell = not vim.o.spell
	vim.notify((vim.o.spell and "Enabled" or "Disabled") .. " spell")
end, { desc = "Toggle Spell" })

-- `restart!` skips :restart's own session round-trip; we do it ourselves.
map("n", "<leader>R", function()
	local session = vim.fn.stdpath("state") .. "/restart_session.vim"
	vim.cmd("mksession! " .. vim.fn.fnameescape(session))
	vim.cmd("restart! source " .. vim.fn.fnameescape(session))
end, { desc = "Restart Neovim" })

-- delete marks (use m + character for a mark)
map("n", "dm", function()
	local mark = vim.fn.getcharstr()
	-- Esc, or anything that is not a mark name, would make :delmarks throw.
	if not mark:match("^[a-zA-Z0-9'`\"%[%]<>%.%^]$") then
		return
	end
	vim.cmd("delmarks " .. mark)
end, { desc = "Delete mark" })

-- Command history
map("n", "<leader>:", "q:", { desc = "Command History" })
map("n", "<leader>sc", "q:", { desc = "Command History" })

-- Terminal
map("n", "<leader>fT", "<cmd>terminal<cr>", { desc = "Terminal (cwd)" })
map("n", "<leader>ft", "<cmd>terminal<cr>", { desc = "Terminal (Root Dir)" })
map("n", "<C-:>", "<cmd>terminal<cr>", { desc = "Terminal (Root Dir)" })

-- Scratch
map("n", "<leader>.", "<cmd>enew<cr>", { desc = "New Scratch Buffer" })

-- Toggles (native)
map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle Wrap" })
map("n", "<leader>uL", "<cmd>set relativenumber!<cr>", { desc = "Toggle Relative Number" })
map("n", "<leader>ul", "<cmd>set number!<cr>", { desc = "Toggle Line Number" })
map("n", "<leader>uc", "<cmd>set conceallevel!<cr>", { desc = "Toggle Conceal Level" })
map("n", "<leader>uA", "<cmd>set showtabline!<cr>", { desc = "Toggle Tabline" })

-- Other native replacements
map("n", "<leader>sm", ":marks<cr>", { desc = "Marks" })
map("n", "<leader>sM", ":Man<cr>", { desc = "Man Pages" })
map("n", "<leader>sq", "<cmd>copen<cr>", { desc = "Quickfix List" })
map("n", '<leader>s"', ":registers<cr>", { desc = "Registers" })
map("n", "<leader>s/", "q/", { desc = "Search History" })
map("n", "<leader>sa", ":autocmd<cr>", { desc = "Autocmds" })
map("n", "<leader>sC", ":commands<cr>", { desc = "Commands" })
map("n", "<leader>sj", ":jumps<cr>", { desc = "Jumps" })
map("n", "<leader>sl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>N", ":help news<cr>", { desc = "Neovim News" })
map("n", "<leader>un", function()
	vim.notify("Notifications dismissed", vim.log.levels.INFO)
end, { desc = "Dismiss Notifications" })

-- Native Neovim 0.13+ features
map("n", "*", "*``", { desc = "Search word under cursor and center" })
map("n", "#", "#``", { desc = "Search word under cursor backward and center" })
map("t", "<C-w>", "<C-\\><C-n><C-w>", { desc = "Window navigation from terminal" })

-- Quickfix/Location list navigation
map("n", "<leader>cn", "<cmd>cnext<cr>", { desc = "Next Quickfix" })
map("n", "<leader>cp", "<cmd>cprevious<cr>", { desc = "Previous Quickfix" })
map("n", "<leader>co", "<cmd>copen<cr>", { desc = "Open Quickfix" })
map("n", "<leader>cc", "<cmd>cclose<cr>", { desc = "Close Quickfix" })
map("n", "<leader>ln", "<cmd>lnext<cr>", { desc = "Next Location" })
map("n", "<leader>lp", "<cmd>lprevious<cr>", { desc = "Previous Location" })
map("n", "<leader>lo", "<cmd>lopen<cr>", { desc = "Open Location" })
map("n", "<leader>lc", "<cmd>lclose<cr>", { desc = "Close Location" })

-- Spell checking
map("n", "]s", function()
	vim.cmd("normal! ]s")
end, { desc = "Next Spell Error" })
map("n", "[s", function()
	vim.cmd("normal! [s")
end, { desc = "Previous Spell Error" })

-- Fix Spell checking
map("n", "z0", "1z=", { desc = "Fix word under cursor" })
