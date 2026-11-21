#!/usr/bin/env bash
# Checks the format-on-save contract. One formatter runs per save, chosen by the
# project the file belongs to:
#   1. prettier, when the repo has a prettier config (file or package.json key)
#   2. biome, when the repo has biome.json
#   3. bun fmt, when the repo has a [fmt] section in bunfig.toml
#   4. oxfmt, always available: the repo's own config, else ~/.oxfmtrc.json
# The binary is resolved from the nearest node_modules/.bin first, so a
# monorepo's hoisted prettier is used from a service subdirectory.
# Run: just test-format
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
ROOT=$PWD
export XDG_CONFIG_HOME="$(repo_config_home "$TMP/conf")"

SRC=$'const x = {a:1,b:2}\nfunction foo(){return   "hello"}\n'

# A $HOME with both configs: neither may be read as a project config.
HOME_FAKE="$TMP/home"
mkdir -p "$HOME_FAKE"
echo '{"semi": false, "singleQuote": true, "tabWidth": 4}' >"$HOME_FAKE/.oxfmtrc.json"
echo '{"semi": false}' >"$HOME_FAKE/.prettierrc"

# Every stubbed formatter names itself on stdout, so a case asserts which
# formatter ran rather than what it printed.
BIN="$TMP/bin"
mkdir -p "$BIN"
write_stub() {
	printf '#!/bin/sh\necho %s\ncat\n' "$2" >"$1"
	chmod +x "$1"
}
write_stub "$BIN/prettier" PRETTIER
write_stub "$BIN/biome" BIOME
write_stub "$BIN/bun" BUN
export PATH="$BIN:$PATH"

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

# Saves the file through nvim, which runs conform's format_on_save.
save() {
	HOME="$HOME_FAKE" nvim --headless -c "write" -c "qa!" "$1" >/dev/null 2>&1 || true
}

first_line() {
	head -1 "$1"
}

echo "1. monorepo: config at the root, file three levels down"
R=$TMP/monorepo
mkdir -p "$R/services/sales/src" "$R/node_modules/.bin"
echo '{"printWidth":120}' >"$R/.prettierrc.js"
write_stub "$R/node_modules/.bin/prettier" NODE_PRETTIER
printf '%s' "$SRC" >"$R/services/sales/src/t.ts"
save "$R/services/sales/src/t.ts"
check "hoisted node_modules/.bin/prettier wins over the one on PATH" "$(first_line "$R/services/sales/src/t.ts")" NODE_PRETTIER

echo "2. prettier config in package.json"
R=$TMP/package_json
mkdir -p "$R/src"
echo '{"name":"x","prettier":{"semi":false}}' >"$R/package.json"
printf '%s' "$SRC" >"$R/src/t.ts"
save "$R/src/t.ts"
check "package.json prettier key selects prettier" "$(first_line "$R/src/t.ts")" PRETTIER

echo "3. biome.json"
R=$TMP/biome
mkdir -p "$R/src"
echo '{}' >"$R/biome.json"
printf '%s' "$SRC" >"$R/src/t.ts"
save "$R/src/t.ts"
check "biome.json selects biome, not the prettier on PATH" "$(first_line "$R/src/t.ts")" BIOME

echo "4. bunfig.toml with a [fmt] section"
R=$TMP/bunfmt
mkdir -p "$R/src"
printf '[fmt]\nlineWidth = 100\n' >"$R/bunfig.toml"
printf '%s' "$SRC" >"$R/src/t.ts"
save "$R/src/t.ts"
check "bunfig [fmt] selects bun fmt" "$(first_line "$R/src/t.ts")" BUN

echo "5. no project config: oxfmt with the machine config"
R=$TMP/no_config
mkdir -p "$R/src"
echo '{"name":"a"}' >"$R/package.json"
printf '%s' "$SRC" >"$R/src/t.ts"
save "$R/src/t.ts"
want=$(cd "$R" && oxfmt -c "$HOME_FAKE/.oxfmtrc.json" --stdin-filepath src/t.ts <<<"$SRC")
check "machine ~/.oxfmtrc.json applies, ~/.prettierrc does not" "$(cat "$R/src/t.ts")" "$want"

