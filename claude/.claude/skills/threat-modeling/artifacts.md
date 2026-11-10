# threat-modeling: drift check and output profiles

> **Re-read note:** If the Read tool reports "file unchanged", reload with
> `cat <skill-dir>/artifacts.md` via Bash.

Two parts. Read the section you need at the point you need it.

---

## Part 1 — Drift check (`--prior <THREAT_MODEL.md>`)

Threat models go stale as the code moves. The drift check re-verifies a
prior model against the current checkout and produces Section 9 of the new model.
It runs inside whichever mode is active, after that mode's research is done
(bootstrap Stage 7 / interview emit) — the fresh research is what makes the
verdicts checkable.

### Inputs

- The prior model. If it follows this skill's schema, parse Section 4 directly. If
  it is an external model, first normalize: extract per threat an id, a
  one-sentence threat statement, the surface/asset it names, its scores, and
  any evidence, into a working table. Note in Section 9 that normalization happened.
- The prior model's target commit, from its provenance block. If absent,
  record "prior commit unknown" and skip the new-surface git diff (verdicts
  still run against current code).

### Procedure

**Step 1 — Verdict every prior threat.** First resolve each prior id through
the prior model's Section 7 `id_aliases` map (if present): a prior id that resolves
to a merged survivor is verdicted once against the survivor, with the alias
noted in Section 9 notes. Then, for each prior Section 4 row, re-check the claim against
the current code and assign exactly one verdict:

| Verdict | Meaning | Required evidence |
|---|---|---|
| `FIXED` | The condition that made this threat scoreable is gone (control landed, surface removed). | file:line of the control/removal, or the fixing commit hash |
| `STILL_PRESENT` | The threat stands materially as written. | file:line showing the surface/condition still exists |
| `CHANGED` | The threat stands but its surface, actor set, or score basis moved. | file:line or commit for what moved, plus the re-scored row |
| `NOT_CHECKABLE` | The threat's subject is not in this repo (or requires runtime/owner knowledge). | one line saying what would be needed to check it |

Rules:

- Every verdict carries evidence per the table; a verdict without evidence
  is `NOT_CHECKABLE`, not a guess.
- Every commit hash cited must resolve via
  `git -C <target-dir> cat-file -t <hash>`.
- `FIXED` means the enabling condition is gone — not "a related bug was
  patched". Apply the threat-vs-vulnerability litmus test: a patched
  instance with the surface still live is `STILL_PRESENT` (the patch may
  lower likelihood).

**Step 2 — Carry forward and re-base.** `STILL_PRESENT` and `CHANGED`
threats enter the new model's Section 4 (keep their statements, re-check their
controls with as-built verification, re-derive status). Re-base any
likelihood whose stated enabler was fixed — do not carry stale scores
forward. `FIXED` threats do not enter Section 4; they live only in Section 9.
`NOT_CHECKABLE` threats enter Section 4 with `in_repo: no|partial` if their subject
is out-of-repo, otherwise land in Section 6 as open questions.

**Step 3 — New surface since the prior model.** If the prior commit is
known:

```
git -C <target-dir> log --oneline <prior-commit>..HEAD
git -C <target-dir> diff --stat <prior-commit>..HEAD
```

Read the changes that touch entry points, flows, stored assets, auth, or
config defaults. **Every piece of new risky surface found here must be
minted as a fully scored Section 4 threat row** (tags, pre/post scores, controls,
in_repo) — narration is not an output. Add new entry points/flows/assets to
Section 3/Section 3b/Section 2 as needed so the coverage invariant still holds.

**Step 4 — Emit Section 9.** Fill the Section 9 table (`prior_id | prior_threat | verdict
| evidence | notes`), then below it:

- Verdict counts: `FIXED: n, STILL_PRESENT: n, CHANGED: n, NOT_CHECKABLE: n`.
- `New threats minted from drift: <id list, or "none">`.
- The prior model's commit and the current commit, so the next drift run has
  both anchors.

**Step 5 — Living-log upkeep.** Drift runs **append, never rewrite**: if an
overview file sits beside the `--prior` model, add a row to its Scan &
assessment history (a pre-v2.1 prior carries the table inline as Section 11
— append there instead; if neither exists, Section 7 and Section 10 are the
log); append status updates to Section 10 (e.g. a `false_positive`
re-confirmed, a `known_gap` closed); and re-derive `disclosure` for every
carried row — a `FIXED` restricted-class threat becomes a full public row,
and any cell generalized under detail classes (b)/(c) whose reason has
lapsed is restored in place (`schema.md` Detail level, drift interaction).
Compare the prior's Section 7 `visibility` with this run's Step 0.55
result; a change is reported in the hand-back, and a private → public
change means the new file must be written at `detail: public`.

Re-sort Section 4 by residual risk after minting (ids stay stable — never
renumber), then continue with the normal emit and verification flow.

---

## Part 2 — Output profiles (`--profile` / kickoff selection)

**Gate:** only when one or more profiles were selected. Profiles render
**after** `THREAT_MODEL.md` has passed emit verification and the review
gates, and **before** the detail pass (SKILL.md Step 2 sequence) — they are
views of a finished model, never a reason to re-open analysis. They render
from the complete working model; each output's commit-guidance class comes
from its template frontmatter (rules in `templates/README.md`).

Procedure, per selected profile:

1. Read `templates/<name>.md` from this skill's directory **now** (not
   earlier). Its frontmatter names the output file(s), the schema sections
   it consumes, and its commit-guidance class; its body is the output structure
   with `{{placeholders}}` and `> fill:` guidance.
2. Re-read the consumed sections from the emitted `THREAT_MODEL.md` on disk
   (not from memory) and fill the template exactly as its `> fill:` blocks
   instruct. The `ai-scan` profile may additionally read working notes
   (sibling locations, fragile constructions, unverified controls) — it is
   the only profile with that permission.
3. Write the output file(s) into the run directory.
4. Consistency lint: every threat id, asset name, and score that appears in
   a profile output must appear identically in `THREAT_MODEL.md`. A profile
   that needs data the schema doesn't carry is a schema problem — record it
   as friction in the hand-back rather than inventing data.

Unknown-profile-name handling is defined once, in `SKILL.md` Step 0.7.
Custom profiles: see `templates/README.md` for the authoring contract. To
render a new or edited profile against an already-finished run, use
`render` mode (`SKILL.md` Step 1) — never re-open a COMPLETE run dir.
