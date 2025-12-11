 return {
  "nvim-orgmode/orgmode",
  event = "VeryLazy",
  ft = { "org" },
  enabled = false,
  config = function()
    require("orgmode").setup({
      org_agenda_files = "~/silverbullet/OrgMode/**/*",
      org_default_notes_file = "~/silverbullet/OrgMode/Inbox.org",
    })
  end,
}
