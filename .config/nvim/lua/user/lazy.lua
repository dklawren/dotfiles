local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- example using a list of specs with the default options
vim.g.mapleader = " " -- make sure to set `mapleader` before lazy so your mappings are correct

require("lazy").setup {
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPre",
    config = function()
      require "user.indentline"
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require "user.whichkey"
    end,
  },
  "nvim-lua/plenary.nvim",
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require "user.autopairs"
    end,
  },
  {
    "numToStr/Comment.nvim",
    event = "BufRead",
    config = function()
      require "user.comment"
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    dependencies = {
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        event = "VeryLazy",
      },
      {
        "kyazdani42/nvim-web-devicons",
        config = function()
          require("nvim-web-devicons").setup {
            override = {
              zsh = {
                icon = "",
                color = "#428850",
                cterm_color = "65",
                name = "Zsh",
              },
            },
            color_icons = true,
            default = true,
          }
        end,
      },
    },
    config = function()
      require "user.treesitter"
    end,
  },
  {
    "kyazdani42/nvim-tree.lua",
    config = function()
      require "user.nvim-tree"
    end,
  },
  "moll/vim-bbye",
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require "user.lualine"
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    event = "VeryLazy",
    config = function()
      require "user.toggleterm"
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    event = "Bufenter",
    cmd = { "Telescope" },
    dependencies = {
      {
        "ahmedkhalf/project.nvim",
        config = function()
          require "user.project"
        end,
      },
    },
    config = function()
      require "user.telescope"
    end,
  },
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      require "user.alpha"
    end,
  },
  {
    "lunarvim/darkplus.nvim",
    config = function ()
      vim.cmd("colorscheme darkplus")
    end
  },
  {
    "hrsh7th/nvim-cmp",
    event = {
      "InsertEnter",
      "CmdlineEnter",
    },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lua",
    },
    config = function()
      require "user.cmp"
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = true,
  },
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    event = "BufReadPre",
    config = function()
      require "user.lsp.mason"
    end,
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = "BufReadPre",
    config = function()
      require "user.lsp.null-ls"
    end,
  },
  {
    "RRethy/vim-illuminate",
    event = "VeryLazy",
    config = function()
      require "user.illuminate"
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    config = function()
      require "user.gitsigns"
    end,
  },
  "farmergreg/vim-lastplace",
  { "Pocco81/auto-save.nvim", opts = {} },
  {
    "toppair/peek.nvim",
    config = function ()
      require "user.peek"
    end
  },
  "BlackLight/nvim-http",
  "f-person/git-blame.nvim",
  {
    "akinsho/bufferline.nvim",
    opts = {}
  }
}
