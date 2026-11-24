---
name: silverbullet-local
description: Use when reading, searching, or editing a SilverBullet space whose Markdown files are accessible in a local folder, including a synced local copy. For spaces without accessible local files, use silverbullet-remote.
---

# Local SilverBullet spaces

Confirm the intended space root, then use ordinary file tools. Local Markdown work needs neither `sb` nor a running SilverBullet instance.

Read the space's applicable operating manual (`AGENTS.md`, `CLAUDE.md`, or user-specified instructions) and the shared [silverbullet-markdown skill](../silverbullet-markdown/SKILL.md) before authoring content. Anchor paths and searches to that root; do not confuse a repository root with a nested note space.

## Work on files

1. Find relevant files with filename/content search, such as `rg --files` and `rg -n`, within the confirmed root. Read the surrounding page before editing.
2. Make focused changes, preserving existing content and conventions. Re-read current bytes before replacing a previously inspected file. Use the file tool's exact-match/conflict handling when available.
3. Read the changed content back and check links and requested behavior. Explain which pages changed.

A synced folder remains a local workflow. Do not switch to its remote copy midway. Filesystem search sees literal Markdown, including code examples; it does not reproduce the task or mention index. Computed/indexed questions need live queries, or an explicitly limited text-based answer if no runtime is available.

## Optional live capabilities

For live operations, check `sb --help`, inspect `sb space ls`, and select an explicit `--space` matching this folder. Listing is human-readable; do not assume `--json` works for it or rely on the CLI's sole-space fallback. Ask if the match is ambiguous.

Use `sb --space notes query 'from t = index.tasks() where not t.done limit 20' --json` for indexed tasks. Queries and Lua require a runtime; file editing does not. Native `sb open /absolute/path/Page.md` is available only in CLI builds that advertise it. Register/open a folder only when the user's request calls for it, rather than as a prerequisite to editing text.