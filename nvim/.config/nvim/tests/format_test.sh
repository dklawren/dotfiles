#!/usr/bin/env bash
# Checks the format-on-save contract:
#   1. No oxfmt config in the project  -> nothing formats a TS buffer.
#   2. oxfmt config in a parent dir    -> oxfmt formats, and vtsls does not
#                                         re-indent the result afterwards.
# Fails loudly if either breaks. Run: just test-format
set -euo pipefail

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SRC=$'const x = {a:1,b:2}\nfunction foo(){return   "hello"}\n'

# Project without an oxfmt config.
mkdir -p "$TMP/no_config/src"
echo '{"name":"a"}' >"$TMP/no_config/package.json"
printf '%s' "$SRC" >"$TMP/no_config/src/t.ts"

# Project with the config at the root and the file nested two levels down.
mkdir -p "$TMP/with_config/packages/app/src"
echo '{"name":"b"}' >"$TMP/with_config/package.json"
echo '{"name":"app"}' >"$TMP/with_config/packages/app/package.json"
echo '{"semi": false, "singleQuote": true, "tabWidth": 4}' >"$TMP/with_config/.oxfmtrc.json"
printf '%s' "$SRC" >"$TMP/with_config/packages/app/src/t.ts"

cat >"$TMP/save.lua" <<'LUA'
-- Give the servers time to attach, save (triggers BufWritePre), then dump.
vim.defer_fn(function()
  vim.cmd('write')
  vim.defer_fn(function()
    io.stderr:write('<<<' .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') .. '>>>\n')
    vim.cmd('qa!')
  end, 2000)
end, 5000)
LUA

save_and_dump() {
	(cd "$1" && nvim --headless -c "source $TMP/save.lua" "$2" 2>&1) |
		sed -n 's/.*<<<\(.*\)/\1/p;/>>>/q' >/dev/null
	cat "$1/$2"
}

fail=0
check() {
	if [ "$2" = "$3" ]; then
		echo "ok   - $1"
	else
		echo "FAIL - $1"
		echo "  want: $(printf '%q' "$3")"
		echo "  got : $(printf '%q' "$2")"
		fail=1
	fi
}

echo "1. project without oxfmt config"
save_and_dump "$TMP/no_config" src/t.ts >/dev/null
check "buffer left untouched" "$(cat "$TMP/no_config/src/t.ts")" "$(printf '%s' "$SRC")"

echo "2. oxfmt config in a parent directory"
save_and_dump "$TMP/with_config" packages/app/src/t.ts >/dev/null
want=$(cd "$TMP/with_config" && oxfmt --stdin-filepath packages/app/src/t.ts <<<"$SRC")
check "matches oxfmt CLI (config tabWidth wins, no vtsls re-indent)" \
	"$(cat "$TMP/with_config/packages/app/src/t.ts")" "$want"

exit $fail
