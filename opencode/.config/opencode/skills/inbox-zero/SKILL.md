---
name: inbox-zero
description: >
  Process the Inbox/ folder in the PKMS vault. Lists pending inbox items,
  helps classify each one (task, project, reference, knowledge, trash), and
  executes the filing. Uses the Inbox Processing Guide from Inbox/README.md.
  Trigger: "process inbox", "inbox zero", "empty inbox", "inbox processing".
---

# Inbox Zero Skill

Processes items in the `Inbox/` folder (organized as `Inbox/YYYY-MM-DD/HH-MM-SS.md`).
Follows the GTD processing workflow from `Inbox/README.md`.

Classification decisions:
1. **Actionable, single-step** (≤2 min: do now; >2 min: create task with tag)
2. **Actionable, multi-step** → Create project page
3. **Reference** → Move to `Resources/`
4. **Knowledge** → Create note in `Knowledge/`
5. **Trash** → Delete or move to `trash/`
6. **Someday** → Add to `Someday/` or tag with `#someday`

## Step 1: List inbox items

```sliq
from p = index.pages()
where p.name:startsWith("Inbox/")
  and p.name != "Inbox/README"
order by p.name asc
```

If none: "Inbox is empty! ✓"
If count > 10: suggest batching (process 5 now, rest later).

Present as numbered list:
```
📥 INBOX ({n} items)
─────────────────────
1. {name} ({date})
2. {name} ({date})
...
```

## Step 2: Process each item

For each inbox file:

### 2a: Read and display content

Read the file and show content to user.
Keep it brief - show first ~20 lines or key content.

### 2b: Classify

Ask: "What is this?"
Options with brief guidance:

| Option | When | Action |
|---|---|---|
| **Task** (do now) | Takes <2 min | Do it immediately, mark done, archive note |
| **Task** (defer) | Single action, >2 min | Create `#next` task with due date if applicable, archive note |
| **Project** | Multi-step, has outcome | Create project page, add first next action, archive note |
| **Reference** | Info to keep, no action | Move to `Resources/{category}/` |
| **Knowledge** | Things to learn/explore | Move to `Knowledge/` or tag as `#idea` |
| **Someday** | Maybe later | Tag with `#someday` and move to Someday/ |
| **Trash** | No value | Delete file or move to `trash/` |

### 2c: Execute

Based on user's choice:

**Task (defer):**
- Edit inbox file to convert to task format: `- [ ] {content} #next [due:: {date}]`
- Or create task in appropriate project page
- Then delete/move original inbox file

**Project:**
- Create project file from template: frontmatter with `state: active`, tags, outcome section
- Add first `#next` action
- Delete inbox file

**Reference:**
- Move file to `Resources/{category}/` (suggest category based on content)
- Or `bash mv` to relocate

**Trash:**
- `bash mv` to `trash/` folder (recoverable holding area)

**Someday:**
- Rewrite content as task with `#someday` tag in Someday/ page
- Or move file to `Someday/` folder

### 2d: Mark progress

After each item, show remaining count: "Done. {n-1} items remaining."

## Step 3: Summary

When inbox is empty:
```
✅ Inbox Zero! ({n} items processed)
─────────────────────
📋 {count} tasks created
📁 {count} projects created
📚 {count} filed as reference
💡 {count} moved to someday
🗑️ {count} trashed
```

## Handling Attachments

Inbox items may have links or references to attachments.
If an inbox note references external files or URLs:
- Include them in the target note/task as `[link](url)`
- For local files, include the path

## Edge Cases

- **Empty inbox note**: Delete it, no classification needed
- **Multiple topics in one note**: Split by suggesting user creates separate items
- **Vague content**: Flag it: "This seems vague. Can you clarify before I file it?"
- **Large inbox (20+)**: Process in batches of 5-10, ask to continue or save for later

## Implementation Notes

- Use `read` to read inbox files (limit to 20-30 lines for display)
- Use `glob` pattern `Inbox/**/*.md` to find items (backup if index stale)
- Use `silverbullet_query` for index lookups when needed
- Use `edit` to convert content to proper format
- Use `bash` with `mv` for file moves (or file rename if available)
- Files moved to `trash/` are excluded from indexing via `sync.ignore` in CONFIG.md
- After changes, call `silverbullet_reload` then `silverbullet_get_logs` to verify
