return {
  "henrique-smr/todoist-neovim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("todoist").setup({
      api_token = os.getenv("TODOIST_API_TOKEN"), -- Get from https://todoist.com/prefs/integrations
      auto_sync = true,
      sync_interval = 30000, -- 30 seconds
      debug = false,
    })
  end,
}
