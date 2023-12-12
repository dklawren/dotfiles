return {
  -- miscellaneous
  "farmergreg/vim-lastplace",
  "BlackLight/nvim-http",
  {
    "toppair/peek.nvim",
    event = { "BufRead", "BufNewFile" },
    build = "deno task --quiet build:fast",
    config = function()
      require("peek").setup()
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },

  -- git support
  "f-person/git-blame.nvim",

  -- colorscheme
  "lunarvim/darkplus.nvim",
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "darkplus",
    },
  },

  -- telescope
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
  "KilloPillers/telescope-media-files.nvim",

  -- autocomplete
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- this way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
    end,
  },

  -- lsp
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
  {
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
  },

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "perl",
        "python",
        "sql",
        "http",
        "php",
      })
    end,
  },

  -- project management
  {
    "coffebar/neovim-project",
    opts = {
      projects = { -- define project roots
        "~/devel/github/mozilla/bmo/upstream/*",
        "~/devel/github/mozilla/lando-ui",
        "~/devel/github/mozilla/lando-api/*",
        "~/devel/github/mozilla/phabricator/*",
        "~/devel/github/dklawren/bmo/*",
        "~/local-devel/*",
        "~/.config/*",
      },
    },
    init = function()
      -- enable saving the state of plugins in the session
      vim.opt.sessionoptions:append("globals") -- save global variables that start with an uppercase letter and contain at least one lowercase letter.
    end,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim", tag = "0.1.4" },
      { "Shatur/neovim-session-manager" },
    },
    lazy = false,
    priority = 100,
  },
}
