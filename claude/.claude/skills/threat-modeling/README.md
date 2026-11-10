# threat-modeling skill

A threat-modeling skill for Claude Code. It analyzes a target codebase (or
interviews the system owner, or both) and produces a threat model with both
STRIDE and CIA views, pre- and post-mitigation risk scoring on the corporate
5×5 scale, and outputs ready for the corporate threat-model Google Sheet.
It produces exactly one file by default, `THREAT_MODEL.md`, meant to be
committed into the target repo. How much that file says follows the repo's
GitHub visibility: a public repo gets a model with exploitation-roadmap
detail withheld in place; a private or internal repo gets full detail.
There is no separate restricted edition. Everything else — an executive
overview companion, CSVs, diagrams, profiles — is opt-in. The skill
performs static analysis only: it never executes the target and never
writes into the target checkout.

## Installation

Copy this directory into your Claude Code skills folder:

```bash
cp -r threat-modeling ~/.claude/skills/
```

For a single project, copy it to `<repo>/.claude/skills/threat-modeling/`
instead. To update, replace the directory with the newer copy. Verify by
typing `/threat-modeling` in a new Claude Code session.

## Usage

```
/threat-modeling [bootstrap-then-interview|bootstrap|interview|render] <target-dir> [flags]
```

**Examples:**

```
# First threat model of a service; the owner is available (recommended)
/threat-modeling bootstrap-then-interview ~/repos/payments-service

# No owner available; also produce the executive overview and rows for the
# corporate Google Sheet
/threat-modeling bootstrap ~/repos/payments-service --artifacts md,overview,csv

# Repo visibility could not be detected (or you want to override it)
/threat-modeling bootstrap ~/repos/payments-service --visibility private

# Owner-led design review, grounded in the architecture document
/threat-modeling interview ~/repos/payments-service --design-doc ~/docs/architecture.md

# Quarterly re-check of a threat model already committed to the repo
/threat-modeling bootstrap ~/repos/payments-service --prior docs/THREAT_MODEL.md

# Add a data-flow diagram to a finished run, without re-analysis
/threat-modeling render <run-dir> --artifacts diagram

# Re-emit a finished run at public detail before the repo goes public
/threat-modeling render <run-dir> --visibility public
```

In an interactive session you need no flags: the skill opens with a short
kickoff conversation and collects everything there. The full flag list is
`SKILL.md`'s argument-hint (the canonical home); this README does not
reproduce it.

## Modes

| Mode | Use when | Command |
|---|---|---|
| `bootstrap-then-interview` | The owner is available and the code is checked out (recommended) | `/threat-modeling bootstrap-then-interview <target-dir>` |
| `bootstrap` | No owner available; derive from code, git history, and advisories | `/threat-modeling bootstrap <target-dir>` |
| `interview` | Owner available; design reviews, or risk that lives outside the code | `/threat-modeling interview <target-dir>` |
| `render` | Regenerate artifacts from a finished run, no new analysis | `/threat-modeling render <run-dir> --artifacts ...` |

## What it does

1. Detects the target repo's GitHub visibility (public / private /
   internal) from its `origin` remote and sets the model's detail level
   from it; `--visibility` overrides.
2. Opens with a short kickoff conversation: a few skippable questions about
   the target (deployment, most sensitive assets, prior findings, known
   false positives) and one about which outputs you want beyond the
   default single file.
3. Researches the target — code, git history, public advisories — and/or
   interviews the system owner, depending on the mode.
4. Enumerates assets, entry points, and data flows, then derives threat rows
   tagged with both STRIDE and CIA, walking a master category checklist so
   no threat class goes missing silently.
5. Scores each threat pre- and post-mitigation, crediting only controls it
   re-verified in code (file:line evidence).
6. Verifies the emitted model mechanically (coverage, evidence resolution,
   score basis) and, if selected, adversarially.
7. Writes one `THREAT_MODEL.md` (sections 1–10) into a run directory at
   the detected detail level — full for private/internal repos; for public
   repos, open-gap locations and exploitation-roadmap rows are withheld in
   place as counted stubs — plus only the extras you selected.

## What you'll be asked

1. **Kickoff:** where the system is deployed and who can reach it.
2. **Kickoff:** who authenticates to it, and which one or two assets would
   cause the most damage if compromised.
3. **Kickoff:** any prior threat models, penetration tests, design
   documents, and known false positives.
4. **Kickoff:** the detected repo visibility and resulting detail level
   (confirm or override), and which outputs you want beyond the default
   single `THREAT_MODEL.md`.
5. **Q1:** what the system does, and the use case and scope under review.
6. **Q1:** the system's assets, entry points, and data flows — confirmed
   against the code.
