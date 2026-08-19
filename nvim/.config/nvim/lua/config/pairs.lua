local map = vim.keymap.set

local pairs_map = {
	["("] = ")",
	["["] = "]",
	["{"] = "}",
	["`"] = "`",
	["'"] = "'",
	['"'] = '"',
}

local code_ft = {
	lua = 1,
	python = 1,
	javascript = 1,
	typescript = 1,
	javascriptreact = 1,
	typescriptreact = 1,
	rust = 1,
	go = 1,
	c = 1,
	cpp = 1,
	java = 1,
	ruby = 1,
	sh = 1,
	bash = 1,
	zsh = 1,
	fish = 1,
	nix = 1,
	toml = 1,
	yaml = 1,
	json = 1,
}

local function in_code_context()
	local ft = vim.bo.filetype
	if ft ~= "markdown" then
		return code_ft[ft] ~= nil
	end
	-- markdown: only pair inside fenced code blocks
	local ok = pcall(require, "nvim-treesitter.parsers")
	if not ok then
		return false
	end
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local node = vim.treesitter.get_node({ pos = { row - 1, col } })
	while node do
		if node:type() == "code_fence_content" then
			return true
		end
		node = node:parent()
	end
	return false
end

local function cursor_in_string()
	local ok = pcall(require, "nvim-treesitter.parsers")
	if not ok then
		return false
	end
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local node = vim.treesitter.get_node({ pos = { row - 1, col } })
	if not node then
		return false
	end
	return node:type():find("string") ~= nil or node:type():find("template") ~= nil
end

for open, close in pairs(pairs_map) do
	if open ~= close then
		map("i", open, function()
			if not in_code_context() then
				return open
			end
			return open .. close .. "<left>"
		end, { expr = true })
	end

	map("i", close, function()
		if not in_code_context() then
			return close
		end

		local col = vim.fn.col(".")
		local line = vim.fn.getline(".")
		local before = line:sub(col - 1, col - 1)
		local after = line:sub(col, col)

		if after == close then
			return "<right>"
		end

		if open == close then
			if before:match("%w") or after:match("%w") then
				return open
			end
			if open == "`" and line:sub(col - 2, col - 1) == "``" then
				return "`"
			end
			if cursor_in_string() then
				return open
			end
			return open .. close .. "<left>"
		end

		return close
	end, { expr = true })
end

-- backspace: delete both chars when between a pair
map("i", "<BS>", function()
	if not in_code_context() then
		return "<BS>"
	end
	local col = vim.fn.col(".")
	local line = vim.fn.getline(".")
	local before = line:sub(col - 1, col - 1)
	local after = line:sub(col, col)
	for open, close in pairs(pairs_map) do
		if before == open and after == close then
			return "<BS><Del>"
		end
	end
	return "<BS>"
end, { expr = true })
