return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
    "artemave/workspace-diagnostics.nvim",
  },
  opts = {
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" }
            }
          }
        }
      },
      perlnavigator = {
        -- on_attach = function(client, bufnr)
        --   require("workspace-diagnostics").populate_workspace_diagnostics(client, 0)
        -- end,
        settings = {
          perlnavigator = {
            includePaths = { "./" },
            perlcriticProfile = "/var/home/dkl/devel/github/mozilla/bmo/.perlcriticrc",
            perltidyProfile = "/var/home/dkl/devel/github/mozilla/bmo/.perltidyrc",
          }
        }
      },
      pyright = {},
    }
  },
  config = function(_, opts)
    require("mason").setup()

    require("mason-lspconfig").setup({
      ensure_installed = { "perlnavigator", "pyright", "lua_ls" }
    })

    vim.diagnostic.config({
      virtual_text = true,
      underline = true,
    })

    for server, config in pairs(opts.servers) do
      config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
      vim.lsp.config(server, config)
      vim.lsp.enable(server)
    end
  end
}