echo "6. project oxfmt config beats the machine one"
R=$TMP/oxfmt_project
mkdir -p "$R/packages/app/src"
echo '{"semi": true, "singleQuote": false, "tabWidth": 2}' >"$R/.oxfmtrc.json"
printf '%s' "$SRC" >"$R/packages/app/src/t.ts"
save "$R/packages/app/src/t.ts"
want=$(cd "$R" && oxfmt -c "$R/.oxfmtrc.json" --stdin-filepath packages/app/src/t.ts <<<"$SRC")
check "project .oxfmtrc.json applies" "$(cat "$R/packages/app/src/t.ts")" "$want"

echo "7. prettier config wins over an oxfmt config in the same repo"
R=$TMP/both
mkdir -p "$R/src"
echo '{"printWidth":120}' >"$R/.prettierrc.js"
echo '{"tabWidth":2}' >"$R/.oxfmtrc.json"
printf '%s' "$SRC" >"$R/src/t.ts"
save "$R/src/t.ts"
check "prettier is first in the chain" "$(first_line "$R/src/t.ts")" PRETTIER

echo "8. files under node_modules are left alone"
R=$TMP/no_config
mkdir -p "$R/node_modules/pkg"
printf '%s' "$SRC" >"$R/node_modules/pkg/t.ts"
save "$R/node_modules/pkg/t.ts"
check "node_modules is not formatted" "$(cat "$R/node_modules/pkg/t.ts")" "$(printf '%s' "$SRC")"

echo "9. a filetype with no conform formatter goes to the LSP on the key"
cat >"$TMP/fallback.lua" <<'LUA'
local conform = require("conform")
conform.list_formatters = function()
	return {}
end
local asked = {}
vim.lsp.get_clients = function()
	return {
		{
			id = 1,
			name = "stub",
			supports_method = function()
				return true
			end,
			request = function(_, method)
				asked[#asked + 1] = method
				return true, 1
			end,
			request_sync = function(_, method)
				asked[#asked + 1] = method
				return {}, nil
			end,
		}
	}
end
vim.cmd("edit " .. vim.fn.fnameescape(assert(os.getenv("FALLBACK_FILE"))))
vim.bo.filetype = "sql"
vim.api.nvim_feedkeys(vim.keycode("<leader>cf"), "x", false)
vim.wait(500)
io.write("asked=" .. table.concat(asked, ",") .. "\n")
LUA
printf 'select 1;\n' >"$TMP/fb.sql"
FB=$(FALLBACK_FILE="$TMP/fb.sql" nvim --headless -u "$ROOT/init.lua" -i NONE \
	-c "luafile $TMP/fallback.lua" -c 'qa!' 2>&1 | sed -n 's/^asked=//p' | tail -1)
check "no conform formatter means the LSP formats it" "$FB" "textDocument/formatting"

echo "10. <leader>uf turns format-on-save off and back on"
R=$TMP/toggle
mkdir -p "$R/src"
echo '{}' >"$R/biome.json"
printf '%s' "$SRC" >"$R/src/t.ts"
OUT=$TMP/toggle.out
export FMT_OUT="$OUT"
nvim --headless -u "$ROOT/init.lua" -i NONE "$R/src/t.ts" \
	-c 'lua vim.api.nvim_feedkeys(vim.keycode("<leader>uf"), "x", false)' \
	-c 'write' \
	-c 'lua vim.fn.writefile({ "off=" .. tostring(vim.g.disable_autoformat) .. "|" .. vim.fn.getline(1) }, os.getenv("FMT_OUT"), "a")' \
	-c 'lua vim.cmd("FormatEnable")' \
	-c 'write' \
	-c 'lua vim.fn.writefile({ "on=" .. tostring(vim.g.disable_autoformat) .. "|" .. vim.fn.getline(1) }, os.getenv("FMT_OUT"), "a")' \
	-c 'qa!' >/dev/null 2>&1 || true
check "the toggle stops the formatter" "$(sed -n 's/^off=//p' "$OUT")" "true|const x = {a:1,b:2}"
check "and a second press lets it run again" "$(sed -n 's/^on=//p' "$OUT")" "false|BIOME"

exit $fail
