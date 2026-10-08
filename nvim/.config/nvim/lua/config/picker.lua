-- List + live-preview floating picker. A filter line is optional: with one,
-- typing narrows the list as you go, and rows that answer equally well keep the
-- order they were given, because that order is usually the useful one.
local M = {}

---Where the matched part of each row is painted. A namespace rather than
---'matchadd' so a narrowing replaces the previous answer instead of stacking
---another one on top of it.
M.ns = vim.api.nvim_create_namespace("picker_matches")

---One highlight group per tier, so the screen says how well a row answered and
---not only that something did. Each starts from a group the colourscheme already
---has, most convincing first: a word found as it was typed looks like a search
---hit, one found through the row's punctuation like an incremental search, and
---one found only in letter order like the completion being picked.
M.match_groups = {
	literal = "PickerMatchLiteral",
	loose = "PickerMatchLoose",
	scattered = "PickerMatchScattered",
}

local TIER_BASES = {
	literal = { "Search" },
	loose = { "IncSearch", "Search" },
	scattered = { "PmenuMatchSel", "Search" },
}

---The part of a row that no word of the needle answered for. It is painted
---too, so the matched runs are islands in the row rather than a long line with
---something in the middle of it, and one island per word of a multi word
---needle says which word answered where.
M.rest_group = "PickerMatchRest"

local REST_BASE = "Comment"

