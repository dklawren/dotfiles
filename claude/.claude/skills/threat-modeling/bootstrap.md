# /threat-modeling bootstrap

> **Re-read note:** If you need this file mid-session and the Read tool
> reports "file unchanged", the prior result was evicted from context; reload
> with `cat <skill-dir>/bootstrap.md` via Bash.

Derive a threat model from **code + past vulnerabilities** when no application
owner is available. The stages: spawn a parallel research swarm, synthesize
its findings into Section 1-Section 3b and a vuln working table (with an inline
spot-check), generalize vulns into threat classes, run the CIA sweep,
gap-fill with STRIDE plus the targeted passes (5b-5i, with an inline
spot-check), dedup (Stage 5.5), verify as-built controls, emit per
`schema.md`.

**Fact provenance:** bootstrap facts are `[Code-verified]` (you read the
source, with file:line) or `[Owner-states]`/`[User-supplied]` (kickoff
intake answers). The tag rules — what tagged facts may and may never do —
live in `SKILL.md` Step 0.7 and apply verbatim here and inside every
subagent.

This mode is read-only static analysis and is **language-agnostic**: the same
stages apply whether the target is C/C++, Rust, Go, Python, Java/Kotlin,
JavaScript/TypeScript, or polyglot. Do not build, run, or fuzz the target. The
Bash tool is permitted **only** for `git` (history mining), `find`/`ls`
(layout), `gh api` (public advisory lookup), `mkdir`/`date` (run-dir
bookkeeping), and `cat` (re-reading skill files). Do not execute anything from
inside `<target-dir>`. The same restriction applies to every subagent you
spawn: pass it verbatim in each prompt. **Never write into `<target-dir>`** —
all state and outputs go to the run directory (see `SKILL.md`).

---

## Inputs

- `<target-dir>` (required): local checkout.
- `--vulns <path>` (optional): past vulnerabilities. Any of:
  - newline-separated CVE IDs (`CVE-2026-29022`)
  - CSV with columns `id,title,component,description` (extra columns ignored)
  - markdown pentest report (parse headings + body for finding descriptions)
  - JSON array of objects with at least `id` and `description` keys
- `--prd <path>` / `--design-doc <path>` (optional): read in Stage 1 (Docs
  reader brief).
- `--prior <path>` (optional): a prior THREAT_MODEL.md; triggers the drift
  pass in Stage 7 (procedure in `artifacts.md`).
- `--target-profile <path>` (optional): a prior run directory (or a profile
  file distilled from one) for this target. Its recurring bug classes seed
  the History miner's keyword set, its authorization primitives seed the
  Surface mapper, and its 5h matrix is diffed against this run's. Record
  `target_profile: <source>` in Section 7.
- `--depth recon|full` (optional, default `full`): `recon` runs stages 1-2
  only. Still write all sections; leave Section 4, Section 4b, Section 5, and Section 8 as header +
  empty table, and put "run with --depth full to populate" in Section 6. Recon runs
  take the reduced emit-check set defined in `SKILL.md` Step 2.1 (no
  Section 4-dependent checks, no review gates, no profiles); provenance records
  `depth: recon`; `COMPLETE` is still written.
- `--fresh` (optional): ignore any resumable run dir and mint a new one.

Shared flags (`--context`, `--artifacts`, `--profile`, `--visibility`,
`--review`, `--taxonomy`, `--out`) are handled in `SKILL.md` Steps 0.5-0.7
and are not restated here.

If `--vulns` is absent, the Vuln-file parser agent is skipped; the History
miner and Advisory fetcher agents cover the same ground from `<target-dir>`'s
own git history and public advisories.

---

## Checkpointing (runs before Stage 1 and after every stage)

On large codebases the Stage-1 swarm can exhaust context or hit rate limits
before Stage 7 emits. Stage state persists as plain JSON files in the **run
directory** so a fresh session can resume without re-spawning the swarm.

- **Start of run:** resolve the run dir per `SKILL.md` (resume an unfinished
  run whose `scope.json` matches the resolved target path; otherwise, or with
  `--fresh`, mint a new one and write `scope.json`).
- **Resume:** read `stage1.json` through `stageN.json` in order, merging keys
  into working state (later files override earlier). Print
  `Resuming from checkpoint: Stage N complete` and skip to Stage N+1.
- **End of every stage N:** Write tool → `<run-dir>/stageN.json` with the
  stage's output (shapes at the tail of each stage below).
- **End of run:** after Stage 7's emit, return to `SKILL.md` Step 2 — it
  owns the review gates, profile rendering, the detail pass, and the
  `COMPLETE` write. This mode file never writes `COMPLETE`.

---

## Stage 1 — Research swarm

Goal: gather everything needed to fill Section 1-Section 3b and the vuln working table, in
parallel. Spawn the agents below **in a single batch** with the Task tool so
they run concurrently. Each agent gets a narrow brief, the absolute path to
`<target-dir>`, and the read-only restriction verbatim. Each returns a
structured text block; you synthesize in Stage 2.

