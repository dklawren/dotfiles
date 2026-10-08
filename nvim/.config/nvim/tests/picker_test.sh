#!/usr/bin/env bash
# Run: bash tests/picker_test.sh
# Exercises lua/config/picker.lua: the label filter, and a real picker being
# typed into. The keystrokes go through tests/pty_drive.py into a real pty:
# insert mode and buffer-local mappings need a terminal, and nvim does not read
# keys while a Lua chunk is running, so the checks are timer callbacks that
# return at once and let the main loop take the keys.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# step name <TAB> the keys to send, hex so an escape can be written.
printf 'A.open\t\nA.opened\t\nA.b\t62\nA.ba\t78\nA.back\t7f\nA.clear\t7f\nA.gam\t67616d\nA.z\t7a\nA.esc_clears\t1b\nA.esc_closes\t1b\nB.open\t\nB.confirm\t620d\nC.open\t\nC.run\t18\nD.open\t\nD.pick\t6a0d\nE.open\t\nF.open\t\nF.one\t6f6e65\nF.dismiss\t1b\nG.open\t\nG.type\t62657461\nG.pick\t0d\nH.open\t\nH.confg\t636f6e6667\nH.dismiss\t1b\nI.open\t\nI.confg\t636f6e6667\nI.dismiss\t1b\nI.typed\t636f6e6669675069636b6572\nI.hits\t\nI.close\t1b\nJ.open\t\nJ.up\t1b5b41\nJ.down\t1b5b42\nJ.one\t6f6e65\nJ.clear\t7f7f7f\nJ.pick\t0d\nK.open\t\nK.word\t6c75612f636f6e6669672f73657373696f6e2e6c7561\nK.grow\t6162636465666768696a6b6c\nK.shrink\t7f7f7f7f7f7f7f7f7f7f7f7f\nK.back\t\nL.open\t\nL.part\t6c75612f636f6e\nL.shared\t09\nL.word\t09\nL.whole\t09\nL.other\t09\nL.last\t09\nL.wrap\t09\nL.close\t1b\nM.open\t\nM.part\t6c75612f63\nM.tab1\t09\nM.typed\t73\nM.tab2\t09\nM.tab3\t09\nM.close\t1b\nO.open\t\nO.numbered\t\nO.close\t1b\nN.open\t\nN.part\t6c75612f636f6e6669672f706169\nN.tab1\t09\nN.tab2\t09\nN.tab3\t09\nN.tab4\t09\nN.tab5\t09\nN.close\t1b\nP.open\t\nP.type_a\t61\nP.painted\t\nP.back\t7f\nP.cleared\t\nP.close\t1b\nR.open\t\nR.pick\t0d\nS.open\t\nS.rows\t\nS.close\t1b\ndone\t\n' >"$tmp/keys"

cat >"$tmp/probe.lua" <<'LUA'
local P = require("config.picker")

local checks, failures = 0, {}
local function check(name, ok, detail)
	checks = checks + 1
	if not ok then
		table.insert(failures, name .. (detail and (": " .. tostring(detail)) or ""))
	end
end
local function eq(name, got, want)
	check(name, vim.deep_equal(got, want), ("got %s, want %s"):format(vim.inspect(got), vim.inspect(want)))
end

-- 1. the filter itself
eq("an empty needle keeps everything", P.matches("", "anything at all"), true)
eq("and so does whitespace", P.matches("   ", "anything"), true)
eq("case does not matter", P.matches("ALPHA", "alpha/one.lua"), true)
eq("a plain word is a substring test", P.matches("alp", "alpha/one.lua"), true)
eq("a word that is not there is not", P.matches("beta", "alpha/one.lua"), false)
eq("every word has to be there", P.matches("alp one", "alpha/one.lua"), true)
eq("in any order", P.matches("one alp", "alpha/one.lua"), true)
eq("and all of them", P.matches("alp two", "alpha/one.lua"), false)
eq("an empty label matches only an empty needle", P.matches("x", ""), false)
eq("but is kept by nothing", P.matches("", ""), true)
eq("a needle is trimmed before it is split", P.matches("  alp  ", "alpha"), true)

-- 2. which row answers best
eq("a whole word beats one inside a longer word", P.score("one", "one") > P.score("one", "someone"), true)
eq("and it beats one that is only part of a file name", P.score("one", "one/x.lua") > P.score("one", "x/one"), true)
eq("an early match beats a late one", P.score("alp", "alpha") > P.score("alp", "gamma/alpha"), true)
eq("a short label beats a long one", P.score("one", "one") > P.score("one", "one and a lot more besides"), true)
eq("a label that does not answer has no score", P.score("one", "two"), nil)
eq("two whole words beat one", P.score("a b", "a b") > P.score("a b", "a bc"), true)
eq("and an empty needle scores everything the same", P.score("", "aaa") == P.score("", "b"), true)

-- 2b. a needle that names a path, found with the punctuation dropped
eq("a path in the needle finds the label that has it", P.score("config/picker", "lua/config/picker.lua") ~= nil, true)
eq("and does so with the separators either way round", P.score("configpicker", "lua/config/picker.lua") ~= nil, true)
eq("a word found as typed beats one found loosely", P.score("picker", "lua/config/picker.lua") > P.score("configpicker", "lua/config/picker.lua"), true)
eq("the loose answer still has to be in there", P.score("config/nope", "lua/config/picker.lua"), nil)
eq("and a needle of nothing but punctuation is not a needle", P.score("--", "lua/config/picker.lua"), nil)
eq("loose matching finds a run of words the label has apart", P.visible_indices({ "alpha/beta/gamma.lua", "nothing here" }, "betagamma"), { 1 })