---Define the groups, but only the ones the colourscheme has not already named.
---A config that wants its own colours for a tier says so and this leaves them
---alone.
function M.ensure_match_groups()
	local wanted = {}
	for tier, group in pairs(M.match_groups) do
		wanted[#wanted + 1] = { group = group, bases = TIER_BASES[tier] or { "Search" } }
	end
	wanted[#wanted + 1] = { group = M.rest_group, bases = { REST_BASE, "Search" } }
	for _, want in ipairs(wanted) do
		if vim.fn.hlexists(want.group) == 0 then
			for _, base in ipairs(want.bases) do
				if vim.fn.hlexists(base) == 1 then
					vim.api.nvim_set_hl(0, want.group, { link = base })
					break
				end
			end
		end
	end
end

---Where the word of `text` that starts before `from` ends: the first character
---that cannot be part of a word, or the end of the text.
---@param text string
---@param from integer
---@return integer
local function label_end(text, from)
	local at = from
	while at <= #text and text:sub(at, at):match("[%w_]") do
		at = at + 1
	end
	return at - 1
end

---Every way one more keystroke of a needle could be finished, best answer
---first: the longest prefix every row that starts with the needle shares, then
---the word each of those rows goes on with, then each of those rows whole. The
---row's own spelling is used, so a label in capitals is not completed in lower
---case, and every answer is a prefix of a row that starts with the needle.
---
---The list is what repeated Tab walks through, so one keystroke that picks the
---wrong name can be undone by the next one instead of by deleting characters.
---An empty needle has nothing to complete, and the longest prefix of a whole
---list is usually the empty string, so the list is empty for it too.
---@param needle string
---@param labels string[] the rows to complete from
---@return string[]
function M.completions(needle, labels)
	needle = needle or ""
	if vim.trim(needle) == "" then
		return {}
	end
	local lower = needle:lower()
	local starts, shared = {}, nil
	for _, label in ipairs(labels or {}) do
		if label:sub(1, #needle):lower() == lower then
			starts[#starts + 1] = label
			if shared == nil then
				shared = label
			else
				local at = 1
				while at <= #shared and shared:sub(at, at):lower() == label:sub(at, at):lower() do
					at = at + 1
				end
				shared = shared:sub(1, at - 1)
			end
		end
	end
	local out, seen = {}, {}
	local function add(text)
		if not seen[text] then
			seen[text] = true
			out[#out + 1] = text
		end
	end
	-- What every row agrees on is the safest answer, so it comes first. It is
	-- only an answer when it is shorter than the rows themselves: with one
	-- row the shared prefix is the whole of it, and offering the whole name
	-- before the word it is made of would skip over the useful step.
	local shortest = nil
	for _, label in ipairs(starts) do
		if shortest == nil or #label < #shortest then
			shortest = label
		end
	end
	local agreed = shared and #shared > #needle and #shared < #shortest and shared or nil
	if agreed then
		add(agreed)
	end
	-- Then one segment at a time, so a long path can be walked down a
	-- directory at a time instead of jumped to the end of, and a name can be
	-- stopped at at the stem of a word only half wanted. A step that stops
	-- short of what every row already agrees on is not a step forward, so it
	-- is not offered: with the needle 'lua/con' the segment 'config' ends
	-- before the shared 'lua/config/'.
	local floor = agreed and #agreed or #needle
	for _, label in ipairs(starts) do
		local at = #needle
		while true do
			-- Separators are walked over, so the next step is the next
			-- segment of the row rather than the tail of the one the needle
			-- is in.
			local from = at + 1
			while from <= #label and not label:sub(from, from):match("[%w_]") do
				from = from + 1
			end
			local stop = label_end(label, from)
			if stop <= at then
				break
			end
			at = stop
			if at > floor then
				add(label:sub(1, at))
			end
		end
	end
	-- Then the whole row, which with one row left is all of it.
	for _, label in ipairs(starts) do
		add(label)
	end
	return out
end

---What one more keystroke of a needle should say: the best of
---M.completions, or the needle itself when there is nothing to complete.
---@param needle string
---@param labels string[] the rows currently surviving
---@return string
function M.complete(needle, labels)
	local out = M.completions(needle, labels)
	return out[1] or (needle or "")
end

---The parts of `label` that none of the hits in `hits` covers, as 0-based
---inclusive byte ranges. A label every hit covers has no rest, and a label no
---hit reaches is all rest.
---@param label string
---@param hits { from: integer, to: integer }[]
---@return { from: integer, to: integer }[]
function M.unmatched(label, hits)
	local spans = vim.deepcopy(hits or {})
	table.sort(spans, function(a, b)
		return a.from < b.from
	end)
	local out, at = {}, 0
	for _, hit in ipairs(spans) do
		if hit.from > at then
			out[#out + 1] = { from = at, to = math.min(hit.from - 1, #label - 1) }
		end
		at = math.max(at, hit.to + 1)
	end
	if at < #label then
		out[#out + 1] = { from = at, to = #label - 1 }
	end
	return out
end

---Bare forms of the labels on screen, keyed by the label. See M.bare_map. The
---table is emptied by close(), which every teardown key and the next open() go
---through, and the most it can hold is one entry per row: 3.8MB for a picker
---over 5000 labels.
local bare_memo = {}

local state = {}

-- Paths to ignore in diagnostic results. Add patterns here as needed.
-- Not used for goto definition: a dependency's .d.ts is the only definition
-- most symbols have, so filtering node_modules left `gd` on an empty list.
local IGNORE_PATTERNS = {
	"node_modules/",
	"%.pnpm%-store/",
	"%.venv/",
	"__pycache__/",
}

local function close()
	bare_memo = {}
	-- The `or 0` is the fix, not noise: a picker opened without a filter line
	-- has no filter window, and ipairs stops at the first hole, so every one of
	-- these loops did nothing at all. The floats stayed on screen, and the
	-- confirmed file was then opened in the preview float, because that was the
	-- window the cursor was left in. Zero is never a live handle.
	for _, win in ipairs({ state.filter_win or 0, state.list_win or 0, state.preview_win or 0 }) do
		if win ~= 0 and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	for _, buf in ipairs({ state.filter_buf or 0, state.list_buf or 0, state.preview_buf or 0 }) do
		if buf ~= 0 and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "nofile" then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end
	state = {}
end

---Whether the picker is up, as far as anything outside this file can tell.
---
---A caller that refreshes the picker on a timer needs to know whether the user
---is still looking at it, or it will put a window back in front of someone who
---has closed it. There was no way to ask before, which is why the one caller
---that refreshes did it on a fixed 300ms and hoped.
---@return boolean
function M.is_open()
	return state.list_win ~= nil and vim.api.nvim_win_is_valid(state.list_win)
end

---Whether a label survives what has been typed. Every word in the needle has to
---be in the label, in any case, and their order does not matter: `nv` finds
---`vim_config` and `conf vim` finds it too.
---@param needle string
---@param label string
---@return boolean
function M.matches(needle, label)
	return M.score(needle, label) ~= nil
end

local function build_bare(label)
	local chars, offsets = {}, {}
	local at = label:find("%w")
	while at do
		offsets[#offsets + 1] = at
		chars[#chars + 1] = label:sub(at, at)
		at = label:find("%w", at + 1)
	end
	local bare = { table.concat(chars), offsets }
	bare_memo[label] = bare
	return bare
end

---`label` with the punctuation dropped, and the offset in `label` of every
---character that survived. A match made in the stripped copy has to be reported
---against the original, or a highlight would land on the wrong columns. One is
---built per label and kept: the picker scores every row on every keystroke, and
---this is most of what a keystroke costs once a word is not there literally.
---@param label string already lowercased
---@return string bare the label with the punctuation dropped
---@return integer[] offsets of every character that survived, 1-based into label
function M.bare_map(label)
	local hit = bare_memo[label] or build_bare(label)
	return hit[1], hit[2]
end

---The tightest run in `label` holding `needle`'s characters in order, as
---(span, from, to), all 1-based and inclusive, or nil when there is none. The
---search restarts at every occurrence of the first character, so the shortest
---run wins, and the span is what a caller needs rather than a yes or no: a
---needle sprayed across half a path is a worse answer than one packed into a few
---characters.
---@param needle string
---@param label string
---@return integer|nil span, integer|nil from, integer|nil to
function M.window(needle, label)
	if needle == "" or label == "" then
		return nil
	end
	local best
	local at = label:find(needle:sub(1, 1), 1, true)
	while at do
		local last, ok = at, true
		for i = 2, #needle do
			local next_at = label:find(needle:sub(i, i), last + 1, true)
			if not next_at then
				ok = false
				break
			end
			last = next_at
		end
		if ok and (not best or last - at < best.span) then
			best = { span = last - at + 1, from = at, to = last }
		end
		at = label:find(needle:sub(1, 1), at + 1, true)
	end
	return best and best.span, best and best.from, best and best.to
end

---Where each word of a needle was found in a label, and how. `literal` when it
---is in the label as it was typed, `loose` when it is in the label with the
---punctuation dropped, `scattered` when its characters are in order inside a run
---no longer than twice the word plus four characters. nil when a word is nowhere
---to be found.
---
---The offsets are 0-based bytes into the label and inclusive, which is what a
---highlight needs. A loose or scattered answer covers the separators it had to
---cross, because those characters are part of what matched and a highlight that
---left them out would say something the finder did not do.
---@param needle string
---@param label string
---@return { from: integer, to: integer, tier: string }[]|nil
function M.match_words(needle, label)
	needle = vim.trim(needle or ""):lower()
	label = (label or ""):lower()
	local words = {}
	for word in needle:gmatch("%S+") do
		words[#words + 1] = word
	end
	if #words == 0 then
		return {}
	end
	-- A label that holds a word as it was typed never needs the bare map, and
	-- building it is most of what a keystroke costs, so it is made on the first
	-- word that is not there to be found literally.
	local bare_label, offsets
	local found = {}
	for _, word in ipairs(words) do
		local at = label:find(word, 1, true)
		if at then
			found[#found + 1] = { from = at - 1, to = at + #word - 2, tier = "literal" }
		else
			if not bare_label then
				bare_label, offsets = M.bare_map(label)
			end
			-- A needle is allowed to name a path, a file, or a chain of both,
			-- and the label is one line of text with separators of its own.
			local bare = word:gsub("[^%w]", "")
			if bare == "" then
				return nil
			end
			local bare_at = bare_label:find(bare, 1, true)
			if bare_at then
				found[#found + 1] = {
					from = offsets[bare_at] - 1,
					to = offsets[bare_at + #bare - 1] - 1,
					tier = "loose",
				}
			else
				local span, from, to = M.window(bare, bare_label)
				if not span or span > #bare * 2 + 4 then
					return nil
				end
				found[#found + 1] = {
					from = offsets[from] - 1,
					to = offsets[to] - 1,
					tier = "scattered",
				}
			end
		end
	end
	return found
end

---How well a label answers a needle, or nil when it does not answer it at all.
---Five things count, in this order: a needle word landing on a whole word beats
---one landing inside a longer word, a word found as it was typed beats one only
---found with the punctuation dropped, a word found with its characters in order
---beats nothing, an early match beats a late one, and a short label beats a long
---one. They are folded into a single number with enough room between them that a
---better match on any one of them wins, and a label longer than the weights
---assume is scored as if it were not. The weights are per needle word, so a
---needle of more than 99 loosely found words would outrank a literal one; nobody
---types that, and a test pins the bound rather than leaving it to be discovered.
---
---Where each word was found comes from M.match_words, so the ranking and the
---highlight cannot disagree about what matched.
---@param needle string
---@param label string
---@return integer|nil
function M.score(needle, label)
	needle = vim.trim(needle or ""):lower()
	label = (label or ""):lower()
	if needle == "" then
		return 0
	end
	local found = M.match_words(needle, label)
	if not found then
		return nil
	end
	local whole, loose, scattered, earliest = 0, 0, 0, math.huge
	for _, hit in ipairs(found) do
		if hit.tier == "literal" then
			-- hit.from is a 0-based offset, so label:sub(hit.from) is the
			-- character just before the match: the same test as before, on the
			-- offsets the finder reports.
			local before = label:sub(hit.from, hit.from)
			if hit.from == 0 or not before:match("[%w_]") then
				whole = whole + 1
			end
			earliest = math.min(earliest, hit.from)
		elseif hit.tier == "loose" then
			loose = loose + 1
		else
			scattered = scattered + 10000000 - math.min(hit.to - hit.from + 1, 999)
		end
	end
	if earliest == math.huge then
		earliest = 0
	end
	return whole * 1000000 - loose * 1000000000 - scattered - earliest * 1000 - math.min(#label, 999)
end

---Which of a list of labels survive a needle, best answer first. Rows that
---score the same keep the order they were given, so nothing is reshuffled on a
---tie, and an empty needle leaves the whole list alone: there is nothing to
---rank by yet.
---@param labels string[]
---@param needle string
---@return integer[] indices into labels, 1-based
function M.visible_indices(labels, needle)
	local keep = {}
	for i, label in ipairs(labels) do
		local score = M.score(needle, label)
		if score then
			keep[#keep + 1] = { index = i, score = score }
		end
	end
	if vim.trim(needle or "") == "" then
		return vim.tbl_map(function(row)
			return row.index
		end, keep)
	end
	table.sort(keep, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.index < b.index
	end)
	return vim.tbl_map(function(row)
		return row.index
	end, keep)
end

---What the list is showing right now: the items behind the visible rows, the
---rows themselves, the text they were narrowed by, the range of each row that
---matched, the buffer they are in, how many rows there were to start with, and
---whether the needle has left nothing at all. Reading this is how a caller tells
---which of its items the cursor is on without tracking the buffer.
---@return { items: any[], labels: string[], needle: string, count: integer, total: integer, no_match: boolean, highlights: table[], buf: integer|nil, filter_buf: integer|nil }
function M.visible()
	local items, needle = state.items or {}, state.needle or ""
	local count = #(state.visible_items or {})
	return {
		items = state.visible_items or {},
		labels = state.visible_labels or {},
		needle = needle,
		count = count,
		total = #items,
		no_match = vim.trim(needle) ~= "" and count == 0,
		highlights = state.highlights or {},
		buf = state.list_buf,
		filter_buf = state.filter_buf,
	}
end

-- preview callbacks passed to opts.preview(item, ctx)
local ctx = {}

function ctx.set_lines(lines, ft)
	if not (state.preview_win and vim.api.nvim_win_is_valid(state.preview_win)) then
		return
	end
	if
		not (
			state.preview_buf
			and vim.api.nvim_buf_is_valid(state.preview_buf)
			and vim.bo[state.preview_buf].buftype == "nofile"
		)
	then
		state.preview_buf = vim.api.nvim_create_buf(false, true)
	end
	vim.api.nvim_win_set_buf(state.preview_win, state.preview_buf)
	vim.bo[state.preview_buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, lines)
	vim.bo[state.preview_buf].modifiable = false
	vim.bo[state.preview_buf].filetype = ft or ""
end

function ctx.set_cursor(lnum, col)
	if state.preview_win and vim.api.nvim_win_is_valid(state.preview_win) then
		vim.api.nvim_win_set_cursor(state.preview_win, { lnum, col or 0 })
		vim.api.nvim_win_call(state.preview_win, function()
			vim.cmd("normal! zz")
		end)
	end
end

function ctx.set_file(path, lnum, col)
	local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or { "[unreadable] " .. path }
	ctx.set_lines(lines, vim.filetype.match({ filename = path }))
	lnum = math.min(math.max(lnum or 1, 1), math.max(#lines, 1))
	vim.api.nvim_win_set_cursor(state.preview_win, { lnum, math.max((col or 1) - 1, 0) })
	vim.api.nvim_win_call(state.preview_win, function()
		vim.cmd("normal! zz")
	end)
end

---@class picker.Opts
---@field title? string
---@field skip_single? boolean Auto-confirm when there is exactly one item (default true)
---@field format fun(item: any, i: integer): string
---@field preview? fun(item: any, ctx: table)
---@field on_confirm fun(item: any)
---@field filter? boolean add a line to narrow the list as you type
---@field keys? table<string, { desc: string, run: fun(item: any) }> extra buffer-local keys, shown in the title

---@param items table[] list of arbitrary entries
---@param opts picker.Opts
function M.open(items, opts)
	if not items or #items == 0 then
		vim.notify("Nothing to show", vim.log.levels.INFO)
		return
	end
	if #items == 1 and opts.skip_single ~= false then
		opts.on_confirm(items[1])
		return
	end

	close()

	-- A filter line sits above the list, so the list and the preview move down
	-- by one line and the list loses one of its rows.
	local filter = opts.filter and true or false
	local filter_h = filter and 1 or 0
	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.75) - filter_h
	local list_width = math.floor(width * 0.38)
	local row = math.floor((vim.o.lines - height) / 2) + filter_h
	local col = math.floor((vim.o.columns - width) / 2)

	local hints = {}
	for lhs, action in pairs(opts.keys or {}) do
		hints[#hints + 1] = ("%s %s"):format(lhs, action.desc)
	end
	if filter then
		hints[#hints + 1] = "<CR> open"
	end
	local title = opts.title or ""
	if #hints > 0 then
		title = title == "" and table.concat(hints, "  ") or (title .. "   " .. table.concat(hints, "  "))
	end

	state.items = items
	-- The index is passed on, because a caller that numbers its rows asks for
	-- it: vim.tbl_map hands over the value alone, and the yank history numbers
	-- every row, so its label raised an error on the first one and the picker
	-- came up empty.
	state.labels = {}
	for i, item in ipairs(items) do
		state.labels[i] = opts.format(item, i)
	end
	state.needle = ""

	state.list_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, state.labels)
	vim.bo[state.list_buf].modifiable = false

	state.list_win = vim.api.nvim_open_win(state.list_buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = list_width,
		height = height,
		border = "rounded",
		title = title,
		title_pos = "center",
	})
	vim.wo[state.list_win].cursorline = true
	vim.wo[state.list_win].wrap = false

	-- Tracked in state so close() can delete it.
	state.preview_buf = vim.api.nvim_create_buf(false, true)
	state.preview_win = vim.api.nvim_open_win(state.preview_buf, false, {
		relative = "editor",
		row = row,
		col = col + list_width + 2,
		width = width - list_width - 2,
		height = height,
		border = "rounded",
		title = "preview",
		title_pos = "center",
	})
	vim.wo[state.preview_win].wrap = false
	vim.wo[state.preview_win].number = true

	---What is under the cursor in the list, or nil when nothing is.
	---@return any|nil
	local function selected()
		if not (state.list_win and vim.api.nvim_win_is_valid(state.list_win)) then
			return nil
		end
		local row = vim.api.nvim_win_get_cursor(state.list_win)[1]
		return (state.visible_items or {})[row]
	end

	local function render()
		if not opts.preview then
			return
		end
		local item = selected()
		if item == nil then
			ctx.set_lines({}, "qf")
			return
		end
		opts.preview(item, ctx)
	end

	---How much of the list is left, on the right of the filter line. A needle
	---that keeps everything says so, because a count that only appears when
	---something has gone is the one that gets noticed too late.
	local function paint_filter_status()
		if not (state.filter_buf and vim.api.nvim_buf_is_valid(state.filter_buf)) then
			return
		end
		vim.api.nvim_buf_clear_namespace(state.filter_buf, M.ns, 0, -1)
		local shown, total = #(state.visible_items or {}), #(state.items or {})
		local text = shown == total and ("all %d"):format(total) or ("%d of %d"):format(shown, total)
		local col = math.max((list_width or 0) - #text, 0)
		-- A needle that reaches the count has no room for it: the line is
		-- full, and drawing over what has been typed would be worse than
		-- saying nothing. The list itself still says what happened, and the
		-- count comes back the moment the needle leaves room again.
		local typed = vim.fn.strdisplaywidth(vim.api.nvim_buf_get_lines(state.filter_buf, 0, 1, false)[1] or "")
		if col <= typed then
			return
		end
		vim.api.nvim_buf_set_extmark(state.filter_buf, M.ns, 0, 0, {
			virt_text = { { text, "Comment" } },
			virt_text_win_col = col,
			hl_mode = "combine",
		})
	end

	---Move the selection. Reachable from the filter line as well as from the
	---list, because the filter line is where the cursor is, and a picker whose
	---selection cannot be moved with one hand on the keys is half a picker.
	local function move(delta)
		if not (state.list_win and vim.api.nvim_win_is_valid(state.list_win)) then
			return
		end
		local count = #(state.visible_items or {})
		if count == 0 then
			return
		end
		local line = vim.api.nvim_win_get_cursor(state.list_win)[1]
		vim.api.nvim_win_set_cursor(state.list_win, { math.min(math.max(line + delta, 1), count), 0 })
		render()
	end

	---Show the rows that survive the needle, keeping the order they came in.
	---A keystroke can arrive after the picker has closed, so this checks it is
	---still on screen before touching anything.
	---@param needle string
	local function refilter(needle)
		if not (state.list_buf and vim.api.nvim_buf_is_valid(state.list_buf)) then
			return
		end
		if not (state.list_win and vim.api.nvim_win_is_valid(state.list_win)) then
			return
		end
		-- The row that was chosen, before the ranking gets a say. Typing
		-- must not choose a different row: if the item under the cursor is
		-- still in the list, it stays under the cursor wherever the ranking
		-- has put it, because the answer to a letter is not a request to
		-- select something else.
		local before = selected()
		local line = vim.api.nvim_win_get_cursor(state.list_win)[1]
		state.needle = needle
		local keep = M.visible_indices(state.labels, needle)
		state.visible_items = {}
		state.visible_labels = {}
		for i, idx in ipairs(keep) do
			state.visible_items[i] = state.items[idx]
			state.visible_labels[i] = state.labels[idx]
		end
		-- With nothing surviving, the list would be a blank rectangle with no
		-- way to tell it apart from a picker that has not drawn yet, so it says
		-- what it could not find. The rows themselves stay empty, so there is
		-- still nothing to confirm.
		local lines = state.visible_labels
		if vim.trim(needle or "") ~= "" and #lines == 0 then
			lines = { ("nothing matches %s"):format(vim.trim(needle)) }
		end
		vim.bo[state.list_buf].modifiable = true
		vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, lines)
		vim.bo[state.list_buf].modifiable = false
		paint_filter_status()
		-- Paint what matched, and how well, so a row that only answered
		-- through its punctuation or its characters in order is not a guess
		-- on screen and does not look like a row that contains the word.
		--
		-- Extmarks, not nvim_buf_add_highlight, which is deprecated and which
		-- the picker called once per span on every keystroke. The columns are
		-- the same numbers: a span is 1-based and inclusive, an extmark takes a
		-- 0-indexed start and an exclusive end, so from and to + 1 are what it
		-- always was. The end is clamped to the length of the line, because an
		-- extmark refuses an end_col past it where a highlight quietly accepted
		-- one, and a gap that runs to the end of a label does exactly that.
		-- hl_eol is set for those, so a mark that reaches the last character
		-- still shades the space after it the way it did.
		vim.api.nvim_buf_clear_namespace(state.list_buf, M.ns, 0, -1)
		state.highlights = {}
		if vim.trim(needle or "") ~= "" then
			M.ensure_match_groups()
			for row, label in ipairs(state.visible_labels) do
				local hits = M.match_words(needle, label) or {}
				state.highlights[row] = vim.deepcopy(hits)
				local width = #label
				local function mark(from, to, group)
					local stop = math.min(to + 1, width)
					vim.api.nvim_buf_set_extmark(state.list_buf, M.ns, row - 1, from, {
						end_col = stop,
						hl_group = group,
						hl_eol = stop >= width,
					})
				end
				for _, hit in ipairs(hits) do
					mark(hit.from, hit.to, M.match_groups[hit.tier] or "Search")
				end
				for _, gap in ipairs(M.unmatched(label, hits)) do
					mark(gap.from, gap.to, M.rest_group)
				end
			end
		end
		local target = line
		for row, item in ipairs(state.visible_items) do
			if before ~= nil and item == before then
				target = row
				break
			end
		end
		vim.api.nvim_win_set_cursor(state.list_win, { math.min(math.max(target, 1), math.max(#keep, 1)), 0 })
		render()
	end

	local function confirm()
		-- The last letter and the Enter can arrive in one chunk, before the
		-- narrowing has run, so the needle is applied here rather than
		-- trusting that it already was. Without this, Enter on a fast
		-- typist confirms the row that happened to be under the cursor
		-- before the last letter narrowed anything.
		if state.filter_buf and vim.api.nvim_buf_is_valid(state.filter_buf) then
			refilter(vim.api.nvim_buf_get_lines(state.filter_buf, 0, 1, false)[1] or "")
		end
		local item = selected()
		if item == nil then
			return
		end
		close()
		opts.on_confirm(item)
	end

	---Run an extra key's action on the row under the cursor. With nothing
	---narrowed to, there is no row and the key does nothing.
	---@param action { desc: string, run: fun(item: any) }
	local function run_action(action)
		local item = selected()
		if item == nil then
			return
		end
		close()
		action.run(item)
	end

	vim.api.nvim_create_autocmd("CursorMoved", { buffer = state.list_buf, callback = render })
	for _, lhs in ipairs({ "<CR>", "<C-o>" }) do
		vim.keymap.set("n", lhs, confirm, { buffer = state.list_buf })
	end
	for _, lhs in ipairs({ "<Esc>", "q", "<C-c>" }) do
		vim.keymap.set("n", lhs, close, { buffer = state.list_buf })
	end
	for lhs, action in pairs(opts.keys or {}) do
		vim.keymap.set("n", lhs, function()
			run_action(action)
		end, { buffer = state.list_buf })
	end

	if filter then
		state.filter_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_open_win(state.filter_buf, true, {
			relative = "editor",
			row = row - 1,
			col = col,
			width = list_width,
			height = 1,
			style = "minimal",
			border = "none",
		})
		state.filter_win = vim.api.nvim_get_current_win()
		-- Every change narrows the list, whether it came from a keystroke or
		-- from code setting the line.
		vim.api.nvim_buf_attach(state.filter_buf, false, {
			on_lines = function()
				local first = vim.api.nvim_buf_get_lines(state.filter_buf, 0, 1, false)[1] or ""
				-- Typing holds the text lock, and a locked edit of any buffer is
				-- refused, so the narrowing waits for the keystroke to finish.
				vim.schedule(function()
					refilter(first)
				end)
			end,
		})
		vim.keymap.set("i", "<CR>", function()
			vim.cmd.stopinsert()
			confirm()
		end, { buffer = state.filter_buf })
		vim.keymap.set("i", "<C-c>", close, { buffer = state.filter_buf })
		-- Tab finishes the word being typed from the rows that are left, which
		-- is the one thing a keyboard filter has that typing alone does not.
		-- Pressing it again walks the other ways it could be finished, so a
		-- name picked by accident costs one keystroke rather than a deletion.
		-- Writing the line is what runs the narrowing, the same as a keystroke.
		local function complete()
			if not (state.filter_buf and vim.api.nvim_buf_is_valid(state.filter_buf)) then
				return
			end
			local typed = vim.api.nvim_buf_get_lines(state.filter_buf, 0, 1, false)[1] or ""
			-- The cycle is anchored to the needle it started from, and the rows
			-- that were on screen then, so the answer a second Tab gives is not
			-- judged against a list the first Tab has already narrowed. What
			-- ends the cycle is typing: a keystroke means a new choice, made
			-- from the rows on screen now. Writing one of the completions does
			-- not, which is the whole point of a cycle.
			local ways = state.cycle and M.completions(state.cycle.needle, state.cycle.labels) or {}
			local ours = typed == (state.cycle and state.cycle.needle)
			for _, way in ipairs(ways) do
				if way == typed then
					ours = true
				end
			end
			if not (state.cycle and ours) then
				state.cycle = { needle = typed, labels = vim.deepcopy(state.visible_labels), at = 0 }
				ways = M.completions(state.cycle.needle, state.cycle.labels)
			end
			if #ways == 0 then
				return
			end
			state.cycle.at = state.cycle.at % #ways + 1
			local done = ways[state.cycle.at]
			if done ~= typed then
				vim.api.nvim_buf_set_lines(state.filter_buf, 0, 1, false, { done })
				-- Writing the line leaves the insert cursor where it was, in
				-- the middle of what was just completed, so the next keystroke
				-- would land inside the word. A completion that ends where the
				-- person was typing has to leave the cursor after it.
				if state.filter_win and vim.api.nvim_win_is_valid(state.filter_win) then
					vim.api.nvim_win_set_cursor(state.filter_win, { 1, #done })
				end
			end
		end
		vim.keymap.set("i", "<Tab>", complete, { buffer = state.filter_buf })
		vim.keymap.set("n", "<Tab>", complete, { buffer = state.filter_buf })
		-- Escape clears what has been typed, and only then leaves: the usual
		-- order, so one Escape is never the wrong one.
		local function escape()
			if vim.trim(state.needle or "") ~= "" then
				vim.api.nvim_buf_set_lines(state.filter_buf, 0, 1, false, { "" })
			else
				vim.cmd.stopinsert()
				close()
			end
		end
		vim.keymap.set("i", "<Esc>", escape, { buffer = state.filter_buf })
		-- The same keys in normal mode, for the moment before startinsert has
		-- taken hold or after <C-o>: the three that would otherwise do nothing
		-- useful in a one line scratch buffer.
		vim.keymap.set("n", "<CR>", function()
			confirm()
		end, { buffer = state.filter_buf })
		vim.keymap.set("n", "<C-c>", close, { buffer = state.filter_buf })
		vim.keymap.set("n", "<Esc>", escape, { buffer = state.filter_buf })
		-- Arrows and the other two ways of walking a list, from the line the
		-- cursor is on, in either mode of either line.
		for _, walk in ipairs({
			{ "<Down>", 1 },
			{ "<C-n>", 1 },
			{ "<Up>", -1 },
			{ "<C-p>", -1 },
		}) do
			for _, mode in ipairs({ "i", "n" }) do
				vim.keymap.set(mode, walk[1], function()
					move(walk[2])
				end, { buffer = state.filter_buf })
			end
		end
		-- The extra keys again, in insert mode: the filter line is where the
		-- cursor is, so a key that only worked in the list would be unusable
		-- for as long as the filter is on.
		for lhs, action in pairs(opts.keys or {}) do
			vim.keymap.set("i", lhs, function()
				vim.cmd.stopinsert()
				run_action(action)
			end, { buffer = state.filter_buf })
		end
		vim.cmd.startinsert()
	end

	refilter("")
end

---The file an item is about, spelled the way its producer spelled it: the
---filename for an LSP location, the buffer's own path otherwise.
---@return string
local function path_of(item)
	return item.filename or vim.api.nvim_buf_get_name(item.bufnr)
end

---@param items table[] list of diagnostics (with .bufnr, .lnum, .col, .message, .severity, .source)
---@param title string
---@param opts? { scope?: "buffer"|"workspace" }
function M.diagnostics(items, title, opts)
	opts = opts or {}
	items = M.filter_ignored(items)
	local function confirm(item)
		if opts.scope ~= "buffer" then
			vim.cmd.buffer(item.bufnr)
		end
		vim.api.nvim_win_set_cursor(0, { item.lnum + 1, item.col })
		vim.cmd("normal! zz")
	end
	M.open(items, {
		title = title,
		filter = true,
		format = function(item)
			local sev = ({ "Err", "Warn", "Info", "Hint" })[item.severity] or "?"
			local name = vim.api.nvim_buf_get_name(item.bufnr)
			return ("[%s] %s:%d: %s"):format(sev, vim.fn.fnamemodify(name, ":."), item.lnum + 1, item.message)
		end,
		preview = function(item, ctx)
			local lines = vim.api.nvim_buf_get_lines(item.bufnr, 0, -1, false)
			ctx.set_lines(lines, vim.bo[item.bufnr].filetype)
			ctx.set_cursor(item.lnum + 1, item.col)
		end,
		on_confirm = confirm,
	})
end

---@param items table[] list of LSP locations (with .filename or .bufnr, .lnum, .col, .text)
---@param title string
function M.locations(items, title)
	M.open(items, {
		title = title,
		filter = true,
		format = function(item)
			return ("%s:%d: %s"):format(vim.fn.fnamemodify(path_of(item), ":."), item.lnum, vim.trim(item.text or ""))
		end,
		preview = function(item, ctx)
			ctx.set_file(path_of(item), item.lnum, item.col)
		end,
		on_confirm = function(item)
			local fname = path_of(item)
			vim.cmd.edit(vim.fn.fnameescape(fname))
			vim.api.nvim_win_set_cursor(0, { item.lnum, math.max((item.col or 1) - 1, 0) })
			vim.cmd("normal! zz")
		end,
	})
end

---LSP code actions, fed from `vim.ui.select` with `kind == 'codeaction'`.
---`items` are `{ action: lsp.CodeAction|lsp.Command, ctx: lsp.HandlerContext }`;
---`on_choice` is Neovim's own callback, which resolves (codeAction/resolve) and applies the edit.
---@param items table[]
---@param on_choice fun(choice:any) Neovim code_action callback
---@param format_item? fun(item:any):string label from vim.ui.select opts
function M.code_actions(items, on_choice, format_item)
	format_item = format_item
		or function(item)
			local title = item.action and item.action.title or "(unnamed)"
			return item.action and item.action.disabled and (title .. " (disabled)") or title
		end
	M.open(items, {
		title = "Code Actions",
		skip_single = false,
		filter = true,
		format = format_item,
		preview = function(item, ctx)
			local action = item.action or item
			local lines = { "Title: " .. (action.title or "") }
			if action.kind then
				table.insert(lines, "Kind:  " .. action.kind)
			end
			if action.command then
				local cmd = type(action.command) == "table" and action.command.command or tostring(action.command)
				table.insert(lines, "Command: " .. cmd)
			end
			if action.edit then
				local uris = {}
				if action.edit.documentChanges then
					for _, ch in ipairs(action.edit.documentChanges) do
						if ch.textDocument then
							table.insert(uris, ch.textDocument.uri)
						end
					end
				elseif action.edit.changes then
					for uri, _ in pairs(action.edit.changes) do
						table.insert(uris, uri)
					end
				end
				if #uris > 0 then
					table.insert(lines, "")
					table.insert(lines, ("Edits %d file(s):"):format(#uris))
					for _, uri in ipairs(uris) do
						table.insert(lines, "  " .. vim.uri_to_fname(uri))
					end
				end
			end
			if action.disabled then
				table.insert(lines, "")
				table.insert(lines, "Disabled: " .. (action.disabled.reason or "yes"))
			end
			ctx.set_lines(lines, "markdown")
		end,
		on_confirm = on_choice,
	})
end

---Filter out ignored paths (nix/store, node_modules, .venv, etc.).
---@param items { filename?: string, bufnr: integer }[]
---@return { filename?: string, bufnr: integer }[]
function M.filter_ignored(items)
	return vim.tbl_filter(function(item)
		local name = path_of(item)
		for _, pattern in ipairs(IGNORE_PATTERNS) do
			if name:match(pattern) then
				return false
			end
		end
		return true
	end, items)
end

return M
