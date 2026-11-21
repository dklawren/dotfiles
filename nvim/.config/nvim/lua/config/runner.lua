local NS = vim.api.nvim_create_namespace("runner")
local TEST_CALLEES = { it = true, test = true }

local M = {}

local target_buf = require("config.buffer").target

local last

local function notify(msg, level, title)
	vim.notify(msg, level or vim.log.levels.INFO, { title = title or "runner" })
end

---A run that takes minutes reads worse as "123.456s", and one that takes half a
---second reads worse as "0s".
local function seconds(t)
	return t < 10 and ("%.1fs"):format(t) or ("%.0fs"):format(t)
end

local function plural(n, word)
	return ("%d %s"):format(n, n == 1 and word or word .. "s")
end

---The project's own copy of a tool when it has one, as `npm run` would pick.
local function local_bin(root, cmd)
	local bin = root .. "/node_modules/.bin/" .. cmd[1]
	if vim.fn.executable(bin) == 1 then
		return vim.list_extend({ bin }, cmd, 2)
	end
	return cmd
end

local current

local function spawn(cmd, cwd, start, title, on_exit)
	if vim.fn.executable(cmd[1]) == 0 then
		notify(vim.fs.basename(cmd[1]) .. " is not on PATH", vim.log.levels.ERROR, title)
		return
	end
	if current then
		pcall(function()
			current:kill("sigterm")
		end)
	end
	notify(start, nil, title)
	local started = vim.uv.hrtime()
	local job
	job = vim.system(
		cmd,
		{ cwd = cwd, text = true },
		vim.schedule_wrap(function(result)
			if current == job then
				current = nil
			end
			on_exit(result, (vim.uv.hrtime() - started) / 1e9)
		end)
	)
	current = job
end

local function cursor_node(buf)
	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok or not parser then
		return nil
	end
	parser:parse()
	return vim.treesitter.get_node({ bufnr = buf })
end

local function nearest_js_title(buf)
	local node = cursor_node(buf)
	while node do
		if node:type() == "call_expression" then
			local callee = node:field("function")[1]
			local base = callee and (callee:type() == "member_expression" and callee:field("object")[1] or callee)
			local args = node:field("arguments")[1]
			local first = args and args:named_child(0)
			if base and TEST_CALLEES[vim.treesitter.get_node_text(base, buf)] and first and first:type() == "string" then
				return (vim.treesitter.get_node_text(first, buf):gsub("^[\"'`]", ""):gsub("[\"'`]$", ""))
			end
		end
		node = node:parent()
	end
end

local function nearest_go_name(buf)
	local node = cursor_node(buf)
	while node do
		if node:type() == "function_declaration" then
			local name = vim.treesitter.get_node_text(node:field("name")[1], buf)
			return name:match("^Test") and name or nil
		end
		node = node:parent()
	end
end

local function show_failures(items)
	vim.diagnostic.reset(NS)
	local by_buf = {}
	for _, item in ipairs(items) do
		local buf = vim.fn.bufadd(item.filename)
		by_buf[buf] = by_buf[buf] or {}
		table.insert(by_buf[buf], {
			lnum = item.lnum - 1,
			col = math.max((item.col or 1) - 1, 0),
			message = item.text,
			severity = vim.diagnostic.severity.ERROR,
			source = "test",
		})
	end
	for buf, diagnostics in pairs(by_buf) do
		vim.diagnostic.set(NS, buf, diagnostics)
	end
	vim.fn.setqflist({}, " ", { title = "tests", items = items })
	if #items > 0 then
		vim.cmd("botright copen")
	else
		vim.cmd("cclose")
	end
end

---Output that no parser could read, put in quickfix so the run still says why.
---@param title string
---@param text string
---@param efm string
---@param open boolean
---@return string[] the lines put in the list
local function raw_report(title, text, efm, open)
	local lines = vim.split(text, "\n", { trimempty = true })
	vim.fn.setqflist({}, " ", { title = title, lines = lines, efm = efm })
	if open then
		vim.cmd("botright copen")
	end
	return lines
end

local function vitest_failures(result)
	-- vitest 4 ignores --outputFile and prints the report on stderr, with log lines
	-- around it, so the outermost object in either stream is what gets decoded.
	local text = result.stdout .. "\n" .. result.stderr
	local first = text:find("{", 1, true)
	local stop = text:match(".*()%}")
	if not first or not stop or stop < first then
		return nil
	end
	local ok, report = pcall(vim.json.decode, text:sub(first, stop))
	if not ok then
		return nil
	end
	local items = {}
	for _, file in ipairs(report.testResults or {}) do
		for _, test in ipairs(file.assertionResults or {}) do
			if test.status == "failed" then
				local message = (test.failureMessages or {})[1] or test.fullName
				local lnum, col = message:match(vim.pesc(file.name) .. ":(%d+):(%d+)")
				table.insert(items, {
					filename = file.name,
					lnum = tonumber(lnum) or (test.location and test.location.line) or 1,
					col = tonumber(col) or 1,
					text = test.fullName .. ": " .. vim.split(message, "\n")[1],
				})
			end
		end
	end
	return items
end

local function run_vitest(root, file, title)
	local cmd = local_bin(root, { "vitest" })
	if cmd[1] == "vitest" then
		cmd = { "npx", "vitest" }
	end
	vim.list_extend(cmd, { "run", "--reporter=json", file })
	if title then
		vim.list_extend(cmd, { "-t", title })
	end
	return {
		cmd = cmd,
		cwd = root,
		tool = "vitest",
		scope = title and "nearest test" or "this file",
		done = function(result)
			return vitest_failures(result), result
		end,
	}
end