-- 2a. each tier paints in its own group, so the screen says how well a row
-- answered
eq("there is one group per tier", vim.fn.sort(vim.tbl_keys(P.match_groups)), { "literal", "loose", "scattered" })
eq("and no two tiers share one", vim.tbl_count(P.match_groups), 3)
P.ensure_match_groups()
local resolved = {}
for tier, group in pairs(P.match_groups) do
	eq(("%s has a group"):format(tier), vim.fn.hlexists(group), 1)
	resolved[tier] = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), "name")
end
eq("a literal match resolves to a search hit", resolved.literal, "Search")
eq("a loose one to something weaker", resolved.loose ~= resolved.literal, true)
eq("and a scattered one weaker still", resolved.scattered ~= resolved.loose, true)
check("a tier with no group would fall back to a plain hit", P.match_groups.literal ~= "Search", P.match_groups.literal)

-- 2c. the last resort: an abbreviation, or a word with a letter wrong in it
eq("a window is the span of the tightest run of characters", P.window("cfg", "config"), 6)
eq("in a longer label it is measured inside that", P.window("abc", "xxabcyy"), 3)
eq("a needle out of order has no window", P.window("ba", "abc"), nil)
eq("and neither does one with a letter missing", P.window("sesssion", "session"), nil)
eq("an empty needle has no window", P.window("", "abc"), nil)
local span, from, to = P.window("cfg", "xxconfigxx")
eq("a window says where it is, not only how wide", { span, from, to }, { 6, 3, 8 })

-- 2d. where each word matched, which is what the highlight paints
eq("a word found as typed is marked where it is", P.match_words("session", "lua/config/session.lua"), {
	{ from = 11, to = 17, tier = "literal" },
})
eq("and one inside a longer word is still marked", P.match_words("one", "someone"), { { from = 4, to = 6, tier = "literal" } })
eq("a loose answer covers the separators it crossed", P.match_words("config/picker", "lua_config_picker.lua"), {
	{ from = 4, to = 16, tier = "loose" },
})
eq("and the same needle in the same label is literal when it is there", P.match_words("config/picker", "lua/config/picker.lua"), {
	{ from = 4, to = 16, tier = "literal" },
})
eq("a scattered answer covers what it skipped too", P.match_words("confg", "lua/config/session.lua"), {
	{ from = 4, to = 9, tier = "scattered" },
})
eq("every word of a multi word needle is marked", P.match_words("readme md", "README.md"), {
	{ from = 0, to = 5, tier = "literal" },
	{ from = 7, to = 8, tier = "literal" },
})
eq("a word that is nowhere marks nothing at all", P.match_words("zz", "lua/config/session.lua"), nil)
eq("and an empty needle has no marks", P.match_words("", "lua/config/session.lua"), {})
eq("a label longer than the needle is not truncated by the needle", P.match_words("e", "some/e/where/e"), {
	{ from = 3, to = 3, tier = "literal" },
})

-- 2e. the parts of a row no word answered for
eq("a match in the middle leaves the ends", P.unmatched("lua/config/session.lua", {
	{ from = 11, to = 17 },
}), {
	{ from = 0, to = 10 },
	{ from = 18, to = 21 },
})
eq("a match at the start leaves the tail", P.unmatched("README.md", { { from = 0, to = 5 } }), {
	{ from = 6, to = 8 },
})
eq("a match at the end leaves the head", P.unmatched("README.md", { { from = 7, to = 8 } }), {
	{ from = 0, to = 6 },
})
eq("a row the needle covers whole has no rest", P.unmatched("README", { { from = 0, to = 5 } }), {})
eq("no match at all is all rest", P.unmatched("abc", {}), { { from = 0, to = 2 } })
eq("two matches leave the middle between them", P.unmatched("one.lua", {
	{ from = 0, to = 2 },
	{ from = 4, to = 6 },
}), {
	{ from = 3, to = 3 },
})
eq("the order the hits arrive in does not matter", P.unmatched("one.lua", {
	{ from = 4, to = 6 },
	{ from = 0, to = 2 },
}), P.unmatched("one.lua", {
	{ from = 0, to = 2 },
	{ from = 4, to = 6 },
}))
eq("the hits are not changed by asking for the rest", P.unmatched("one.lua", {
	{ from = 0, to = 2 },
	{ from = 4, to = 6 },
}), { { from = 3, to = 3 } })
eq("the rest group is one name of its own", P.rest_group, "PickerMatchRest")
eq("and not one of the tier groups", vim.tbl_contains(vim.tbl_values(P.match_groups), P.rest_group), false)

-- 2f. what one more keystroke of a needle would say
eq("an empty needle is left alone", P.complete("", { "alpha", "beta" }), "")
eq("a needle nothing shares is left alone", P.complete("x", { "alpha" }), "x")
eq("it becomes the prefix every row shares", P.complete("a", { "alpha", "beta" }), "alpha")
eq("a needle already there is not shortened", P.complete("al", { "alpha", "beta" }), "alpha")
eq("a needle that is already the whole prefix finishes the word instead", P.complete("config/", { "config/picker.lua", "config/session.lua" }), "config/picker")
eq("a prefix the rows really do share is taken whole", P.complete("lua/con", { "lua/config/picker.lua", "lua/config/session.lua" }), "lua/config/")
eq("with nothing more shared, the word is finished", P.complete("one.", { "one.lua", "one.md" }), "one.lua")
eq("with one row, the word the needle is inside comes first", P.complete("LU", { "lua/config.lua" }), "lua")
eq("the row's own spelling is kept", P.completions("LUA/CON", { "Lua/Config/picker.lua", "Lua/Config/session.lua" })[1], "Lua/Config/")
eq("a needle nothing starts with is left alone", P.complete("zed", { "alpha", "beta" }), "zed")
eq("a whole row already typed changes nothing", P.complete("one.lua", { "one.lua" }), "one.lua")
eq("one row left means Tab takes all of it", P.complete("lua/config/picker", { "lua/config/picker.lua" }), "lua/config/picker.lua")
eq("the answer is always a prefix of a row that was left", P.complete("a", { "Alpha", "alpha/two" }), "Alpha")

