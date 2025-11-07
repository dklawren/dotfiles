return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function ()
    require("lualine").setup({
      options = { theme = "tokyonight" },
      extensions = {'quickfix', 'nvim-tree', 'trouble', 'lazy', 'mason'},
    })
  end
}
