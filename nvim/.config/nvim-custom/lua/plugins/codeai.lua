return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    strategies = {
      chat = {
        adapter = "ollama",
        model = "gemma3:4b",
      },
      inline = {
        adapter = "ollama",
        model = "gemma3:4b",
      },
      cmd = {
        adapter = "ollama",
        model = "gemma3:4b",
      },
    },
  },
}
