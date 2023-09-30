-- OPTIONS

vim.opt.backup = false                          -- creates a backup file
vim.opt.clipboard = "unnamedplus"               -- allows neovim to access the system clipboard
vim.opt.cmdheight = 1                           -- more space in the neovim command line for displaying messages
vim.opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
vim.opt.conceallevel = 0                        -- so that `` is visible in markdown files
vim.opt.fileencoding = "utf-8"                  -- the encoding written to a file
vim.opt.hlsearch = true                         -- highlight all matches on previous search pattern
vim.opt.ignorecase = true                       -- ignore case in search patterns
vim.opt.linebreak = true
vim.opt.mouse = "a"                             -- allow the mouse to be used in neovim
vim.opt.pumheight = 10                          -- pop up menu height
vim.opt.showmode = false                        -- we don't need to see things like -- INSERT -- anymore
vim.opt.showtabline = 0                         -- always show tabs
vim.opt.smartcase = true                        -- smart case
vim.opt.smartindent = true                      -- make indenting smarter again
vim.opt.splitbelow = true                       -- force all horizontal splits to go below current window
vim.opt.splitright = true                       -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false                        -- creates a swapfile
vim.opt.termguicolors = true                    -- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 1000                       -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true                         -- enable persistent undo
vim.opt.updatetime = 300                        -- faster completion (4000ms default)
vim.opt.writebackup = false                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
vim.opt.expandtab = true                        -- convert tabs to spaces
vim.opt.shiftwidth = 2                          -- the number of spaces inserted for each indentation
vim.opt.tabstop = 2                             -- insert 2 spaces for a tab
vim.opt.cursorline = true                       -- highlight the current line
vim.opt.number = true                           -- set numbered lines
vim.opt.laststatus = 3                          -- only the last window will always have a status line
vim.opt.showcmd = false                         -- hide (partial) command in the last line of the screen (for performance)
vim.opt.ruler = false                           -- hide the line and column number of the cursor position
vim.opt.numberwidth = 4                         -- minimal number of columns to use for the line number {default 4}
vim.opt.signcolumn = "yes"                      -- always show the sign column, otherwise it would shift the text each time
vim.opt.wrap = false                            -- display lines as one long line
vim.opt.scrolloff = 8                           -- minimal number of screen lines to keep above and below the cursor
vim.opt.sidescrolloff = 8                       -- minimal number of screen columns to keep to the left and right of the cursor if wrap is `false`
vim.opt.guifont = "monospace:h17"               -- the font used in graphical neovim applications
vim.opt.fillchars.eob=" "                       -- show empty lines at the end of a buffer as ` ` {default `~`}
vim.opt.shortmess:append "c"                    -- hide all the completion messages, e.g. "-- XXX completion (YYY)", "match 1 of 2", "The only match", "Pattern not found"
vim.opt.whichwrap:append("<,>,[,],h,l")         -- keys allowed to move to the previous/next line when the beginning/end of line is reached
vim.opt.iskeyword:append("-")                   -- treats words with `-` as single words
vim.opt.formatoptions:remove({ "c", "r", "o" }) -- This is a sequence of letters which describes how automatic formatting is to be done

vim.g.mapleader = " " -- make sure to set `mapleader` before lazy so your mappings are correct

-- LAZY PLUGINS

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",
  "lunarvim/darkplus.nvim",
  "farmergreg/vim-lastplace",
  "Pocco81/auto-save.nvim",
  "BlackLight/nvim-http",
  "f-person/git-blame.nvim",
  "akinsho/bufferline.nvim",
  "neovim/nvim-lspconfig",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "folke/neodev.nvim",
  "jose-elias-alvarez/null-ls.nvim",
  "nvim-lualine/lualine.nvim",
  "nvim-tree/nvim-web-devicons",
  "lewis6991/gitsigns.nvim",
  "numToStr/Comment.nvim",
  "windwp/nvim-autopairs",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "nvim-treesitter/nvim-treesitter",
  "kyazdani42/nvim-tree.lua",
  "nvim-lua/plenary.nvim",
  "BurntSushi/ripgrep",
  "nvim-telescope/telescope.nvim",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "saadparwaiz1/cmp_luasnip",
  "hrsh7th/cmp-nvim-lua",
  "hrsh7th/nvim-cmp",
  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  "folke/which-key.nvim",
  "natecraddock/workspaces.nvim",
  "ntpeters/vim-better-whitespace",
  "hrsh7th/cmp-nvim-lsp-signature-help",
  "christoomey/vim-tmux-navigator",
  "kdheepak/lazygit.nvim",
  "stevearc/oil.nvim",
  "lukas-reineke/indent-blankline.nvim",
}

-- INDENT BLANKLINE

require("ibl").setup {}

-- COLORSCHEME

vim.cmd("colorscheme darkplus")

-- WORKSPACES

require("workspaces").setup {}

-- WHICH-KEY

require("which-key").setup {}

-- MASON

require("mason").setup {}
require("mason-lspconfig").setup {
  ensure_installed = {"pyright", "perlnavigator","html", "lua_ls", "ruff_lsp"},
  automatic_installation = true,
}

-- NULL-LS

require("null-ls").setup {}

-- PERLNAVIGATOR

