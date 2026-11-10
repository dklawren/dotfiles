# /threat-modeling interview

> **Re-read note:** If you need this file mid-session and the Read tool
> reports "file unchanged", the prior result was evicted from context; reload
> with `cat <skill-dir>/interview.md` via Bash.

Build a threat model by interviewing the application owner. The backbone is
the **four-question framework**; the TOE scoping and per-asset/per-flow CIA
elicitation from Mozilla's SSDLC method are merged into it. The owner is in
the session; your job is to ask, listen, ground their answers in the code
where you can, and emit per `schema.md`.

The four questions (use this exact wording when you introduce each phase; the
phrasing is deliberate):

1. **What are we working on?**
2. **What can go wrong?**
3. **What are we going to do about it?**
4. **Did we do a good job?**

Reference: Shostack, *The Four Question Framework for Threat Modeling* (2024).

Ask **one thing at a time**. Wait for the answer. Do not dump a questionnaire.

---

## Inputs

- `<target-dir>` (required): local checkout. You will read it to ground
  answers; you will not execute it, and you will not write into it.
- `--design-doc <path>` / `--prd <path>` (optional): read before Q1 so you
  can summarize back instead of starting cold.
- `--seed <THREAT_MODEL.md>` (optional): a prior `bootstrap` output. If
  present, the interview focuses on its Section 6 open questions and any threat
  rows with uncertain scores, instead of building from scratch.
- `--prior <THREAT_MODEL.md>` (optional): triggers the drift pass at emit
  (procedure in `artifacts.md`).

Shared flags (`--context`, `--artifacts`, `--profile`, `--visibility`,
`--review`, `--taxonomy`, `--out`, `--fresh`) are handled in `SKILL.md`
Steps 0.5-0.7 and are not restated here.

---

## Checkpointing (interview mode is the most eviction-prone — write as you go)

`scope.json` was written at Step 0.5. After each question phase, checkpoint
with the Write tool so an interrupted interview loses nothing:

- After Q1 → `<run-dir>/q1.json`: TOE, assets, entry points, flows, and the
  provenance tags on each fact.
- After Q2 (and its dedup + spot-check) → `<run-dir>/q2.json`: candidate
  threat rows (provisional `W`-ids), merge log, spot-check results.
- After Q3 → `<run-dir>/q3.json`: scores, `score_basis`, and the
  **verified-controls ledger** (control → file:line for every `(verified:)`
  tag — this plays the role of bootstrap's `control_evidence` map in the
  Step 2 recount lint).
- After Q4 → `<run-dir>/q4.json`: ranking adjustments, coverage results,
  owner feedback.

**Resume:** read `q1.json` … `qN.json` in order, then re-summarize to the
owner — "here is where we left off" — and continue from the next question.
Never re-ask what a checkpoint already holds.

---

## Provenance discipline

Every fact you write into the model carries one of these tags in your
working notes:

- `[Code-verified]` — you read the source in `<target-dir>` and confirmed it,
  with a file:line reference.
- `[Owner-states]` — the owner told you and you have not (or cannot) verify
  it in code.
- `[User-supplied]` — a kickoff intake answer from someone who is not the
  owner (tag rules in `SKILL.md` Step 0.7).

The final files do not include the tags inline in prose. In the Section 4
`controls` cells, **only code-verified controls appear**, each suffixed
`(verified: file:line)` — an owner-stated control never enters the cell
(`schema.md` controls rule): it goes to Section 6 as a follow-up and does not move
the post score. Every `[Owner-states]` or `[User-supplied]` fact that
affects a score MUST be listed in Section 6 in the follow-up format. This is how an
interview-mode threat model stays honest about what is asserted versus
observed.

---

## Q1 — What are we working on?

Goal: fill Section 1 System context + TOE block, Section 2 Assets (with category and CIA
flags), Section 3 Entry points, Section 3b Data flows.

**Kickoff merge:** the Step 0.7 kickoff already collected deployment/
exposure, crown jewels, prior work, known FPs, and engagement context —
never re-ask those. Open Q1 by summarizing the kickoff answers back and
asking what is wrong or missing.

