return {
  'saghen/blink.cmp',
  dependencies = {
    "rafamadriz/friendly-snippets"
  },
  version = '1.*',
  opts = {
    keymap = {
      preset = 'default',
      ["<CR>"] = { "accept", "fallback" },
      ["<C><leader>"] = { "show" },
    },

    appearance = {
      nerd_font_variant = 'mono'
    },
    signature = { enabled = true },
    completion = {
      documentation = { auto_show = true },
      menu = {
        auto_show = true,
        draw = {
          treesitter = { "lsp" },
          columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
        }
      }
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      per_filetype = {
        codecompanion = { "codecompanion" },
      }
    },
    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" },
}
