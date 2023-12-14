return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "pyright",
        "perlnavigator",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
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
  },
}