local function run_go(root, dir, name)
	local cmd = { "go", "test", dir }
	if name then
		vim.list_extend(cmd, { "-run", "^" .. name .. "$" })
	end
	return {
		cmd = cmd,
		cwd = root,
		tool = "go test",
		scope = name and "nearest test" or "this file",
		done = function(result)
			local efm = "%*[ ]%f:%l: %m,%f:%l:%c: %m"
			local parsed = vim.fn.getqflist({ lines = vim.split(result.stdout .. result.stderr, "\n"), efm = efm })
			local items = {}
			for _, item in ipairs(parsed.items) do
				if item.valid == 1 then
					-- go prints a path relative to its working directory, but the parse can
					-- resolve it to an absolute one, and joinpath appends that.
					local name = vim.fn.bufname(item.bufnr)
					local path = name:sub(1, 1) == "/" and name or vim.fs.joinpath(root, name)
					table.insert(items, { filename = path, lnum = item.lnum, col = item.col, text = item.text })
				end
			end
			return items, result
		end,
	}
end

local function plan(scope)
	local buf = target_buf()
	local path = vim.api.nvim_buf_get_name(buf)
	local ft = vim.bo[buf].filetype
	if ft:match("^typescript") or ft:match("^javascript") then
		local root = vim.fs.root(path, "package.json")
		if not root then
			return nil, "no package.json above this file"
		end
		return run_vitest(root, path, scope == "nearest" and nearest_js_title(buf) or nil)
	elseif ft == "go" then
		local root = vim.fs.root(path, "go.mod")
		if not root then
			return nil, "no go.mod above this file"
		end
		local dir = "./" .. vim.fs.relpath(root, vim.fs.dirname(path))
		return run_go(root, dir, scope == "nearest" and nearest_go_name(buf) or nil)
	end
	return nil, "no test runner for filetype " .. ft
end

local function execute(spec)
	last = spec
	local tool = spec.tool or "tests"
	spawn(spec.cmd, spec.cwd, tool .. " · " .. (spec.scope or "all"), "tests", function(result, took)
		local items = spec.done(result)
		if not items then
			-- No report at all: the runner itself refused to start, and its output is
			-- the only account of why.
			local lines = raw_report("tests", result.stdout .. result.stderr, "%m", true)
			notify(("%s · %s (exited %d)"):format(tool, lines[1] or "no report", result.code), vim.log.levels.ERROR, "tests")
			return
		end
		show_failures(items)
		if #items > 0 then
			notify(("%s · %d failing in %s"):format(tool, #items, seconds(took)), vim.log.levels.WARN, "tests")
		elseif result.code == 0 then
			notify(("%s · passed in %s"):format(tool, seconds(took)), nil, "tests")
		else
			-- Nothing parsed from a failed run: a suite that did not compile or a
			-- crash, and its output is the only report there is.
			raw_report("tests", result.stdout .. result.stderr, "%m", true)
			notify(("%s · exited %d, no failure parsed"):format(tool, result.code), vim.log.levels.ERROR, "tests")
		end
	end)
end

function M.test(scope)
	local spec, err = plan(scope)
	if not spec then
		notify(err, vim.log.levels.WARN)
		return
	end
	execute(spec)
end

function M.test_last()
	if not last then
		notify("nothing ran yet", vim.log.levels.WARN)
		return
	end
	execute(last)
end

local CHECKS = {
	typescript = {
		root = "tsconfig.json",
		cmd = { "tsc", "--noEmit", "--pretty", "false" },
		efm = "%f(%l\\,%c): %trror TS%n: %m",
	},
	go = { root = "go.mod", cmd = { "go", "vet", "./..." }, tool = "go vet", efm = "%f:%l:%c: %m,%f:%l: %m" },
	rust = {
		root = "Cargo.toml",
		cmd = { "cargo", "check", "--message-format", "short" },
		efm = "%f:%l:%c: %t%*[^:]: %m",
	},
}
CHECKS.typescriptreact = CHECKS.typescript

function M.check()
	local buf = target_buf()
	local path = vim.api.nvim_buf_get_name(buf)
	local check = CHECKS[vim.bo[buf].filetype]
	local root = check and vim.fs.root(path, check.root)
	if not root then
		notify("no project check for filetype " .. vim.bo[buf].filetype, vim.log.levels.WARN)
		return
	end
	local cmd = local_bin(root, check.cmd)
	local tool = check.tool or check.cmd[1]
	spawn(cmd, root, tool .. " · checking", "check", function(result, took)
		raw_report(tool, result.stdout .. result.stderr, check.efm, false)
		local found = #vim.tbl_filter(function(item)
			return item.valid == 1
		end, vim.fn.getqflist())
		if found > 0 then
			vim.cmd("botright copen")
			notify(("%s · %s"):format(tool, plural(found, "problem")), vim.log.levels.WARN, "check")
		elseif result.code == 0 then
			vim.cmd("cclose")
			notify(("%s · clean in %s"):format(tool, seconds(took)), nil, "check")
		else
			vim.cmd("botright copen")
			notify(("%s · exited %d, no problem parsed"):format(tool, result.code), vim.log.levels.ERROR, "check")
		end
	end)
end

vim.keymap.set("n", "<leader>tn", function()
	M.test("nearest")
end, { desc = "Test Nearest" })
vim.keymap.set("n", "<leader>tf", function()
	M.test("file")
end, { desc = "Test File" })
vim.keymap.set("n", "<leader>tl", M.test_last, { desc = "Test Last" })
vim.keymap.set("n", "<leader>tc", M.check, { desc = "Project Check" })
vim.keymap.set("n", "<leader>tx", function()
	vim.diagnostic.reset(NS)
end, { desc = "Clear Test Failures" })

return M
