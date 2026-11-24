# Mention results and replies

`identity.mentions(recipient, options)` queries `at-mention` and page-level `recipients` relations, filters completed tasks, and returns a bounded list sorted by page and position. It relies on the index to distinguish signatures and code examples from addressing mentions. `total` counts matches before limiting and `truncated` reports whether more matches remain after the current page. `offset` defaults to zero; omitting `limit` returns all remaining matches.

Each entry includes `kind`, `page`, `ref`, `target`, optional `pos`, `snippet`, optional `fromTag`, `inComment`, and available authors (`by`) and `replyTo`. Ordinary mentions reply to the first signed author when present; otherwise they use `identity.own()`. Multiple authors remain in `by` so the reader can choose appropriately from context. Owner-only spaces can return `self`; anonymous contexts may have no reply target. Page-level recipients currently use the current identity fallback; inspect page authorship before deciding whom to address.

`pos` is a UTF-16 position, not a line or byte offset. Read the page and locate the surrounding text; use `ref` for a native page reference where supported. Local filenames append `.md` to the page name. Remote results have no invented filesystem path. Positions/snippets are a snapshot and can become stale after edits.

An example exchange:

```markdown
@mira The planting dates are updated. -- @helper
```

The trailing `-- @helper` signs the block and must end its line. It does not address helper again. The original `@helper` request still queues until removed/redirected or its containing task is completed. A paragraph's signature does not prove authenticated authorship. Frontmatter `authors:` credits the page; it does not automatically sign every body mention. Frontmatter `recipients:` is a page-level request and must be handled as such.
