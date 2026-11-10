# threat-modeling: output schema

> **Re-read note:** Read this file immediately before writing output — not at
> startup. If the Read tool reports "file unchanged", the prior result was
> evicted from context; reload with `cat <skill-dir>/schema.md` via Bash.

All files go into the **run directory**, never into `<target-dir>`.

---

## Who consumes these files (the contract)

The headings, column order, and enum values below are an interface. Keep them
exactly as shown so these consumers can parse them:

| Consumer | Reads |
|---|---|
| Developers finding the model in their repo | Section 4 top rows and Section 8 tell them what; the optional overview file, when produced, tells them how |
| Vulnerability scanners / triage | Section 3, Section 3b, Section 4 (surface + threat + residual risk drive scan focus and finding priority); `ATTACK_SURFACE.yaml` + `SCAN-SEEDS.md` when the `ai-scan` profile was rendered; Section 10 so known FPs are not re-reported — scanners read `THREAT_MODEL.md` only, which is why it carries nothing but Sections 1–10 |
| Drift re-check (`--prior` on a later run) | Section 4 ids, threats, evidence, Section 7 provenance commit, `id_aliases`, `visibility`/`detail`, Section 10 (append-only log) and, when an overview sits beside the prior, its scan history |
| Corporate threat-model Google Sheet | the five CSV files (column contracts below) |
| Leadership and reviewers skimming for priorities | the Executive summary at the top of `THREAT_MODEL_OVERVIEW.md` (opt-in: `--artifacts overview`); otherwise Section 4's top rows, which are sorted by residual risk |
| Output profiles (`templates/*.md`) | the sections named in each template's `consumes:` frontmatter |
| `render` mode | Section 7 provenance (to reconstruct commands and the detail level) + the overview's artifact index when one exists |
| Human reviewers | everything |

A consumer that only needs the threat table can regex for `^## 4\. Threats$`
and read until the next `^## `. Section 4b, Section 8, Section 9, and Section 10 are
additive: consumers must tolerate their absence (older models lack
them; Section 9 appears only with `--prior`). Models emitted before v2.1.0
carried the Executive summary, Sections 0/0b, and Section 11 inside
`THREAT_MODEL.md`; consumers — and drift runs handed such a file via
`--prior` — must tolerate their presence there too: the content contract is
identical, only the file moved. Models emitted before v2.2.0 may be
accompanied by a `THREAT_MODEL_RESTRICTED.md`; from v2.2.0 there is exactly
one model file per run, and its `detail` level (Section 7) says whether
anything was withheld in place.

---

## File 1: THREAT_MODEL.md — required sections, in order

`THREAT_MODEL.md` is the model proper — title plus Sections 1–10, nothing
else. Everything wrapper-grade (executive summary, usage guide, artifact
index, scan history) lives in the companion file (File 1b) so scanners and
drift runs parse a lean model.

```markdown
# Threat Model: <system name>

## 1. System context

## 2. Assets

## 3. Entry points & trust boundaries

## 3b. Data flows

## 4. Threats

## 4b. Attack chains

## 5. Category coverage & deprioritized

## 6. Open questions

## 7. Provenance

## 8. Recommended controls

## 9. Drift check

## 10. Known gaps & false positives
```

---

## File 1b: THREAT_MODEL_OVERVIEW.md — optional companion (`--artifacts overview`)

**Opt-in, never default.** The one default output is `THREAT_MODEL.md`; the
overview is written only when selected at kickoff or via `--artifacts
overview` (or later with `render`). When produced it sits beside
`THREAT_MODEL.md` in the run dir and holds everything a human wants first
and a scanner never reads. Derived at emit from the emitted
`THREAT_MODEL.md` — re-read from the emitted tables, never from memory. It
is written at the same `detail` level as the model and goes wherever the
model goes.

Required sections when produced, in order:

```markdown
# Threat Model Overview: <system name>

## Executive summary

## How to use these documents

## Artifact index

## Scan & assessment history
```

### Executive summary (always present, first section after the title)

A plain-language overview a non-engineer can read in two minutes, so every
produced overview carries a review-ready summary. Derived at emit
from Sections 1, 4, and 8 of `THREAT_MODEL.md`. No jargon without a gloss;
no table wider than five columns; risk words are the band names leadership
already knows (Acceptable / Mitigate by following release / Mitigate before
next release).

Contents, in order:

1. **What this system is and who depends on it** — two sentences.
2. **Top risks** — a table of up to five Section 4 rows ranked by residual
   risk, columns: `rank | threat id | risk | band before defenses | band
   today`. `rank` is a plain 1–5; `threat id` is the row's Section 4 id
   **verbatim**. Never renumber: `T`-ids belong to Section 4 rows and mean
   the same thing everywhere they appear — a summary that relabels its top
   five as T1–T5 collides with the real T1–T5.
   At `detail: public`, stubbed rows appear here exactly as they do in
   Section 4 — as counted stubs, never with withheld detail.
