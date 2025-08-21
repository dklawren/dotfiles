return {
  "nvim-treesitter/nvim-treesitter",
  branch = 'master',
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")

    config.setup({
      ensure_installed = { "lua", "markdown", "markdown_inline", "perl", "python", "html" },
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}