### Q1a. System description

If `--design-doc`/`--prd` or bootstrap findings exist: read them, then
**summarize the system back to the owner in 4-6 sentences** and ask "Is this
right? What did I miss?" This is faster than asking them to describe it cold
and surfaces drift between doc and reality.

If starting cold: "In two or three sentences, what does this system do and
who uses it?"

### Q1b. TOE: use case being modeled

The use case scopes the model to one operational context; a system with
several use cases deserves several models.

> "What is the specific use case we're threat modeling today? For example:
> processing untrusted input at runtime, an operator installing the tool, or
> the authentication flow from credential entry to session issuance?"

Capture it in one sentence; it lands inside the Section 1 prose (it is not
a labeled TOE field).

### Q1c. TOE: in scope / out of scope

> "The TOE is the software behavior itself — what the code does when it
> runs. Which components and behaviors are in scope?"

Then: "And what are we explicitly NOT modeling — build toolchain, repo
hosting, CI/CD, developer laptops — unless the software depends on them at
runtime?" If the owner pulls build/repo concerns in, gently suggest a
separate supply-chain model and record the boundary decision with its
reason. Record both lists.

### Q1d. Documentation

> "Any docs I should link — design docs, diagrams, PRDs?"

(The release under review needs no question: the target commit recorded in
Section 7 provenance is the anchor.) Do not record individual names in the output —
provenance says `owner: present` and attributes authorship to the owning
team or "Mozilla security review".

### Q1e. Assets, entry points, flows

- "What data does it hold or pass through that would be bad to lose, leak,
  or tamper with?" → Section 2 assets. For each: category (Data / Process /
  Infrastructure / External System) and "Is it more sensitive for
  Confidentiality, Integrity, or Availability — or several?" → C/I/A flags.
- "Where does input come from? Walk me from the outside in: network, files,
  CLI, other services." → Section 3 entry points.
- "Where does privilege change? Unauth to auth, user to admin, one service
  trusting another?" → trust boundaries.
- "How does data move between those pieces — and does anything leave the
  system: logs, telemetry, third-party APIs?" → Section 3b flows, each with
  crosses-boundary, trust transition, and C/I/A flags.

While the owner answers, **read the code** to corroborate: routes, file-open
calls, listeners, deserializers, template renders. Where code confirms, tag
`[Code-verified]` with file:line. Where code shows an entry point or flow
the owner did not mention, ask about it: "I see a `/admin/debug` route in
`routes.rs:88`; is that reachable in production?"

If `--seed` was provided: read its Section 1-Section 3b, summarize back, and ask only
"What's wrong or missing here?"

Lock down the asset and flow lists before moving on. **Checkpoint q1.json.**

---

## Q2 — What can go wrong?

Goal: fill Section 4 threat rows (threat, actor list, stride, cia, surface, asset,
in_repo).

Start open: **"For each of those entry points, what can go wrong? What's the
worst thing someone could do?"** Let the owner answer in their own words
first. Capture each answer as a candidate row.

When the owner stalls, switch to structured prompts — two sweeps that catch
different things:

### Q2a. STRIDE per entry point

| | Ask |
|---|---|
| **S**poofing | "Could someone pretend to be a user or service they're not, here?" |
| **T**ampering | "Could input or stored data be modified in transit or at rest?" |
| **R**epudiation | "If someone did something bad here, would you know who?" |
| **I**nfo disclosure | "Could this leak data it shouldn't?" |
| **D**enial of service | "Could someone make this unavailable or too expensive to run?" |
| **E**levation | "Could someone end up with more access than they started with?" |

### Q2b. CIA sweep per asset and per flow

Be systematic: all three dimensions for one asset/flow before the next.

- Confidentiality: "What would be bad if someone read or exfiltrated this
  without authorization? Who could try, and how?"
- Integrity: "What if it were modified or corrupted — in transit or at rest?"
- Availability: "What if it became unavailable or degraded? What could cause
  that — attack or otherwise?" (External dependencies count: "what happens
  when the IdP / database / object store is down?")