**Prepend the kickoff intake digest to every agent brief, tagged:**
deployment/exposure to the Surface mapper and Infra reader (prioritize
internet-facing surfaces); data classes and crown jewels to the Asset finder
(seed its grep list); prior-findings paths to the Vuln-file parser; known
FPs to the History miner and Advisory fetcher (still report matches, flagged
known-FP — suppression happens only at emit, with a Section 10 note, never at
collection). Agents treat intake facts as hypotheses to confirm in code, not
ground truth — the SKILL.md Step 0.7 tag rules apply inside subagents too.

**Per-target adaptation:** when `--target-profile` is set (or a prior
COMPLETE run dir for this target exists), append its recurring bug classes
to the History miner brief as extra grep keywords, its known authorization
primitives to the Surface mapper brief, and carry its prior 5h matrix into
Stage 5h for diffing. This is how repeat runs get sharper per repo instead
of restarting generic.

Skip the swarm and run the briefs yourself sequentially if `<target-dir>` is
small (<50 source files), `--depth recon` is set, **or the Task tool is not
available in your environment** — record the adaptation in Section 7 provenance
(`swarm: inline-sequential`). Same briefs, same outputs, same checkpoint
shape either way.

| Agent | Brief | Returns |
|---|---|---|
| **Docs reader** | Read `README*`, `SECURITY.md`, `CHANGELOG*`, top-level `docs/`, the build manifest (`Cargo.toml` / `package.json` / `setup.py` / `CMakeLists.txt`), and any `--prd`/`--design-doc` files. Summarize what the project says it is, who uses it, security claims, and documented fixes. | Prose system description; list of self-documented security fixes. |
| **Surface mapper** | Grep the source tree for entry-point signatures (table below). For each hit, name the surface, the file:function, and what crosses it. Include supply-chain surfaces (lockfiles, vendored deps, `curl \| sh` in build scripts). **Mandatory frontend/template sub-brief:** map every rendering surface — SPA code, server-rendered templates, anywhere a stored string one class of user controls is displayed to another class of user (including admin-to-admin) — and note whether output encoding/sanitization is visible at each. **Fork-delta sub-brief (targets that fork or extend an upstream):** enumerate the fork's own additions (e.g. an extensions/ or custom-modules dir) **exhaustively** — every route, API method, listener, custom field; the sampling cap below applies to the upstream body only. Fork code composing with permissive upstream defaults inherits that exposure — flag those seams for 5c. Bound the scan: exclude `vendor/`, `node_modules/`, `third_party/`, generated code; cap at ~5 representative hits per surface row (upstream body only). | Candidate Section 3 rows: `{entry_point, description, trust_boundary, file_refs}` + rendering-surface notes. |
| **Flow mapper** | Trace how data moves: ingress (HTTP/gRPC/queue handlers, uploads), processing (transform, store, forward), egress (responses, logs, third-party SDK calls, telemetry). For each flow: source → destination, what asset it carries, whether the channel is authenticated/encrypted/validated, and whether it crosses a trust boundary. Logging and telemetry are flows too — they are often a confidentiality surface. | Candidate Section 3b rows: `{flow, source, destination, crosses_boundary, trust_transition, description, file_refs}`. |
| **Infra reader** | Read deploy-time config: `*.tf`/`*.tfvars`, k8s manifests and helm charts, `Dockerfile*`, CI workflows, IAM/service-account/ACL files. For each: (a) the identity it runs as and what that identity can reach, (b) any access grant not managed in this tree, (c) credentials or principals that survive a migration or teardown, (d) **security-relevant defaults that ship off or wide** (TLS verification toggles, network policies absent, debug endpoints exposed), (e) **artifact/model/package signing and verification at load or deploy** (image attestation, model checksums, package signature checks — an executed-artifact path with no verification is a finding), plus secret-sync mechanics (secret-store version pinning vs latest, whole-blob vs per-key extraction, optional mounts) and any designed break-glass paths (feeds 5i). Mark which referenced components live outside this repo — those feed `in_repo: no|partial`. | Candidate Section 3 rows for infra surfaces + candidate Section 4 rows: `{threat, surface, asset, in_repo}`. |
| **Asset finder** | Identify what the code protects or produces: sensitive data it reads/writes (secrets, keys, PII, user records, DBs, audit logs), process assets (services, jobs, signing), infrastructure assets (databases, buckets, queues, caches), external-system assets. For each: category (Data/Process/Infrastructure/External System), where it lives, and **which CIA dimensions it is sensitive on (Yes/No each)**. Grep seeds: `password`, `secret`, `api_key`, `token`, `private_key`; PII indicators (`email`, `user_id`, `dob`, `address`); storage references; config loading. | Candidate Section 2 rows: `{asset, category, description, sensitivity, C, I, A}`. |
| **History miner** | Two steps. **(a)** Glance at the build manifest and file extensions to identify language **and domain**, then derive 6-10 commit-message keywords specific to that stack on top of the base set `CVE- security vuln fix exploit`. Derive from what the code does, not a lookup table (native parser → `overflow OOB UAF integer`; web service → `injection SSRF IDOR traversal`; crypto → `timing constant-time nonce`). **(b)** `git -C <target-dir> log --all -i --grep='<base ∪ derived, \|-joined>' --oneline`, then read the full message + diff of each hit. Also grep any `issues/` or `bugs/` export in-tree. **(c) Control removals and trust assumptions:** grep history for removals of guards (`remove`/`delete`/`drop` near `valid`/`check`/`gate`/`require`) and for trust-assumption phrases ("only written by", "trusted", "assumes"); for each assumption found, verify a code counterpart exists at HEAD — an assumption enforced nowhere is a vuln-table row and a 5c fragility item. **Cite commits by hash only — never copy author names, handles, or emails from commit metadata into any artifact or note.** | Vuln rows: `{id (commit hash), title, component, class, vector}`. |
| **Advisory fetcher** | **Only if the kickoff engagement answer permits public advisory lookups** (default: yes; if lookups are forbidden, skip and record a Section 10 `tooling_limit` entry plus a Section 6 open question — do not decide this ad hoc). GitHub is the only reachable source (`SKILL.md` Step 0 item 4): if `git -C <target-dir> remote get-url origin` is GitHub and `gh` is on PATH: `gh api /repos/{owner}/{repo}/security-advisories`. Otherwise return "no reachable advisory source" (also a Section 10 `tooling_limit`). | Vuln rows: `{id (CVE/GHSA), title, component, class, vector}`. |
| **Vuln-file parser** | Only spawn if `--vulns <path>` was provided. Parse the file into normalized rows. | Vuln rows: `{id, title, component, class, vector}`. |

