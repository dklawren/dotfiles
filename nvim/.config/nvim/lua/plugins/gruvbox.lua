-- Gruvbox colorscheme, so `theme-switch gruvbox-dark` (which writes "gruvbox"
-- to ~/.config/theme-active/nvim-colorscheme) has a colorscheme to load.
-- Catppuccin is configured separately in catppuccin.lua.
return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    contrast = "medium",
  },
}
