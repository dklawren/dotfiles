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
    },
  },
}