Use bootstrap findings to make the prompts concrete: if you saw an
unauthenticated endpoint touching a sensitive asset, ask about it directly.

### Q2c. Targeted probes (ask once each, where applicable)

- **Retention:** "For each stored data asset — does it grow forever? Is
  there an expiry job? Can you delete one user's data on request?" Missing
  answers on PII become threat rows, not notes.
- **Rendering:** "Is anything one class of user types shown to another class
  of user — including admin-to-admin?" (stored XSS probe).
- **Fragility:** "Any identity linking by email or other user-suppliable
  attribute? Client-chosen IDs used as storage keys? Protections that only
  hold if middleware stays in its current order? Defaults that ship open —
  auto-import, auto-approve, TLS verification toggles?"
- **AI/LLM (only if Step 0.6 found AI components, or the owner says the
  system calls a model):** "What text an attacker can influence ever reaches
  a prompt? Is model output executed, rendered, or used as tool arguments —
  and what bounds what the tools can do? Where do the weights, prompts, and
  retrieval data come from, and who can write to them? What limits token
  spend from a single cheap request?" Map answers to the AI class table in
  `bootstrap.md` 5f; rows score and tag like any other threat.

### Q2d. Derived classes

From the context (stack, language, deployment, data), name the 5-8 attack
classes most likely to matter for *this* system — at the granularity of
"IDOR on dataset rows", not "web vulnerabilities". Show the list: "Based on
what you've described, these are the classes I'd focus on. Anything you'd
add from incidents you've seen?" Their additions are high-signal; weight
them above your own. If a class you'd expect for this stack (injection,
deserialization, auth, memory safety, crypto, supply chain, infra/IAM)
didn't make either list, ask why before dropping it.

For each candidate threat, pin down: **actor(s)** (the enum list in
`schema.md` — record every actor class that can reach it, not just one),
**stride** and **cia** tags (both, always), **surface** (Section 3/Section 3b name),
**asset** (Section 2 name), **in_repo** (can this repo's owners fix it: yes / no /
partial). Phrase the threat at the level where it survives a patch. As you
capture rows, **cluster**: several owner anecdotes about the same
actor-wants-outcome are one row with multiple tags, not several rows.

If `--seed` was provided: walk the seed's Section 4 table row by row and ask "Does
this apply? Is the actor list right?" Then ask "What's missing?"

### Q2 → Q3 boundary: dedup, then spot-check (before any scoring)

1. **Dedup:** run the `bootstrap.md` Stage 5.5 merge test and merge
   semantics over the candidate rows, so the owner scores each root cause
   once and validates the merged table in Q4. Record the merge log.
