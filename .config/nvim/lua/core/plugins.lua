local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  'folke/which-key.nvim',
  'folke/neodev.nvim',
  'ellisonleao/gruvbox.nvim',
  'nvim-tree/nvim-tree.lua',
  'nvim-tree/nvim-web-devicons',
  'nvim-lualine/lualine.nvim',
  'nvim-lua/plenary.nvim', 
  'nvim-treesitter/nvim-treesitter',
  'nvim-telescope/telescope.nvim',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-path',
  'L3MON4D3/LuaSnip',
  'saadparwaiz1/cmp_luasnip',
  'rafamadriz/friendly-snippets',
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',
  'neovim/nvim-lspconfig',
  'farmergreg/vim-lastplace',
  'Yggdroot/hiPairs',
  'windwp/nvim-autopairs',
  'Pocco81/auto-save.nvim',
  'pwntester/octo.nvim',
  'rest-nvim/rest.nvim',
  'lewis6991/gitsigns.nvim',
}

local opts = {}

require('lazy').setup(plugins, opts)
