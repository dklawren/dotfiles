-- blink.cmp is loaded when something asks for it rather than at startup.
--
-- Both halves of the plugin are deferred, not just the setup: its plugin/ file
-- is 3.17ms to source, the largest single file in this config's startup, and
-- setup is 0.83ms more. Calling vim.pack.add at load time is what put that
-- 3.17ms on every start, because :packadd with no bang adds the directory to
-- the runtimepath and nvim then sources its plugin/ files itself at the end of
-- startup, whether or not anything has asked for them.
--
-- Completion is a thing you get when you type, and typing is insert mode, so
-- the first InsertEnter is where both the add and the setup happen. The cost
-- moves rather than disappears: the first entry into insert mode in a session
-- pays the 4ms that every startup used to pay instead.
--
-- The spec is unchanged and still registered with vim.pack from the first
-- InsertEnter, so :Pack, :PackUpdate and :PackDelete see it the same as before.
-- The one thing that changes is when a missing plugin is noticed: an install
-- that has never happened now prompts inside insert mode, so the add is
-- wrapped and the error notified rather than raised under the user's cursor.
local group = vim.api.nvim_create_augroup("BlinkCmpLazyLoad", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	group = group,
	once = true,
	callback = function()
		local ok, err = pcall(function()
			vim.pack.add({
				{
					src = "https://github.com/saghen/blink.cmp",
					version = vim.version.range("^1"),
				},
			})
			-- Everything else is a blink default: the super-tab keymap preset,
			-- the mono icons, the four default sources, the Rust fuzzy matcher
			-- and no documentation window.
			require("blink.cmp").setup({
				keymap = { preset = "super-tab" },
				appearance = {
					use_nvim_cmp_as_default = true,
				},
			})
		end)
		if not ok then
			vim.notify("blink.cmp did not load: " .. tostring(err), vim.log.levels.ERROR)
		end
	end,
})
