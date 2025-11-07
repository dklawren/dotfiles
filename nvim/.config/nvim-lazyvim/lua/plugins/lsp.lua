return {
  "neovim/nvim-lspconfig",
  opts = {
    autoformat = false,
    servers = {
      perlnavigator = {
        settings = {
          perlnavigator = {
            includePaths = { "./" },
            perlcriticProfile = "/var/home/dkl/devel/github/mozilla/bmo/.perlcriticrc",
            perltidyProfile = "/var/home/dkl/devel/github/mozilla/bmo/.perltidyrc",
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
