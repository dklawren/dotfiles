#!/usr/bin/env bash
# Run: bash tests/runner_test.sh
# The Lua goes in a file rather than through `-c "lua ..."`, which would expand
# $@ and $out inside the fake vitest before nvim ever saw them.
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/script.lua" <<'LUA'
local runner = require("config.runner")
local failures, checks = 0, 0
local function check(ok, msg)
	checks = checks + 1
	if not ok then
		failures = failures + 1
		print("FAIL: " .. msg)
	end
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. "/node_modules/.bin", "p")
vim.fn.writefile({ "{}" }, dir .. "/package.json")
vim.fn.writefile({ "{}" }, dir .. "/tsconfig.json")
dir = vim.uv.fs_realpath(dir)
local spec = dir .. "/a.test.ts"
vim.fn.writefile({
	"describe(\"suite\", () => {",
	"  it(\"adds up\", () => {",
	"    expect(1).toBe(2)",
	"  })",
	"})",
}, spec)
local fake = dir .. "/node_modules/.bin/vitest"
vim.fn.writefile({
	"#!/usr/bin/env bash",
	'echo "$@" > ' .. dir .. "/args",
	'sleep "${FAKE_VITEST_SLEEP:-0}"',
	'echo "RUN  v4.1.10 ' .. dir .. '"',
	'echo "{\\"testResults\\":[{\\"name\\":\\"' .. spec .. '\\",\\"assertionResults\\":[{\\"status\\":\\"failed\\",\\"fullName\\":\\"suite adds up\\",\\"failureMessages\\":[\\"AssertionError: boom\\\\n at ' .. spec .. ':3:15\\"]}]}]}" >&2',
	"exit 1",
}, fake)
vim.fn.system({ "chmod", "+x", fake })

vim.cmd("edit " .. vim.fn.fnameescape(spec))
vim.bo.filetype = "typescript"
vim.api.nvim_win_set_cursor(0, { 3, 6 })
runner.test("nearest")
vim.wait(5000, function()
	return #vim.fn.getqflist() > 0
end)

