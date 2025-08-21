return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {},
  keys = {
    { "<leader><leader>", "<cmd>FzfLua files<cr>", desc = "Find files" },
    { "<leader>/", "<cmd>FzfLua live_grep<cr>", desc = "Grep files" },
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep files" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find buffers" },
  },
}
