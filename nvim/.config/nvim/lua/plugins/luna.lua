vim.pack.add({
	"https://github.com/WTFox/luna.nvim",
})

require("luna").setup({
	transparent = true,
	accent = 1.0, -- 0-1, blends syntax accents toward grey_light; 1 = full color
	plugins = {
		all = true, -- enable every plugin integration unconditionally
		auto = true, -- when plugins.all is false, autodetect via lazy.nvim
	},
	on_colors = function(colors) end,
	on_highlights = function(highlights, colors) end,
})
