return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = {
      lua = { "stylua" },
      perl = { "perltidy" },
      python = { "isort", "black" },
      javascript = { { "prettierd", "prettier" } },
    }
    opts.log_level = vim.log.levels.ERROR
    opts.notify_on_error = true
  end,
}