Surface-mapper grep targets (pass this table in its prompt). Treat the
"Look for" column as a **seed, not a checklist**: one concrete token per row
to set the specificity bar, then extend with the idioms of whatever
language/framework the target actually uses.

| Surface | Look for |
|---|---|
| Network | socket `listen`/`accept`/`bind`; HTTP route definitions; RPC/gRPC/GraphQL service defs |
| File / format parsing | file-open calls; format magic-byte checks; "parse"/"decode"/"load"/"unmarshal" function names |
| CLI / env | argv parsers; env reads (e.g., `getenv`) |
| Deserialization | language-native deserializers on external data (e.g., `pickle`, `ObjectInputStream`) |
| DB / query | raw query-string construction; ORM `.raw()`/`.query()` escapes |
| IPC / plugins | dynamic load (e.g., `dlopen`); subprocess spawn; `eval`/`exec` on config; dynamic import |
| Rendering | template render calls; `innerHTML`/`dangerouslySetInnerHTML`; SPA components displaying server data |
| User-configurable automation | rules engines, user-defined webhooks/triggers, saved automations that run server-side on others' data |
| Supply chain | dependency lockfiles; vendored libs; `curl \| sh` in build scripts |
| Infra / IAM | terraform IAM resources; k8s `serviceAccountName`/NetworkPolicy; dataset/table ACL blocks; secrets mounts; TLS/verify toggles in charts |

**Checkpoint:** Write tool → `<run-dir>/stage1.json`:

```json
{
  "stage": 1,
  "swarm": {
    "docs_reader": "<returned text block>",
    "surface_mapper": [ {entry_point, description, trust_boundary, file_refs} ],
    "flow_mapper": [ {flow, source, destination, crosses_boundary, trust_transition, description, file_refs} ],
    "infra_reader": { "surfaces": [...], "threats": [...] },
    "asset_finder": [ {asset, category, description, sensitivity, C, I, A} ],
    "history_miner": [ {id, title, component, class, vector} ],
    "advisory_fetcher": [ {id, title, component, class, vector} ],
    "vuln_file_parser": [ {id, title, component, class, vector} ]
  }
}
```

This is the most expensive checkpoint — the swarm is the majority of the
mode's token spend. Agents that were skipped get an empty list/null. If the
swarm was run inline (small target), populate the same keys from your own
sequential passes.

---

## Stage 2 — Synthesize

Goal: turn the swarm returns into Section 1, Section 2, Section 3, Section 3b of the schema plus a vuln
working table. This stage runs in the orchestrating agent, not a subagent;
it's the join.

**Section 1 System context + TOE.** From the Docs reader's summary plus your own
glance at the tree layout, write 1-2 paragraphs (what it is, language, rough
size, who deploys it, where it runs, and — in one sentence — the specific
use case being modeled) and fill the TOE block: in-scope and out-of-scope
bullet lists with reasons (build toolchain, CI/CD, and developer
workstations are out unless the software depends on them at runtime);
documentation paths.

**Section 2 Assets.** Take the Asset finder's rows. Dedupe, fill obvious gaps
(native code without "host process integrity" → add it), assign `category`,
`sensitivity`, and the C/I/A Yes/No flags.

