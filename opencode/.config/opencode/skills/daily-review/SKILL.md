---
name: daily-review
description: >
  Proactive morning briefing and evening shutdown for the PKMS vault.
  Queries Silverbullet index for due/overdue tasks, #week priorities, and
  today's journal. Helps set top 3 priorities in morning and log wins/update
  stale items in evening. Trigger: "daily review", "morning briefing",
  "evening shutdown", "start day", "end day", "check today".
---

# Daily Review Skill

This skill helps run a daily review cycle using the PKMS Silverbullet vault.
It has two modes: **morning briefing** and **evening shutdown**.

The vault uses these conventions:
- Tasks stored as markdown checkboxes with tags: `#next`, `#week`, `#waiting`, `#someday`
- Domain tags: `#work`, `#personal`
- Daily journal at `Journal/YYYY-MM-DD.md` created from `Library/Custom/Templates/Journal`
- Routines at `Routines.md`
- Dashboard at `Home.md`
- Tagging system docs: `Documentation/Tagging System Reference.md`

## Morning Briefing

Run when user says "daily review", "morning briefing", "start day", "check today".

### Step 1: Fetch today's context

Run Silverbullet queries in parallel:

```sliq
from t = index.tasks()
where not t.done
  and ((t.due and t.due <= os.date('%Y-%m-%d'))
    or (t.scheduled and t.scheduled <= os.date('%Y-%m-%d')))
order by t.due
```

```sliq
from t = index.tasks()
where not t.done
  and table.includes(t.tags, "week")
order by t.priority asc
```

```sliq
from t = index.tasks()
where not t.done
  and table.includes(t.tags, "next")
order by t.priority asc
```

Check if today's journal page exists: `Journal/{today}.md`.
If not, open it in SB so user can create via template.

### Step 2: Present summary

Present a compact summary:

```
📅 {date}
─────────────────────
🔴 Due/Overdue:  {count} tasks
📌 This Week:    {count} tasks
🔥 Next Actions: {count} tasks
```

List due/overdue tasks with: `[ ] {name} (#{tags}) [due: {date}]`
List top 3-5 `#week` tasks.
Flag any tasks due today that aren't tagged `#week`.

### Step 3: Suggest Top 3

If today's journal exists and has empty "Today's Top 3 Priorities", suggest:
- 1 task from highest-priority `#week` item
- 1 task that's due today or overdue
- 1 small/quick task for a win

Ask user to confirm or override. Optionally edit the journal to fill them.

### Step 4: Open dashboard

Open `Home.md` in SB so user sees the full dashboard.

## Evening Shutdown

Run when user says "evening shutdown", "end day", "close day", "wrap up".

### Step 1: Check today's journal

Read today's journal at `Journal/{today}.md`.
Look for:
- Incomplete tasks that were due today
- Empty sections (Notes, Log)
- Tasks with `[due:: {today}]` that aren't done

### Step 2: Suggest updates

For each incomplete task due today:
- Prompt: "Move to tomorrow, retag as `#next`, or archive?"
- If moving: edit the task's `[due::]` to tomorrow's date

### Step 3: Log wins

If the "Log" or "Notes" section in today's journal is empty, prompt:
"What did you get done today? Any wins or blockers?"
If user responds, append to the Log section.

### Step 4: Quick check for tomorrow

List any `#next` tasks without due dates that could be scheduled.
Prompt: "Want to set any of these for tomorrow?"

### Routines reminder

Check today's routine items in `Routines.md`:
- Daily routines with `[repeat:: every day]` - ask if all done
- Weekly routines due today - flag if not done

## Implementation Notes

- Use `silverbullet_query` for index queries (pass SLIQ body starting with `from`)
- Use `read` for file content, `edit` for markdown changes
- Use `silverbullet_open` to open pages in SB
- Today's date: use `os.date('%Y-%m-%d')` in Lua, or calculate from context
- Tag convention: use `#week` (not `#todo/week`) for this-week tasks
