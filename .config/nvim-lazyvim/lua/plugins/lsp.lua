return {
  "neovim/nvim-lspconfig",
  opts = {
    autoformat = false,
    servers = {
      perlnavigator = {
        settings = {
          perlnavigator = {
            includePaths = { "./" },
            perlcriticProfile = "/var/home/dkl/devel/github/mozilla/bmo/master/.perlcriticrc",
            perltidyProfile = "/var/home/dkl/devel/github/mozilla/bmo/master/.perltidyrc",
          },
        },
      },
    },
  },
}