3. **Fix before the next release** — one bullet per Section 4 threat whose
   residual risk is in that band: the risk in one sentence plus the single
   Section 8 control that addresses it and its effort (S/M/L). If the band
   is empty, say so plainly.
4. **Best-value improvements** — the top three Section 8 controls by
   (closes_class, then lowest effort), one line each.
5. **Scope and method** — one line: mode, target commit, date, "static
   analysis only — no code was executed", and, when calibration is
   single-analyst, "likelihood ratings are analyst estimates pending owner
   review".

Recon runs (`--depth recon`) have no Section 4 rows: items 2–4 are replaced by
one sentence stating this is a surface snapshot and a full run is needed to
populate threats.

### How to use these documents

The section that makes the committed model a self-sustaining living
document. Three short paragraphs plus a maintenance note:

1. **What this is (and is not):** a threat model — what could go wrong, who
   would do it, what to do about it. Two files: `THREAT_MODEL.md` is the
   model proper (Sections 1–10); this overview is the wrapper. One-line
   litmus import: entries survive patches; individual bugs are evidence,
   not entries.
2. **How to read it by audience:** developers → `THREAT_MODEL.md` Section 4
   top rows and Section 8; reviewers → Section 2/Section 3/Section 3b coverage and Section 5/Section 6;
   scanners → `THREAT_MODEL.md` only (Section 3/Section 4, plus the ai-scan artifacts
   in the artifact index below); risk owners → the Executive summary above,
   and the RRA if produced.
3. **Detail level:** one sentence naming the repo's visibility and the
   resulting `detail` (from Section 7). At `detail: public`: "n threats
   are tracked as counted stubs; the detail is held by <owning team> and is
   restored in this file when the fix ships." At `detail: full`: "this
   model carries open-gap locations and belongs only in this
   private/internal repo."


