return {
	"mason-org/mason-lspconfig.nvim",
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
	},
	opts = {
		servers = {
			lua_ls = {
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			},
			perlnavigator = {
        settings = {
					perlnavigator = {
						includePaths = { "./" },
						perlcriticProfile = "/var/home/dkl/devel/github/mozilla/bmo/.perlcriticrc",
						perltidyProfile = "/var/home/dkl/devel/github/mozilla/bmo/.perltidyrc",
					},
				},
			},
			pyright = {
        settings = {
		    	pyright = {
				    disableOrganizeImports = false,
				    analysis = {
					    useLibraryCodeForTypes = true,
					    autoSearchPaths = true,
					    diagnosticMode = "workspace",
					    autoImportCompletions = true,
				    },
			    },
		    },
      },
		},
	},
	config = function(_, opts)
		require("mason").setup()

		require("mason-lspconfig").setup({
			ensure_installed = { "perlnavigator", "pyright", "lua_ls" },
		})

		vim.diagnostic.config({
			virtual_text = true,
			underline = true,
		})

    local on_attach = function(client, bufnr)
      local keymap = vim.keymap.set
      local key_opts = {
        noremap = true, -- prevent recursive mapping
        silent = true, -- don't print the command to the cli
        buffer = bufnr, -- restrict the keymap to the local buffer number
      }

      -- native neovim keymaps
      keymap("n", "<leader>gD", "<cmd>lua vim.lsp.buf.definition()<CR>", key_opts) -- goto definition
      keymap("n", "<leader>gS", "<cmd>vsplit | lua vim.lsp.buf.definition()<CR>", key_opts) -- goto definition in split
      keymap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", key_opts) -- Code actions
      keymap("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", key_opts) -- Rename symbol
      keymap("n", "<leader>D", "<cmd>lua vim.diagnostic.open_float({ scope = 'line' })<CR>", key_opts) -- Line diagnostics (float)
      keymap("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>", key_opts) -- Cursor diagnostics
      keymap("n", "<leader>pd", "<cmd>lua vim.diagnostic.goto_prev()<CR>", key_opts) -- previous diagnostic
      keymap("n", "<leader>nd", "<cmd>lua vim.diagnostic.goto_next()<CR>", key_opts) -- next diagnostic
      keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", key_opts) -- hover documentation

      -- fzf-lua keymaps
      keymap("n", "<leader>gd", "<cmd>FzfLua lsp_finder<CR>", key_opts) -- LSP Finder (definition + references)
      keymap("n", "<leader>gr", "<cmd>FzfLua lsp_references<CR>", key_opts) -- Show all references to the symbol under the cursor
      keymap("n", "<leader>gt", "<cmd>FzfLua lsp_typedefs<CR>", key_opts) -- Jump to the type definition of the symbol under the cursor
      keymap("n", "<leader>ds", "<cmd>FzfLua lsp_document_symbols<CR>", key_opts) -- List all symbols (functions, classes, etc.) in the current file
      keymap("n", "<leader>ws", "<cmd>FzfLua lsp_workspace_symbols<CR>", key_opts) -- Search for any symbol across the entire project/workspace
      keymap("n", "<leader>gi", "<cmd>FzfLua lsp_implementations<CR>", key_opts) -- Go to implementation
    end

		for server, config in pairs(opts.servers) do
			config.capabilities = require("cmp_nvim_lsp").default_capabilities(config.capabilities)
      config.on_attach = on_attach
			vim.lsp.config(server, config)
			vim.lsp.enable(server)
		end
	end,
}

-- return {
--   "neovim/nvim-lspconfig",
--   event = { "BufReadPre", "BufNewFile" },
--   dependencies = {
--     "hrsh7th/cmp-nvim-lsp",
--     { "antosha417/nvim-lsp-file-operations", config = true },
--     { "folke/neodev.nvim", opts = {} },
--   },
--   config = function()
--     -- import cmp-nvim-lsp plugin
--     local cmp_nvim_lsp = require("cmp_nvim_lsp")
--
--     local keymap = vim.keymap -- for conciseness
--     vim.api.nvim_create_autocmd("LspAttach", {
--       group = vim.api.nvim_create_augroup("UserLspConfig", {}),
--       callback = function(ev)
--         -- Buffer local mappings.
--         -- See `:help vim.lsp.*` for documentation on any of the below functions
--         local opts = { buffer = ev.buf, silent = true }
--
--         -- set keybinds
--         opts.desc = "Show LSP references"
--         keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references
--
--         opts.desc = "Go to declaration"
--         keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration
--
--         opts.desc = "Show LSP definitions"
--         keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions
--
--         opts.desc = "Show LSP implementations"
--         keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations
--
--         opts.desc = "Show LSP type definitions"
--         keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions
--
--         opts.desc = "See available code actions"
--         keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection
--
--         opts.desc = "Smart rename"
--         keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename
--
--         opts.desc = "Show buffer diagnostics"
--         keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file
--
--         opts.desc = "Show line diagnostics"
--         keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line
--
--         opts.desc = "Go to previous diagnostic"
--         keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer
--
--         opts.desc = "Go to next diagnostic"
--         keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer
--
--         opts.desc = "Show documentation for what is under cursor"
--         keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor
--
--         opts.desc = "Restart LSP"
--         keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
--       end,
--     })
--
--     -- used to enable autocompletion (assign to every lsp server config)
--     local capabilities = cmp_nvim_lsp.default_capabilities()
--
--     vim.diagnostic.config({
--       signs = {
--         text = {
--           [vim.diagnostic.severity.ERROR] = " ",
--           [vim.diagnostic.severity.WARN] = " ",
--           [vim.diagnostic.severity.HINT] = "󰠠 ",
--           [vim.diagnostic.severity.INFO] = " ",
--         },
--       },
--     })
--
--     vim.lsp.config("*", {
--       capabilities = capabilities,
--     })
--
--     vim.lsp.config("svelte", {
--       on_attach = function(client, bufnr)
--         vim.api.nvim_create_autocmd("BufWritePost", {
--           pattern = { "*.js", "*.ts" },
--           callback = function(ctx)
--             -- Here use ctx.match instead of ctx.file
--             client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
--           end,
--         })
--       end,
--     })
--
--     vim.lsp.config("graphql", {
--       filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
--     })
--
--     vim.lsp.config("emmet_ls", {
--       filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
--     })
--
--     vim.lsp.config("eslint", {
--       filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
--     })
--
--     vim.lsp.config("lua_ls", {
--       settings = {
--         Lua = {
--           -- make the language server recognize "vim" global
--           diagnostics = {
--             globals = { "vim" },
--           },
--           completion = {
--             callSnippet = "Replace",
--           },
--         },
--       },
--     })
--   end,
-- }
