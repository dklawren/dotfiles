return {
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
  "KilloPillers/telescope-media-files.nvim",
  {
    "telescope.nvim",
    dependencies = { "nvim-telescope/telescope-fzf-native.nvim" },
    build = "make",
    config = function()
      require("telescope").load_extension("fzf")
    end,
  },
}
