return {
  'nvim-treesitter/nvim-treesitter',
  event = 'VeryLazy',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  build = ':TSUpdate',
  config = function ()
    require("nvim-treesitter.configs").setup {
      ensure_installed = { "http", "json", "lua", "perl", "python" },
      sync_install = true,
      auto_install = true,
      highlight = {
        enable = true,
      },
      indent = { enable = true },
    }
  end
}
