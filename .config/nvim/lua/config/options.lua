-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.backup = false -- creates a backup file
opt.conceallevel = 0 -- so that `` is visible in markdown files
opt.fileencoding = "utf-8" -- the encoding written to a file
opt.fillchars.eob = " " -- show empty lines at the end of a buffer as ` ` {default `~`}
opt.formatoptions:remove({ "c", "r", "o" }) -- This is a sequence of letters which describes how automatic formatting is to be done
opt.hlsearch = true -- highlight all matches on previous search pattern
opt.iskeyword:append("-") -- treats words with `-` as single words
opt.linebreak = true
opt.numberwidth = 4 -- minimal number of columns to use for the line number {default 4}
opt.relativenumber = false -- relative line numbers
opt.showtabline = 0 -- always show tabs
opt.swapfile = false -- creates a swapfile
opt.whichwrap:append("<,>,[,],h,l") -- keys allowed to move to the previous/next line when the beginning/end of line is reached
