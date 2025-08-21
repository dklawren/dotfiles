return {
  'nvim-telescope/telescope.nvim',
  enabled = false,
  keys = {
    { "<leader><leader>", "<cmd>Telescope find_files<cr>" },
    { "<leader>/", "<cmd>Telescope live_grep<cr>" },
  },
  lazy = false,
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-ui-select.nvim'
  },
  config = function ()
    require("telescope").load_extension("ui-select")
  end
}
