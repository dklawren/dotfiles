return {
  "coffebar/neovim-project",
  opts = {
    projects = { -- define project roots
      "~/devel/github/mozilla/bmo/upstream/*",
      "~/devel/github/mozilla/lando-ui",
      "~/devel/github/mozilla/lando-api/*",
      "~/devel/github/mozilla/phabricator/*",
      "~/devel/github/dklawren/bmo/*",
      "~/local-devel/*",
      "~/.config/*",
    },
  },
  init = function()
    -- enable saving the state of plugins in the session
    vim.opt.sessionoptions:append("globals") -- save global variables that start with an uppercase letter and contain at least one lowercase letter.
  end,
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-telescope/telescope.nvim", tag = "0.1.4" },
    { "Shatur/neovim-session-manager" },
  },
  lazy = false,
  priority = 100,
}
