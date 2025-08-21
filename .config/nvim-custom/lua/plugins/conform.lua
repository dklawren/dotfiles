return {
  {
    'stevearc/conform.nvim',
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "isort", "black" },
          rust = { "rustfmt", lsp_format = "fallback" },
          javascript = { "prettierd", "prettier", stop_after_first = true },
          perl = { "perltidy" },
        },
        format_on_save = false,
      })
    end,
    keys = {
      { '<leader>lf', '<cmd>lua vim.lsp.buf.format()<cr>', desc = 'LSP Format code' }
    }
  },
  {
    'windwp/nvim-ts-autotag',
    config = function()
      require("nvim-ts-autotag").setup()
    end
  }
}
