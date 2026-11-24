# SLIQ essentials

SLIQ is Space Lua Integrated Query. Markdown produces indexed page, task, item, paragraph, header, link, and relation objects. Inspect small samples of indexed objects instead of guessing custom fields.

## Sources and syntax

| Source | Selection |
| --- | --- |
| `index.pages("project")` | Pages tagged project |
| `index.contentPages()` | Non-meta pages |
| `index.tasks("work")` | Tasks tagged work |
| `index.items("decision")` | List items tagged decision |
| `index.objects("topic")` | Any object carrying that tag |
| `index.relations("at-mention")` | Indexed addressing relations |
| `index.aspiringPages()` | Linked page names that do not exist |

Bind a variable: `from t = index.tasks()`. Use Lua `==`, `~=`, `and`, `or`, `not`, not SQL or JavaScript equality. Custom frontmatter is page data; inline attributes belong to their enclosing objects. Explicit tags and inherited tags differ.

```sliq
from p = index.pages("project")
where p.status == "planning"
order by p.name
limit 20
select {page=p.name, owner=p.owner}
```

Clauses include `where`, `order by`, `group by`, `having`, `select`, `limit`, and `offset`. Explore with a limit, and use stable ordering when paging; index changes during pagination can affect results.

After grouping, `key` is the group key and `group` is the row array:

```sliq
from t = index.tasks()
where not t.done
group by t.page
select {page=key, count=#group}
order by count desc
```

String helpers include `s:startsWith("x")` and `s:contains("x")`; use nil checks for optional attributes. `table.includes(t, value)` checks membership. Project `{page=t.page, task=t.name, ref=t.ref}` rather than dumping every attribute.

## CLI versus embedded queries

`sb --space notes query 'from p = index.pages() limit 5 select p.name' --json` takes the body only. In Lua use `query[[from p = index.pages() limit 5 select p.name]]`; in Markdown use `${query[[...]]}`. CLI wrapping uses `[[...]]`, so do not embed a literal `]]` into a query argument. Keep arbitrary untrusted text out of generated code.

The index is derived and asynchronous. Confirm freshness when a recent edit should affect the answer. Live runtime access can be unavailable while HTTP file access still works. If falling back to reading Markdown, state that the result is a file-based inspection rather than an exhaustive index query.
