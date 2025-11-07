return {
  "neovim/nvim-lspconfig",
  opts = {
    autoformat = false,
    servers = {
      perlnavigator = {
        settings = {
          perlnavigator = {
            includePaths = { "./" },
            perlcriticProfile = "/home/dkl/devel/github/mozilla/bmo/master/.perlcriticrc",
            perltidyProfile = "/home/dkl/devel/github/mozilla/bmo/master/.perltidyrc",
          },
        },
      },
      systemd_ls = {
        cmd = { 'systemd-lsp' },
        filetypes = { 'systemd' },
        root_dir = function() return nil end,
        single_file_support = true,
        settings = {},
      },
    },
  },
}
