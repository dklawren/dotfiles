vim.pack.add({
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
})

local renderOpts = {
	heading = {
		enabled = true,
		render_modes = true,
		sign = true,
		icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
		position = "overlay",
		signs = { "󰫎 " },
		width = "full",
		left_margin = 0,
		left_pad = 0,
		right_pad = 0,
		min_width = 0,
		border = false,
		border_virtual = false,
		border_prefix = false,
		above = "▄",
		below = "▀",
		backgrounds = {
			"RenderMarkdownH1Bg",
			"RenderMarkdownH2Bg",
			"RenderMarkdownH3Bg",
			"RenderMarkdownH4Bg",
			"RenderMarkdownH5Bg",
			"RenderMarkdownH6Bg",
		},
		foregrounds = {
			"RenderMarkdownH1",
			"RenderMarkdownH2",
			"RenderMarkdownH3",
			"RenderMarkdownH4",
			"RenderMarkdownH5",
			"RenderMarkdownH6",
		},
	},
	paragraph = {
		enabled = true,
		render_modes = true,
		left_margin = 0,
		min_width = 0,
	},
	code = {
		enabled = true,
		render_modes = true,
		sign = true,
		style = "full",
		position = "left",
		language_pad = 0,
		language_name = true,
		disable_background = { "diff" },
		width = "full",
		left_margin = 0,
		left_pad = 0,
		right_pad = 0,
		min_width = 0,
		border = "thin",
		above = "▄",
		below = "▀",
		highlight = "RenderMarkdownCode",
		highlight_language = nil,
		inline_pad = 0,
		highlight_inline = "RenderMarkdownCodeInline",
	},
	dash = {
		enabled = true,
		render_modes = true,
		icon = "─",
		width = "full",
		left_margin = 0,
		highlight = "RenderMarkdownDash",
	},
	bullet = {
		enabled = true,
		render_modes = true,
		-- icons = { "●", "○", "◆", "◇" },
		-- the default errors when the tree is stale and the marker text comes back empty
		ordered_icons = function(ctx)
			local value = vim.trim(ctx.value)
			local value_index = tonumber(value:sub(1, #value - 1)) or 0
			return string.format("%d.", value_index > 1 and value_index or ctx.index)
		end,
		left_pad = 0,
		right_pad = 0,
		highlight = "RenderMarkdownBullet",
	},
	checkbox = {
		enabled = true,
		render_modes = true,
		position = "inline",
		unchecked = {
			icon = "󰄱 ",
			highlight = "RenderMarkdownUnchecked",
			scope_highlight = nil,
		},
		checked = {
			icon = "󰱒 ",
			highlight = "RenderMarkdownChecked",
			scope_highlight = nil,
		},
		custom = {
			todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo", scope_highlight = nil },
		},
	},
	quote = {
		enabled = true,
		render_modes = true,
		icon = "▋",
		repeat_linebreak = false,
		highlight = "RenderMarkdownQuote",
	},
	pipe_table = {
		enabled = true,
		render_modes = true,
		preset = "none",
		style = "full",
		cell = "padded",
		padding = 1,
		min_width = 0,
		border = {
			"┌",
			"┬",
			"┐",
			"├",
			"┼",
			"┤",
			"└",
			"┴",
			"┘",
			"│",
			"─",
		},
		alignment_indicator = "━",
		head = "RenderMarkdownTableHead",
		row = "RenderMarkdownTableRow",
		filler = "RenderMarkdownTableFill",
	},
	callout = {
		note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
		tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
		important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
		warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
		caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
		-- Obsidian: https://help.obsidian.md/Editing+and+formatting/Callouts
		abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
		summary = { raw = "[!SUMMARY]", rendered = "󰨸 Summary", highlight = "RenderMarkdownInfo" },
		tldr = { raw = "[!TLDR]", rendered = "󰨸 Tldr", highlight = "RenderMarkdownInfo" },
		info = { raw = "[!INFO]", rendered = "󰋽 Info", highlight = "RenderMarkdownInfo" },
		todo = { raw = "[!TODO]", rendered = "󰗡 Todo", highlight = "RenderMarkdownInfo" },
		hint = { raw = "[!HINT]", rendered = "󰌶 Hint", highlight = "RenderMarkdownSuccess" },
		success = { raw = "[!SUCCESS]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
		check = { raw = "[!CHECK]", rendered = "󰄬 Check", highlight = "RenderMarkdownSuccess" },
		done = { raw = "[!DONE]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
		question = { raw = "[!QUESTION]", rendered = "󰘥 Question", highlight = "RenderMarkdownWarn" },
		help = { raw = "[!HELP]", rendered = "󰘥 Help", highlight = "RenderMarkdownWarn" },
		faq = { raw = "[!FAQ]", rendered = "󰘥 Faq", highlight = "RenderMarkdownWarn" },
		attention = { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderMarkdownWarn" },
		failure = { raw = "[!FAILURE]", rendered = "󰅖 Failure", highlight = "RenderMarkdownError" },
		fail = { raw = "[!FAIL]", rendered = "󰅖 Fail", highlight = "RenderMarkdownError" },
		missing = { raw = "[!MISSING]", rendered = "󰅖 Missing", highlight = "RenderMarkdownError" },
		danger = { raw = "[!DANGER]", rendered = "󱐌 Danger", highlight = "RenderMarkdownError" },
		error = { raw = "[!ERROR]", rendered = "󱐌 Error", highlight = "RenderMarkdownError" },
		bug = { raw = "[!BUG]", rendered = "󰨰 Bug", highlight = "RenderMarkdownError" },
		example = { raw = "[!EXAMPLE]", rendered = "󰉹 Example", highlight = "RenderMarkdownHint" },
		quote = { raw = "[!QUOTE]", rendered = "󱆨 Quote", highlight = "RenderMarkdownQuote" },
		cite = { raw = "[!CITE]", rendered = "󱆨 Cite", highlight = "RenderMarkdownQuote" },
	},
	link = {
		enabled = true,
		render_modes = true,
		footnote = {
			superscript = true,
			prefix = "",
			suffix = "",
		},
		image = "󰥶 ",
		email = "󰀓 ",
		hyperlink = "󰌹 ",
		highlight = "RenderMarkdownLink",
		wiki = { icon = "󱗖 ", highlight = "RenderMarkdownWikiLink" },
		custom = {
			web = { pattern = "^http", icon = "󰖟 " },
			youtube = { pattern = "youtube%.com", icon = "󰗃 " },
			github = { pattern = "github%.com", icon = "󰊤 " },
			neovim = { pattern = "neovim%.io", icon = " " },
			stackoverflow = { pattern = "stackoverflow%.com", icon = "󰓌 " },
			discord = { pattern = "discord%.com", icon = "󰙯 " },
			reddit = { pattern = "reddit%.com", icon = "󰑍 " },
		},
	},
	sign = {
		enabled = true,
		highlight = "RenderMarkdownSign",
	},
	indent = {
		enabled = false,
		render_modes = false,
		per_level = 2,
		skip_level = 1,
		skip_heading = false,
	},
}

require("render-markdown").setup(renderOpts)

vim.keymap.set("n", "<leader>um", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle Render Markdown" })

-- Markdown preview use cli mdserve
local mdserve_job = nil
vim.keymap.set("n", "<leader>mp", function()
	if mdserve_job then
		vim.fn.jobstop(mdserve_job) -- stop previous mdserve
	end

	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("No file to preview", vim.log.levels.WARN)
		return
	end
	mdserve_job = vim.fn.jobstart({ "mdserve", file, "--port", "1337", "--open" }, { detach = true })
end, { desc = "Markdown preview (mdserve)" })

-- Native image preview: shows the image under the cursor with the builtin vim.ui.img.
-- Needs the kitty graphics protocol (kitty, ghostty, wezterm). Non-PNG local files
-- (webp, jpeg, gif) are converted to PNG with macOS sips before display.
local img_group = vim.api.nvim_create_augroup("md-img-preview", { clear = true })
local img_supported = nil -- nil until the terminal has been probed
local img_cache = {} -- path -> png bytes
local img_shown = nil -- { id, path }

local function img_clear()
	if img_shown then
		pcall(vim.ui.img.del, img_shown.id)
		img_shown = nil
	end
end

local function img_place(path, data)
	local win = vim.api.nvim_get_current_win()
	local pos = vim.api.nvim_win_get_position(win)
	-- img row/col are absolute terminal cells, so offset from the window position
	local row = pos[1] + vim.fn.winline() - 1 + (vim.wo[win].winbar ~= "" and 1 or 0)
	local width = math.floor(vim.fn.winwidth(win) * 0.3)
	local col = math.max(pos[2] + vim.fn.winwidth(win) - width - 1, pos[2] + 1)
	-- width only: kitty derives the height from the image aspect ratio
	local opts = { row = row, col = col, width = width }
	if img_shown and img_shown.path == path then
		vim.ui.img.set(img_shown.id, opts)
		return
	end
	img_clear()
	img_shown = { id = vim.ui.img.set(data, opts), path = path }
end

-- Convert any local image to PNG bytes. Direct passthrough for PNGs.
local function img_png_bytes(path)
	local ok, data = pcall(vim.fn.readblob, path)
	if not ok then
		return nil
	end
	if data:sub(1, 4) == "\137PNG" then
		return data
	end
	local out = vim.fn.tempname()
	vim.fn.system({ "sips", "-s", "format", "png", "--out", out, path })
	if vim.v.shell_error ~= 0 or vim.fn.filereadable(out) ~= 1 then
		return nil
	end
	data = vim.fn.readblob(out)
	vim.fn.delete(out)
	return data
end

local function img_show(path)
	if img_cache[path] then
		return img_place(path, img_cache[path])
	end
	if path:match("^https?://") then
		vim.net.request(path, {}, function(err, res)
			local data = type(res) == "table" and res.body
			if err or type(data) ~= "string" or data:sub(1, 4) ~= "\137PNG" then
				return
			end
			img_cache[path] = data
			vim.schedule(function()
				if vim.bo.filetype == "markdown" then
					img_place(path, data)
				end
			end)
		end)
	else
		local data = img_png_bytes(path)
		if not data then
			return
		end
		img_cache[path] = data
		img_place(path, data)
	end
end

vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
	group = img_group,
	callback = function()
		if vim.bo.filetype ~= "markdown" then
			img_clear()
			return
		end
		-- Markdown ![alt](url) or HTML <img src="url">
		local path = vim.api.nvim_get_current_line():match("!%b[]%((%S+)%)")
			or vim.api.nvim_get_current_line():match('<img%s+src="([^"]+)"')
		if path and not path:match("^%a+://") then
			if path:sub(1, 1) == "~" then
				path = vim.env.HOME .. path:sub(2)
			elseif path:sub(1, 1) ~= "/" then
				path = vim.fs.joinpath(vim.fn.expand("%:p:h"), path)
			end
		end
		if not path or (not path:match("^%a+://") and vim.fn.filereadable(path) ~= 1) then
			img_clear()
			return
		end
		if img_supported == nil then
			local ok, supported = pcall(function()
				return require("vim.ui.img._kitty").supported({ timeout = 300 })
			end)
			img_supported = ok and supported == true
		end
		if img_supported then
			img_show(path)
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
	group = img_group,
	callback = img_clear,
})

-- Clean up mdserve process when exiting nvim
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		if mdserve_job then
			vim.fn.jobstop(mdserve_job)
		end
		pcall(vim.ui.img.del, math.huge)
	end,
})
