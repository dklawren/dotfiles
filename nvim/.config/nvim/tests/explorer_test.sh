#!/usr/bin/env bash
# Run: bash tests/explorer_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib.sh

# A directory is what `nvim .` and `nvim some/folder` hand the editor, and
# without oil claiming it there is nothing to do with that buffer: it is empty.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export XDG_CONFIG_HOME="$(repo_config_home "$TMP/conf")"
printf 'x\n' >"$TMP/a.txt"
mkdir -p "$TMP/sub"
printf 'y\n' >"$TMP/sub/b.txt"

dir_ft=$(nvim --headless -u "$PWD/init.lua" -i NONE "$TMP" \
	-c 'lua vim.wait(1200) io.write("ft=", vim.bo.filetype, "\n")' \
	-c 'qa!' 2>&1 | sed -n 's/^ft=//p' | tail -1)
dir_lines=$(nvim --headless -u "$PWD/init.lua" -i NONE "$TMP" \
	-c 'lua vim.wait(1200) io.write("lines=", vim.api.nvim_buf_line_count(0), "\n")' \
	-c 'qa!' 2>&1 | sed -n 's/^lines=//p' | tail -1)
file_out=$(nvim --headless -u "$PWD/init.lua" -i NONE "$TMP/a.txt" \
	-c 'lua vim.wait(800) io.write("ft=", vim.bo.filetype, "\n")' \
	-c 'qa!' 2>&1 | sed -n 's/^ft=//p' | tail -1)

# The directory oil shows after `-`, read from the listing itself.
oil_dir() {
	nvim --headless -u "$PWD/init.lua" -i NONE "$1" \
		-c "lua vim.wait(1200) vim.api.nvim_feedkeys('-', 'x', false) vim.wait(2000, function() return vim.bo.filetype == 'oil' end) local ok, dir = pcall(require('oil').get_current_dir) io.write('dir=', ok and dir or 'none', '\n')" \
		-c 'qa!' 2>&1 | sed -n 's/^dir=//p' | tail -1
}
file_dir=$(oil_dir "$TMP/sub/b.txt")
up_dir=$(oil_dir "$TMP/sub")

fail=0
if [[ "$dir_ft" != "oil" ]]; then
	echo "FAIL a directory opens a listing, got: $dir_ft"
	fail=1
fi
if [[ "$dir_lines" -lt 2 ]]; then
	echo "FAIL the listing has rows, got: $dir_lines"
	fail=1
fi
if [[ "$file_out" == "oil" ]]; then
	echo "FAIL a file argument still opens as itself, got oil"
	fail=1
fi
# `-` on a file opens the folder the file is in, and on a listing it steps one
# folder up. It walked the wrong way for a while, and a fix that put it back
# was followed by another that moved it again.
want_dir=$(cd "$TMP/sub" && pwd -P)
if [[ "${file_dir%/}" != "$want_dir" ]]; then
	echo "FAIL - on a file opens the folder the file is in, got: $file_dir"
	fail=1
fi
want_up=$(cd "$TMP" && pwd -P)
if [[ "${up_dir%/}" != "$want_up" ]]; then
	echo "FAIL - on a listing steps one folder up, got: $up_dir"
	fail=1
fi
if [[ $fail -eq 0 ]]; then
	echo "explorer checks=5 failures=0"
	echo "explorer tests passed"
fi
exit $fail
