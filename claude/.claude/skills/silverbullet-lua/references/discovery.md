# API and source discovery

Start against the selected runtime:

```sh
sb --space notes eval 'spacelua.listFunctions("space")' --json
sb --space notes eval 'spacelua.describe("space.readPage")' --json
sb --space notes eval 'spacelua.renderApiDocumentation("space")' --text
```

Call `spacelua.listFunctions()` without an argument to discover documented globals when the namespace is unknown. Prefer a relevant namespace over dumping every API. Follow returned `see` references to documentation accessible in the help space or published docs; those pages need not exist in the user's own space.

A nil `spacelua.describe` result means the target is not a recognized function, not permission to invent its parameters. `spacelua.describe("editor")` does not return namespace documentation in the current API. For custom functions, `---` Lua documentation and `@param`, `@return`, `@see`, and `@deprecated` annotations can expose structured metadata.

## Last resort: inspect SilverBullet.md

If live docs and supplied references leave behavior unclear, inspect an existing source checkout first. Otherwise clone the public SilverBullet.md repository into a fresh temporary directory outside the note space. Example for a POSIX shell:

```sh
sb_source_dir="$(mktemp -d)/silverbullet"
git clone --depth 1 https://github.com/silverbulletmd/silverbullet "$sb_source_dir"
rg -n 'system.reboot' "$sb_source_dir/client" "$sb_source_dir/plugs" "$sb_source_dir/libraries"
```

When the server's version or revision is known, prefer its corresponding tag/commit; use `--branch <verified-tag>` for a tagged shallow clone. `sb version` identifies the CLI and is not proof of the remote server version. Default-branch source may differ from the installed runtime; say so when drawing conclusions.

Search `docs/API/`, `libraries/Library/Std/`, `client/plugos/syscalls/`, `client/space_lua/`, `plugs/`, and nearby tests. Read the implementation and relevant tests for the specific API. SilverBullet.md source does not contain SilverBullet+-only APIs; inspect those through the installed `Library/Plus` documentation instead.

Keep the clone as reference material. Do not build, run setup scripts, or edit the source to solve a space scripting question. If network access is unavailable, state the unresolved detail and use available documentation rather than guessing.