-- 2g. every way the word could be finished, which is what repeated Tab walks
local shared = { "lua/config/picker.lua", "lua/config/session.lua", "README.md" }
eq("the shared prefix comes first, then each row is walked down", P.completions("lua/con", shared), {
	"lua/config/",
	"lua/config/picker",
	"lua/config/picker.lua",
	"lua/config/session",
	"lua/config/session.lua",
})
eq("a word that stops short of the shared prefix is not offered", vim.tbl_contains(P.completions("lua/con", shared), "lua/config"), false)
eq("a word is offered for each row that continues it", P.completions("config/", {
	"config/picker.lua",
	"config/session.lua",
}), {
	"config/picker",
	"config/picker.lua",
	"config/session",
	"config/session.lua",
})
eq("a path can be walked a directory at a time", P.completions("lua/config/pa", {
	"lua/config/painter/lua/init.lua",
	"lua/config/painter.lua",
}), {
	"lua/config/painter",
	"lua/config/painter/lua",
	"lua/config/painter/lua/init",
	"lua/config/painter/lua/init.lua",
	"lua/config/painter.lua",
})
eq("and every step is a prefix of the row it came from", (function()
	local row = "lua/config/painter/lua/init.lua"
	for _, step in ipairs(P.completions("lua/config/pa", { row })) do
		if row:sub(1, #step) ~= step then
			return false
		end
	end
	return true
end)(), true)
eq("one row means the whole of it and nothing else", P.completions("one.lua", { "one.lua" }), { "one.lua" })
eq("an empty needle completes nothing", P.completions("", { "alpha" }), {})
eq("and one no row starts with completes nothing", P.completions("x", { "alpha" }), {})
eq("the completions are in the order the rows were given", P.completions("c", { "c/beta", "c/alpha" }), {
	"c/",
	"c/beta",
	"c/alpha",
})
eq("and the shared prefix comes first even when it is the same for all", P.completions("c", { "c/beta", "c/alpha" })[1], "c/")
eq("an abbreviation finds the word it abbreviates", P.score("cfg", "lua/config/session.lua") ~= nil, true)
eq("a letter transposed still finds it", P.score("confg", "lua/config/session.lua") ~= nil, true)
eq("and a letter dropped still finds it", P.score("cofig", "lua/config/session.lua") ~= nil, true)
eq("a scattered needle is not an answer", P.score("abc", "a/x/x/x/x/x/x/x/x/b/c.lua"), nil)
eq("a letter dropped out of a word still finds it", P.score("ba", "beta") ~= nil, true)
eq("one character of it is enough to refuse", P.score("zz", "lua/config/session.lua"), nil)
eq("a found-as-typed word beats a scattered one", P.score("config", "lua/config/session.lua") > P.score("cfg", "lua/config/session.lua"), true)
eq("a scattered word beats one found only with the punctuation dropped", P.score("cfg", "lua/config/picker.lua") > P.score("configpicker", "lua/config/picker.lua"), true)
eq("a whole word beats a loose one, still", P.score("picker", "lua/config/picker.lua") > P.score("configpicker", "lua/config/picker.lua"), true)
eq("a tighter window answers better than a loose one", P.score("cfg", "lua/config/session.lua") > P.score("cfg", "lua/configure/generated/session/graphics/framework.lua"), true)
eq("so the closest answer comes first", P.visible_indices({ "lua/configure/generated/session/graphics/framework.lua", "lua/config/session.lua" }, "cfg"), { 2, 1 })
eq("and a label with none of the letters is left out", P.visible_indices({ "lua/config/session.lua", "lua/plugins/yanky.lua" }, "cfg"), { 1 })

-- 3. which rows survive, and in what order
local labels = { "alpha/one.lua", "beta/two.lua", "alpha/three.lua", "gamma" }
eq("nothing typed keeps the order given", P.visible_indices(labels, ""), { 1, 2, 3, 4 })
eq("one match keeps its place", P.visible_indices(labels, "beta"), { 2 })
eq("no match is an empty list", P.visible_indices(labels, "zzz"), {})
eq("a tie keeps the order the caller gave", P.visible_indices({ "b a", "a b" }, "a b"), { 1, 2 })
eq("a whole word comes before a row that only contains it", P.visible_indices({ "gamma/one.lua", "one" }, "one"), { 2, 1 })
eq("and a row that merely contains the word comes last", P.visible_indices({ "someone", "one" }, "one"), { 2, 1 })
eq("ranking is by answer, not by length of needle", P.visible_indices({ "one two", "one" }, "one"), { 2, 1 })

-- 4. a real picker, typed into
local items = { { name = "alpha" }, { name = "beta" }, { name = "gamma" } }
local confirmed, run = nil, nil
local function open(opts)
	P.open(items, vim.tbl_extend("force", {
		title = "probe",
		skip_single = false,
		format = function(item)
			return item.name
		end,
		preview = function(item, ctx)
			ctx.set_lines({ "preview of " .. (item and item.name or "nothing") }, "qf")
		end,
		on_confirm = function(item)
			confirmed = item
		end,
	}, opts or {}))
end

--- The float windows still on screen, so a check can say the picker left none
--- behind without having to guess which of the handles it tracked are live.
local function floats()
	local out = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative ~= "" then
			out[#out + 1] = win
		end
	end
	return out
end

local function visible_names()
	local out = {}
	for _, item in ipairs(P.visible().items) do
		out[#out + 1] = item.name
	end
	return out
end

--- The marks the picker painted on its list buffer, as one string per mark:
--- line, from, to, group. The filter checks assert the spans the code worked
--- out, which come back through visible().highlights, and nothing above says
--- those spans reached the buffer. Reading them off is the only thing that does,
--- and it is what a migration off the deprecated nvim_buf_add_highlight could
--- get wrong while every other check stayed green.
local function painted()
	local shown = P.visible()
	local out = {}
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(shown.buf, P.ns, 0, -1, { details = true })) do
		out[#out + 1] = ("%d %d %s %s"):format(m[2], m[3], tostring(m[4].end_col), tostring(m[4].hl_group))
	end
	return out
end

--- The marks a row should be carrying, from the spans the picker computed for
--- it: what matched, in the tier's own group, and what did not, in the rest
--- group. Ordered by column, which is the order they come back in.
local function wanted_for(row, label, hits)
	local want = {}
	for _, hit in ipairs(hits) do
		want[#want + 1] = ("%d %d %s %s"):format(row - 1, hit.from, hit.to + 1, P.match_groups[hit.tier] or "Search")
	end
	for _, gap in ipairs(P.unmatched(label, hits)) do
		want[#want + 1] = ("%d %d %s %s"):format(row - 1, gap.from, gap.to + 1, P.rest_group)
	end
	table.sort(want)
	return want
end

-- Which item the cursor is on, found through the list buffer the picker is
-- showing, so a check does not have to guess which window is which.
local function selected_row()
	local buf = P.visible().buf
	if not buf then
		return nil
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			return vim.api.nvim_win_get_cursor(win)[1]
		end
	end
	return nil
end

local function selected_name()
	local row = selected_row()
	return row and (P.visible().items[row] or {}).name or nil
end

-- One mark, described the way the checks want it: row, start, end, group. An
-- index past the end gives a row that cannot be anything, so a check written
-- against an older build fails on the number rather than on a nil index.
local function mark_at(marks, i)
	local mark = marks[i]
	if not mark then
		return { row = -1, from = -1, to = -1, group = "(no mark)" }
	end
	return { row = mark[2], from = mark[3], to = mark[4].end_col, group = mark[4].hl_group }
end

-- The count painted at the right of the filter line, or nil when there is none.
local function filter_status()
	local marks = vim.api.nvim_buf_get_extmarks(P.visible().filter_buf or 0, P.ns, 0, -1, { details = true })
	if #marks == 0 then
		return nil
	end
	return marks[1][4].virt_text[1][1]
end

-- The count, where it was drawn, and how wide the line it sits on is. The
-- window, not a constant, because a test that hard-codes the width breaks the
-- moment the terminal is a different size.
local function filter_count()
	local marks = vim.api.nvim_buf_get_extmarks(P.visible().filter_buf or 0, P.ns, 0, -1, { details = true })
	if #marks == 0 then
		return nil
	end
	local width = 0
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == P.visible().filter_buf then
			width = vim.api.nvim_win_get_width(win)
		end
	end
	return { text = marks[1][4].virt_text[1][1], col = marks[1][4].virt_text_win_col, width = width }
end

-- The line the filter buffer is holding, which is what the count has to dodge.
local function needle()
	return vim.api.nvim_buf_get_lines(P.visible().filter_buf or 0, 0, 1, false)[1] or ""
end

local wins = 0
local line_width = 0

-- For the diagnostics picker below: where this file lives, and the buffers
-- the two problems are in.
local probe_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local problem_files = {}

open({ filter = true })

local steps = {
	{ name = "A.open" },
	{
		name = "A.opened",
		check = function()
			eq("the picker opens on everything", visible_names(), { "alpha", "beta", "gamma" })
			eq("with an empty needle", P.visible().needle, "")
			eq("and all of the rows counted", { P.visible().count, P.visible().total }, { 3, 3 })
			eq("nothing has been ruled out yet", P.visible().no_match, false)
			eq("the filter line says everything is still there", filter_status(), "all 3")
			wins = #vim.api.nvim_list_wins()
			-- A caller that refreshes the picker on a timer needs to be able to
			-- ask whether the user is still looking at it, or it will put a
			-- window back in front of someone who has closed it. There was no
			-- way to ask, which is why the one caller that refreshes re-listed
			-- on a fixed 300ms and hoped.
			eq("and it can be asked whether it is open", P.is_open(), true)
		end,
	},
	{ name = "A.b", check = function()
		eq("one letter narrows the list", visible_names(), { "beta" })
		eq("and the needle is what was typed", P.visible().needle, "b")
		eq("the filter line says how much is left", filter_status(), "1 of 3")
	end },
	{ name = "A.ba", check = function()
		eq("a needle no row can answer empties it", visible_names(), {})
		eq("and the picker says so", P.visible().no_match, true)
		eq("saying what it was looking for", vim.api.nvim_buf_get_lines(P.visible().buf, 0, 1, false), { "nothing matches bx" })
		eq("the count says the same thing", filter_status(), "0 of 3")
		eq("and the whole list is still counted", { P.visible().count, P.visible().total }, { 0, 3 })
		eq("so there is nothing to confirm", vim.tbl_isempty(P.visible().items), true)
	end },
	{ name = "A.back", check = function()
		eq("backspace puts the row back", visible_names(), { "beta" })
	end },
	{ name = "A.clear", check = function()
		eq("clearing the needle brings everything back", visible_names(), { "alpha", "beta", "gamma" })
		eq("and the count says all of it is back", filter_status(), "all 3")
		eq("with nothing ruled out", P.visible().no_match, false)
		eq("and the notice gone with them", #vim.api.nvim_buf_get_lines(P.visible().buf, 0, -1, false), 3)
	end },
	{ name = "A.gam", check = function()
		eq("more letters narrow again", visible_names(), { "gamma" })
	end },
	{ name = "A.z", check = function()
		eq("a word no row has empties it", visible_names(), {})
		eq("and the notice names that word instead", vim.api.nvim_buf_get_lines(P.visible().buf, 0, 1, false), { "nothing matches gamz" })
	end },
	{ name = "A.esc_clears", check = function()
		eq("the first Escape clears the needle", visible_names(), { "alpha", "beta", "gamma" })
		eq("and leaves the picker open", #vim.api.nvim_list_wins(), wins)
	end },
	{ name = "A.esc_closes", check = function()
		eq("the second Escape closes it", P.visible().count, 0)
		eq("and nothing is left on screen", #vim.api.nvim_list_wins(), wins - 3)
		eq("and it says so, so a refresh on a timer can stand down", P.is_open(), false)
	end },

	-- 4. Enter takes the row that survived the needle
	{ name = "B.open", open = function()
		confirmed = nil
		open({ filter = true })
	end },
	{ name = "B.confirm", check = function()
		eq("Enter confirms the row that was left", confirmed and confirmed.name, "beta")
		eq("and the picker is gone", P.visible().count, 0)
	end },

	-- 4b. a label is given the number of its row. The yank history numbers every
	-- row and its label raised an error on the first one, because the labels
	-- were built with vim.tbl_map, which hands a function the value and nothing
	-- else, so the index it asked for was nil.
	{ name = "O.open", open = function()
		open({
			format = function(item, i)
				return ("%d. %s"):format(i, item.name)
			end,
		})
	end },
	{ name = "O.numbered", check = function()
		eq("a label that numbers its rows is given the number", P.visible().labels, { "1. alpha", "2. beta", "3. gamma" })
		eq("and the rows under them are the same rows", visible_names(), { "alpha", "beta", "gamma" })
	end },
	{ name = "O.close", check = function()
		eq("and it closes like any other", P.visible().count, 0)
	end },

	-- 4c. what the picker paints on the rows. Every filter check above asserts
	-- the spans the code computed, and none of them looks at the buffer, so a
	-- picker that computed the right spans and painted nothing at all would pass
	-- all of them.
	{ name = "P.open", open = function()
		open({ filter = true })
	end },
	{ name = "P.type_a", text = "" },
	{ name = "P.painted", check = function()
		local shown = P.visible()
		eq("the needle went in", shown.needle, "a")
		local want = {}
		for row, label in ipairs(shown.labels) do
			vim.list_extend(want, wanted_for(row, label, shown.highlights[row] or {}))
		end
		eq("and the buffer carries every span it worked out, in the right place", painted(), want)
		check("which is not nothing", #want > 0, vim.inspect(want))
		local rows = {}
		for _, mark in ipairs(painted()) do
			rows[tonumber(mark:match("^(%d+)") or "-1")] = true
		end
		local lined = vim.tbl_count(rows)
		eq("with a mark on every row that is showing", lined, shown.count)
	end },
	{ name = "P.back", text = "" },
	{ name = "P.cleared", check = function()
		eq("clearing the needle takes the marks with it", painted(), {})
		eq("and every row is back", P.visible().count, 3)
	end },
	{ name = "P.close", text = "" },

	-- 5. an extra key runs on the row under the cursor
	{
		name = "C.open",
		open = function()
			confirmed, run = nil, nil
			open({
				filter = true,
				keys = {
					["<C-x>"] = {
						desc = "run",
						run = function(item)
							run = item
						end,
					},
				},
			})
		end,
	},
	{ name = "C.run", check = function()
		eq("the extra key runs on the first row", run and run.name, "alpha")
		eq("and does not confirm anything", confirmed, nil)
		eq("and closes the picker", P.visible().count, 0)
	end },

	-- 6. without a filter line, a row is picked in normal mode as before
	{
		name = "D.open",
		open = function()
			confirmed = nil
			open()
		end,
		check = function()
			eq("without a filter line everything is listed", visible_names(), { "alpha", "beta", "gamma" })
			eq("and there is no needle to type in", P.visible().needle, "")
		end,
	},
	{ name = "D.pick", check = function()
		eq("the second row is the one confirmed", confirmed and confirmed.name, "beta")
	end },
	{ name = "E.open" },

	-- 7. rows that answer the needle equally well are left alone, rows that
	-- answer it better move up
	{
		name = "F.open",
		open = function()
			confirmed = nil
			P.open({ { name = "beta/one.lua" }, { name = "one" }, { name = "gamma/one.lua" } }, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function()
			eq("the rows start in the order they were given", visible_names(), { "beta/one.lua", "one", "gamma/one.lua" })
		end,
	},
	{ name = "F.one", check = function()
		eq("the row that is the word comes first", visible_names()[1], "one")
		eq("and both rows that contain it stay", #visible_names(), 3)
		eq("the needle reads back what was typed", P.visible().needle, "one")
	end },
	{ name = "F.dismiss", check = function()
		eq("Escape still only clears it", visible_names(), { "beta/one.lua", "one", "gamma/one.lua" })
	end },

	-- 8. the diagnostics picker, which now takes a filter too: two files, a
	-- problem in each, and the needle says which one is wanted
	{
		name = "G.open",
		open = function()
			problem_files = {}
			local items = {}
			for i, name in ipairs({ "alpha/one.lua", "beta/two.lua" }) do
				local path = probe_dir .. "/" .. name
				vim.fn.mkdir(probe_dir .. "/" .. vim.fn.fnamemodify(name, ":h"), "p")
				vim.fn.writefile({ "local a = 1", "local b = 2", "local c = 3" }, path)
				vim.cmd.edit(vim.fn.fnameescape(path))
				local bufnr = vim.api.nvim_get_current_buf()
				problem_files[name] = vim.api.nvim_buf_get_name(bufnr)
				items[i] = { bufnr = bufnr, lnum = 1, col = 0, message = "unused local", severity = 1, source = "probe" }
			end
			P.diagnostics(items, "probe")
		end,
		check = function()
			eq("both problems are listed", P.visible().count, 2)
		end,
	},
	{ name = "G.type", check = function()
		eq("typing the file name narrows to its problem", P.visible().count, 1)
		eq("and the row is the one that has it", P.visible().labels[1]:find("two.lua", 1, true) ~= nil, true)
	end },
	{ name = "G.pick", check = function()
		eq("Enter takes it", P.visible().count, 0)
		eq("and the buffer is the one that was asked for", vim.api.nvim_buf_get_name(0), problem_files["beta/two.lua"])
		eq("on the line the problem was on", vim.api.nvim_win_get_cursor(0)[1], 2)
	end },
	-- 9. typing a word with a letter in the wrong place still finds the row
	{
		name = "H.open",
		open = function()
			confirmed = nil
			P.open({ { name = "lua/plugins/yanky.lua" }, { name = "lua/config/session.lua" }, { name = "README.md" } }, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function()
			eq("the three rows are listed", visible_names(), { "lua/plugins/yanky.lua", "lua/config/session.lua", "README.md" })
		end,
	},
	{ name = "H.confg", check = function()
		eq("a needle with a letter transposed narrows the list", visible_names(), { "lua/config/session.lua" })
		eq("and the needle reads back exactly what was typed", P.visible().needle, "confg")
	end },
	{ name = "H.dismiss", check = function()
		eq("Escape still only clears it", visible_names(), { "lua/plugins/yanky.lua", "lua/config/session.lua", "README.md" })
	end },

	-- 10. what matched is painted on the row, so a fuzzy hit is not a guess
	{
		name = "I.open",
		open = function()
			confirmed = nil
			P.open({ { name = "README.md" }, { name = "lua/config/session.lua" } }, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function()
			eq("nothing is painted before anything is typed", vim.tbl_isempty(P.visible().highlights), true)
		end,
	},
	{ name = "I.confg", check = function()
		eq("the scattered answer is the only row left", visible_names(), { "lua/config/session.lua" })
		eq("and the run it matched is marked", P.visible().highlights[1], {
			{ from = 4, to = 9, tier = "scattered" },
		})
		local marks = vim.api.nvim_buf_get_extmarks(P.visible().buf, P.ns, 0, -1, { details = true })
		eq("the buffer really carries the mark", #marks, 3)
		eq("on the row the answer is on", mark_at(marks, 1), { row = 0, from = 0, to = 4, group = "PickerMatchRest" })
		eq("and the run the finder used is the second mark", mark_at(marks, 2), { row = 0, from = 4, to = 10, group = "PickerMatchScattered" })
		eq("with the rest of the row dimmed around it", mark_at(marks, 3), { row = 0, from = 10, to = 22, group = "PickerMatchRest" })
	end },
	{ name = "I.dismiss", check = function()
		eq("clearing the needle takes the paint with it", vim.tbl_isempty(P.visible().highlights), true)
		eq("and no mark is left on the buffer", #vim.api.nvim_buf_get_extmarks(P.visible().buf, P.ns, 0, -1, {}), 0)
		eq("with both rows back", visible_names(), { "README.md", "lua/config/session.lua" })
	end },

	-- 11. a row that contains the word as it stands is not painted like a row
	-- that only answered with the row's punctuation dropped
	{
		name = "I.typed",
		open = function()
			confirmed = nil
			P.open({ { name = "configpicker.lua" }, { name = "lua/config/picker.lua" } }, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function() end,
	},
	{ name = "I.hits", check = function()
		eq("both rows answer", visible_names(), { "configpicker.lua", "lua/config/picker.lua" })
		local marks = vim.api.nvim_buf_get_extmarks(P.visible().buf, P.ns, 0, -1, { details = true })
		eq("both rows are painted, match and rest", #marks, 5)
		-- By group, not by position: a mark's index says which call added it,
		-- and what this cares about is which tier a row's own mark carries.
		local by_group = {}
		for _, mark in ipairs(marks) do
			local group = mark[4].hl_group
			by_group[group] = by_group[group] or {}
			table.insert(by_group[group], { mark[2], mark[3], mark[4].end_col })
		end
		eq(
			"the row with the word as it stands is the plain one",
			by_group.PickerMatchLiteral,
			{ { 0, 0, 12 } }
		)
		eq(
			"and the one that needed its punctuation dropped is marked weaker",
			by_group.PickerMatchLoose,
			{ { 1, 4, 17 } }
		)
		eq("and the rest of both rows is dimmed", #(by_group.PickerMatchRest or {}), 3)
	end },
	{ name = "I.close", check = function() end },

	-- 12. typing moves the ranking around, but it must not move the selection
	-- to a different row
	{
		name = "J.open",
		open = function()
			confirmed = nil
			P.open({ { name = "gamma/one.lua" }, { name = "beta/one.lua" }, { name = "one.lua" } }, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function()
			eq("three rows, in the order they were given", visible_names(), { "gamma/one.lua", "beta/one.lua", "one.lua" })
			eq("and the first is the one under the cursor", selected_name(), "gamma/one.lua")
		end,
	},
	{ name = "J.up", check = function()
		eq("up from the first row stays on it", selected_name(), "gamma/one.lua")
	end },
	{ name = "J.down", check = function()
		eq("an arrow key moves the selection from the filter line", selected_name(), "beta/one.lua")
	end },
	{ name = "J.one", check = function()
		eq("the whole word wins, then the shorter path", visible_names(), { "one.lua", "beta/one.lua", "gamma/one.lua" })
		eq("and the cursor followed the row it was on", selected_name(), "beta/one.lua")
		eq("which is now the second row", selected_row(), 2)
	end },
	{ name = "J.clear", check = function()
		eq("clearing the needle puts the order back", visible_names(), { "gamma/one.lua", "beta/one.lua", "one.lua" })
		eq("and the same row is still the one chosen", selected_name(), "beta/one.lua")
		eq("back on the second line", selected_row(), 2)
	end },
	{ name = "J.pick", check = function()
		eq("and Enter confirms that row, not the one that moved", confirmed and confirmed.name, "beta/one.lua")
	end },

	-- 13. a needle long enough to reach the count gets the line to itself
	{
		name = "K.open",
		open = function()
			confirmed = nil
			P.open({
				{ name = "lua/config/session.lua" },
				{ name = "lua/plugins/yanky.lua" },
				{ name = "README.md" },
			}, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function()
			local count = filter_count()
			line_width = count.width
			eq("the count is drawn at the right of the line", count.col + #count.text, count.width)
			eq("and says everything is still there", count.text, "all 3")
		end,
	},
	{ name = "K.word", check = function()
		eq("one row answers a whole path", visible_names(), { "lua/config/session.lua" })
		eq("the count says so", filter_status(), "1 of 3")
		local count = filter_count()
		eq("and is still drawn clear of what was typed", count.col > #needle(), true)
	end },
	{ name = "K.grow", check = function()
		eq("a needle that fills the line leaves nothing to match", visible_names(), {})
		eq("and the list says so", vim.api.nvim_buf_get_lines(P.visible().buf, 0, 1, false)[1]:find("nothing matches", 1, true) ~= nil, true)
		eq("the count is gone rather than drawn over the needle", filter_status(), nil)
		eq("and the needle is what reaches the count's place", #needle() >= line_width - #"0 of 3", true)
	end },
	{ name = "K.shrink", check = function() end },
	{ name = "K.back", check = function()
		eq("the count comes back when the needle leaves room", filter_status(), "1 of 3")
		eq("and the row is back too", visible_names(), { "lua/config/session.lua" })
	end },
	-- 14. Tab finishes the word from the rows that are left
	{
		name = "L.open",
		open = function()
			confirmed = nil
			P.open({
				{ name = "lua/config/picker.lua" },
				{ name = "lua/config/session.lua" },
				{ name = "README.md" },
			}, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function() end,
	},
	{ name = "L.part", check = function() end },
	{ name = "L.shared", check = function()
		eq("Tab takes the prefix the two rows share", needle(), "lua/config/")
		eq("so both of them are still listed", visible_names(), { "lua/config/picker.lua", "lua/config/session.lua" })
		eq("and the count says so", filter_status(), "2 of 3")
	end },
	{ name = "L.word", check = function()
		eq("a second Tab finishes the word the first row goes on with", needle(), "lua/config/picker")
		eq("leaving the one row that has it", visible_names(), { "lua/config/picker.lua" })
		eq("with the count at one", filter_status(), "1 of 3")
	end },
	{ name = "L.whole", check = function()
		eq("a third Tab takes the rest of that row", needle(), "lua/config/picker.lua")
		eq("leaving the one row that answered", visible_names(), { "lua/config/picker.lua" })
		eq("with the count at one", filter_status(), "1 of 3")
	end },
	{ name = "L.other", check = function()
		eq("a fourth Tab moves on to the other row's word", needle(), "lua/config/session")
		eq("which is still a prefix of a row that was there", visible_names(), { "lua/config/session.lua" })
	end },
	{ name = "L.last", check = function()
		eq("a fifth Tab takes the rest of that row too", needle(), "lua/config/session.lua")
		eq("with the count still at one", filter_status(), "1 of 3")
	end },
	{ name = "L.wrap", check = function()
		eq("a sixth Tab comes back round to the shared prefix", needle(), "lua/config/")
		eq("and both rows are listed again", visible_names(), { "lua/config/picker.lua", "lua/config/session.lua" })
		eq("with the count behind it", filter_status(), "2 of 3")
	end },
	{ name = "L.close", check = function() end },

	-- 15. typing ends the cycle, so the next Tab works from what is on screen
	{
		name = "M.open",
		open = function()
			confirmed = nil
			P.open({
				{ name = "lua/config/picker.lua" },
				{ name = "lua/config/session.lua" },
				{ name = "README.md" },
			}, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function() end,
	},
	{ name = "M.part", check = function() end },
	{ name = "M.tab1", check = function()
		eq("Tab takes the prefix the two rows share", needle(), "lua/config/")
		eq("with both rows still listed", visible_names(), { "lua/config/picker.lua", "lua/config/session.lua" })
	end },
	{ name = "M.typed", check = function() end },
	{ name = "M.tab2", check = function()
		eq("a letter ends the cycle and narrows to one row", visible_names(), { "lua/config/session.lua" })
		eq("and Tab completes from that row, not from the old cycle", needle(), "lua/config/session")
		eq("so the row the cycle would have offered is not chosen", needle() == "lua/config/picker", false)
	end },
	{ name = "M.tab3", check = function()
		eq("a further Tab takes the rest of that row", needle(), "lua/config/session.lua")
	end },
	{ name = "M.close", check = function() end },

	-- 16. a nested path is walked a directory at a time
	{
		name = "N.open",
		open = function()
			confirmed = nil
			P.open({
				{ name = "lua/config/painter/lua/init.lua" },
				{ name = "lua/config/painter.lua" },
			}, {
				title = "probe",
				skip_single = false,
				filter = true,
				format = function(item)
					return item.name
				end,
				on_confirm = function(item)
					confirmed = item
				end,
			})
		end,
		check = function() end,
	},
	{ name = "N.part", check = function() end },
	{ name = "N.tab1", check = function()
		eq("Tab finishes the directory the needle is inside", needle(), "lua/config/painter")
		eq("and both rows still have it as a prefix", visible_names(), {
			"lua/config/painter.lua",
			"lua/config/painter/lua/init.lua",
		})
	end },
	{ name = "N.tab2", check = function()
		eq("a second Tab finishes the row it ranked first", needle(), "lua/config/painter.lua")
		eq("which stays on top, the deeper row still matching on punctuation", visible_names()[1], "lua/config/painter.lua")
	end },
	{ name = "N.tab3", check = function()
		eq("a third Tab goes down one directory of the row below it", needle(), "lua/config/painter/lua")
		eq("and the row it names comes first", visible_names()[1], "lua/config/painter/lua/init.lua")
		eq("with the shorter sibling still matching on its punctuation", #visible_names(), 2)
	end },
	{ name = "N.tab4", check = function()
		eq("a fourth Tab goes down to the file's stem", needle(), "lua/config/painter/lua/init")
		eq("and the sibling is left out at last", visible_names(), { "lua/config/painter/lua/init.lua" })
	end },
	{ name = "N.tab5", check = function()
		eq("a fifth Tab finishes the file name", needle(), "lua/config/painter/lua/init.lua")
	end },
	{ name = "N.close", check = function() end },

	-- 18. a picker without a filter line has no filter window, and closing it
	-- used to skip every window because the hole stopped the loop: the floats
	-- stayed up and the file opened in the preview float.
	{
		name = "R.open",
		open = function()
			confirmed = nil
			-- The real <leader>fb runs in normal mode. An earlier filter test
			-- in this one nvim leaves it in insert mode, and a picker opened
			-- there cannot read Enter, so the entry has to be normalised here.
			vim.cmd.stopinsert()
			local path = probe_dir .. "/probe/picked.lua"
			vim.fn.mkdir(probe_dir .. "/probe", "p")
			vim.fn.writefile({ "local picked = 1" }, path)
			P.open({ { name = "alpha" }, { name = "beta" }, { name = "gamma" } }, {
				title = "probe",
				skip_single = false,
				format = function(item)
					return item.name
				end,
				on_confirm = function()
					vim.cmd.edit(vim.fn.fnameescape(path))
				end,
			})
		end,
		check = function()
			eq("the picker is up with its floats", #floats(), 2)
		end,
	},
	{ name = "R.pick", check = function()
		eq("Enter takes the row", P.visible().count, 0)
		eq("and every float is gone", #floats(), 0)
		eq("the file is in a normal window", vim.bo.buftype, "")
		eq("and it is the one that was picked", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"), "picked.lua")
	end },

	-- 15. a definition inside a dependency is a row, not a row dropped by the
	-- ignore patterns the diagnostic list uses
	{
		name = "S.open",
		open = function()
			P.locations({
				{ filename = "src/agent.ts", lnum = 1, col = 1, text = "local x = 1" },
				{ filename = "src/see.ts", lnum = 1, col = 1, text = "export const see" },
				{ filename = "node_modules/.pnpm/typebox/lib/type.mjs", lnum = 1, col = 1, text = "declare module" },
			}, "probe")
		end,
	},
	{ name = "S.rows", check = function()
		local files = {}
		for i, item in ipairs(P.visible().items) do
			files[i] = item.filename
		end
		eq("the definition inside node_modules is a row like any other", files, {
			"src/agent.ts",
			"src/see.ts",
			"node_modules/.pnpm/typebox/lib/type.mjs",
		})
	end },
	{ name = "S.close" },

	{ name = "done" },
}

local function report()
	local text = ("picker checks=%d failures=%d\n"):format(checks, #failures)
	for _, f in ipairs(failures) do
		text = text .. "FAIL " .. f .. "\n"
	end
	local out = io.open(os.getenv("PICKER_RESULT") or "/dev/null", "w")
	out:write(text)
	out:close()
end

local i = 0
local function run()
	i = i + 1
	local step = steps[i]
	if not step then
		vim.schedule(function()
			report()
			vim.cmd("qa!")
		end)
		return
	end
	-- The check belongs to the step above: those keys have been sitting in the
	-- terminal for a whole step by now, so this is where they are judged, and
	-- it has to run before the next picker is opened over the top of it.
	local previous = steps[i - 1]
	if previous and previous.check then
		previous.check()
	end
	if step.open then
		step.open()
	end
	local f = io.open(os.getenv("PICKER_STATUS") or "/dev/null", "a")
	f:write(step.name .. "\n")
	f:close()
	-- Long enough for the keys to be written and taken, short enough that the
	-- whole run is not a wait.
	vim.defer_fn(run, 600)
end

vim.defer_fn(run, 600)
LUA

if ! python3 tests/pty_drive.py "$tmp/keys" "$tmp/status" "$tmp/result" -- \
	nvim -u NONE -i NONE --cmd "set rtp^=$PWD" -c "autocmd VimEnter * luafile $tmp/probe.lua"; then
	printf 'picker test did not pass\n'
	exit 1
fi
