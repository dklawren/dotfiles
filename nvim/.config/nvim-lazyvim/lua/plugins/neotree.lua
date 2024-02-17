return {
  "nvim-neo-tree/neo-tree.nvim",
  config = function()
    require("neo-tree").setup({
      window = {
        mappings = {
          ["e"] = function()
            vim.api.nvim_exec("Neotree focus filesystem left", true)
          end,
          ["b"] = function()
            vim.api.nvim_exec("Neotree focus buffers left", true)
          end,
          ["g"] = function()
            vim.api.nvim_exec("Neotree focus git_status left", true)
          end,
        },
      },
    })
  end,
}
