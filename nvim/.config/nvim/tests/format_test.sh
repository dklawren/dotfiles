#!/usr/bin/env bash
# Checks the format-on-save contract:
#   1. No oxfmt config anywhere       -> oxfmt formats with its built-in defaults.
#   2. Global ~/.oxfmtrc.json only    -> oxfmt formats with the global config.
#   3. oxfmt config in a parent dir   -> project config wins over global, and
#                                        vtsls does not re-indent the result after.
# Fails loudly if any of these break. Run: just test-format
set -euo pipefail

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

SRC=$'const x = {a:1,b:2}\nfunction foo(){return   "hello"}\n'

# Two fake $HOMEs so the test doesn't depend on, and can't collide with, the
# developer's real global config.
FAKE_HOME_EMPTY="$TMP/home_empty"
FAKE_HOME_GLOBAL="$TMP/home_global"
mkdir -p "$FAKE_HOME_EMPTY" "$FAKE_HOME_GLOBAL"
echo '{"semi": false, "singleQuote": true, "tabWidth": 4}' >"$FAKE_HOME_GLOBAL/.oxfmtrc.json"

# 1. No config anywhere.
mkdir -p "$TMP/no_config/src"
echo '{"name":"a"}' >"$TMP/no_config/package.json"
printf '%s' "$SRC" >"$TMP/no_config/src/t.ts"

# 2. No project config, but a global one at $FAKE_HOME_GLOBAL/.oxfmtrc.json.
mkdir -p "$TMP/global_only/src"
echo '{"name":"a"}' >"$TMP/global_only/package.json"
printf '%s' "$SRC" >"$TMP/global_only/src/t.ts"

# 3. Project config at the root, file nested two levels down. Global config
#    (same $FAKE_HOME_GLOBAL) must lose to it.
mkdir -p "$TMP/with_config/packages/app/src"
echo '{"name":"b"}' >"$TMP/with_config/package.json"
echo '{"name":"app"}' >"$TMP/with_config/packages/app/package.json"
echo '{"semi": true, "singleQuote": false, "tabWidth": 2}' >"$TMP/with_config/.oxfmtrc.json"
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
	local home="$1" dir="$2" file="$3"
	(cd "$dir" && HOME="$home" nvim --headless -c "source $TMP/save.lua" "$file" 2>&1) |
		sed -n 's/.*<<<\(.*\)/\1/p;/>>>/q' >/dev/null
	cat "$dir/$file"
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

echo "1. no config anywhere"
save_and_dump "$FAKE_HOME_EMPTY" "$TMP/no_config" src/t.ts >/dev/null
want=$(cd "$TMP/no_config" && HOME="$FAKE_HOME_EMPTY" oxfmt --stdin-filepath src/t.ts <<<"$SRC")
check "matches oxfmt CLI defaults" "$(cat "$TMP/no_config/src/t.ts")" "$want"

echo "2. global config only, no project config"
save_and_dump "$FAKE_HOME_GLOBAL" "$TMP/global_only" src/t.ts >/dev/null
want=$(cd "$TMP/global_only" && oxfmt -c "$FAKE_HOME_GLOBAL/.oxfmtrc.json" --stdin-filepath src/t.ts <<<"$SRC")
check "matches oxfmt CLI with global config" "$(cat "$TMP/global_only/src/t.ts")" "$want"

echo "3. project config wins over global"
save_and_dump "$FAKE_HOME_GLOBAL" "$TMP/with_config" packages/app/src/t.ts >/dev/null
want=$(cd "$TMP/with_config" && oxfmt --stdin-filepath packages/app/src/t.ts <<<"$SRC")
check "matches oxfmt CLI (project config wins, no vtsls re-indent)" \
	"$(cat "$TMP/with_config/packages/app/src/t.ts")" "$want"

exit $fail