2. **Inline validation:** code-verify the 3 highest-consequence
   `[Owner-states]` structural claims captured so far (an entry point's
   existence, a flow's auth status, a boundary) and feed the results back
   into the conversation — "you said X, the code shows Y" — so Q3 scores
   anchor on corrected facts rather than being corrected afterward in Section 6.
   Cap at 3 checks to respect owner time; unresolved ones proceed as
   `[Owner-states]` per the discipline above.

**Checkpoint q2.json.**

---

## Q3 — What are we going to do about it?

Goal: fill pre/post impact and likelihood plus controls for every Section 4 row;
fill Section 5 Deprioritized; collect Section 8 Recommended controls.

For each threat row, in order:

1. **Pre-mitigation:** "If this happened with **no controls in place**, how
   bad would it be?" → `pre_impact`; "and how likely would someone succeed,
   assuming no controls?" → `pre_likelihood`. Read the 5×5 scales from
   `schema.md` if needed. If the owner is unsure, offer anchors from
   bootstrap: past security fixes and obvious exposure push likelihood up;
   multiple auth layers with no exploitation history push it down. Record
   each score's anchor in `score_basis` (contract in `schema.md`).
2. **Controls today:** "What's in place right now that stops or limits
   this?" For each named control, verify in code where possible and tag
   `(verified: file:line)` in the cell. A control you cannot verify **stays
   out of the cell**: record it as an `[Owner-states]` Section 6 follow-up ("verify
   by: <check>") — it does not move the post score. If they track controls
   in a sheet: "Does this control have an ID there? If not we leave the ID
   blank for you to assign." Never invent Control IDs.
3. **Post-mitigation:** "Given those controls, where are impact and
   likelihood now?" Credit verified controls only; heuristic in `schema.md`
   (strong consistent control: likelihood down 1-2 levels; partial: 0-1;
   impact rarely moves). Record the credited control per post score in
   `score_basis`. `status` is derived at emit per the `schema.md`
   precedence — do not ask for it.
4. **Risk acceptance:** if the owner says "we're accepting this risk",
   capture their reason verbatim and move the row's disposition to Section 5 with
   that reason.

The answer to Q3 is allowed to be "nothing, and we're not going to":
deprioritized threats with a recorded reason are a valid output.

After scoring, ask one closing question per **threat class** (not per row):
"If we could land one engineering control that makes this whole class go
away or shrink, what would it be?" Record the answer (or your own proposal
if the owner punts) as a Section 8 row: control, description, type
(Preventive/Detective/Corrective), threat_ids, closes_class, effort. Prefer
controls that survive the next bug (sandboxing, parameterized queries, CSP,
allocation caps) over patches for the last one.

**Checkpoint q3.json** (including the verified-controls ledger).

---

## Q4 — Did we do a good job?

Goal: validate before writing.

- Read the draft Section 4 table back, sorted by residual (post-mitigation) risk.
  Ask: **"Does this ranking reflect your understanding of the system's risk?
  Is anything ranked too high or too low?"** Adjust.
- Ask: **"Is there any risk you have been concerned about that is not on
  this list?"** Add and score it.
- Check coverage yourself: every Section 3 entry point and Section 3b flow name must
  appear in at least one Section 4 `surface` cell, OR a Section 5b row must say
  "<name>: out of scope because …". Every Section 2 asset must appear in at least
  one Section 4 `asset` cell or a Section 5b row. If neither, either add a threat or ask
  the owner why it's safe and record the answer in Section 5b.
- Fill the **category ledger** (`schema.md` Section 5a, the master checklist)
  with the owner in the room — it takes two minutes and is the highest-value
  part of Q4: read out each category with no disposition yet and ask "does
  this apply here?" An owner's "not applicable because <TOE fact>" is exactly
  the grounding the ledger needs; a category neither of you can disposition
  becomes a Section 6 question, never a blank.
- Ask: **"Would you do this again for the next service? What would make it
  easier?"** Record the answer in your hand-back (not in the file); it's
  feedback for this skill.

**Checkpoint q4.json.**

---

## Emit

Identify 3-5 attack chains (Section 4b) linking Section 4 ids. If `--prior` is in effect,
read `artifacts.md` now and run the drift pass (it fills Section 9 and may mint new
rows; re-score them with the owner while they are still present).

Read `schema.md` **now**, then write `<run-dir>/THREAT_MODEL.md` (the model
proper: Sections 1-10) at full detail — the detail pass in `SKILL.md` Step
2.6 applies the run's `detail` level afterwards — then the selected extras
only (overview companion per `schema.md` File 1b if selected; CSVs per
`schema.md`; diagram per `diagram.md` only if selected at kickoff). Set Section 7 Provenance per `schema.md` with `mode: interview`
(or `bootstrap-then-interview`), `owner: present`, and
`calibration: owner-reviewed`.

**Then return to `SKILL.md` Step 2**, which owns the full end-of-run
sequence: all emit-verification checks, the review gates, profile rendering,
the detail pass, the `COMPLETE` write, and the hand-back. This mode file
never writes `COMPLETE`. Mode-specific hand-back additions for interview
(folded into the Step 2 hand-back, never volume-framed):

- Every `[Owner-states]` claim that affects a score, as a follow-up list
  (already in Section 6): `- [Owner-states] <claim>. Affects: <Tn field>. Verify
  by: <suggested check>.`
- If `--seed` was provided: a short diff summary ("added three rows on the
  webhook path, downgraded T2 residual because the owner's size-cap claim
  was code-verified").
