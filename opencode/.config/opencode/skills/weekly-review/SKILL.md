---
name: weekly-review
description: >
  Guided weekly review following GTD 3-phase process (Get Clear → Get Current →
  Get Creative). Queries the Silverbullet vault for inbox items, project health,
  task statuses, and waiting-for items. Helps set #week priorities for the week
  ahead. Trigger: "weekly review", "start review", "weekly", "review week".
---

# Weekly Review Skill

Implements the GTD weekly review process using the PKMS vault.
The vault has a `Library/Custom/Templates/Weekly Review` template for reference.

Phases follow GTD: **Get Clear** → **Get Current** → **Get Creative**.

## Phase 1: Get Clear (Collect & Process)

### 1a: Brain dump prompt

Start with: "Before we dive in, anything on your mind? Write it down first."
Give user space to dump thoughts, then proceed.

### 1b: Check inbox

Query inbox items:

```sliq
from p = index.pages()
where p.name:startsWith("Inbox/") and p.name != "Inbox/README"
order by p.lastModified desc
```

Report count and list with last-modified dates.
If >5 items, suggest prioritizing oldest first.
If none, mark "Inbox clear ✓".

### 1c: Review past week's daily journals

List journal entries from the past 7 days:

```sliq
from p = index.pages("journal")
where p.lastModified >= os.date('%Y-%m-%d', os.time() - 7*86400)
order by p.name desc
```

For each journal, read and extract:
- Incomplete tasks that were due during the week
- Ideas tagged `#idea`
- Any tasks in the Log section

Prompt: "Any loose ends from this week's journals to capture?"

## Phase 2: Get Current (Update Your System)

### 2a: Review next actions

Query all `#next` tasks:

```sliq
from t = index.tasks()
where not t.done
  and table.includes(t.tags, "next")
order by t.priority asc, t.due asc
```

List them grouped by project page (t.page).
Check: are any done that should be marked? Are any stale (created >2 weeks ago)?
Suggest moving stale `#next` items to `#someday` or archiving.

### 2b: Review active projects

Query active projects:

```sliq
from p = index.pages()
where p.name:startsWith("Projects/")
  and p.state == "active"
order by p.lastModified desc
```

For each project:
1. Read the project page
2. Check it has at least one `#next` task on the page
3. Check last modified date - flag if >2 weeks stale
4. Check status field is set

Present table:
```
Project                    Next Action?   Last Modified    Stale?
────────────────────────────────────────────────────────────
Project A                  Yes            Jul 25           No
Project B                  NO             Jul 01           YES ⚠️
```

For each project missing a next action: "Project '{name}' has no next action. Can you add one, or should it move to on-hold/archive?"

### 2c: Review waiting-for items

```sliq
from t = index.tasks()
where not t.done
  and table.includes(t.tags, "waiting")
order by t.due asc
```

List with due dates. Flag any overdue waiting items.
Prompt: "Follow up on overdue waiting items?"

### 2d: Review calendar

Prompt: "Check your calendar for next week. Any events that need prep or create tasks?"
Integrate with external calendar if available; otherwise note the reminder.

## Phase 3: Get Creative (Look Ahead & Plan)

### 3a: Select #week priorities

From the `#next` task pool, suggest 3-5 tasks to promote to `#week`:
- Prioritize overdue or soon-due tasks
- Include tasks from at-risk projects (stale, missing actions)
- Mix of work and personal if applicable

User confirms selection. Update task tags via edit:
- Change `#next` to `#week` on selected tasks (or add `#week` alongside)
  - Convention: replace `#next` with `#week` (each task has ONE status tag)

### 3b: Review someday/maybe

```sliq
from t = index.tasks()
where not t.done
  and table.includes(t.tags, "someday")
order by t.page
```

List all. Ask: "Any of these ready to become active? Any to delete/archive?"
If any promoted to `#next`, update tag.

```sliq
from p = index.pages()
where p.name:startsWith("Someday/")
order by p.lastModified desc
```

Same review for Someday pages.

### 3c: Review areas

```sliq
from p = index.pages("area")
order by p.name
```

Quick check: "Any area need attention? New project needed for any area?"
Focus on Health, Career, Finance, Home.

## Week Ahead Planning

### Set top 3 priorities for the week

From the `#week` tasks just set, identify top 3.
Present to user for confirmation.
These become the anchor for daily morning briefings all week.

### Check routines for next week

Read `Routines.md` and highlight weekly items due in the coming days.
Flag any that conflict with planned tasks.

## Weekly Review Completion

When done, optionally create a weekly review note:
- Prompt: "Want to log this review to a weekly note?"
- If yes, open `Library/Custom/Templates/Weekly Review` in SB for user to fill

Final summary:
```
✅ Weekly Review Complete
─────────────────────
📥 Inbox: {n} items → processed
📋 Projects: {n} active, {n} need attention
🎯 This Week: {n} tasks set
⏸️ Waiting: {n} items
💡 Someday: {n} items reviewed
```

## Implementation Notes

- Use `silverbullet_query` for all index queries
- Use `read` for project pages, `edit` for tag/status changes
- Tag convention: `#week` (not `#todo/week`) for this-week priorities
- Each task gets exactly ONE status tag (#next/#week/#waiting/#someday)
- When promoting, replace `#next` → `#week` on the task line
- Today's date: `os.date('%Y-%m-%d')` in Lua context