**Maintenance note:** "Re-run `/threat-modeling bootstrap <target>
--prior <path-to-THREAT_MODEL.md>` quarterly, or after any change to entry
points, auth, or stored assets. Owner: <team>." Drift runs append to
Section 9/Section 10 and the scan history below; they never rewrite history.

**Detail line (always):** at `detail: public` — "Written for a public repo:
exploitation-roadmap detail withheld in place (see Section 7 `detail`)."; at
`detail: full` — "Written for a <private|internal> repo: full detail. Do not
copy outside the repo's access group."

### Artifact index

One table listing **every** sibling artifact — produced or not — with the
exact command to (re)generate it:

| Artifact | Where it lives | Audience | Regenerate with |
|---|---|---|---|

- Produced artifacts: run-dir sibling filename (or repo/tracker home once
  moved).
- Unselected artifacts get a row: "not produced this run — regenerate with
  `/threat-modeling render <run-dir> --artifacts diagram`" (or the
  matching `--profile`).
- The full-model regeneration row reconstructs the original invocation from
  Section 7 provenance (mode, flags, `--prior <THREAT_MODEL.md>`).
- Lints (run in SKILL.md Step 2): every file written in the run dir appears
  here (including `THREAT_MODEL.md` and this overview itself); every command
  parses against the argument-hint.

### Scan & assessment history

**Required and append-only.** Pointers only — never finding content in a
public file:

| date | activity | run ref / tracker query | findings home |
|---|---|---|---|

Activities: threat-model runs (this one included), drift re-checks, vuln
scans, pentests. Drift runs append a row rather than rewriting. (Before
v2.1.0 this table lived in `THREAT_MODEL.md` as Section 11; a drift run
handed a pre-v2.1 prior appends there in place.) When no overview exists,
the model's own Section 7 and the committed file's git history are the run
log, and scan outcomes touching a row land in Section 10 as refs.

---

## File 1 section contracts (THREAT_MODEL.md, Sections 1–10)

### 1. System context

One to three paragraphs of prose (what the system is, what it does, the
specific operational context being modeled, who uses it, where it runs),
followed by the **TOE block**:

```markdown
**In scope:** <bullet list of components and behaviors included>
**Out of scope:** <bullet list of explicit exclusions, each with a brief
reason — e.g., build toolchain, CI/CD, developer workstations>
**Documentation:** <paths/links to PRD, design docs, or "none supplied">
```

(The release/version under review is not a Section 1 field — the target
commit in Section 7 provenance is the anchor. The use case being modeled is
one sentence inside the prose, not a labeled field.)

Kickoff intake answers (deployment/exposure, population, crown jewels) feed
this section tagged per SKILL.md Step 0.7; facts from the intake's
non-public context are detail class (c): rendered in full at `detail: full`,
generalized in place at `detail: public` with the generalization noted.

### 2. Assets

Markdown table. One row per thing worth protecting.

| asset | category | description | sensitivity | C | I | A |
|---|---|---|---|---|---|---|

- `category` ∈ {`Data`, `Process`, `Infrastructure`, `External System`}.
- `sensitivity` ∈ {`low`, `medium`, `high`, `critical`}. A kickoff-stated
  crown jewel is minimum `high`.
- `C`/`I`/`A` ∈ {`Yes`, `No`}: is the asset sensitive on that dimension?
  At least one must be `Yes`.

### 3. Entry points & trust boundaries

Markdown table. One row per place untrusted input enters the system or
privilege level changes. Entry points answer "where does input arrive".

| entry_point | description | trust_boundary | reachable_assets |
|---|---|---|---|

`trust_boundary` is free text naming the crossing (e.g. "untrusted file →
process memory", "unauth network → authenticated session").
`reachable_assets` is a comma-separated list of asset names from Section 2.
Supply-chain, build-time, and infra/IAM surfaces **are** entry points even
though no runtime input crosses them.

### 3b. Data flows

Markdown table. One row per movement of an asset between components. Flows
answer "how do assets move" — each table catches threats the other misses.

| flow | source | destination | crosses_boundary | trust_transition | description | C | I | A |
|---|---|---|---|---|---|---|---|---|

- `source`/`destination`: asset or component names; asset names must match Section 2.
- `crosses_boundary` ∈ {`Yes`, `No`}.
- `trust_transition`: how trust changes (e.g. "Unauthenticated → System");
  blank if no crossing.
- `description`: what the flow carries, plus its auth/encryption status.
- `C`/`I`/`A` ∈ {`Yes`, `No`}.

### 4. Threats

Markdown table. **This is the threat model proper.** One row per
actor-wants-outcome pair, at the abstraction level where it survives a patch.

| id | threat | actor | stride | cia | surface | asset | in_repo | pre_impact | pre_likelihood | controls | post_impact | post_likelihood | status | evidence | disclosure |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

- `id`: `T1`, `T2`, … **Id lifecycle:** working rows carry provisional ids
  (`W1`, `W2`, …) through the research/dedup/verification stages; final
  `T`-ids are assigned exactly once, at emit, in sorted order — so a dedup
  merge before emit is invisible to consumers. After a model exists (drift
  runs, interview edits of a seed), ids are stable: never renumber surviving
  rows. A post-emit merge keeps the lower-numbered id and records the alias
  in Section 7 (`id_aliases: T9→T4 (merged)`) and in the final stage JSON; drift
  runs resolve prior ids through that map (`artifacts.md`).
- `threat`: One sentence, active voice, names the outcome. "Remote code
  execution via untrusted media parsing", not "buffer overflow in dr_wav".
- `actor`: **comma-separated list** of one or more of {`remote_unauth`,
  `remote_auth`, `adjacent_network`, `local_user`, `local_admin`,
  `supply_chain`, `insider`}. A threat reachable by several actors carries
  them all; do not flatten to one or split the row.
- `stride`: comma-separated list of {`S`, `T`, `R`, `I`, `D`, `E`}
  (Spoofing, Tampering, Repudiation, Info disclosure, DoS, Elevation).
- `cia`: comma-separated list of {`C`, `I`, `A`}. Every row carries **both**
  a `stride` and a `cia` tag.
- `surface`: which Section 3 entry point(s) and/or Section 3b flow(s) this threat
  traverses, by name.
- `asset`: which Section 2 asset(s) this threat compromises.
- `in_repo` ∈ {`yes`, `no`, `partial`}: does the subject of this threat live
  in this repository? `no`/`partial` rows stay in the model (readers need
  them) but are summarized in a scope note at the end of Section 4 so owners know
  what they can and cannot fix here.
- `pre_impact`, `post_impact` ∈ {`Negligible`, `Minor`, `Moderate`, `Major`,
  `Catastrophic`}.
- `pre_likelihood`, `post_likelihood` ∈ {`Rare`, `Unlikely`, `Possible`,
  `Likely`, `Certain`}.
- `controls`: existing **verified, credited** controls only — controls you
  re-read in code this run that actually move this row's post-score —
  comma-separated, each suffixed `(verified: file:line)`. Or `none`, which
  means "no credited control". **Owner-stated and user-supplied controls
  never enter this cell in any mode**: they go to Section 6 (in the follow-up
  format) and working notes, and they do not move post scores. A real but
  score-irrelevant verified control belongs in working notes (stage-6
  `not_credited`) and Section 6/Section 8, not in the cell, so `status` stays derivable.
  **Controls cells hold controls only** — no commentary, no
  "but"/"however" clauses; counter-evidence goes to working notes and the
  hand-back.
- `status`: **derived, never hand-set**, from the other cells at emit time.
  Evaluate in this order, first match wins:
  1. `controls` = none → `unmitigated`;
  2. owner explicitly accepted the risk → `risk_accepted`;
  3. post risk in the Acceptable band due to controls → `mitigated`;
  4. post risk < pre risk → `partially_mitigated`;
  5. otherwise → `unmitigated`.
- `evidence`: CVE IDs, issue links, pentest finding IDs, or git commit hashes
  that **instantiate** this threat. May be empty — **omit evidence rather
  than stretch it**; an empty cell is compliant, a weak or unverifiable hash
  is not. Every commit hash must resolve in the target's history at emit
  time. Evidence raises likelihood; it is not the threat.
- `disclosure` ∈ {`public`, `restricted`} — **derived, never hand-set**, by
  the rules in the Detail level section below. Filled at **both** detail
  levels: at `detail: full` it is informational (what would be stubbed if
  this repo went public — `render --visibility public` acts on it); at
  `detail: public` it is what the detail pass acted on.

**Sort the table by residual risk** (post_impact × post_likelihood hidden
values, descending; break ties by pre-mitigation risk descending) so the top
rows are the live priorities.

**Pre vs post scoring:** score pre-mitigation as if no controls existed;
score post-mitigation crediting **only verified controls** (an owner-stated
or user-supplied control does not move the post score — it lands in Section 6
instead). Heuristic: a strong, consistently enforced control drops likelihood
1-2 levels; a partial or inconsistent one drops it 0-1; impact rarely changes
unless the control prevents the harm entirely.

**Score basis (durable justification).** The final stage checkpoint JSON
must carry a `score_basis` map: per T-id, one line per pre score naming its
anchor (exposure from intake, past-fix density from history, technique
prevalence, default posture) and one per post score naming the credited
verified control. The panel severity calibrator and drift re-basing consume
it; the recount lint requires 100% Section 4 coverage. At **`detail: full`
only**, render it as a compact appendix table (`id | pre basis | post
basis`); at `detail: public` the file omits it (basis lines may contain
absent-control pointers, detail class b) and Section 7 notes the omission.

**Taxonomy rollups.** Directly under the table, add one or two short rollup
lists ("Threats by STRIDE category", "Threats by CIA dimension" — id lists
per category). Order them by the run's `taxonomy_lead` (STRIDE first, CIA
first, or both in that order for `both`). If the AI/LLM pass ran (Step 0.6
found AI components), add a third rollup "AI/LLM threats" listing the ids
minted by that pass with their AI class (e.g. "T7 — indirect prompt
injection"); omit the rollup entirely when no AI components exist.

### 4b. Attack chains

After clustering, identify 3-5 realistic multi-hop chains that combine Section 4
rows (e.g., "SSRF (T4) → cloud metadata credentials → artifact substitution
(T9)"). One bullet per chain: the path, the threat ids it links, and the
single control that breaks it. This section adds no new rows; it connects
existing ones.

### 5. Category coverage & deprioritized

Two tables. The first is the **category ledger** — the mechanism that makes
"a whole threat class went missing" impossible to do *silently*. Scope
discipline is the model's ceiling: the AI finds what the scope tells it to
look for, so every category below gets an explicit disposition, every run,
every mode.

**5a. Category ledger.** One row per master category (list below), no
exceptions:

| category | disposition | detail |
|---|---|---|

`disposition` ∈ {`covered` (list the Tn ids), `deprioritized` (points at a
5b row), `not-applicable` (one-line reason grounded in the TOE — "no web UI",
"single-tenant by design"), `needs-owner` (points at a Section 6 question)}.
A category may never be blank, and "not-applicable" must cite a TOE fact,
not a hunch.

**Master category checklist** (this list is the single home; bootstrap
Stage 5 and the emit check reference it):

1. Authentication & session management
2. Authorization & access control (vertical, horizontal/IDOR, default-deny)
3. Injection (SQL/NoSQL/command/template)
4. Cross-site scripting & content injection (rendering surfaces)
5. CSRF & clickjacking (any cookie-authenticated UI)
6. SSRF & outbound-request abuse
7. Cross-origin policy (CORS, postMessage, framing)
8. Deserialization & unsafe parsing of untrusted data
9. File & upload handling (traversal, type confusion, client-chosen ids)
10. Cryptography & key management
11. Secrets management (committed, env, config)
12. Credential & token lifecycle (expiry, revocation, IdP propagation)
13. Supply chain (dependencies, build, CI/CD, artifact integrity — incl.
    signing/verification of models, packages, and images at load/deploy)
14. Infrastructure & deployment defaults (IAM, network policy, TLS toggles)
15. Availability & resource exhaustion (DoS, decompression, quotas, cost)
16. Data retention, privacy & compliance (erasure, PII growth)
17. Logging, monitoring & forensic readiness (repudiation, evidence
    retention, expected-vs-actual detection surface: where logs land and
    who can read them)
18. Business logic & abuse (workflow bypass, races, fraud)
19. Transport security (interception, downgrade, MITM)
20. Multi-tenancy & isolation — *when the intake says multi-tenant*
21. AI/LLM threats (prompt injection, output handling, agency, model supply
    chain, poisoning, cost) — *when Step 0.6 found AI components*
22. Fork/extension seams — *when the target forks or extends an upstream*
23. Break-glass & operational safety (designed emergency paths for auth
    disable, secret rotation, rollback, kill switches — and anything that
    actively blocks emergency response)

Add target-specific categories freely (a queueing system adds
"message-queue trust"; the checklist is a floor, not a ceiling). Never
delete a master row to make the ledger look complete.

**5b. Deprioritized.** Threats considered and explicitly parked.

| threat | reason |
|---|---|

Common reasons: out of scope per TOE, actor not in threat model, asset not
present, risk accepted by owner (record their reason verbatim), insufficient
grounding (failed the concreteness bar — also logged in Section 10).

### 6. Open questions

Bullet list. Things the mode could not determine: deployment context,
intended actors, controls that could not be verified in code, uncertain
scores, panel split verdicts (both positions).
Unverified owner/user claims use the format:
`- [Owner-states|User-supplied] <claim>. Affects: <Tn field>. Verify by:
<suggested check>.`

### 7. Provenance

```markdown
- mode: interview | bootstrap | bootstrap-then-interview | render
- skill: threat-modeling v2.2.0 — copy the version from SKILL.md's
  Version line (the canonical home) at emit; never retype from memory
