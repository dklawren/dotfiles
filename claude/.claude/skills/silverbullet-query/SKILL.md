---
name: silverbullet-query
description: Use when answering questions about indexed SilverBullet pages, tasks, tags, relations, custom attributes, or SLIQ queries, including optional SilverBullet+ semantic search.
---

# Query SilverBullet

Inspect `sb --help` and `sb space ls`; select an explicit `--space` or user-provided `--url`. Do not infer the target from an unrelated cwd or the sole configured space. For local work, confirm the connection corresponds to the folder; for remote work, no local copy is required. Read the selected space's operating manual with file tools or `sb fs read`.

Queries require the runtime and its index. Inspect a small sample of indexed objects to discover available fields, including custom attributes:

```sh
sb --space notes query 'from t = index.tasks() limit 3 select t' --json
```

Fields absent from the sample may exist on other objects; narrow samples to the relevant tag or pages.

Read [SLIQ](references/sliq.md) before constructing a query. Pass just the query body to `sb query`:

```sh
sb --space notes query 'from t = index.tasks() where not t.done order by t.page limit 20 select {page=t.page, task=t.name, ref=t.ref}' --json
```

Start with bounded results and only relevant fields. Retain page/ref information so answers can point back to source. A limit is a partial answer unless the task explicitly requests a sample; paginate or compute a count when completeness matters. Ordinary queries should use read-only expressions; SLIQ can call mutation-capable Lua functions.

For textual context, read the actual local page or `sb fs read` rather than answering solely from an index snippet. Queries are not full-file search. A pending index, unavailable runtime, or error is not evidence that no matches exist. After edits, verify a narrow expected result before relying on the index; do not indiscriminately reboot a space to refresh it.

For conceptual or related-page search, read [semantic search](references/semantic-search.md). It is an optional SilverBullet+ capability, not a requirement for SLIQ.