local qf = vim.fn.getqflist()
check(#qf == 1, "one failure in quickfix, got " .. #qf)
check(qf[1] and qf[1].lnum == 3 and qf[1].col == 15, "failure lands on the stack line")
local args = table.concat(vim.fn.readfile(dir .. "/args"), " ")
check(args:find("-t adds up", 1, true) ~= nil, "nearest passes the test title, got: " .. args)
check(#vim.diagnostic.get(vim.fn.bufnr(spec)) == 1, "failure is a diagnostic in the buffer")

vim.fn.delete(dir .. "/args")
runner.test_last()
vim.wait(5000, function()
	return vim.fn.filereadable(dir .. "/args") == 1
end)
check(vim.fn.filereadable(dir .. "/args") == 1, "last re-runs the previous command")

-- The quickfix window is where you land after a failing run, and pressing the
-- key again there has to be about the test file, not about the qf window.
vim.fn.delete(dir .. "/args")
vim.cmd("botright copen")
check(vim.bo.buftype == "quickfix", "the failing run opened the quickfix window")
runner.test("file")
vim.wait(5000, function()
	return vim.fn.filereadable(dir .. "/args") == 1
end)
check(vim.fn.filereadable(dir .. "/args") == 1, "a run from the quickfix window is about the test file")

-- The project check has to answer the same question from the same window.
local said = {}
vim.notify = function(msg)
	said[#said + 1] = tostring(msg)
end
runner.check()
vim.wait(300)
local check_msg = table.concat(said, " | ")
check(not check_msg:find("no project check", 1, true), "a project check from the quickfix window is about the file, got: " .. check_msg)
vim.cmd("cclose")
vim.api.nvim_set_current_buf(vim.fn.bufnr(spec))

-- A run still going is replaced, not raced: the first vitest is killed when
-- the second one starts, so two results cannot land on the same list.
vim.fn.writefile({ "#!/usr/bin/env bash", "sleep 30", "exit 1" }, fake)
vim.fn.system({ "chmod", "+x", fake })
local started = vim.uv.hrtime()
runner.test("file")
vim.wait(150)
runner.test("file")
vim.wait(3000)
check((vim.uv.hrtime() - started) / 1e9 < 10, "the second run replaced the first instead of queueing behind it")

-- A runner that refuses to start prints no report, and its own output is the
-- only account of why, so it goes to quickfix rather than a notification.
vim.fn.writefile({
	"#!/usr/bin/env bash",
	'echo "✘ [ERROR] No loader is configured for .md files" >&2',
	"echo 'no report here' >&2",
	"exit 1",
}, fake)
vim.cmd("cclose")
local told = nil
vim.notify = function(msg, level)
	if level == vim.log.levels.ERROR then
		told = tostring(msg)
	end
end
runner.test("file")
vim.wait(5000, function()
	return told ~= nil
end)
local lines = vim.fn.getqflist()
check(#lines > 0, "a run with no report puts its output in quickfix, got " .. #lines)
check(told and told:find("No loader is configured", 1, true) ~= nil, "the notification names the first line, got " .. tostring(told))

-- go prints its failures as a path relative to the working directory, and the
-- item has to land on that file, not on the package root joined with it.
local gomod = vim.fn.tempname()
vim.fn.mkdir(gomod .. "/bin", "p")
vim.fn.writefile({ "module example.com/x", "", "go 1.22" }, gomod .. "/go.mod")
vim.fn.writefile({ "package x" }, gomod .. "/sum_test.go")
vim.fn.writefile({
	"#!/usr/bin/env bash",
	'echo "--- FAIL: TestSum (0.00s)" >&2',
	'echo "    $PWD/sum_test.go:7: Sum(2,3) = -1, want 5" >&2',
	"exit 1",
}, gomod .. "/bin/go")
vim.uv.fs_chmod(gomod .. "/bin/go", tonumber("755", 8))
local path_before = vim.env.PATH
vim.env.PATH = gomod .. "/bin:" .. path_before
vim.cmd.edit(vim.fn.fnameescape(gomod .. "/sum_test.go"))
vim.bo.filetype = "go"
vim.fn.setqflist({})
vim.cmd("cclose")
runner.test("file")
vim.wait(8000, function()
	return #vim.fn.getqflist() > 0
end)
local go_items = vim.fn.getqflist()
check(#go_items == 1, "a go failure is one quickfix item, got " .. #go_items)
if go_items[1] then
	local name = vim.fn.bufname(go_items[1].bufnr)
	check(go_items[1].lnum == 7, "the go item is on the failing line, got " .. go_items[1].lnum)
	check(
		vim.fn.filereadable(vim.fn.fnamemodify(name, ":p")) == 1,
		"the go item points at a file that exists, got " .. name
	)
end
-- Every line the runner says names the tool and what it is doing. The start
-- line used to be the command line, an absolute path plus every flag, which is
-- unreadable at the one moment the message is there to say "it is going".
vim.fn.writefile({ "#!/usr/bin/env bash", 'echo \'{"testResults":[]}\' >&2', "exit 0" }, fake)
vim.fn.system({ "chmod", "+x", fake })
local told_again = {}
vim.notify = function(msg, level)
	told_again[#told_again + 1] = tostring(level or vim.log.levels.INFO) .. ":" .. tostring(msg)
end
vim.api.nvim_set_current_buf(vim.fn.bufnr(spec))
vim.api.nvim_win_set_cursor(0, { 3, 6 })
runner.test("nearest")
vim.wait(5000, function()
	for _, m in ipairs(told_again) do
		if m:match("passed in") then
			return true
		end
	end
	return false
end)
local function find(said, pat)
	for _, m in ipairs(said) do
		if m:match(pat) then
			return m
		end
	end
end
local start_line = find(told_again, "vitest · nearest test")
check(start_line ~= nil, "a run names the tool and the scope, got: " .. table.concat(told_again, " | "))
check(start_line and not start_line:find(dir, 1, true), "the command line is not the message, got: " .. tostring(start_line))
check(
	find(told_again, "^%d:vitest · passed in %d+%.%ds$") ~= nil,
	"a pass says how long it took, got: " .. table.concat(told_again, " | ")
)

-- The same shape for a project check, and one problem is not "problems".
local fake_tsc = dir .. "/node_modules/.bin/tsc"
vim.fn.writefile({ "#!/usr/bin/env bash", 'echo "a.test.ts(3,15): error TS2322: nope"', "exit 2" }, fake_tsc)
vim.fn.system({ "chmod", "+x", fake_tsc })
local told_check = {}
vim.notify = function(msg, level)
	told_check[#told_check + 1] = tostring(level or vim.log.levels.INFO) .. ":" .. tostring(msg)
end
vim.cmd("cclose")
runner.check()
vim.wait(5000, function()
	for _, m in ipairs(told_check) do
		if m:match("problem") then
			return true
		end
	end
	return false
end)
check(find(told_check, "tsc · checking") ~= nil, "a check names the tool and what it is doing, got: " .. table.concat(told_check, " | "))
check(find(told_check, "^3:tsc · 1 problem$") ~= nil, "a check counts problems in words, got: " .. table.concat(told_check, " | "))
vim.cmd("cclose")

-- The start line is said when the job starts, not when it finishes: that is the
-- whole reason it exists. A run that only notifies at the end looks identical
-- afterwards, so the fake sleeps and the check looks mid-run.
vim.fn.mkdir(dir .. "/node_modules/.bin", "p")
local slow = dir .. "/node_modules/.bin/vitest"
vim.fn.writefile({
	"#!/usr/bin/env bash",
	"sleep 0.6",
	'echo \'{"numPassedTests":1,"numFailedTests":0,"testResults":[]}\' >&2',
	"exit 0",
}, slow)
vim.fn.system({ "chmod", "+x", slow })
local going = {}
vim.notify = function(msg, _level, opts)
	if opts and opts.title == "tests" then
		going[#going + 1] = tostring(msg)
	end
end
vim.api.nvim_set_current_buf(vim.fn.bufnr(spec))
vim.api.nvim_win_set_cursor(0, { 3, 6 })
local tf = vim.fn.maparg("<leader>tf", "n", false, true)
check(type(tf.callback) == "function", "<leader>tf is a mapping that runs the tests")
tf.callback()
check(vim.wait(400, function()
	return #going > 0
end, 10), "the start line is said while the run is going, not after it")
vim.wait(5000, function()
	return going[#going]:match("passed in") ~= nil
end)
check(going[1] == "vitest · this file", "the first line names the tool and the scope, got " .. tostring(going[1]))
check(
	going[#going]:match("^vitest · passed in %d+%.%ds$") ~= nil,
	"the last line says the run passed and how long it took, got " .. tostring(going[#going])
)

vim.env.PATH = path_before

print(("runner checks=%d failures=%d"):format(checks, failures))
if failures > 0 then
	error("runner test failed")
end
print("runner tests passed")
LUA

run_lua "vim.cmd('luafile $TMP/script.lua')"