**Section 3 Entry points & trust boundaries.** Merge Surface mapper + Infra reader
rows. Dedupe, name the trust boundary for each, and for each list which Section 2
assets are reachable from it. Supply-chain, build-time, and infra/IAM
surfaces **are** entry points. **Every Section 3 row and every Section 3b row must get at
least one threat in Stages 3-5 or a Section 5 deprioritized entry**; that's the
coverage invariant the emit-time check enforces.

**Section 3b Data flows.** Take the Flow mapper's rows. Dedupe, resolve source and
destination names against Section 2, mark boundary crossings and trust transitions,
set the C/I/A flags.

**Vuln working table.** Concatenate rows from History miner + Advisory
fetcher + Vuln-file parser. Dedupe by `id`. For each row, decide which Section 3
entry point (or Section 3b flow) it traversed; read the relevant source to confirm.
If a vuln's entry point isn't in Section 3, the Surface mapper missed one; add it
now. Hold this table in working notes; it does **not** go into the output
verbatim. It becomes the `evidence` column in Stage 3.

**Inline spot-check (mandatory before the checkpoint):** spot-verify 3
load-bearing claims in code before continuing — sample 3 Section 3 entry points and
2 Section 3b flows from swarm output and re-open one `file_ref` each: the file must
exist and the cited construct must be there. Any failure quarantines that
swarm agent's remaining rows for full (not sampled) re-verification before
use, **now** — a failed spot-check triggers re-research of that area
immediately, not at emit. Record `spot_check: {sampled, failed, fixed}` in
the checkpoint.

**Checkpoint:** Write tool → `<run-dir>/stage2.json` with keys
`section1_context`, `section2_assets`, `section3_entry_points`,
`section3b_flows`, `vuln_table`, `spot_check`.

---

## Stage 3 — Generalize: vulns → threats

Goal: cluster Stage-2 vulns into threat rows at the right abstraction level.

### 3a. Cluster

Group the vuln table by `(entry point or flow, bug class, asset reached)`.
Each cluster becomes **one** candidate threat:

- 3 heap overflows + 1 integer overflow, all in audio parsers, all reaching
  process memory → **one** threat: "Memory corruption leading to RCE via
  untrusted audio file parsing". Evidence: all 4 IDs.
- 2 SQL injections in different endpoints → **one** threat: "Data
  exfiltration / tampering via SQL injection in HTTP API". Evidence: both IDs.

Apply the litmus test to each cluster's threat statement: would it still be
true after every listed evidence item is patched? If not, you're still at
vuln level; zoom out.

### 3b. Variant scan (raises likelihood)

For each cluster, look for **siblings**: code paths with the same shape that
weren't in the vuln list (other format parsers, other endpoints calling the
same unsafe helper, other size fields multiplied without overflow checks).
You are not proving these exploitable; you are estimating how much of the
surface shares the pattern. More siblings → higher likelihood.

Keep sibling locations in working notes and surface them in the hand-back.
Do **not** put `file:func` references in the Section 4 `evidence` cell; evidence is
for confirmed past vulns only. **Omit evidence rather than stretch it** — an
empty cell is fine; a weak or unverifiable reference is not. A commit
qualifies as evidence only if its **own subject/diff instantiates the threat
class** — a reliability fix, refactor, or adjacent-area change that merely
touches the same files goes to working notes, not the evidence cell. A hash
may be paired with its public tracker id (`abc1234 (Bug 12345)`) for
anchoring. **Resolve every evidence hash the moment it enters a cluster**
(`git -C <target-dir> cat-file -t <hash>`) and read the commit subject to
confirm it instantiates the class — a dead or off-class hash must not
inflate `pre_likelihood` for four stages before the emit lint catches it.
Score with the `schema.md` 5×5 words from the first draft — never
High/Critical band shorthand that needs later translation.

### 3c. Score and tag

For each cluster, assign:

- `actor`: from the entry point — **as a list**. A surface reachable by more
  than one actor class (e.g., an insider and a compromised authenticated
  session) carries all of them.
- `stride` and `cia` tags: every row gets both.
- `in_repo`: yes / no / partial — is the subject of this threat fixable in
  this repository?
- `pre_impact` / `pre_likelihood`: score as if no controls existed. Anchor
  likelihood on observables (see the no-owner calibration rule in
  `schema.md`): ≥1 confirmed past vuln in this exact surface → at least
  `Likely`; public exploit or active exploitation → `Certain`; no evidence
  but siblings found and the technique is well known → `Possible`. Record
  each score's anchor in the `score_basis` map (contract in `schema.md`) —
  impact and likelihood both; intake exposure answers count as anchors when
  cited.
- `controls`: candidates only for now — grep for mitigations relevant to the
  stack (size caps, input validation, sandboxing; parameterized queries;
  auth middleware, CSRF tokens, CSP; rate limiting; audit logging). Stage 6
  verifies them.
