require('nvim-treesitter.configs').setup {
  ensure_installed = { 'c', 'css', 'lua', 'html', 'perl', 'python', 'php', 'yaml' },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
  }
}
