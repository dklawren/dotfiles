vim.pack.add({
	{ src = "https://github.com/mfussenegger/nvim-dap", version = "b516f20b" },
	{ src = "https://github.com/igorlfs/nvim-dap-view", version = vim.version.range("1.*") },
})

local _dap_initialized = false

local function init_dap()
	if _dap_initialized then
		return
	end

	_dap_initialized = true

	local dap = require("dap")

	local js_debug_path = vim.fn.expand("$HOME/vscode-js-debug/dist/src/dapDebugServer.js")
	dap.adapters["pwa-node"] = {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = {
			command = "node",
			args = { js_debug_path, "${port}" },
		},
	}
	dap.adapters["node"] = function(cb, config)
		if config.type == "node" then
			config.type = "pwa-node"
		end
		local a = dap.adapters["pwa-node"]
		if type(a) == "function" then
			a(cb, config)
		else
			cb(a)
		end
	end

	-- Disable default nvim-dap behavior of automatically loading .vscode/launch.json
	---@diagnostic disable-next-line: duplicate-set-field
	dap.providers.configs["dap.launch.json"] = function()
		return {}
	end

	local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
	for _, ft in ipairs(js_filetypes) do
		dap.configurations[ft] = {
			{
				type = "pwa-node",
				request = "attach",
				name = "Nvim Debug App",
				port = 9229,
				address = "localhost",
				localRoot = vim.fn.getcwd(),
				remoteRoot = "/usr/src/app",
				sourceMaps = true,
				protocol = "inspector",
				cwd = vim.fn.getcwd(),
			},
			{
				type = "pwa-node",
				request = "launch",
				name = "Nvim Mocha Tests",
				program = vim.fn.getcwd() .. "/node_modules/mocha/bin/_mocha",
				args = {
					"--require",
					"ts-node/register/transpile-only",
					"--require",
					"source-map-support/register",
					"--reporter",
					"spec",
					"--colors",
					vim.fn.getcwd() .. "/tests/unit/**/*.[tj]s",
				},
				internalConsoleOptions = "openOnSessionStart",
				skipFiles = { "<node_internals>/**" },
				sourceMaps = true,
				protocol = "inspector",
				cwd = vim.fn.getcwd(),
			},
		}
	end

	-- nvim-dap-view setup
	require("dap-view").setup({
		auto_toggle = true,
		winbar = {
			controls = {
				enabled = true,
			},
		},
		windows = {
			size = 0.4,
			position = "right",
		},
		virtual_text = {
			enabled = true,
		},
		keymaps = {
			base = {
				next_view = "<Tab>",
				prev_view = "<S-Tab>",
			},
		},
	})
end

-- stylua: ignore start
vim.keymap.set("n", "<leader>db", function() init_dap(); require("dap").toggle_breakpoint() end,         { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dB", function() init_dap(); require("dap").list_breakpoints(); vim.cmd("copen") end, { desc = "List Breakpoints" })
vim.keymap.set("n", "<leader>dc", function() init_dap(); require("dap").continue() end,                 { desc = "Run/Continue" })
vim.keymap.set("n", "<leader>dC", function() init_dap(); require("dap").run_to_cursor() end,            { desc = "Run to Cursor" })
vim.keymap.set("n", "<leader>dg", function() init_dap(); require("dap").goto_() end,                    { desc = "Go to Line (No Execute)" })
vim.keymap.set("n", "<leader>di", function() init_dap(); require("dap").step_into() end,                { desc = "Step Into" })
vim.keymap.set("n", "<leader>dj", function() init_dap(); require("dap").down() end,                     { desc = "Down" })
vim.keymap.set("n", "<leader>dk", function() init_dap(); require("dap").up() end,                       { desc = "Up" })
vim.keymap.set("n", "<leader>dl", function() init_dap(); require("dap").run_last() end,                 { desc = "Run Last" })
vim.keymap.set("n", "<leader>do", function() init_dap(); require("dap").step_out() end,                 { desc = "Step Out" })
vim.keymap.set("n", "<leader>dO", function() init_dap(); require("dap").step_over() end,                { desc = "Step Over" })
vim.keymap.set("n", "<leader>dP", function() init_dap(); require("dap").pause() end,                    { desc = "Pause" })
vim.keymap.set("n", "<leader>dr", function() init_dap(); vim.cmd("DapViewJump repl") end,               { desc = "Toggle REPL" })
vim.keymap.set("n", "<leader>ds", function() init_dap(); require("dap").session() end,                  { desc = "Session" })
vim.keymap.set("n", "<leader>dt", function() init_dap(); require("dap").terminate() end,                { desc = "Terminate" })
vim.keymap.set("n", "<leader>dh", function() init_dap(); require("dap-view").hover() end,               { desc = "DAP Hover" })
vim.keymap.set("n", "<leader>du", function() init_dap(); vim.cmd("DapViewToggle") end,                  { desc = "DAP View Toggle" })
vim.keymap.set("x", "<leader>dw", function() vim.cmd("DapViewWatch") end,                               { desc = "DAP Watch Selection" })
-- stylua: ignore end
