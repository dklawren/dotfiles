return {
  "pankajgarkoti/daily-notes.nvim",
  config = function()
    require("daily-notes").setup({
      base_dir = "~/silverbullet", -- Your notes directory
      journal_path = "Journal", -- Subdirectory for daily notes
      -- template_path = "~/Documents/Notes/templates/daily.md", -- Optional template
      file_format = "%Y-%m-%d.md", -- Date format for filenames
      dir_format = nil, -- Date format for directories
      template_path = nil, -- Optional template file path
    })
  end,
  keys = {
    {
      "<leader>dn",
      function()
        require("daily-notes").open_daily_note()
      end,
      desc = "Open daily note",
    },
    {
      "<leader>dk",
      function()
        require("daily-notes").open_adjacent_note(-1)
      end,
      desc = "Previous daily note",
    },
    {
      "<leader>dj",
      function()
        require("daily-notes").open_adjacent_note(1)
      end,
      desc = "Next daily note",
    },
    {
      "<leader>dm",
      function()
        require("daily-notes").create_tomorrow_note()
      end,
      desc = "Create tomorrow's note",
    },
    {
      "<leader>dc",
      function()
        require("daily-notes").configure_interactive()
      end,
      desc = "Configure daily notes",
    },
  },
  cmd = {
    "DailyNote",
    "DailyNotePrev",
    "DailyNoteNext",
    "DailyNoteTomorrow",
    "DailyNoteConfig",
  },
}