- `post_impact` / `post_likelihood`: provisional, pending Stage 6.
- `recommended_control` (working notes, not a Section 4 column): one class-level
  control per cluster that survives the next bug ("sandbox the decoder
  process", "parameterized queries everywhere", "enable CSP
  default-src 'self'"), with type (Preventive/Detective/Corrective) and
  effort. These become Section 8 rows at emit.

**Checkpoint:** Write tool → `<run-dir>/stage3.json` (carry all prior keys
plus `section4_threats`, `mitigation_notes`, `sibling_locations`).

---

## Stage 4 — CIA sweep (per asset, per flow)

Past-vuln clustering is biased toward what's already been found; the CIA
sweep is systematic. Walk **every Section 2 asset and every Section 3b flow**, and for
each one consider all three dimensions:

- **Confidentiality:** who could read or exfiltrate this without
  authorization, and how? (For flows: interception, over-broad logging,
  leaking to third parties.)
- **Integrity:** who could modify or corrupt it, in transit or at rest?
- **Availability:** what makes it unavailable or degraded — attack, outage,
  or resource exhaustion?

Record every plausible hit in a **raw CIA grid** in working notes
(`asset/flow × dimension → candidate threat`). Then **cluster the grid
through the Stage-3 generalization** before anything reaches Section 4: many grid
cells collapse into one actor-wants-outcome row carrying multiple `cia`
tags. Do not emit one row per grid cell — the grid is exhaustive input, the
Section 4 table stays clustered. Keep the raw grid in working notes; it feeds the
per-dimension CSV rows if CSVs were selected.

**Grid-remainder check (clustering must not swallow distinct root causes):**
after clustering, walk the raw grid once more — every plausible cell must
land in a Section 4 row or a Section 5 entry. Clustering merges *shared root causes only*:
CSRF is not XSS, CORS misconfiguration is not an authorization gap,
automation-rule abuse is not generic tampering, transport MITM is not the
app-layer threat it enables. A cell with its own distinct mechanism gets its
own row even when the affected asset already has one. This is the measured
failure mode of cluster-style models: the mechanical long tail (CSRF, CORS,
webhook/rules abuse, transport) silently disappears into broader rows.

Coverage invariant after this stage: **every asset and every flow has at
least one Section 4 row or a Section 5 deprioritized entry.**

**Checkpoint:** Write tool → `<run-dir>/stage4.json` (all prior keys plus
`cia_grid`, updated `section4_threats`, `section5_deprioritized`).

---

## Stage 5 — Gap-fill: STRIDE + the targeted passes (5b-5i)

### 5a. STRIDE walk

For **every Section 3 entry point that has no Section 4 row yet**, walk STRIDE and add at
least the plausible ones:

| | For this entry point, could an attacker… |
|---|---|
| Spoofing | …pretend to be a trusted source? |
| Tampering | …modify data in transit or at rest? |
| Repudiation | …act without leaving attributable logs? |
| Info disclosure | …read data they shouldn't? |
| DoS | …exhaust a resource (CPU, memory, disk, connections)? |
| Elevation | …end up with more privilege than they started with? |

Also walk the entry points that **do** have rows: is the existing row the
only plausible threat, or are other STRIDE categories live too? (A file
parser with an RCE threat probably also has a DoS threat.)

For any **cookie-authenticated web UI**, explicitly answer CSRF and
clickjacking (token/SameSite posture, frame-ancestors) — a Section 4 row or a Section 5
entry, never silence.

For **infra/IAM entry points**, walk these instead: over-grant (identity
reaches more than the app needs); lateral identity (co-located workload can
assume it); drift (grants managed outside this tree); residual access
(predecessor credentials survive); column exposure (broad reads expose PII
the app doesn't need); scope enforcement (what bounds an automated approve/
merge/write path to its intended scope).

### 5b. Retention and compliance pass

For **every stored data asset** in Section 2, answer four questions from the code
and config:

1. Is growth bounded (size caps, TTLs, partition expiry)?
2. Is there an expiry or cleanup job?
3. Is there a per-user deletion path?
4. Can a stored record be linked back to a user, so an erasure request is
   satisfiable?

A missing answer on a PII-bearing asset is a **threat row** (typically
`cia: C` with regulatory impact), not an open question. Only downgrade to Section 6
if the code genuinely cannot show the answer either way.

Also ask the **forensic-retention** questions: for every log or transcript a
threat row or a Section 5 deprioritization relies on ("audit trail exists"), find
its retention/GC default (TTL, garbage collector, rotation). Evidence that
self-deletes faster than a realistic detection window is a repudiation
threat row, and any Section 5 deprioritization citing a control must carry a
`(verified: file:line)` tag **including that retention default** — an
unverified "we'd see it in the logs" is not a reason to deprioritize.

Also build the **expected-vs-actual detection table** (feeds category 17):
for each log/telemetry source a defender would expect — request logs, audit
tables, cloud data-access audit, WAF/LB logs, DB statement logs, SIEM sinks,
analytics datasets — record: exists? → where it lands → who can read it →
retention. "The state is queryable but the change is unlogged" and "reads of
the crown-jewel dataset are unaudited" are threat rows, not notes; the table
itself goes to working notes (and into the file only at `detail: full`).

### 5c. Fragility pass (design-level and code-idiom threats)

Hunt for correct-looking constructions that betray the system later:

- **Layer-ordering fragility:** middleware or layer stacks where reordering
  silently drops a protection (body limits, auth, rate limits applied per
  route instead of globally).
- **Client-chosen identifiers** used as storage keys or filenames
  (overwrite, collision, and enumeration risks).
- **Identity linking that falls back to weaker claims** — account linking or
  lookup by unverified email or other attacker-suppliable attribute.
- **Defaults that widen exposure:** auto-import, auto-approve, auto-enroll
  paths that ship enabled.
- **TLS-verification and similar foot-guns** reachable from production
  config: chart/config toggles that disable verification, missing
  NetworkPolicy, permissive CORS defaults.

Each hit becomes a threat row phrased at outcome level, with the fragile
construction noted in working notes (not in `evidence`).

### 5d. Rendering-surface pass

Using the Surface mapper's frontend sub-brief: for every place a stored
string controlled by one class of user is rendered to another class of user
(including admin-controlled strings shown to other admins), either confirm
output encoding/sanitization with file:line in working notes, or add a
stored-XSS/content-injection threat row. An empty result from this pass on a
system with any web UI is suspect — re-check before accepting it.

### 5e. Dependency-availability pass

For each external runtime dependency (database, IdP, object storage,
registry, third-party API): add an explicit outage/degradation threat
(`cia: A`) or a reasoned Section 5 deprioritization. "The IdP going down" is a
threat row even though no attacker is required.

### 5f. AI/LLM threat pass (only when Step 0.6 found AI components)

For each AI component found (model call sites, prompts, agents/tools, MCP
servers, RAG/vector stores, model artifacts, training/eval data), walk this
checklist and add outcome-level threat rows for the plausible ones. Map each
to the shared taxonomies as usual (STRIDE + CIA) and note the AI class in
the threat sentence so the Section 4 AI rollup can list it:

| AI class (OWASP LLM Top 10 / MITRE ATLAS aligned) | Ask |
|---|---|
| Prompt injection (direct & indirect) | Can attacker-controlled text (user input, stored records, fetched pages, tool results) reach a prompt that has more authority than the attacker? |
| Insecure output handling | Is model output executed, rendered, or interpolated (SQL, shell, HTML, tool args) without validation? |
| Excessive agency / tool abuse | What can the model's tools do at maximum, and what bounds a hijacked agent (allowlists, approvals, spend caps)? |
| Sensitive-data disclosure via model | Can prompts/context leak secrets or PII into responses, logs, or the provider? Is context shared across users/tenants? |
| Model & data supply chain | Where do weights, prompts, embeddings, and fine-tuning data come from; are they integrity-checked like any other artifact? |
| Poisoning (training/RAG) | Who can write to what the model learns from or retrieves (feedback loops, shared indexes, scraped corpora)? |
| Model DoS / cost abuse | Can an unauthenticated or cheap request drive unbounded tokens, recursion, or fan-out? |
| Trust-boundary confusion | Is model output treated as trusted input anywhere downstream (the litmus: an LLM is an untrusted-input *source*, not a validator)? |

These are ordinary Section 4 rows — same litmus test, same scoring, same evidence
rules. Do not fabricate AI threats when Step 0.6 found nothing; record
`ai_components: none found` in Section 7 and skip this pass.

### 5g. Credential & session lifecycle pass

For **every credential the system issues or stores** (sessions, API/bearer
keys, OAuth/IdP tokens, automation keys, agent tokens), answer from code:

1. What creates it, what expires it, what revokes it — and does revocation
   actually take effect (is the revocation column consulted on use)?
2. When the upstream identity is disabled or its MFA is revoked at the IdP,
   does that propagate to this credential, or does it keep working?
3. Is the credential bound to anything (IP, client, MFA state) or is
   possession sufficient for its full lifetime?

A credential that unlocks restricted data and has **no revocation path or no
upstream-deprovisioning propagation** is a threat row, not a note. This pass
exists because enumeration methods run out of prompts exactly here: the
post-login lifecycle is invisible to per-asset and per-entry-point walks.

### 5h. Authorization proof matrix (roles, entitlements, escalation edges)

STRIDE's "could an attacker elevate?" is too shallow for systems with real
role/entitlement machinery — measured runs found member-to-admin chains that
per-entry-point walks missed. This pass makes authorization *provable*:

1. **Enumerate every authorization primitive:** role tables/whitelists,
   policy classes (one line of effective logic each), tier/feature matrices,
   claim flags, controller gates **and their base-class inheritance**.
2. **Build a role × capability matrix** — one row per role/tier, one column
   per consequential capability; every cell is allow/deny **with a file:line
   proof**. A cell without a proof line does not ship.
3. **Walk escalation edges**, each with verdict REACHABLE / BLOCKED /
   UNCERTAIN plus proof:
   - who grants each role (UI, API, IdP sync, env allowlists, seeds), and
     whether grantors can self-serve or mint peers;
   - self-service paths: group/tenant admins acting on **arbitrary target
     users** (verify the target is validated, not just the container),
     invitation flows (do parallel invite paths grant different
     privileges?), signup perks;
   - horizontal: does every ownership policy test the **record**, not the
     actor? (Measured failure: a policy reading the *actor's* attribute
     handed every member full user CRUD including peer password resets.)
   - token lifetime vs revocation: are capabilities embedded in tokens or
     re-read live per request? do role/group removals revoke already-issued
     credentials? any non-default token lifetimes that bypass the TTL?
   - MFA/step-up boundaries **by inheritance chain, not by grepping for
     skips** (measured failure: an API base class that simply never included
     the MFA filter — there was no skip to find);
   - fail-open lookups (feature matrices returning allow on unknown keys),
     unscoped role checks (a role test without its resource argument),
     missing `verify_authorized`/`verify_policy_scoped` backstops, and
     Scope resolvers that fall through returning nil instead of none;
   - identity linking: flows that bind an external identity to a
     pre-existing local row without re-proving control (password reset on
     link, email verification).
4. Every REACHABLE edge becomes a Section 4 row. The matrix itself is an
   appendix rendered only at `detail: full` (detail class b); at `detail:
   public` Section 7 notes its omission and the overview's artifact index,
   if one is written, notes its existence. If `--target-profile` supplied a
   prior matrix, diff and report changed cells.

### 5i. Break-glass & operational safety

For each of: (a) emergency auth disable/enable, (b) secret rotation,
(c) image/artifact rollback, (d) stopping a job/scan/spend flood — answer
from code and deploy config: does a **designed** path exist, or does the
emergency require raw infrastructure access? Then hunt for what actively
**blocks** emergency response: destroy-protection pins on exactly the
resources an incident must change, evidence-deleting job hooks,
single-approver bottlenecks, kill switches removed in history (grep for
their removal), and IaC that can clobber live out-of-band-managed state
(missing ignore-changes on seeded secrets). A privileged workflow with no
designed break-glass, or with an active blocker, is a Section 4 row (usually
`cia: A` or `I`), not a note.

Threats added in Stage 5 have empty `evidence`. That's expected; score
likelihood from technique prevalence and surface reachability alone. **The
final Section 4 table must contain at least one row with empty evidence**, or
gap-fill didn't run.

**Category ledger walk (closes Stage 5 — the scope-discipline backstop).**
Open the master category checklist in `schema.md` Section 5a and walk it end
to end: for each category, record `covered` (with the Tn ids), point it at a
Section 5b deprioritized row, mark it `not-applicable` with a TOE-grounded
reason, or mint a Section 6 `needs-owner` question. A category you cannot
disposition means a pass was skipped or the scope is wrong — go back and run
the relevant pass (5a–5i) against that category NOW, before dedup. This walk
exists because measured runs showed whole categories going missing silently
when scope was thin; the ledger makes every omission explicit and reviewable.

Populate Section 5b (Deprioritized) with categories you considered and ruled out,
with reasons ("Repudiation: not applicable, no multi-user actions").

**Inline spot-check (mandatory before the checkpoint):** for 3 sampled
minted rows, confirm in code that the named surface and asset resolve
against Section 3/Section 2 by exact name and that the working note names at least one
concrete location (the SKILL.md concreteness bar). A failure means the pass
that minted the row cut corners — re-research that area **now**, not at
emit. Record `spot_check: {sampled, failed, fixed}` in the checkpoint.

**Checkpoint:** Write tool → `<run-dir>/stage5.json` (all prior keys,
updated `section4_threats`, `section5_deprioritized`, `spot_check`).

---

## Stage 5.5 — Dedup (after all Stage-5 passes, before control verification)

Clustering happens per-source (Stage 3 clusters vulns, Stage 4 clusters the
CIA grid, Stage 5 passes mint independently), so the same root cause can
appear twice under different framings — one row from the CIA sweep ("config
tampering via unauthenticated admin API", cia:I) and one from the STRIDE
walk ("privilege elevation via unauthenticated admin API", stride:E). Merge
them **before** Stage 6 so each control is verified once per merged row, not
per duplicate.

**Merge test — two rows merge when all three hold:**

1. Same root-cause mechanism (the condition a single fix would remove);
2. Same surface, or overlapping surface sets;
3. Same asset, or one asset set contains the other.

Different STRIDE/CIA framings of the same mechanism are exactly what merges.
The Stage-4 grid-remainder rule is the counter-rule and applies verbatim:
**distinct mechanisms never merge** — CSRF is not XSS, CORS misconfiguration
is not an authorization gap, transport MITM is not the app-layer threat it
enables. Keep the clearest threat statement.

**Merge semantics:** union the `actor`, `stride`, `cia`, `surface`, and
`asset` lists; concatenate and dedupe `evidence` (all IDs kept — evidence is
additive); union the controls candidates (Stage 6 verifies the union once);
pre scores take the per-cell maximum of the merged rows;
`recommended_control` notes concatenate. The surviving row records
`merged_from: [working ids]` in working notes. Working ids stay provisional
(`W`-ids) until emit — a pre-emit merge is invisible to consumers
(`schema.md` id lifecycle); never renumber survivors.

**Checkpoint:** Write tool → `<run-dir>/stage5_5.json` (all prior keys,
merged `section4_threats`, `merge_log`).

---

## Stage 6 — As-built control verification

Every control cited in a Section 4 `controls` cell must now be verified:

1. Read the code or config that implements it. Record `file:line` (or
   chart/manifest path + key) in working notes. A `(verified: …)` tag is a
   promise that **you re-read those exact lines this run and they implement
   the control on the specific path the threat traverses** — open the actual
   handler/route/config, not a similar-looking one. Pattern-matching a
   helper that exists in the codebase but is not applied on this path is the
   exact failure mode that produces false verified tags; when in doubt,
   trace from the route registration to the handler before tagging.
2. Check it is enforced everywhere the threat reaches, not just somewhere:
   a body limit on one route does not mitigate a threat spanning ten.
3. Tag the control in the cell: `(verified: file:line)` on success. A
   control you cannot verify in code **never enters the cell in any mode**
   (owner-stated and user-supplied claims included — `schema.md` controls
   rule): drop it from the cell and add a Section 6 open question in the follow-up
   format instead. A verified absence at a specific location (the "go here"
   pointer) goes to working notes and Section 6/Section 8 — it is detail class
   (b), generalized in place by the detail pass at `detail: public`.
4. Re-score `post_impact`/`post_likelihood` crediting **verified controls
   only** (heuristic in `schema.md`), and record each post score's credited
   control in `score_basis`. Derive `status` per the schema precedence —
   never set it by hand.
5. Controls cells hold controls only. Any "but"/"however" commentary you are
   tempted to write goes to working notes and the hand-back.

**Checkpoint:** Write tool → `<run-dir>/stage6.json` (all prior keys,
verified `section4_threats`, `control_evidence` map of control → file:line,
`not_credited` list, `score_basis` map).

---

## Stage 7 — Emit

**Coverage check (before writing) — mechanical, not impressionistic.** For
every Section 2 asset, Section 3 entry point, and Section 3b flow, grep its exact name against
your working Section 4 surface/asset cells and Section 5 entries, and write the per-item
result (`covered_by: [ids]` or `UNCOVERED`) to `<run-dir>/stage7-lint.json`.
The lint may be recorded as PASS **only if that file shows zero UNCOVERED
items** — a PASS logged without the per-item artifact is itself a defect
(this exact failure shipped once: a flow was uncovered while the step log
said the lint passed). Any UNCOVERED item means Stage 4/5 was incomplete; go
back and fix it now.

**Attack chains (Section 4b).** Identify 3-5 multi-hop chains linking Section 4 ids, each
with the single control that breaks it.

**Sort and number.** Sort Section 4 by residual (post-mitigation) risk descending,
ties broken by pre-mitigation risk. Assign final `id` = `T1`, `T2`, … in
sorted order (working `W`-ids retire here; see `schema.md` id lifecycle).
Add the taxonomy rollups per the run's `taxonomy_lead`.

**Section 6 Open questions:** everything the code couldn't tell you — deployment
context, intended actors, unverifiable controls, risk appetite. These seed
a later `interview --seed` pass.

**Section 8 Recommended controls:** from the Stage-3c/5 working notes — one row per
class-level control with `type`, `threat_ids`, `closes_class`, `effort`. If
two clusters are closed by the same control, emit one row with both id sets.

**Drift pass (only if `--prior`):** read `artifacts.md` now and run the
drift-check procedure; it fills Section 9 and may mint new Section 4 rows (re-sort after).

**Write the files.** Read `schema.md` **now**, then write
`<run-dir>/THREAT_MODEL.md` (the model proper: Sections 1-10 including the
living-document Section 10) in one Write at its final path (no
assemble-then-copy), always at full detail — the detail pass in `SKILL.md`
Step 2.6 applies the run's `detail` level afterwards. Then the selected
extras only: the overview companion (Executive summary, usage guide,
artifact index, scan history) if selected, CSVs per `schema.md`, diagram
per `diagram.md` (only if selected at kickoff — never volunteer any of
them).

Set Section 7 Provenance per `schema.md`, with
`calibration: single-analyst estimates pending owner review`.

**Then return to `SKILL.md` Step 2**, which owns the full end-of-run
sequence: all emit-verification checks, the review gates, profile rendering,
the detail pass, the `COMPLETE` write, and the hand-back. Do not restate or
subset those checks here — Step 2 is their single home. Mode-specific
hand-back additions for bootstrap (folded into the Step 2 hand-back, and
never volume-framed):

- Which Stage-5 passes minted rows and which came back clean (clean passes
  are logged in Section 10).
- Stage-3b sibling locations as candidate leads for a vulnerability scan.
- The Section 8 recommended controls, top 3 by (closes_class, effort asc).
- The Section 6 open questions, framed as "ask the owner".
- The 5h authorization-matrix location (in the file at `detail: full`;
  working notes only at `detail: public`) and its REACHABLE escalation
  edges.