require("lspconfig").perlnavigator.setup {
  settings = {
    perlnavigator = {
      perlcriticProfile = '/var/home/dkl/devel/github/mozilla/bmo/upstream/master/.perlcriticrc',
      perltidyProfile = '/var/home/dkl/devel/github/mozilla/bmo/upstream/master/.perltidyrc',
      perlPath = 'perl',
      enableWarnings = true,
      perlcriticEnabled = true,
      perltidyEnabled = true,
      includePaths = {'./', './lib'},
    }
  }
}

-- LUALINE
-- See `:help lualine.txt`

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {},
}

-- BUFFERLINE

require("bufferline").setup {}

-- GITSIGNS

require('gitsigns').setup {}

-- COMMENTS

require('Comment').setup {}

-- AUTOPAIRS

require("nvim-autopairs").setup {}

-- TREESITTER

require("nvim-treesitter.configs").setup {
  ensure_installed = { "lua", "perl", "python" },
  sync_install = true,
  auto_install = true,
  highlight = {
    enable = true
  },
}

-- NVIM-TREE

require("nvim-tree").setup {
  sort_by = "case_sensitive",
  view = {
    width = 40,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
}

-- TELESCOPE

require("telescope").setup {
  defaults = {
    path_display = { "smart" },
    file_ignore_patterns = { ".git/", "node_modules" },
  },
  extensions = {
    workspaces = {
      keep_insert = true,
    }
  }
}

require('telescope').load_extension('workspaces')

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = '[F]ind a specific [f]ile' })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = '[F]ind using live [g]rep'})
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = '[F]ind existing [b]uffers'})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = '[F]ind in [h]elp documentation' })
vim.keymap.set("n", "<leader>fw", "<cmd>Telescope workspaces<cr>", { desc = '[F]ind a specific [w]orkspace' })
vim.keymap.set("n", "<leader><space>", builtin.buffers, { desc = 'Find existing buffers' })
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = '[F]ind recently [o]pened files' })
vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind in current [d]iagnostics' })
vim.keymap.set('n', '<leader>hp', "<cmd>Telescope harpoon marks<cr>", { desc = '[H]arpoon [p]rint list of marks' })
vim.keymap.set('n', '<leader>hm', '<cmd>lua require("harpoon.mark").add_file()<cr>', { desc = '[H]arpoon [m]ark current file' })
vim.keymap.set('n', '<leader>hu', '<cmd>lua require("harpoon.mark").rm_file()<cr>', { desc = '[H]arpoon [u]nmark current file' })

-- AUTOCOMPLETE

require("luasnip.loaders.from_vscode").lazy_load()

local cmp = require("cmp")
local luasnip = require("luasnip")

local check_backspace = function()
  local col = vim.fn.col "." - 1
  return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
end

cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  experimental = {
    ghost_text = true,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    -- ['<Tab>'] = cmp.mapping(function(fallback)
    --   if cmp.visible() then
    --     cmp.select_next_item()
    --   elseif luasnip.expand_or_locally_jumpable() then
    --     luasnip.expand_or_jump()
    --   else
    --     fallback()
    --   end
    -- end, { 'i', 's' }),
    -- ['<S-Tab>'] = cmp.mapping(function(fallback)
    --   if cmp.visible() then
    --     cmp.select_prev_item()
    --   elseif luasnip.locally_jumpable(-1) then
    --     luasnip.jump(-1)
    --   else
    --     fallback()
    --   end
    -- end, { 'i', 's' }),
    --
    -- luasnip
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require("luasnip").jumpable(-1) then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
    { name = "nvim_lua" },
    { name = 'nvim_lsp_signature_help' },
  })
})

cmp.setup.filetype("gitcommit", {
  sources = cmp.config.sources({
    { name = "cmp_git" },
    { name = "buffer" },
  })
})

cmp.setup.cmdline({ "/", "?" }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  }
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
    { name = "cmdline" },
  })
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()
require('lspconfig')["perlnavigator"].setup {
  capabilities = capabilities
}
require('lspconfig')["pyright"].setup {
  capabilities = capabilities
}

-- KEYMAPS

local keymap = vim.keymap.set
local opts = { silent = true }

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Clear highlights
keymap("n", "<leader>h", "<cmd>nohlsearch<CR>", opts)

-- Close buffers
keymap("n", "<S-q>", "<cmd>bdelete<CR>", opts)

-- Better paste
keymap("v", "p", '"_dP', opts)

-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)

-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- NvimTree
keymap("n", "<leader>e", ":NvimTreeFindFileToggle<CR>", {desc = "Toggle Nvim Tree window"})

-- Oil
-- keymap("n", "<leader>e", ":Oil --float .<CR>", {desc = "Toggle Nvim Tree window"})

-- LazyGit
keymap("n", "<leader>gg", ":LazyGit<CR>", {desc = "Toggle LazyGit window"})

-- Comment
keymap("n", "<leader>/", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", {desc = "Comment current line"})
keymap("x", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", {desc = "Comment currently selecting lines"})

-- Lsp Format
function FormatFunction()
  vim.lsp.buf.format({
    async = true,
    range = {
      ["start"] = vim.api.nvim_buf_get_mark(0, "<"),
      ["end"] = vim.api.nvim_buf_get_mark(0, ">"),
    }
  })
end
keymap("n", "<leader>lf", "<cmd>lua vim.lsp.buf.format{ async = true }<cr>", {desc = "[L]SP [f]ormat current buffer"})
keymap("x", "<leader>ls", "<cmd>lua FormatFunction()<cr>", {noremap = true, desc = "[L]SP format current [s]election"})

--  OIL

require("oil").setup {}
