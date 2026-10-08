-- Retry transient network failures (corporate proxy/VPN blips) instead of
-- failing the whole install on the first curl error.
local FFF_CURL_ARGS = { "--retry", "3", "--retry-delay", "2", "--connect-timeout", "15" }

local function is_wsl()
	if vim.uv.os_uname().sysname:lower() ~= "linux" then
		return false
	end
	if os.getenv("WSL_DISTRO_NAME") or os.getenv("WSL_INTEROP") then
		return true
	end
	local f = io.open("/proc/version", "r")
	if not f then
		return false
	end
	local content = f:read("*a")
	f:close()
	return content:lower():find("microsoft", 1, true) ~= nil
end

local function notify_install_failure(err)
	vim.schedule(function()
		vim.notify("fff.nvim binary install failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
	end)
end

-- Ensure the fff binary exists on startup and after install/update.
--
-- Runs fully async: fff's own download_or_build_binary() blocks the caller
-- with a fixed 2-minute vim.wait, which a real `cargo build --release` can
-- exceed, turning a slow-but-fine build into a hard install failure. We're
-- inside a live Neovim session (not a headless hook that exits as soon as we
-- return), so nothing forces us to block, and pcall keeps any error from
-- surfacing as an uncaught autocmd error.
local function ensure_fff_binary(force)
	local ok, download = pcall(require, "fff.download")
	if not ok then
		return
	end

	local function download_or_build()
		local dl_ok, dl_err = pcall(
			download.ensure_downloaded,
			{ force = force, extra_curl_args = FFF_CURL_ARGS },
			function(success, err)
				if success then
					return
				end
				vim.schedule(function()
					vim.notify(
						"fff.nvim: prebuilt binary unavailable (" .. (err or "unknown error") .. "), building from source",
						vim.log.levels.WARN
					)
				end)
				local build_ok, build_err = pcall(download.build_binary, function(bok, berr)
					if not bok then
						notify_install_failure(berr)
					end
				end)
				if not build_ok then
					notify_install_failure(build_err)
				end
			end
		)
		if not dl_ok then
			notify_install_failure(dl_err)
		end
	end

	-- Prebuilt Linux release binaries have a known SIGILL crash on CPUs
	-- without AVX-512, which is common under WSL. Build against the host's
	-- own CPU features first and only fall back to the prebuilt binary
	-- (still forced through the retrying curl) if the build itself fails.
	if force and is_wsl() and vim.fn.executable("rustup") == 1 then
		local build_ok, build_err = pcall(download.build_binary, function(bok, berr)
			if bok then
				return
			end
			vim.schedule(function()
				vim.notify(
					"fff.nvim: local build failed (" .. (berr or "unknown error") .. "), falling back to prebuilt binary",
					vim.log.levels.WARN
				)
			end)
			download_or_build()
		end)
		if not build_ok then
			notify_install_failure(build_err)
		end
		return
	end

	download_or_build()
end

-- Before vim.pack.add: PackChanged fires inside add(), so a later handler never
-- sees "install" and the Rust binary is never built. See |vim.pack-events|.
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("fff-pack-changed", { clear = true }),
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "fff.nvim" and (kind == "install" or kind == "update") then
			if not ev.data.active then
				vim.cmd.packadd("fff.nvim")
			end
			ensure_fff_binary(true)
		end
	end,
})

-- Check for binary when the plugin loads (deferred to not block startup)
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	group = vim.api.nvim_create_augroup("fff-startup-check", { clear = true }),
	callback = function()
		vim.schedule(function()
			ensure_fff_binary(false)
		end)
	end,
})

vim.pack.add({
	"https://github.com/dmtrKovalenko/fff.nvim",
})

-- Only what differs from fff's own defaults: a shell prompt, a taller picker
-- with the prompt on top, a bigger preview read, and the vim-flavoured keys.
require("fff").setup({
	prompt = "> ",
	layout = {
		height = 0.85,
		width = 0.85,
		prompt_position = "top",
		preview_size = 0.45,
	},
	preview = {
		max_size = 15 * 1024 * 1024,
		chunk_size = 16384,
	},
	keymaps = {
		close = { "<Esc>", "<C-c>" },
		select = { "<CR>", "<C-o>" },
		move_up = { "<Up>", "<C-p>", "<C-k>" },
		move_down = { "<Down>", "<C-n>", "<C-j>" },
		preview_scroll_up = { "<C-u>", "<PageUp>" },
		preview_scroll_down = { "<C-d>", "<PageDown>" },
	},
})

-- stylua: ignore start
vim.keymap.set("n", "<leader><space>", function() require("fff").find_files() end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>/", function() require("fff").live_grep() end, { desc = "Grep" })
vim.keymap.set("n", "<leader>ff", function() require("fff").find_files() end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function() require("fff").live_grep() end, { desc = "Grep" })
vim.keymap.set({ "n", "x" }, "<leader>fw", function() require("fff").live_grep_under_cursor() end, { desc = "Grep Word" })
vim.keymap.set("n", "<leader>fc", function() require("fff").find_files_in_dir(vim.fn.stdpath("config")) end, { desc = "Find Config File" })
vim.keymap.set("n", "<leader>fr", function() require("fff").find_files() end, { desc = "Recent Files" })
-- stylua: ignore end
