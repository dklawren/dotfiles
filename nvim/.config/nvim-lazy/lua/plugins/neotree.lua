return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    -- "3rd/image.nvim",
  },
  config = function()
    require("neo-tree").setup({
      window = {
        mappings = {
          ["e"] = function()
            vim.api.nvim_exec("Neotree focus filesystem left reveal", true)
          end,
          ["b"] = function()
            vim.api.nvim_exec("Neotree focus buffers left reveal", true)
          end,
          ["g"] = function()
            vim.api.nvim_exec("Neotree focus git_status left reveal", true)
          end,
        },
      },
    })
  end,
}
