-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.cmd([[
  autocmd BufReadPre * hi TrailingWhitespace guibg=red|match TrailingWhitespace /\s\+$/
]])