- skill_path: <absolute path of the skill directory actually loaded — makes
  the version claim verifiable and exposes source-vs-installed drift>
- date: YYYY-MM-DD
- target: <path or repo url> @ <commit, or "not a git repo">
- intake: interactive | --context <path> | merged-into-interview | none
  — plus a one-line digest of the exposure and crown-jewel answers
- artifacts: md[,overview][,csv][,diagram]
- profiles: <comma list of rendered profiles, or "none">
- visibility: public | private | internal | unknown — source: gh api |
  --visibility (override; detected <x>) | kickoff | default
- detail: full | public (n rows stubbed, k cells generalized, appendices
  omitted: score_basis[, 5h matrix]) — SKILL.md Step 0.55 mapping
- taxonomy_lead: stride | cia | both
- review: <none | self | adversarial (refuted/uncertain counts) |
  panel (confirmed/refuted/split counts)>
- depth: full | recon
- dedup: <n candidate rows merged into m final rows>
- id_aliases: <T9→T4 (merged), … | none>
- ai_components: <"yes — <what was found>" | "none found">
- inputs: <design doc | --vulns | --prd | --seed | "none">
- prior: <path of --prior model, or "none">
- owner: <present | unset — never an individual's name; attribute to the
  owning team or "Mozilla security review">
