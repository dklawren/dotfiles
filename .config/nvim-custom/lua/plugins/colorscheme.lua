-- vim.pack.add({"https://github.com/folke/tokyonight.nvim.git"})
-- vim.cmd[[colorscheme tokyonight]]
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
  config = function()
    vim.cmd[[colorscheme tokyonight]]
  end,
}