7. **Q2:** what could go wrong, guided by STRIDE prompts and a systematic
   per-asset, per-flow CIA review.
8. **Q3:** impact and likelihood before mitigations, the controls in place
   today, and impact and likelihood after.
9. **Q4:** whether the ranked risks reflect your understanding of the
   system, and whether anything is missing.

Bootstrap-only runs ask just the kickoff questions (1–4).

## Output files

All outputs land in the run directory:
`<parent-of-target>/threat-models/<target-basename>/<UTC-timestamp>/` —
beside the target checkout, never inside it. `--out <dir>` overrides the
parent directory.

| File | What it is | When |
|---|---|---|
| `THREAT_MODEL.md` | The one threat model (sections 1–10), intended for the target repo; detail level follows the repo's visibility (Section 7 records it) | always — the only default output |
| `THREAT_MODEL_OVERVIEW.md` | Companion: executive summary, usage guide, artifact index, scan history | `--artifacts overview` |
| `THREAT_MODEL_{assets,dataflows,asset_threats,dataflow_threats,controls}.csv` | Rows for the corporate Google Sheet | `--artifacts csv` |
| `THREAT_MODEL_dataflow.md` | Mermaid data-flow diagram, with optional threat overlay | `--artifacts diagram` |
| `workspace.dsl` | C4 model of the same data flows, in Structurizr DSL | `--artifacts diagram` with format `both` |
| `RRA.md` / `THREAT_MODEL_narrative.md` / `ATTACK_SURFACE.yaml` + `SCAN-SEEDS.md` | Profile outputs (written in full; not for public repos — keep with private scan findings) | `--profile rra,general,ai-scan` |

## Detail level and repo visibility

| Repo visibility (GitHub) | Detail level | What the one file contains |
|---|---|---|
| `private` | `full` | Everything, including open-gap locations and the score-basis appendix. The repo's access control is the boundary. |
| `internal` | `full` (confirmed at kickoff) | Same as private; every org member can already read the code. |
| `public` | `public` | The comprehensive model, with a tight list withheld in place: unmitigated top-band rows that read as an exploitation roadmap become counted stubs; "go here" pointers to absent controls and non-public deployment facts are generalized. |
| not detectable | `public` (asked at kickoff when interactive) | Fail-safe: withhold. |

Detection uses the checkout's `origin` remote and `gh api`; `--visibility`
overrides it. Withheld detail is never lost — it stays in the run directory's
working notes, and `render <run-dir> --visibility private` re-emits the file
in full for the security team.

Choosing the diagram at kickoff offers two formats: `mermaid` (default,
renders natively on GitHub) or `both`, which additionally emits a C4 model
as a Structurizr DSL workspace generated from the same intermediate model,
for teams that maintain architecture diagrams in Structurizr.

Google Sheet paste order:

1. Fill the Overview tab by hand from Section 1 of `THREAT_MODEL.md`.
2. Paste the assets CSV at A2 of the Assets tab; dataflows at A2 of Data Flows.
3. Paste the controls CSV at A2 of the Controls tab, then assign Control IDs.
4. Update the threat CSVs' Control IDs column with those IDs.
5. Paste asset-threats at A3 of Asset-Threats; dataflow-threats at A3 of
   Data Flow-Threats.

## Risk scoring

| Likelihood | Impact | Risk = L×I | Acceptability |
|---|---|---|---|
| Certain (10) | Catastrophic (10) | 100 | Mitigate before next release |
| Likely (8) | Major (8) | 64 | Mitigate by following release |
| Possible (5) | Moderate (5) | 25 | Acceptable |
| Unlikely (2) | Minor (2) | 4 | Acceptable |
| Rare (1) | Negligible (1) | 1 | Acceptable |

The sheet computes Risk from the hidden numeric values (in parentheses); the
skill outputs only the qualitative words. Bands: 1–39 Acceptable, 40–79
Mitigate by following release, 80–100 Mitigate before next release. Every
threat is scored twice: pre-mitigation (as if no controls existed) and
post-mitigation (crediting code-verified controls only).

## Lineage & references

Based on Anthropic's open-source threat-model skill (the modes, staged
bootstrap research, four-question interview), extended with the Mozilla
SSDLC CIA/TOE layer (per-asset and per-flow CIA enumeration, corporate 5×5
scoring, the five-CSV sheet contract).

- Shostack, *The Four Question Framework for Threat Modeling* — https://shostack.org/files/papers/The_Four_Question_Framework.pdf
- OWASP Threat Modeling Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
- OWASP Top 10 for LLM Applications — https://owasp.org/www-project-top-10-for-large-language-model-applications/
- MITRE ATLAS — https://atlas.mitre.org/
- C4 model — https://c4model.com/
- Structurizr — https://structurizr.com/
