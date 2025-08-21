return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>" }
  },
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.opt.termguicolors = true
    require("nvim-tree").setup({
      sort = {
        sorter = "case_sensitive",
      },
      view = {
        width = 40,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = true,
      },
    })
    local api = require("nvim-tree.api")
    api.events.subscribe(api.events.Event.FileCreated, function(file)
      vim.cmd("edit " .. vim.fn.fnameescape(file.fname))
    end)
  end,
}
