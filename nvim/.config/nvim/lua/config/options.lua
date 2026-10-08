-- Only what differs from the nvim defaults: check a value here with
-- `nvim --clean -c 'set <opt>?'` before adding a line for it.
vim.opt.number = true -- Line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.cursorline = true -- Highlight current line
vim.opt.wrap = false -- Don't wrap lines
vim.opt.scrolloff = 10 -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor

-- Indentation
vim.opt.tabstop = 2 -- Tab width
vim.opt.shiftwidth = 2 -- Indent width
vim.opt.softtabstop = 2 -- Soft tab stop
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.smartindent = true -- Smart auto-indenting
vim.opt.shiftround = true -- Round indent

-- Search settings
vim.opt.ignorecase = true -- Case insensitive search
vim.opt.smartcase = true -- Case sensitive if uppercase in search
vim.opt.hlsearch = false -- Don't highlight search results

-- Visual settings
vim.opt.termguicolors = true -- Enable 24-bit colors
vim.opt.signcolumn = "yes" -- Always show sign column
vim.opt.showmatch = true -- Highlight matching brackets
vim.opt.matchtime = 2 -- How long to show matching bracket
vim.opt.cmdheight = 0 -- Auto-expand when there's output
vim.opt.showmode = false -- Don't show mode in command line
vim.opt.pumheight = 10 -- Popup menu height
vim.opt.pumblend = 10 -- Popup menu transparency
vim.opt.pummaxwidth = 60 -- cap completion popup width
vim.opt.completeopt = "menu,menuone,noselect,popup" -- popup shows completionItem/resolve preview
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
vim.opt.synmaxcol = 300 -- Syntax highlighting limit
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.ruler = false -- Disable the default ruler
vim.opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
vim.opt.winminwidth = 5 -- Minimum window width

-- File handling
vim.opt.writebackup = false -- Don't create backup before writing
vim.opt.swapfile = false -- Don't create swap files
vim.opt.undofile = true -- Persistent undo
vim.opt.undolevels = 10000
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.fn.mkdir(vim.o.undodir, "p")

vim.opt.updatetime = 500
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.opt.autowrite = true -- Auto save

vim.opt.path:append("**") -- include subdirectories in search
vim.opt.mouse = "a" -- Enable mouse support
-- Clipboard provider and 'clipboard' live in config/clipboard.lua

-- Folding settings
vim.opt.foldlevel = 99 -- Start with all folds open
vim.opt.formatoptions = "jcroqlnt" -- tcqj
vim.opt.nrformats = "unsigned"
vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"

-- Split behavior
vim.opt.splitbelow = true -- Horizontal splits go below
vim.opt.splitright = true -- Vertical splits go right
vim.opt.splitkeep = "screen"

-- Command-line completion
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignore:append("*.o,*.obj,*.pyc,*.class,*.jar")

-- Better diff options (indent-heuristic + inline:char are now defaults, linematch stays custom)
vim.opt.diffopt:append("linematch:60,indent-heuristic,inline:char")

-- Performance improvements
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- global floating window border (all vim.lsp, vim.diagnostic, etc.)
vim.opt.winborder = "rounded"
-- completion popup menu border
vim.opt.pumborder = "rounded"
vim.opt.fillchars = {
	foldopen = "",
	foldclose = "",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}
vim.opt.jumpoptions = "view"
vim.opt.laststatus = 3 -- global statusline
vim.opt.linebreak = true -- Wrap lines at convenient points
vim.opt.shortmess:append("WIcC")

vim.g.markdown_recommended_style = 0

-- `.env`, `.env.*` and `*.env` are detected as filetype `env` by Neovim itself
-- (syntax/env.vim + ftplugin/env.vim), so only the gaps are listed here.
vim.filetype.add({
	extension = {
		txt = "markdown",
		ejs = "embedded_template",
	},
	filename = {
		["env"] = "env",
	},
	pattern = {
		["[jt]sconfig.*.json"] = "jsonc",
		[".*%.tomg%-config.*"] = "toml",
		[".*%.ejs%.t"] = "embedded_template",
		[".*%.code%-snippets"] = "json",
	},
})
