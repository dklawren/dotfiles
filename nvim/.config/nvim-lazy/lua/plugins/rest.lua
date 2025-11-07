return {
  "rest-nvim/rest.nvim",
  enabled = false,
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("rest-nvim").setup{}
  end
}
