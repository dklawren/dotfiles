local map = vim.keymap.set
local opts = { silent = true }
local lists = require("config.lists")

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

-- Move Lines. A move past either end of the buffer is a no-op: `:move` on the
-- first or last line raises E16, and holding <A-j> at the bottom of a file is
-- how anyone finishes moving a line down.
local function move_line(down, count)
	local row = vim.fn.line(".")
	local target = down and row + count or row - count
	if target < 1 or target > vim.api.nvim_buf_line_count(0) then
		return
	end
	vim.cmd(down and ("move .+%d"):format(count) or ("move .-%d"):format(count + 1))
	vim.cmd("normal! ==")
end

---The visual selection, moved whole, or left where it is at either end. The
---ends come from the anchor and the cursor: a mapping runs while the selection
---is still live, and the '< '> marks are only set once it ends.
local function move_selection(down, count)
	local here, anchor = vim.fn.line("."), vim.fn.line("v")
	local top, bottom = math.min(here, anchor), math.max(here, anchor)
	if down and bottom + count > vim.api.nvim_buf_line_count(0) then
		return
	end
	if not down and top - count < 1 then
		return
	end
	vim.cmd(("%d,%dmove %d"):format(top, bottom, down and bottom + count or top - count - 1))
	vim.cmd("normal! gv=gv")
end

map("n", "<A-j>", function()
	move_line(true, vim.v.count1)
end, { desc = "Move Down" })
map("n", "<A-k>", function()
	move_line(false, vim.v.count1)
end, { desc = "Move Up" })
map("i", "<A-j>", function()
	vim.cmd("stopinsert")
	move_line(true, vim.v.count1)
	vim.cmd("normal! gi")
end, { desc = "Move Down" })
map("i", "<A-k>", function()
	vim.cmd("stopinsert")
	move_line(false, vim.v.count1)
	vim.cmd("normal! gi")
end, { desc = "Move Up" })
map("x", "<A-j>", function()
	move_selection(true, vim.v.count1)
end, { desc = "Move Down" })
map("x", "<A-k>", function()
	move_selection(false, vim.v.count1)
end, { desc = "Move Up" })
map("x", "J", function()
	move_selection(true, 1)
end, { desc = "Move Block Down" })
map("x", "K", function()
	move_selection(false, 1)
end, { desc = "Move Block Up" })

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
-- location list
map("n", "<leader>xl", lists.location, { desc = "Location List" })

-- quickfix list
map("n", "<leader>xq", lists.quickfix, { desc = "Quickfix List" })

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
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>sv", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>sh", "<C-W>s", { desc = "Split Window Below", remap = true })
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
map("n", "<leader><tab>m", ":tabmove ", { desc = "Move Tab" })

-- Copy whole file content to clipboard
map("n", "<leader>yy", "<cmd>%y+<cr>", { desc = "Yank whole file" })

-- Select all text in buffer with Alt-a
map("n", "<A-a>", "ggVG", { silent = true, desc = "Select all" })

map("n", "<leader>us", function()
	vim.o.spell = not vim.o.spell
	vim.notify(vim.o.spell and "on" or "off", vim.log.levels.INFO, { title = "spell" })
end, { desc = "Toggle Spell" })

-- `:restart` carries the layout itself, written with the 'sessionoptions' the
-- session layer sets, so the project comes back as it was closed.
map("n", "<leader>R", "<cmd>restart<cr>", { desc = "Restart Neovim" })

-- delete marks (use m + character for a mark)
map("n", "dm", function()
	local mark = vim.fn.getcharstr()
	-- Esc, or anything that is not a mark name, would make :delmarks throw.
	if mark:match("^[a-zA-Z0-9'`\"%[%]<>%.%^]$") then
		vim.cmd("delmarks " .. mark)
	end
end, { desc = "Delete mark" })

-- Command history
map("n", "<leader>:", function()
	lists.history(":")
end, { desc = "Command History" })
map("n", "<leader>sc", function()
	lists.history(":")
end, { desc = "Command History" })

-- Terminal
-- :terminal opens in the current directory, which is where nvim started, not
-- the root of the file's project
map("n", "<leader>fT", "<cmd>terminal<cr>", { desc = "Terminal (cwd)" })
map("n", "<C-:>", "<cmd>terminal<cr>", { desc = "Terminal (cwd)" })

-- Video, PDFs and other binaries have no text preview in nvim, so a buffer
-- holding one opens in whatever app the system registered for its type.
map("n", "<leader>fo", function()
	local path = vim.api.nvim_buf_get_name(0)
	if vim.bo.buftype ~= "" or path == "" then
		vim.notify("No file in this buffer", vim.log.levels.WARN)
		return
	end
	local cmd, err = vim.ui.open(path)
	if not cmd then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Open File in System App" })

map("n", "<leader>.", "<cmd>enew<cr>", { desc = "New Buffer" })
map("n", "<leader>U", function()
	require("config.lists").undo()
end, { desc = "Undo Tree" })

-- Toggles (native)
map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle Wrap" })
map("n", "<leader>uL", "<cmd>set relativenumber!<cr>", { desc = "Toggle Relative Number" })
map("n", "<leader>ul", "<cmd>set number!<cr>", { desc = "Toggle Line Number" })
map("n", "<leader>uc", function()
	vim.wo.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
end, { desc = "Toggle Conceal Level" })
-- 1 hides the tabline until there is a second tab, 2 always shows it, so a
-- toggle that assumed 2 would not come back to what was set.
local tabline_was = 1
map("n", "<leader>uA", function()
	if vim.o.showtabline == 0 then
		vim.o.showtabline = tabline_was
	else
		tabline_was = vim.o.showtabline
		vim.o.showtabline = 0
	end
end, { desc = "Toggle Tabline" })

-- Other native replacements
map("n", "<leader>sm", lists.marks, { desc = "Marks" })
map("n", "<leader>sM", ":Man<cr>", { desc = "Man Pages" })
map("n", "<leader>sq", lists.quickfix, { desc = "Quickfix List" })
map("n", '<leader>s"', lists.registers, { desc = "Registers" })
map("n", "<leader>s/", function()
	lists.history("/")
end, { desc = "Search History" })
map("n", "<leader>sa", lists.autocmds, { desc = "Autocmds" })
map("n", "<leader>sC", lists.commands, { desc = "Commands" })
map("n", "<leader>sj", lists.jumps, { desc = "Jumps" })
map("n", "<leader>s;", lists.changes, { desc = "Change List" })
map("n", "<leader>sN", lists.messages, { desc = "Messages" })
map("n", "<leader>sl", lists.location, { desc = "Location List" })
map("n", "<leader>N", ":help news<cr>", { desc = "Neovim News" })
map("n", "<leader>un", "<cmd>messages clear<cr>", { desc = "Clear Messages" })

map("n", "*", "*``", { desc = "Search word under cursor, stay in place" })
map("n", "#", "#``", { desc = "Search word under cursor backward, stay in place" })
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

-- Spell checking. `]` is a prefix, so a mapping to `]s` would recurse: go
-- through `normal!` to run the built-in instead.
map("n", "]s", "<cmd>normal! ]s<cr>", { desc = "Next Spell Error" })
map("n", "[s", "<cmd>normal! [s<cr>", { desc = "Previous Spell Error" })

-- Fix Spell checking
map("n", "z0", "1z=", { desc = "Fix word under cursor" })
