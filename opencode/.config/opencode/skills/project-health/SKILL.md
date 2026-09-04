---
name: project-health
description: >
  Audit all active projects in the PKMS vault. Checks for stale status,
  missing next actions, overdue linked tasks, and projects without recent
  updates. Produces a health report. Trigger: "project health", "check projects",
  "audit projects", "stale projects", "project status".
---

# Project Health Skill

Audits active projects in `Projects/` folder. Identifies neglect and
suggests concrete actions (add next action, move to on-hold, archive).

Project health rules:
- Every active project MUST have at least one `#next` task
- Projects with no update in 2+ weeks are stale
- Projects with overdue linked tasks need attention
- Projects on-hold for 3+ months → archive or move to Someday

## Step 1: Fetch all active projects

```sliq
from p = index.pages()
where p.name:startsWith("Projects/")
  and p.state == "active"
order by p.lastModified desc
```

Also fetch non-active for reference:

```sliq
from p = index.pages()
where p.name:startsWith("Projects/")
  and p.state != "active"
order by p.state, p.lastModified desc
```

## Step 2: Deep-inspect each active project

For each active project, read the page file and gather:

### 2a: Next action check

Query tasks on the project page:

```sliq
from t = index.tasks()
where not t.done
  and t.page == "{project_name}"
  and table.includes(t.tags, "next")
```

If count == 0: ⚠️ **Missing next action**

### 2b: Staleness check

Compare last modified date to 14 days ago.
- If `lastModified < 14 days ago`: ⚠️ **Stale** (no recent activity)
- If `lastModified < 30 days ago`: 🔴 **Very stale** (consider on-hold/archive)

### 2c: Overdue task check

```sliq
from t = index.tasks()
where not t.done
  and t.page == "{project_name}"
  and t.due and t.due < os.date('%Y-%m-%d')
```

If count > 0: ⚠️ **{n} overdue tasks**

### 2d: Waiting items check

```sliq
from t = index.tasks()
where not t.done
  and t.page == "{project_name}"
  and table.includes(t.tags, "waiting")
```

List with expected dates.

### 2e: Outcome check

Read project page frontmatter and first section after `## Outcome`.
If outcome section is empty or just template text: ⚠️ **No clear outcome defined**

## Step 3: Generate health report

Present as a table:

```
PROJECT HEALTH REPORT — {date}
═══════════════════════════════════════════════════
Project                   Next  Stale  Overdue  Waiting  Health
───────────────────────────────────────────────────────────────
Project A                 ✅    ✅     ✅       ✅       ✅ Good
Project B                 ⚠️    ✅     ✅       ✅       ⚠️ Needs next action
Project C                 ✅    ⚠️     ⚠️ 2    ✅       ⚠️ Stale + overdue
Project D                 ⚠️    🔴     ✅       ✅       🔴 Very stale, no next action
```

Color coding:
- ✅ - healthy
- ⚠️ - needs attention  
- 🔴 - critical

## Step 4: Suggest actions per project

For each project with issues, prompt:

| Issue | Suggestion |
|---|---|
| Missing next action | "Add a `#next` task to {project}. What's the next concrete step?" |
| Stale (2-4 weeks) | "Still active? Add a status update or next action, or set state to on-hold." |
| Very stale (4+ weeks) | "Move to on-hold or archive? If still active, what's the plan?" |
| Overdue tasks | "{n} tasks overdue: extend dates, do them now, or drop them?" |
| No outcome | "Define the outcome for {project} - what does 'done' look like?" |

Execute user's decisions:
- Edit project page to add next action as `- [ ] #next {action}`
- Update frontmatter `state:` field (e.g., `state: onhold`)
- Edit overdue task dates
- If archiving: move file to `Archive/{year}/{project}.md`

## Step 5: Quick view of non-active projects

Show count of planned, on-hold, idea, completed projects:

```
Pipeline: {n} idea → {n} planned → {n} active → {n} on-hold → {n} completed
```

If any on-hold for 3+ months, flag for archive.

## Implementation Notes

- Use `silverbullet_query` for index queries
- Use `read` for project pages, `edit` for modifications
- Use `glob` to list project files if index is unreliable
- For "weeks since modified": compare mtime from file system or `p.lastModified`
- Use `bash` with `date` command if Lua date math is awkward
- Tag convention: `#next` for next actions, `#week` for weekly commitments
