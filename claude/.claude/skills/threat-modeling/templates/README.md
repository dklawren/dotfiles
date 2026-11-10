# threat-modeling: output profile templates

A **profile** is an extra artifact rendered from the finished threat model,
shaped for a specific audience or downstream consumer. Profiles never change
the analysis — the same schema-conformant `THREAT_MODEL.md` is always built
first; a profile is a *view* of it.

## How it works

1. Profiles are selected at the Step 0.7 kickoff (interactive) or with
   `--profile <name>[,<name>...]` (non-interactive). Selected profiles are
   recorded in the provenance block.
2. At render time (after `THREAT_MODEL.md` passes emit verification and the
   review gates, before the detail pass and the `COMPLETE` marker), the skill
   reads `templates/<name>.md` — **at that point, not earlier** — and
   follows it: the template's frontmatter says which schema sections feed
   it, what file(s) it writes, and its commit-guidance class; the body is the
   output structure with `{{placeholders}}` and per-section fill guidance in
   `> fill:` blockquotes.
3. Output lands in the run directory as the file(s) named in the template's
   frontmatter.
4. To render a new or edited template against an already-finished run
   without redoing analysis, use `render` mode (see `SKILL.md` Step 1 /
   README Usage) — COMPLETE run dirs are never modified.

## Built-in profiles

| Profile | Audience / consumer | Output | Commit guidance (`disclosure`) |
|---|---|---|---|
| `rra` | Risk owners; rapid-risk-assessment reviewers | `RRA.md` or `RRA-ENTRY.md` — exactly one of the two per render, chosen by mode: fresh doc and decision record (dependency/vendor choices) write `RRA.md` (house-format Mozilla RRA: header table, Service Notes, Data Dictionary, CIA threat scenarios with Standard-Levels labels, risk-labeled recommendations); living-log entry for a "[main]" doc (pairs with `--prior` drift runs) writes `RRA-ENTRY.md` | restricted by default |
| `general` | Engineers, design reviewers, wiki readers | `THREAT_MODEL_narrative.md` — prose walkthrough of the model | restricted by default |
| `ai-scan` | AI vulnerability scanners and harnesses | `ATTACK_SURFACE.yaml` + `SCAN-SEEDS.md` — machine-oriented scan handoff | **always restricted** (detail class d) |

## Adding or editing a profile

Drop `templates/<name>.md` into this directory (or edit a built-in). Required
frontmatter:

```yaml
---
name: <profile-name>          # what --profile matches
output: <one or more filenames>   # written into the run dir
consumes: [1, 2, 3, 3b, 4, 6, 8]  # schema sections this view reads;
                                  # "working notes" is allowed for ai-scan only
audience: <one line>
disclosure: public | restricted   # see rule below
---
```

Rules for template authors:

- **Disclosure rule (commit guidance for the whole file):** profiles
  render from the complete working model, before the detail pass, so an
  output is **`restricted` unless** the template declares `disclosure:
  public` *and* reads only public rows and cells (the `schema.md` tight-list
  classes a-d never appear). Since v2.2.0 there is no restricted edition to
  file these under: `restricted` means "written in full at either detail
  level, carries a not-for-public-repos header, exempt from the detail
  lint, and must not be committed into a public repo" — keep it with the
  private scan findings instead. `public` outputs take the run's detail
  level and are in the detail lint's grep scope. When in doubt, declare
  `restricted` — the file can be cleared later; it cannot be unpublished.
  (Scope note: this when-in-doubt-restricted rule classifies **whole
  template output files** and is the single home for profile-output
  guidance. Row- and cell-level classification inside the model follows
  the `schema.md` Detail level rules, whose when-unsure default is public.
  The two rules cover different objects and do not conflict.)
- Templates read the emitted `THREAT_MODEL.md` (and CSVs if present); they
  must not ask for new analysis. If a template needs data the schema doesn't
  carry, that's a schema change, not a template change. Only `ai-scan` may
  read working notes.
- Keep `> fill:` guidance imperative and short — it is prompt text the
  rendering agent follows verbatim.
- Never include an individual person's name; attribute to "Mozilla security
  review" and the owning team.

These built-ins are **starting points, expected to be iterated** — sections
marked `EDIT-ME` are where organization-specific wording (risk-band names,
data-classification labels, ticket links) should be substituted.