- calibration: <"owner-reviewed" | "single-analyst estimates pending owner
  review" — the latter whenever no interview happened>
```

This template is the single home of every provenance line; other files
reference it rather than restating field formats.

### 8. Recommended controls

One row per proposed control that does not exist yet. Class-level controls
preferred: a control that closes or materially shrinks an entire threat
cluster regardless of which instance is found next.

| control | description | type | threat_ids | closes_class | effort |
|---|---|---|---|---|---|

- `type` ∈ {`Preventive`, `Detective`, `Corrective`}.
- `threat_ids`: comma-separated Section 4 ids.
- `closes_class` ∈ {`yes`, `partial`}.
- `effort` ∈ {`S`, `M`, `L`}.

### 9. Drift check (only with `--prior`)

See `artifacts.md` for the procedure. Format:

| prior_id | prior_threat | verdict | evidence | notes |
|---|---|---|---|---|

`verdict` ∈ {`FIXED`, `STILL_PRESENT`, `CHANGED`, `NOT_CHECKABLE`}, each with
file:line or commit evidence. New surface found during the check is **minted
as scored Section 4 rows**, never left as narration; list the new ids here. At
`detail: public`, Section 9 rows for `restricted`-class threats get the same
stub treatment as Section 4; `FIXED` rows appear in full (fix shipped — full
disclosure is the honest end state).

### 10. Known gaps & false positives

**Required and append-only** — this is the living log that keeps future runs
and scanners honest. One table:

| date | item | type | status | ref |
|---|---|---|---|---|

- `type` ∈ {`false_positive` (previously investigated and ruled FP, with the
  ruling ref — seeded from kickoff intake; future runs and scanners must not
  re-report these), `removed_by_verification` (adversarial/panel-refuted
  rows and concreteness-bar downgrades — an honest one-line record that the
  claim was considered and rejected), `known_gap` (surface acknowledged
  un-modeled, e.g. a component out of TOE that deserves its own model; Section 6
  questions unanswered across three consecutive runs graduate here),
  `tooling_limit` (e.g. advisory lookup forbidden or unreachable this run)}.
- Rules: drift runs **append and update `status`, never delete**; entries
  carry no exploit detail (the section is public); every panel-refuted row
  and every intake FP must appear here (emit verification checks this).
  Below the table, list **clean passes**: gap-fill passes that ran and
  found nothing ("5d rendering: ran, output encoding verified at each
  surface"), so a future reader knows silence was checked, not skipped.
- Scan-run outcomes affecting a threat row land here as status updates with
  a ref — never as finding content.

---

## Detail level (what `detail: public` withholds)

**One file, one audience: whoever can read the repo.** The model lives in
the target repository, so the repo's GitHub visibility (SKILL.md Step 0.55)
decides how much the file says:

- **`detail: full`** (private or internal repo): nothing is withheld. The
  repo's access control is the boundary; the people who can read the model
  can already read the code and are the ones who will fix the gaps.
- **`detail: public`** (public or unknown repo): the model is still the
  comprehensive, living document — the code is public anyway, and a reader
  derives the architecture, surfaces, and most threats in minutes; hiding
  them only hides the risk from the people who can fix it. What a public
  file must NOT do is **curate live attack paths**: rank the unfixed gaps
  and say "start here". So every row and cell defaults to **public**, and
  only the tight list below is withheld — **in place, in the same file**.
  **When genuinely unsure: default PUBLIC unless the detail matches the
  tight list.**

The `disclosure` column classifies rows at both levels; the detail pass
(SKILL.md Step 2.6) acts on it only at `detail: public`.

**The tight restricted list — nothing else is ever withheld:**

- **(a) Roadmap rows:** a Section 4 row is `restricted` only when `status` ∈
  {`unmitigated`, `partially_mitigated`} AND residual risk is in the
  **Mitigate before next release** band AND the row's specifics (threat
  sentence, surface cell, evidence) amount to a direct exploitation roadmap
  beyond what minutes of public-code reading yields. At `detail: public`
  such rows appear in Section 4 **as counted stubs**:
  `| Tn | <STRIDE/CIA class only, no specifics> | tracked internally (ref:
  <tracker id, or the run id>) |` — counted, not hidden: transparency about
  the existence of open risk without the detail. Rollups list stubbed rows
  as an opaque count. The full row stays in the run dir's working notes,
  which are never committed.
- **(b) Go-here pointers (cell-level):** verified-**absent**-control
  locations for unmitigated/partially-mitigated high-residual items — these
  live in working notes (stage-6 `not_credited`/gap records), Section 6, and Section 8,
  since absent controls never enter a controls cell. At `detail: public`
  the pointer is generalized to "location tracked internally (ref: <id>)";
  **the row itself stays public.** The `score_basis` appendix is omitted at
  `detail: public` for the same reason.
- **(c) Non-public deployment/infra context:** cluster layout, internal
  hostnames, tenancy, org config — anything sourced from the kickoff's
  non-public answers or otherwise not derivable from the public repo. A
  Section 1/Section 3/Section 3b cell carrying it is generalized in place at
  `detail: public`, with the sanitization noted in the file.
- **(d) Scan tooling and chain narratives:** `SCAN-SEEDS.md`,
  `ATTACK_SURFACE.yaml`, unredacted attack-surface packs, and pointers into
  private scan findings — never for a public repo at any detail level
  (these are separate profile outputs, not part of the model file). A
  Section 4b **chain narrative** is restricted iff any member row is
  restricted — derived member-by-member per chain, never as a blanket rule;
  public member rows stay public, and at `detail: public` the file lists
  restricted chains as a count only. (Rows never inherit restriction from
  chain membership — a measured failure once flipped 6 public rows
  restricted and hollowed out a public model.)

Everything else — mitigated rows, risk-accepted rows, unmitigated rows below
the top band, generic industry-standard classes, threat statements, scores,
status, actor/surface/asset names — is **public**.

**What gets written (emission sequence in SKILL.md Step 2.6):**

- `THREAT_MODEL.md` — the **one** model file, Sections 1–10, at the run's
  `detail` level. At `detail: full` it carries full cells, full chains, the
  `score_basis` appendix, and the 5h authorization-proof-matrix appendix
  when bootstrap ran. At `detail: public` it carries the stub and
  generalization treatment above, and the appendices are omitted. Either
  way it is intended to be committed into the target repo by a human, via
  PR — the skill never writes into the target. **There is no
  `THREAT_MODEL_RESTRICTED.md`.** Withheld detail at `detail: public` lives
  only in the run dir's working notes (`stageN.json`, `qN.json`), which are
  never committed; `render <run-dir> --visibility private` re-emits it in
  full when the security team needs the complete picture.
- `THREAT_MODEL_OVERVIEW.md` (only with `--artifacts overview`) — written
  at the same `detail` level, with the same stubs, and goes wherever the
  model goes.
- CSVs and the diagram render from the complete working model and then take
  the same cell-level treatment as the model at the run's `detail` level.
  **Profile outputs are the exception:** their `disclosure` frontmatter is
  commit guidance for the whole file (`templates/README.md`) — a profile
  declared `restricted` (`ai-scan` always) is written in full at either
  detail level, carries a not-for-public-repos header, and is excluded from
  the detail lint.

**Drift interaction:** when a `restricted`-class threat's fix ships, the
next `--prior` run re-derives `disclosure` — FIXED rows become public
history (at `detail: public` the stub is replaced by the real row marked
fixed) and generalized cells are restored in place: full disclosure after
remediation. A drift run also re-detects visibility; if the repo changed
(private → public is the dangerous direction), the hand-back says so and
the new file is written at the new level.

---

## Scoring guide (corporate 5×5 scale)

### Impact

| value | means |
|---|---|
| `Negligible` | No material harm to the asset. |
| `Minor` | Damage recoverable easily, within days. |
| `Moderate` | Damage requires some effort to recover, weeks. |
| `Major` | Significant damage affecting multiple assets or business systems, months. |
| `Catastrophic` | Unrecoverable damage, or business-wide impact. |

### Likelihood

| value | means |
|---|---|
| `Rare` | Almost certainly won't happen (~once per 10 years). |
| `Unlikely` | Requires unlikely circumstances (~once per 2 years). |
| `Possible` | Credible, but requires a determined or resourced attacker (~once per year). |
| `Likely` | More likely than not (~once per month). |
| `Certain` | Will occur, possibly immediately or continually (~once per day). |

### Hidden numeric values and risk bands

Risk = hidden impact × hidden likelihood. The corporate sheet computes this
automatically from the qualitative words; use it yourself for sorting and for
the Executive summary's risk bands.

| Qualitative | Hidden value |
|---|---|
| Negligible / Rare | 1 |
| Minor / Unlikely | 2 |
| Moderate / Possible | 5 |
| Major / Likely | 8 |
| Catastrophic / Certain | 10 |

Risk acceptability bands:

- 1–39: **Acceptable**
- 40–79: **Mitigate by following release**
- 80–100: **Mitigate before next release**

### No-owner calibration (bootstrap without interview)

Without an owner, do not guess likelihood. Anchor each score on enumerated
observables and cite them per score in `score_basis`: is the surface exposed
by default configuration; are there past fixes in the same surface (git
history); how prevalent and automatable is the technique. Kickoff intake
answers about exposure and population (`[Owner-states]`/`[User-supplied]`)
are legitimate anchors too — cite them per score exactly like code
observables. Defaults that ship wide-open (auto-import, auto-approve, TLS
verification off) push likelihood **up**, not down. State in provenance that
scores are single-analyst estimates pending owner review.

---

## CSV files (only when `csv` is in the selected artifacts)

Five files, column contracts compatible with the corporate threat-model
Google Sheet tabs. Names in threat CSVs must resolve against the assets and
data-flows CSVs; never invent Control IDs. Per-dimension expansion always
reads the **final emitted Section 4 table** (post-dedup, post-review); the
cross-file lint rejects two threat-CSV rows sharing (asset|boundary,
dimension, threat sentence). Cell treatment per the Detail level section:
full at `detail: full`; at `detail: public`, any cell carrying a
restricted detail class is generalized exactly as in the model.

### File 2: THREAT_MODEL_assets.csv → Assets tab (paste at A2)

```
Name,Category,Description,Confidentiality,Integrity,Availability
```

| Column | Valid values |
|---|---|
| Name | free text — short, unique, must match names used in threat CSVs |
| Category | `Data` \| `Process` \| `Infrastructure` \| `External System` |
| Description | free text |
| Confidentiality / Integrity / Availability | `Yes` \| `No` |

### File 3: THREAT_MODEL_dataflows.csv → Data Flows tab (paste at A2)

```
Name,Source Asset,Destination Asset,Cross Trust Boundary?,Description,Trust Transition,Confidentiality,Integrity,Availability
```

`Source Asset`/`Destination Asset` must match names from the assets CSV.
`Trust Transition` blank when `Cross Trust Boundary?` is `No`.

**Out-of-repo flow endpoints:** a flow that ends at a component outside this
repo (SIEM, IdP, upstream registry, …) still needs a resolvable destination —
model that component as a Section 2 asset with `category: External System` so the
CSV lint passes truthfully. Never falsify `Cross Trust Boundary?` or point a
flow at itself to satisfy name resolution; a lint failure means the assets
table is incomplete, and the fix is there.

### File 4: THREAT_MODEL_asset_threats.csv → Asset-Threats tab (paste at A3)

For threats whose primary subject is an **asset** (stored data, a running
process, an installed artifact).

```
CIA Triad,Relevant Asset,Threat Description,Impact,Likelihood,Control IDs (CSV),Controls,Impact,Likelihood
```

| Column | Valid values |
|---|---|
| CIA Triad | `Confidentiality` \| `Integrity` \| `Availability` (full words, exact case) |
| Relevant Asset | must match an assets-CSV name |
| Threat Description | one sentence, active voice, outcome-level |
| Impact (pre), Likelihood (pre) | the 5×5 qualitative words above |
| Control IDs (CSV) | comma-separated existing IDs from the Controls tab; blank if unassigned; **never invented** |
| Controls | free text (the live sheet auto-populates from Control IDs) |
| Impact (post), Likelihood (post) | same scale; same as pre if no controls |

Sort by pre-mitigation risk descending. A Section 4 row tagged with multiple CIA
dimensions becomes one CSV row per dimension (the sheet is one-dimension-per-
row); keep the Section 4 table as the clustered source of truth.

### File 5: THREAT_MODEL_dataflow_threats.csv → Data Flow-Threats tab (paste at A3)

Same columns as File 4 except column B is `Relevant Boundary` (a data-flow
name from the dataflows CSV). Use for threats that exploit a flow or boundary
crossing (interception, in-transit tampering, injection in transit) rather
than a static asset.

### File 6: THREAT_MODEL_controls.csv → Controls tab (paste at A2)

```
Control ID,Control Name,When control introduced,Description,Control Type,Link to documentation
```

- `Control ID`: leave blank — the owner assigns IDs in the sheet.
- `When control introduced`: a date (or `existing`) for verified as-built
  controls; `Recommended` for Section 8 proposals.
- `Control Type` ∈ {`Preventive`, `Detective`, `Corrective`}.

### Google Sheets paste order

1. **Overview tab** — paste the Section 1 TOE prose, documentation links,
   and a changelog row, by hand.
2. **Data Flow Diagram tab** — if a diagram was generated: render the Mermaid
   block at mermaid.live, export PNG, Insert → Image → Image over cells.
3. **Assets tab** — copy assets-CSV rows below the header, paste at A2.
4. **Data Flows tab** — same, paste at A2.
5. **Controls tab** — same, paste at A2, then assign Control IDs.
6. **Asset-Threats tab** — update `Control IDs (CSV)` with the IDs just
   assigned, then paste rows at A3. Hidden risk columns auto-populate.
7. **Data Flow-Threats tab** — same, paste at A3.
8. **Review** — check both threat tabs for "Mitigate before next release"
   rows; each needs an assigned control and a plan.

---

## Example Section 4 rows (excerpt)

```markdown
| id | threat | actor | stride | cia | surface | asset | in_repo | pre_impact | pre_likelihood | controls | post_impact | post_likelihood | status | evidence | disclosure |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T1 | Remote code execution via untrusted audio file parsing | remote_unauth | T,E | I,A | WAV/FLAC file parsing | host process integrity | yes | Catastrophic | Likely | none | Catastrophic | Likely | unmitigated | CVE-2026-29022 | public |
| T2 | Policy tampering via console push path abused by a compromised admin session | insider, remote_auth | T,E | I | admin policy API | fleet policy state | yes | Major | Possible | audit log (verified: src/audit.rs:88) | Major | Unlikely | partially_mitigated | | public |
```

T1 stays in the model after the CVE is patched: attackers will still send
malformed audio files. The CVE is evidence the surface is fertile, not the
threat itself. Note T1's `disclosure`: although it is unmitigated and
top-band, its class and CVE are public knowledge derivable from the code in
minutes — nothing here curates an attack path, so it stays `public` and is
rendered in full even at `detail: public`; only a specific go-here pointer
or step-by-step chain narrative would be withheld. T2 shows a multi-actor row and a verified control moving
only the post-mitigation likelihood.
