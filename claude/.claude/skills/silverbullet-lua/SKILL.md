---
name: silverbullet-lua
description: Use when writing, inspecting, or debugging SilverBullet Space Lua functions, commands, live expressions, configuration, or views, or when discovering their APIs.
---

# Space Lua

Select the target with `sb space ls` and explicit `--space` (or a user-provided `--url`). Local file editing can work offline; Lua execution needs the selected space's runtime. Read the space's operating manual and the shared [silverbullet-markdown skill](../silverbullet-markdown/SKILL.md) when editing pages. Inspect `sb --help` before using unfamiliar commands.

## Discover before implementing

Use the live API documentation rather than guessing names or signatures:

```sh
sb --space notes eval 'spacelua.listFunctions("editor")' --json
sb --space notes eval 'spacelua.describe("editor.getText")' --json
sb --space notes eval 'spacelua.renderApiDocumentation("editor")' --text
```

`describe` accepts a function or dotted function name; namespace discovery uses `listFunctions` or `renderApiDocumentation`. Inspect parameters, returns, examples, and `see` links. Runtime capabilities vary by version and installed libraries. If documentation is insufficient, follow [API and source discovery](references/discovery.md), including a last-resort clone of SilverBullet.md.

## Author and verify

Read [runtime and reload](references/runtime.md) before installing a `space-lua` block. Use a plain `lua` fence for an inert example. Prefer a small named namespace; preserve the space's existing design and APIs.

Use local file tools for an accessible folder, or `sb fs read/edit/write` for a remote-only space, retaining the inspected revision for conditional writes. `sb eval` evaluates one expression; `sb script --file script.lua` or stdin runs multiple statements. End scripts with `return` to obtain a result. Print output goes to runtime logs, not the returned value.

Verify new logic with narrow calls, inspect `sb --space notes logs -n 50`, and confirm saved content and expected results. Reload only after handling any open unsaved buffer: reboot saves it before refreshing files. A successful process, empty stdout, or a ready runtime does not establish that the user's script loaded correctly. Report syntax/runtime failures precisely and repair only the requested code.
