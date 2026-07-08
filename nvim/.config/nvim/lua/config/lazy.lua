local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "catppuccin-mocha" } },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- Perl LSP - Need to find a better place for this
vim.lsp.config["perl-lsp"] = {
  cmd = { "perl-lsp" },
  filetypes = { "perl" },
  root_markers = { "cpanfile", "Makefile.PL", "Build.PL", ".git" },
}
vim.lsp.enable("perl-lsp")
vim.api.nvim_set_hl(0, "@lsp.type.macro.perl", { link = "Keyword" })      -- has, with, extends
vim.api.nvim_set_hl(0, "@lsp.type.property.perl", { link = "Identifier" }) -- hash keys
vim.api.nvim_set_hl(0, "@lsp.type.namespace.perl", { link = "Type" })     -- Foo::Bar
vim.api.nvim_set_hl(0, "@lsp.type.parameter.perl", { link = "Special" })  -- sub params
vim.api.nvim_set_hl(0, "@lsp.type.keyword.perl", { link = "Constant" })   -- $self/$class
vim.api.nvim_set_hl(0, "@lsp.mod.scalar.perl", { fg = "#61afef" })        -- $ blue
vim.api.nvim_set_hl(0, "@lsp.mod.array.perl", { fg = "#c678dd" })         -- @ purple
vim.api.nvim_set_hl(0, "@lsp.mod.hash.perl", { fg = "#e5c07b" })          -- % gold
vim.api.nvim_set_hl(0, "@lsp.mod.modification.perl", { fg = "#e06c75" })  -- writes in red
vim.api.nvim_set_hl(0, "@lsp.mod.declaration.perl", { bold = true })
vim.api.nvim_set_hl(0, "@lsp.mod.readonly.perl", { italic = true })
vim.api.nvim_set_hl(0, "@lsp.mod.defaultLibrary.perl", { italic = true }) -- imported functions
