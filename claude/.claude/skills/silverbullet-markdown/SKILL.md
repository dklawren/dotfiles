---
name: silverbullet-markdown
description: Use when authoring or interpreting SilverBullet Markdown pages, wiki links, frontmatter, tags, inline attributes, tasks, mentions, or embedded Space Lua.
---

# SilverBullet Markdown

Read the selected space's operating manual first and preserve its established style. SilverBullet stores pages as Markdown; keep prose useful when viewed outside SilverBullet.

## Pages and links

A file `Projects/Orchard.md` is the page `Projects/Orchard`. File commands use the `.md` suffix; page APIs and wiki links omit it. Wiki links are rooted at the space root, regardless of the source page's directory.

* `[[Projects/Orchard]]` links to a page.
* `[[Projects/Orchard|the project]]` adds a label.
* `[[Projects/Orchard#Decisions]]` links to a heading.
* `[[Projects/Orchard@123]]` is a position reference. Positions are UTF-16 offsets and can move after edits.

Backlinks are computed; do not maintain duplicate backlink lists. Before renaming a page, consider inbound links: a filesystem rename alone is not a link-aware rename. Inspect the supported live rename API or update affected links deliberately within the requested scope.

Use ATX headings (`#`, `##`). The filename already names the page; ordinarily start with a summary and reserve `#` for its sections. Prefer `*` bullets, one source line per prose paragraph, and compact headings with content on the next line when the space uses that style. These are authoring defaults, not parser requirements; preserve existing conventions. Use frontmatter delimiters for YAML rather than introducing decorative horizontal rules.

## Frontmatter, tags, and attributes

Frontmatter must be at the beginning of the file. Its keys become page attributes. The filename determines `name`; do not override it in YAML.

```markdown
---
tags: project active
status: planning
owner: Mira
related:
  - "[[Garden Notes]]"
---
Orchard tracks the planting proposal.

# Next steps
* [ ] Draft a planting map #work [priority: high]
* [x] Inventory tools #work
```

Space-separated bare names are the concise frontmatter `tags` convention. YAML arrays are also supported; preserve the space's chosen style. Quote wiki links in YAML values.

Hashtag scope matters: a paragraph containing only hashtags tags the page; a hashtag in ordinary prose tags that paragraph; one on an item or task tags that object. Tags such as `#project` and `#status/blocked` are useful query categories. Page and ancestor tags may also be inherited by contained objects; distinguish explicit `tags` from inherited `itags` when querying.

Inline `[key: value]` attributes attach structured YAML values to the containing object:

```markdown
A measured observation. [confidence: 0.8]

* Use the northern beds #decision [status: accepted]
* [ ] Check drainage [due: "2026-10-01"]
```

Tasks expose `done` and `state` in the index. Preserve custom task states and nesting; do not infer that every nonblank checkbox is completed without checking the live schema.

## Mentions and authorship

`@name` addresses an identity. A trailing `-- @name`, `— @name`, or `– @name` signs the block instead. A signature must end its line; it does not add another inbox item. A single hyphen or `(@name)` is not a signature.

```markdown
@helper Please check the planting dates. -- @mira
```

Frontmatter `recipients: ["helper"]` addresses the page; `authors: ["mira"]` credits the page. Page authorship does not attribute every unsigned mention in the body. Signatures are self-declared prose, not authenticated proof of identity. Use the space's actual identity conventions; owner-only spaces can use `@self`.

## Dynamic content and code

`${expression}` evaluates Space Lua and renders its value. A `space-lua` fence defines executable, space-wide code after indexing/loading. A plain `lua` fence is suitable for a displayed example that should not be installed as a space script.

````markdown
```space-lua
orchard = orchard or {}
function orchard.label()
  return "Planting plan"
end
```

${orchard.label()}
````

SLIQ inside Lua uses `query[[from p = index.pages() limit 5 select p.name]]`; inline Markdown uses `${query[[...]]}`. Keep essential facts in ordinary prose rather than only in computed output. Space Lua can perform mutations; do not evaluate untrusted page code just to read or summarize it. Inspect live API documentation before authoring nontrivial scripts or queries.
