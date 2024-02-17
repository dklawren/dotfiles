return {
  { "f-person/git-blame.nvim", opts = {} },
  {
    "ThePrimeagen/git-worktree.nvim",
    config = function()
      require("telescope").load_extension("git_worktree")
      vim.keymap.set("n", "<leader>gw", "<cmd>Telescope git_worktree<CR>", { desc = "List Git Worktrees" })
      vim.keymap.set(
        "n",
        "<leader>gn",
        "<cmd>:lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
        { desc = "Create New Git Worktree" }
      )
    end,
  },
}
