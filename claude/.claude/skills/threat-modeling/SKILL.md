---
name: threat-modeling
description: >-
  Mozilla SSDLC threat model for a target codebase: STRIDE and CIA threat
  rows, pre/post-mitigation 5x5 scoring, verified as-built controls, and
  outputs for the corporate threat-model sheet. Modes: bootstrap (from
  code), interview (owner-driven), bootstrap-then-interview, render.
  Default output: exactly one file, THREAT_MODEL.md (sections 1-10), whose
  level of detail follows the target repo's GitHub visibility (public repo:
  exploitation-roadmap detail withheld in place; private/internal repo:
  full detail). No separate restricted edition. Optional add-ons:
  THREAT_MODEL_OVERVIEW.md (exec summary, usage guide, artifact index, scan
  history), CSVs, data-flow diagrams (Mermaid + C4/Structurizr), drift
  re-check (--prior), profiles (rra/general/ai-scan). Use when asked to
  "threat model" or "run an RRA".
argument-hint: "[bootstrap-then-interview|bootstrap|interview|render] <target-dir|run-dir|THREAT_MODEL.md> [--context <file>] [--vulns <file>] [--design-doc <file>] [--prd <file>] [--seed <THREAT_MODEL.md>] [--prior <THREAT_MODEL.md>] [--target-profile <run-dir|file>] [--depth recon|full] [--artifacts md,overview,csv,diagram] [--profile rra,general,ai-scan,<custom>] [--visibility public|internal|private] [--review none|self|adversarial|panel] [--taxonomy stride|cia|both] [--out <dir>] [--fresh]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash(git:*)
  - Bash(gh api:*)
  - Bash(find:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(grep:*)
  - Bash(wc:*)
  - Bash(mkdir:*)
  - Bash(date:*)
  - AskUserQuestion
  - Task
---

# threat-modeling

**Version: 2.2.0** — this line is the canonical version home. Everything
else (schema Section 7 provenance, README) copies from here; never retype a version
from memory.

A threat model answers **"what could go wrong with this system, who would do
it, and what should we do about it?"** independently of whether any specific
bug has been found yet. It is the map; vulnerability discovery is the metal
detector. A good threat model tells scanners where to look, tells triage which
findings matter, and tells leadership which risks block a release.

**Litmus test:** If patching one line of code makes an entry disappear, it was
a vulnerability, not a threat. A threat ("attacker achieves RCE via untrusted
media parsing") still stands after every known bug is fixed; a vulnerability
("`dr_wav.h:412` doesn't bounds-check `chunk_size`") does not. This skill
produces threats. Vulnerabilities appear only as **evidence** that raises a
threat's likelihood score.

**Quality principle:** ratings and confidence come from the concreteness of
grounded context — never from artifact volume. A model with 12 concrete rows
beats one with 40 thin rows. Three enforceable rules (this block is their
single home; emit checks and hand-backs reference it):

1. **Concreteness bar** (checked at emit for every Section 4 row): the row's
   working note must name (a) at least one concrete location for the surface
   (file:line, route, or config key — from swarm file_refs, kickoff answers,
   or owner testimony, tagged accordingly), (b) a Section 2 asset by exact name, and
   (c) one reachability sentence per listed actor ("remote_unauth reaches
   this because the route has no auth middleware — routes.rs:88"). A row that
   cannot meet the bar is merged into a neighbor, downgraded to Section 5 with
   reason "insufficient grounding", or converted to a Section 6 question — it does
   not ship as a Section 4 row. Downgrades are logged in Section 10.
2. **Rating justification:** every pre/post score cites its anchor
   observable in the `score_basis` map (contract in `schema.md`) — in every
   mode, for impact and likelihood both.
3. **Anti-metric:** row count, artifact count, and section length are never
   quality signals and must never be reported as achievements. Never add a
   row to appear thorough; never split a row to raise a count. Hand-backs
   report evidence density, verification outcomes, and inventory coverage
   instead — and report removals/downgrades as a quality signal, not hidden.

**Invocation:**
`/threat-modeling [bootstrap-then-interview|bootstrap|interview|render] <target-dir> [flags]`

---

## Step 0 — Safety preamble (always runs first)

This skill performs **static analysis only**. It reads source, git history,
and any documents the user supplies. It does not build, execute, fuzz, or
modify the target, and does not make network requests against the target's
infrastructure.

**Never write into `<target-dir>`.** All outputs and working state go to a
run directory outside the target (Step 0.5). The target checkout may be
wiped and re-cloned at any time; the threat model must survive that. The
model is *intended* to live in the target repo, but the skill never commits
it: committing is a human decision, done on a branch with a PR. The hand-back
supplies the copy command.

Before proceeding, confirm and state in your first response:

1. The target directory exists and is a local checkout you can read.
2. You will not execute any code from the target directory.
3. All output files will be written outside the target directory, and you
   will name the run directory you are using. In an interactive session the
   user may override that location before any work starts.
4. Advisory lookups use `gh api` against GitHub security advisories only.
   Other advisory sources (NVD, non-GitHub trackers) are out of reach for
   this skill: record them as a Section 10 `tooling_limit` entry and a Section 6 open
   question instead of improvising a fetch. Never query the target's live
   deployment. The kickoff engagement answer (Step 0.7) can forbid even the
   GitHub lookup.

If the user asks you to validate a threat by running an exploit, decline and
point them at the engagement's vulnerability pipeline instead.

---

## Step 0.5 — Run directory (resolve before the kickoff, so answers persist)

All state and outputs live in a per-run directory the target cannot reach:

- Default: `<parent-of-target>/threat-models/<target-basename>/<UTC
  timestamp, YYYYMMDDTHHMMSSZ>/` — beside the target checkout, never inside
  it. `--out <dir>` overrides the **parent**: the run dir becomes
  `<dir>/<UTC timestamp>/`, so repeat runs mint sibling directories instead
  of colliding with resume logic. (To reopen a specific unfinished run,
  point `--out` at its parent — resume matching does the rest.)
- **Containment guard (hard stop):** after resolving the run directory,
  compare its absolute path against the resolved target path. If the run
  directory falls inside the target, stop and ask the user for a location
  (an `--out` value or an interactive answer). Never proceed with a run
  directory inside the target.
- In an interactive session, state the resolved run directory in the Step 0
  preamble and let the user override it before any work starts.
- Immediately after the Step 0 preamble, write `scope.json` into the run dir:
  `{"target": "<absolute resolved target path>", "commit": "<git rev-parse HEAD or null>", "started": "<ISO date>"}`.
  The Step 0.55 visibility result (`visibility`, `detail`, `visibility_source`)
  and the kickoff answers (Step 0.7) are appended to it so a resumed run
  never re-asks. Two targets that share a basename get distinct run dirs;
  `scope.json` is the tiebreaker when resuming.
- **Resume:** if the newest run dir for this target has no `COMPLETE` marker
  file and its `scope.json` matches the resolved target path, reopen it and
  continue from its stage notes — `stage1.json`… in bootstrap, `q1.json`…
  in interview (checkpoint contracts live in each mode file). Otherwise (or
  with `--fresh`) create a new run dir. A run dir with a `COMPLETE` marker
  is finished history — never modify it (to add artifacts later, use
  `render`, which writes a fresh sibling run dir).
- Stage notes are plain JSON files written with the Write tool into the run
  dir after each stage/phase, so an interrupted session can resume without
  redoing research or re-interviewing the owner.
- Emit writes `THREAT_MODEL.md` **directly at its final path inside the run
  dir** — no assemble-somewhere-then-copy step that can half-complete. Write
  every artifact via a single Write each — no shell concatenation assembly.
- The `COMPLETE` marker is written **only by Step 2** — with one named
  exception: `render` mode (Step 1) never routes through Step 2 and writes
  `COMPLETE` itself at the end of its own lint subset. In every case the
  marker is **exactly one line, the bare ISO timestamp, nothing else**
  (tools parse it; prose breaks them).

---

## Step 0.55 — Repository visibility → detail level (cheap, always runs)

There is **one** threat model file and no restricted edition. How much it
says is decided here, once, from where the file is going to live: the target
repository. This step is the single home for the detection procedure and the
mapping; what each detail level withholds is defined in `schema.md`, Detail
level section.

Procedure:

1. `git -C <target-dir> remote get-url origin`. Parse a GitHub
   `owner/repo` from either URL form (`https://github.com/o/r[.git]`,
   `git@github.com:o/r[.git]`).
2. If it is GitHub and `gh` is on PATH:
   `gh api /repos/<owner>/<repo> --jq .visibility` → `public`, `private`,
   or `internal`. Any failure (not GitHub, no remote, `gh` missing or
   unauthenticated, 404) → `unknown`. Never guess from the URL alone.
3. Map to the run's `detail` level:

   | visibility | detail | note |
   |---|---|---|
   | `public` | `public` | roadmap rows stubbed, go-here pointers and non-public context generalized **in place** (`schema.md` tight list a–d) |
   | `private` | `full` | every row and cell complete; the repo itself is the access boundary |
   | `internal` | `full` | readable by every org member, who already have the source; **interactive runs confirm this in Batch 2** |
   | `unknown` | `public` | fail-safe: withhold; interactive runs ask in Batch 2 instead of defaulting |

4. `--visibility public|internal|private` **overrides** detection (explicit
   flags always win). When the flag disagrees with a successful detection,
   record both in Section 7 (`visibility: private (override; detected
   public)`) so a reviewer sees the choice.
5. Write `visibility`, `detail`, and `visibility_source`
   (`gh api` | `--visibility` | `kickoff` | `default`) into `scope.json`
   and later into Section 7 provenance. State the result in the Step 0
   preamble: "Repo `o/r` is **public** on GitHub → detail level `public`."

Withheld detail is never lost: at `detail: public` it stays in the run dir's
working notes (`stageN.json` / `qN.json`, never published), and a later
`render --visibility private` on the same run dir re-emits the full file
(Step 1, render mode). The reverse (full → public) works from any finished
run or committed file, since the `disclosure` column is always derived.

---

## Step 0.6 — AI/LLM component detection (cheap, always runs)

Before the kickoff, grep the target for AI-system markers: LLM SDK imports
and API clients (`anthropic`, `openai`, `bedrock`, `vertex`, `ollama`,
`transformers`, …), prompt files/templates, agent/tool frameworks and MCP
configs, embedding or vector-store clients, model weight files, fine-tuning
or eval datasets, inference servers — **and service-based integrations with
no SDK**: config keys like `ai[-_]review`, `llm`, `copilot`, a `.url` paired
with an `.auth-key`/bearer token near review/summary/assistant features, bot
usernames, and any outbound service whose responses become user-visible
content. SDK grep alone provably misses service-call integrations.

The detection is **correctable mid-run**: if later research (history mining,
docs, the owner) reveals an AI integration the grep missed, flip
`ai_components` to yes, record the correction in Section 7, and run the 5f pass —
never skip it because the early grep said no.

- **Any hit →** set `ai_components: yes` in working state. Bootstrap Stage 5
  then runs the **AI threat pass** (5f in `bootstrap.md`) and interview Q2
  adds the AI probe topics. Threats from this pass are ordinary Section 4 rows,
  plus an "AI/LLM threats" rollup under Section 4 (see `schema.md`).
- **No hits →** record `ai_components: none found` in Section 7 provenance and skip
  the pass. Do not fabricate AI threats for systems that have none.

---

## Step 0.7 — Kickoff: target intake + output selection

One coherent opening conversation, at most **two batched AskUserQuestion
messages**, before any research. Every question is skippable; defaults are
shown in brackets; flags pre-answer only their own item and never suppress
the rest of the kickoff in an interactive session. This step is the single
home for the intake spec, the `--context` format, the review ladder, and the
unknown-profile error rule.

### Batch 1 — about the target (intake)

Preface: "Seven quick context questions — answer any subset; leave anything
blank to accept the bracketed default. Inferred or defaulted answers are
recorded as assumptions."

1. **Deployment & exposure** — where does this run and who can reach it:
   internet-facing / behind an IdP or VPN / org-internal / local-CLI /
   library embedded in other products? Multi-tenant? [inferred from code —
   show your inference]
2. **Authenticated population** — who logs in (anonymous public, self-signup,
   org employees, admins only) and rough scale? [unknown]
3. **Crown jewels** — the one or two data/assets whose compromise would be
   worst, in your words? [inferred from code — show it]
4. **Prior work** — paths to prior threat models (newest auto-sets `--prior`
   unless `--prior` was given explicitly — explicit flags always win),
   pentest reports or scan findings (routed per Q4 in Answer routing below),
   design docs (`--design-doc`)? [none]
5. **Known false positives** — claims previously investigated and ruled FP,
   so this run does not re-report them? [none]
6. **Engagement context** — authorization basis; are public advisory lookups
   allowed; any disclosure constraints; any non-public deployment facts
   (internal hostnames, tenancy, upstream services)? [authorized internal
   review; lookups allowed; none]
7. **Scope corrections** — anything in scope an outsider would miss (admin
   panels, cron jobs/daemons, internal APIs, mobile/desktop clients,
   brand-new or unlaunched features, sibling repos this one depends on), and
   anything explicitly OUT of scope? The model is only as good as its scope
   — a component missing here tends to go missing from every table.
   [scope = this repository as inferred]

**Provenance tags.** Every intake answer is tagged in working notes:
`[Owner-states]` when the answerer owns/built the system, `[User-supplied]`
otherwise. Rules (enforceable, and they apply inside subagents too): tagged
facts may (a) set TOE scope and Section 1 context, (b) move `pre_impact`/
`pre_likelihood` anchors — cite the answer in `score_basis` exactly like a
code observable, and (c) gate passes (advisory lookup, FP suppression).
They may NEVER (d) create or stand in for a `(verified: file:line)` control
tag, or (e) move a post score. Every tagged fact that affected a score gets
a Section 6 line: `- [Owner-states|User-supplied] <claim>. Affects: <Tn field>.
Verify by: <check>.`

**Answer routing.** Q1–Q2 → Section 1 TOE prose + pre_likelihood anchors
(internet-facing + anonymous population raises the anchor one level;
internal-only lowers it one level; cite the answer per score). Q3 → Section 2
sensitivity and C/I/A flags + pre_impact anchors (a stated crown jewel is
minimum sensitivity `high`). Q4 → sets `--prior`/`--vulns`/`--design-doc`; a prior threat-modeling run
directory additionally becomes `--target-profile` — its recurring bug
classes, authorization primitives, and Section 10 known-gaps seed the Stage-1
research briefs and the 5h matrix diff (bootstrap.md).
The `--vulns` parser is bootstrap-only (the Vuln-file parser agent in
`bootstrap.md` Stage 1); in a pure interview run, record the vuln file's
path in Section 7 inputs, use its findings as Q2 evidence prompts, and carry
anything unaddressed as Section 6 pointers — never silently drop the path.
Q5 → Section 10 `false_positive` seeds; matching candidate rows are suppressed at
emit **with a Section 10 note** ("previously ruled FP: <ref>"), never silently
dropped and never re-reported in Section 4. Q6 → Section 7 provenance + the advisory-
lookup gate; every non-public deployment fact is detail class (c) by
definition (`schema.md` Detail level) and is generalized in place when the
run's `detail` is `public`.

**Interview mode:** the interview's Q1a–Q1d already cover most of intake.
Ask only the remainder here (typically 4, 5, 6); never ask the same question
twice — `interview.md` opens Q1 by summarizing the kickoff answers back.

**Non-interactive runs** use `--context <file>` or record `intake: none` and
proceed on inferences.

### `--context <file>` format (non-interactive intake)

A simple markdown Q/A file: one `##` heading per intake topic, free-text
answer below it. Recognized headings (all optional):

```markdown
# threat-modeling context
## Deployment & exposure
Internet-facing multi-tenant SaaS behind a CDN; admin UI behind the org IdP.
## Authenticated population
~40k self-signup users; 12 org admins.
## Crown jewels
User vault contents; signing keys.
## Prior work
- prior model: docs/THREAT_MODEL.md
- pentest: reports/2026-q2-pentest.md
- scan findings: scans/run-14/VULN-FINDINGS.json
## Known false positives
- "JWT alg confusion in login" — ruled FP, tracker ref SEC-2214 (2026-05)
## Engagement
Authorized Mozilla security review; public advisory lookups allowed.
## Non-public context
Deploys to internal cluster gke-prod-7; tenancy shared with billing svc.
```

Rules: a missing file passed via `--context` is a **hard error**, not a
silent skip. `Prior work` paths route exactly like Q4. Everything under
`Non-public context` is detail class (c) — generalized in place at
`detail: public`. Unrecognized headings and
content are carried verbatim into working notes tagged `[User-supplied]`,
never discarded. The file's path and a one-line digest go into Section 7
(`intake: --context <path>`). Both intake routes produce the identical
working-state shape so downstream stages have one code path.

### Batch 2 — about the outputs

One message. Lead with the default bundle, then the add-ons:

> Default: **one file, `THREAT_MODEL.md`** (Sections 1–10) at detail level
> **<detail>** — because `<owner/repo>` is **<visibility>** on GitHub —
> plus self-review and both taxonomies. Nothing else is produced unless you
> add it here (or later with `render`):
>
> 0. **Detail level** — keep the detected level, or override
>    (`--visibility public|internal|private`). For `internal` repos: "every
>    org member can read this repo, so the model will carry full detail
>    including open-gap locations — keep, or treat as public?" For
>    `unknown`: "I could not detect the repo's visibility — is it public,
>    internal, or private?" (no default accepted silently in an interactive
>    session).
> 1. **Overview companion** — `THREAT_MODEL_OVERVIEW.md`: plain-language
>    executive summary of the top risks, how-to-use guide, artifact index,
>    scan & assessment history. Recommended when leadership or a review
>    board will read the model; scanners never need it.
> 2. **Corporate CSV pack** — five CSVs for the corporate threat-model
>    Google Sheet.
> 3. **Data-flow diagram** — Mermaid DFD. Follow-ups if selected: threat-ID
>    overlay color-coded by CIA, yes or no? And format — `mermaid` (default;
>    renders natively on GitHub) or `both` (additionally emits a Structurizr
>    DSL `workspace.dsl` from the same intermediate model — see `diagram.md`
>    Part 2; never emit DSL without the Mermaid fallback).
> 4. **Drift re-check** — path to a prior model of this system (sets
>    `--prior`).
> 5. **Output profiles** — extra views rendered from the finished model:
>    **rra**, **general**, **ai-scan**, or any custom template in
>    `templates/`.
> 6. **Taxonomy lead** — STRIDE, CIA, or both (every row carries both tags
>    either way; this only orders the rollups).
> 7. **Verification depth** — see the ladder below.
> 8. **Depth** — `full` (default) or `recon` (stages 1–2 only: a quick
>    surface snapshot; no threat rows, no profiles).

**Review ladder** (single home):

| Level | Cost | Use for |
|---|---|---|
| `none` | near-zero | throwaway drafts; provenance says so |
| `self` (default) | no subagent cost | routine internal models |
| `adversarial` | one subagent (~10–20% of a bootstrap run) | any model a team will act on |
| `panel` | ≈3× adversarial (three independent judges re-reading code) | tier-1 targets; **recommended before a model is committed into a public repo** |

Panel replaces neither the mechanical emit-verification lints (always run)
nor human sign-off. A `detail: public` run with `--review none|self` gets a
warning at kickoff: interactive sessions proceed only on explicit
confirmation; non-interactive runs proceed but provenance records
`review below recommended level for public detail` and the hand-back flags
that the model should not be committed until a deeper review runs.

**Non-interactive invocations** (CI, subagent): skip both batches.
**Explicit flags always win**; defaults fill only what flags leave
unspecified: `--artifacts md`, no profiles, `--taxonomy both`,
`--review self`, detail level from Step 0.55 detection (`unknown` →
`public`), `--depth full`, no drift check unless `--prior` was passed.
(`--artifacts md,csv,diagram` means exactly those three — defaults never
subtract from or override a given flag.)

Rules:

- The markdown model is always on; **everything else — the overview
  included — is opt-in.** One default output, by design: a reader who
  finds `THREAT_MODEL.md` in a repo has the whole model.
- Record every selection and intake answer in `scope.json` and the Section 7
  provenance block so a resumed run does not re-ask.
- Selection gates work: if the overview is off, do not write it (and the
  artifact-index lint does not apply); if CSVs are off, skip Control-ID
  bookkeeping; if the diagram is off, **never generate it** — do not
  volunteer one; if no
  `--prior`, skip the drift pass; if no profiles, never read `templates/`.
- Profiles are **views, not analyses**: they render from the finished,
  verified model (see `templates/README.md`). A profile can never lower
  analysis rigor; for a genuinely lighter pass, that is what `--depth recon`
  is for — but recon supports **no profiles**.
- Resolve `--profile` names against `templates/<name>.md`; an unknown name
  is an error listing the available templates, not a silent skip.
- If `--prior` is set (from flag or kickoff), read `artifacts.md` at the
  point the drift pass runs — not now.

---

## Step 1 — Route to a mode

Parse `$ARGUMENTS`:

| First token | Route to |
|---|---|
| `interview` | Read `interview.md` in this directory and follow it. |
| `bootstrap` | Read `bootstrap.md` in this directory and follow it. |
| `bootstrap-then-interview` | Bootstrap first, then interview seeded from the draft. See below. |
| `render` | Render-only, no analysis. See below. |
| anything else, or empty | Ask the user: **"Is someone who owns or built this system available to answer questions in this session?"** Yes and the codebase is checked out → recommend `bootstrap-then-interview`. Yes but no codebase → `interview.md`. No → `bootstrap.md`. |

`--prior` is not a mode: it adds a drift pass (see `artifacts.md`) to
whichever mode runs. A drift-only re-check is `bootstrap --prior <file>`
with `--artifacts md` — bootstrap's research stages feed the re-verification.

All analysis modes write the same artifact set (schema in `schema.md`) so
downstream consumers do not need to know which mode produced it.

| | `interview` | `bootstrap` |
|---|---|---|
| **Needs** | An application owner present in the session | A local checkout; optionally past vulns |
| **Method** | Four-question framework merged with the TOE/CIA interview: *what are we working on → what can go wrong (STRIDE + CIA sweep) → what are we going to do about it (pre/post scoring) → did we do a good job* | Staged research: parallel research swarm → synthesize + spot-check → generalize vulns into threat classes → CIA sweep → STRIDE gap-fill + targeted passes + spot-check → dedup → verify controls → emit |
| **Best for** | New systems, design reviews, risk that lives in business logic the code doesn't show | Inherited systems, third-party code, anything with a CVE history |
| **Provenance tag** | `interview` | `bootstrap` |

### `render` mode (regenerate artifacts from a finished run)

`/threat-modeling render <run-dir or THREAT_MODEL.md> [--artifacts …]
[--profile …] [--visibility …]`. Reads the existing verified model, does
**no new analysis**, and writes the requested artifacts into a **fresh
sibling run dir** (COMPLETE dirs stay immutable) with provenance
`mode: render, source: <run-dir>`. Render runs the relevant lints only
(profile consistency, no-names, the artifact-index lint when an overview is
written, and the detail lint when `detail` is `public`), then writes
`COMPLETE` itself and hands back the list of files written — render never
routes through Step 2; this is the one exception to Step 0.5's
single-writer rule, named there. This is also how an edited template is
tested against an existing model, and the command the overview's artifact
index embeds for artifacts a run did not produce.

**Re-emitting at a different detail level.** `render <run-dir>
--visibility private` re-emits `THREAT_MODEL.md` at `detail: full` from the
run dir's working notes (the only place withheld detail is kept); `render
<run-dir or THREAT_MODEL.md> --visibility public` re-emits at `detail:
public` from a full model (needs no working notes — the `disclosure` column
is always derived). Use this when a repo changes visibility, or when the
one model needs to be shared outside the repo's access group.

**Context durability (interview mode).** Interview mode is multi-turn; tool
results from early reads may be evicted before you need them. In interview
mode, do **not** read `interview.md`, `diagram.md`, or `artifacts.md` in
full up front — read the relevant section at the point you need it, one
question or stage at a time. (Bootstrap is single-session: reading
`bootstrap.md` fully at the start is fine.) If a re-read via the Read tool
is refused as "file unchanged", the prior result was evicted; reload with
`cat <path>` via Bash instead.

**Interview backbone** (so you can proceed even if `interview.md` is
unavailable mid-session):

| Q | Question | Fills schema sections |
|---|---|---|
| Q1 | What are we working on? | Section 1 context + TOE, Section 2 assets (with CIA flags), Section 3 entry points, Section 3b data flows |
| Q2 | What can go wrong? | Section 4 threat rows (id, threat, actor, stride, cia, surface, asset) via STRIDE prompts + per-asset/per-flow CIA sweep |
| Q3 | What are we going to do about it? | Section 4 pre/post impact & likelihood, controls; Section 5 deprioritized; Section 8 recommended controls |
| Q4 | Did we do a good job? | validate ranking, coverage check, Section 6 open questions |

### `bootstrap-then-interview` mode

When the owner is available *and* the codebase is checked out, this is the
recommended path: the owner's time goes to refining a code-grounded draft
instead of describing the system from scratch.

1. Tell the owner: "I'll read the code first and come back with a draft
   (about 5-10 min), then we'll walk it together. Want that, or would you
   rather start cold?" Only proceed if they opt in; otherwise fall back to
   `interview.md`.
2. Read `bootstrap.md` and follow it end-to-end. Write the draft
   `THREAT_MODEL.md` into the run dir (the draft is always written at
   `detail: full` — the detail pass runs once, in Step 2, on the refined
   model).
3. Immediately continue into interview mode: read `interview.md` and follow
   it with `--seed <run-dir>/THREAT_MODEL.md` in effect. The Section 6 open
   questions from bootstrap become your Q1-Q4 prompts; the owner confirms,
   corrects, and adds rather than starting from nothing.
4. Overwrite the run dir's `THREAT_MODEL.md` with the refined model. Set
   provenance `mode: bootstrap-then-interview`.

The same flow is available manually: run `bootstrap` first, then
`interview --seed <run-dir>/THREAT_MODEL.md` in a later session.

---

## Step 2 — End of run (single owner of the sequence and of COMPLETE)

All modes MUST emit `<run-dir>/THREAT_MODEL.md` (Sections 1–10)
conforming to `schema.md` in this directory — the one default output — plus
whichever optional artifacts the kickoff selected (overview companion per
`schema.md` File 1b; CSV contracts in `schema.md`; diagram in `diagram.md`;
drift appendix in `artifacts.md` Part 1; profiles in `artifacts.md` Part 2
+ `templates/`). **Read `schema.md` immediately before you write the files**,
not at routing time; in interview mode the gap between routing and emit can
be many turns, and an early read will be evicted before it's used.

When a mode file finishes its emit, it returns here. The sequence is fixed
and this step owns it end to end — mode files never write `COMPLETE`:

**emit verification → self-review → adversarial or panel (if selected) →
profile rendering → detail pass → COMPLETE → hand-back.**

The review ladder is **cumulative**: emit verification (2.1) always runs;
the self-review gate (2.2) runs at `--review self` and above and is skipped
only at `--review none`; adversarial (2.3) and panel (2.4) run additionally
at their own levels, after 2.2.

(Dedup already ran inside the mode, before control verification.)

### 2.1 Emit verification

Read the emitted `THREAT_MODEL.md` back from disk and check:

1. All required sections present in order (`THREAT_MODEL.md`: Sections
   1–10; and, only if the overview was selected, `THREAT_MODEL_OVERVIEW.md`:
   Executive summary, usage guide, artifact index, scan history — per
   `schema.md`); Section 4 row count matches working state; every risk in
   an Executive summary cites its Section 4 id verbatim and resolves to that
   row (rank numbers are plain 1–5, never `T`-prefixed — the summary never
   renumbers threats).
2. Coverage invariant over **all three inventories**: every Section 3 entry point,
   every Section 3b flow, **and every Section 2 asset** appears in at least one Section 4
   surface/asset cell or a Section 5b entry.
2b. **Category-ledger completeness:** the Section 5a ledger has one row per
   master-checklist category (`schema.md` Section 5a is the list's single
   home), none blank, every `covered` id exists in Section 4, every
   `deprioritized` entry points at a real Section 5b row, every
   `not-applicable` reason cites a TOE fact, and the conditional categories
   (multi-tenancy, AI/LLM, fork seams) are dispositioned consistently with
   the intake and Step 0.6 results. A missing or blank category row fails
   emit — this is the "no silently missing threat class" guarantee.
3. Every commit hash in an evidence cell resolves
   (`git -C <target-dir> cat-file -t <hash>`) — drop any that don't and
   note the removal.
4. **Verified-tag re-check:** for every `(verified: file:line)` in a
   controls cell, re-open the cited lines and confirm they implement that
   control **on the path the threat traverses** (trace route → handler if
   needed). A tag that fails this check is removed and the row re-scored —
   a false verified tag is worse than an honest `none`.
5. **Rollup lint:** every Section 4 row id appears in every taxonomy rollup list
   matching its tags (a row tagged `I` in stride appears in the
   Info-disclosure list; a row tagged `C` in cia appears in the
   Confidentiality list; AI-pass rows appear in the AI rollup).
6. If CSVs were emitted: every asset/flow name in a threat CSV resolves in
   the assets/flows CSVs; no Control ID is invented; per-dimension expansion
   read the **final emitted Section 4 table** (post-dedup, post-review) and no two
   threat-CSV rows share (asset|boundary, dimension, threat sentence); **no
   MD-vs-CSV fact divergence** — if a flow's CSV row can't be written
   truthfully, fix the Section 2/Section 3b modeling per `schema.md`, never bend a CSV
   value to pass the lint.
7. **No-names lint:** grep every **human-facing** output file for individual
   names, handles, and emails (commit metadata is the usual leak); attribute
   only to teams or "Mozilla security review". Machine bookkeeping files
   (`scope.json`, `stageN.json`, `qN.json`) are exempt — they may hold
   absolute paths needed for resume, and they are never published.
8. **Recount lint:** every count you assert anywhere (step log, provenance,
   hand-back — row counts, verified-tag counts, stub and generalized-cell
   counts) must be re-derived by command from the emitted files (`grep -c`,
   `wc -l`, or the Grep tool's count mode), not from memory. In bootstrap
   mode the stage-6 `control_evidence` map must reconcile 1:1 with the
   `(verified:)` tags actually emitted; in interview mode the `q3.json`
   verified-controls ledger plays the same role. `score_basis` coverage
   must be 100% of Section 4 rows. A ledger that flatters the run is a defect
   equal to a wrong threat row.
9. **Concreteness bar** (Quality principle rule 1): check every Section 4 row;
   handle failures per that rule and log them in Section 10.
10. **Artifact-index lint (only when the overview was written):** every
    file actually written in the run dir appears in the overview's artifact
    index, and every "Regenerate with" command parses against this file's
    argument-hint.

Fix anything that fails.

**Recon runs (`--depth recon`)** have no Section 4 rows by design: only checks 1,
7, 8, and 10 apply; checks 2–6 and 9, the review gates, and profile
rendering are skipped. The detail pass (2.6) and its lint still run when
`detail` is `public`: a recon snapshot's Section 1/Section 3/Section 3b can
carry class-(c) intake context, and it must be generalized in place exactly
as in a full run. Provenance records
`depth: recon`; `COMPLETE` is still written at the end of this step.

### 2.2 Self-review gate (runs at `--review self` and above)

Re-read Section 4 once with a reviewer's eye and fix in place:

1. **Status lint:** re-derive every `status` from its own row per the
   `schema.md` precedence; any status-vs-controls contradiction is a bug.
2. **Controls-cell purity:** no "but/however" commentary in controls cells;
   move it to working notes.
3. **Default-vs-configurable check:** for every threat whose likelihood
   assumed a risky behavior is *optional*, verify what the code's actual
   default is — defaults that ship wide-open raise likelihood, and "possible
   misconfiguration" is an underclaim when it is the default.
4. **Rendering-pass sanity:** if the target has any web UI and the
   rendering-surface pass produced zero rows and zero Section 5 entries, it did not
   run properly — redo it.
5. Any unverifiable load-bearing claim is a Section 6
   entry, not a silent choice.
6. **Dedup survivorship scan:** one final pairwise pass of Section 4 for rows that
   pass the merge test (`bootstrap.md` Stage 5.5) and survived — finding one
   is a dedup defect; merge in place and note it.

### 2.3 Adversarial review (`--review adversarial`)

Runs after the self-review gate, on the written file, **before COMPLETE**
(nothing is final until this folds in). Spawn one independent subagent
(Task tool; read-only restriction verbatim) with the 3 highest-residual
rows plus the 2 most unusual rows, briefed to REFUTE each against the code.
Fold verdicts in: refuted → fix or drop (drops are logged in Section 10 as
`removed_by_verification`); uncertain → Section 6. Record the outcome counts in
Section 7 provenance.

### 2.4 Panel review (`--review panel`)

Three independent judges with distinct lenses, after the self-review gate.
Spawn all three in **one Task batch**; each gets the read-only restriction
verbatim, the emitted Section 4 table (plus Section 2/Section 3/Section 3b for name resolution), and
the target dir — but **not** each other's outputs and **not** the working
notes: independence is the point; only what a judge can re-derive from code
and the emitted evidence counts.

| Judge | Lens brief |
|---|---|
| **Refuter** | Assume each row is wrong. Find the code fact that disproves the threat, its surface, or the listed actors' ability to reach it. |
| **Evidence auditor** | Re-resolve every evidence hash, tag, and citation; re-read every `(verified: file:line)` on the actual code path. A tag you cannot reproduce is a failure. |
| **Severity calibrator** | Re-derive every score from the `schema.md` 5×5 anchors and the row's `score_basis` citations. Flag any score whose stated basis does not support it. |

Row selection: all rows in the top two residual bands, plus every row
carrying a `(verified:)` tag, plus the 3 most unusual rows; cap 15 and note
the cap in provenance. Each judge returns per-row **CONFIRM / REFUTE /
UNCERTAIN** with a one-line code-grounded reason.

Folding (only the orchestrator edits rows; judges only verdict):

- Any judge **refuting a factual claim** → fix the row if the refutation is
  a correctable cell, else remove it and log it in Section 10 as
  `removed_by_verification` — removals are recorded, never silent.
- An evidence-auditor tag failure is **authoritative regardless of the other
  judges** (mechanical, not opinion): strip the tag, re-score the row.
- **Split verdicts** on judgment calls → keep the row, record both positions
  in Section 6 ("panel split: <positions>"). A 2–1 REFUTE on a judgment call is
  still a split — keep the row. Rows are removed only via a factual
  refutation or an evidence-auditor tag failure, never by vote count.
- **Calibrator disagreement** → re-score, with the reasoning recorded in
  `score_basis`.

Record `review: panel (confirmed: a, refuted: r, split: s)` in Section 7.
Cost ≈ 3× adversarial; recommended for tier-1 targets and before a model is
committed into a public repo (see the Step 0.7 ladder).

### 2.5 Profile rendering

For each selected profile, read `templates/<name>.md` and render it from
the verified **complete** model per `artifacts.md` Part 2. Profiles render
before the detail pass so they see full cells; each output's
commit-guidance class comes from its template frontmatter
(`templates/README.md`).

### 2.6 Detail pass (`detail` from Step 0.55)

One file, edited in place. There is no second edition to write. The
content rules (what each detail class is) live in `schema.md`, Detail level
section; this is the procedure's single home.

1. Derive `disclosure` for every Section 4 row and flag every class-(b)/(c)
   **cell** (go-here pointers, non-public context) per `schema.md`. This
   runs at **both** detail levels — the column is always filled.
2. **`detail: full`** (private or internal repo): stop here. Every row and
   cell stays complete; the `score_basis` appendix and, in bootstrap, the
   5h authorization-matrix appendix are rendered in the file. Section 7
   records `detail: full`.
3. **`detail: public`** (public or unknown repo): rewrite `THREAT_MODEL.md`
   (and the overview, if written) in place — class-(a) rows become counted
   stubs; class-(b)/(c) cells are generalized with the sanitization noted;
   class-(d) chain narratives are listed as a count; the `score_basis` and
   5h appendices are omitted (noted in Section 7). Withheld detail remains
   only in the run dir's working notes; the hand-back says where.
4. **Detail lint (`detail: public` only):** grep the model (and the
   overview, any CSVs, and any profile output declared `disclosure: public`)
   for every stubbed row's title words and evidence strings, every
   generalized go-here `file:line` pointer, and every non-public-context
   string from intake. Stubs only. Profile outputs declared
   `disclosure: restricted` (`ai-scan` always) are exempt from the lint and
   carry a header saying they are not for a public repo.

### 2.7 Write COMPLETE, then hand back

Write the `COMPLETE` marker. Then print to the user:

1. Paths to all files written (run dir first).
2. The top 5 threats by **residual** (post-mitigation) risk, one line each:
   id, description, pre → post band.
3. Any threats in the "Mitigate before next release" band.
4. **Quality metrics — never row counts as achievements** (Quality
   principle): evidence density (fraction of Section 4 rows whose evidence
   resolves; fraction of controls tags re-verified on-path), verification
   outcomes (self/adversarial/panel confirmed–refuted–split counts),
   coverage completeness (UNCOVERED count from the coverage lint — must be
   zero), and the count of candidate rows removed or downgraded for failing
   the concreteness bar.
5. For `bootstrap`: open questions the code could not answer (these seed a
   later `interview` pass). For `interview`: owner statements that could not
   be verified in code (these seed follow-up code review).
6. If a drift pass ran: the verdict counts (fixed / still present / changed /
   not checkable) and any newly minted threat rows.
7. **Commit note:** "Repo `<owner/repo>` is **<visibility>**, so this model
   was written at detail level **<detail>**. To commit it, copy
   `<run-dir>/THREAT_MODEL.md` (and the overview, if produced) to
   `<repo>/docs/` (or the repo's convention) on a branch and open a PR —
   this skill never writes into the target. On the next run, pass the
   committed `THREAT_MODEL.md` via `--prior`." At `detail: public` add the
   stub and generalized-cell counts (recount lint) and: "withheld detail is
   in `<run-dir>` working notes only — never commit the run dir; re-emit in
   full with `render <run-dir> --visibility private` if the model must be
   shared inside the security team." At `detail: full` add: "this file
   carries open-gap locations — it belongs only in the private/internal
   repo it was written for; if the repo goes public, re-run `render
   --visibility public` first." If `detail` is `public` and review depth
   was below `panel`, say the model should not be committed until a deeper
   review runs and a second security engineer has reviewed it.
