---
name: rra
output: RRA.md, RRA-ENTRY.md
consumes: [1, 2, 4, 6, 8]
audience: risk owners and RRA reviewers (Mozilla RRA house format)
disclosure: restricted
---

# Rapid Risk Assessment (RRA) profile

An RRA is a **lightweight, service-level risk snapshot** — the kind produced
in a 30–60 minute review. It deliberately trades threat-row granularity for a
decision-ready view: what data the service holds, how bad the worst realistic
C, I, and A failures are, and what to do next — framed the way the house
format frames it: **reputation, productivity, cost, and "has this happened
before?"**. Render it from the finished model; do not re-analyze.

This template mirrors the structure of manually-produced Mozilla RRAs
(header table → Service Notes → Data Dictionary → Threat Scenarios by CIA →
risk-labeled Recommendations). Three usage modes — pick ONE per render:

1. **Fresh assessment** (default): emit the full document below.
2. **Living-log entry** (`--prior` runs, or when the owner keeps a "[main]"
   RRA doc): write ONLY `RRA-ENTRY.md` — a dated mini-review entry (format
   at the bottom) for the owner to append under their doc's Service Notes.
   Never regenerate the whole living doc — it is owned and hand-curated.
   Exactly one of the two output files is written per render.
3. **Decision record**: when the run's TOE is a dependency/library/vendor
   *choice* rather than a service, fill Service Notes with the
   decision-record block instead of the service description.

> fill: Mapping from the model — Section 1 TOE → Service Notes; Section 2
> assets → Data Dictionary (roll rows up to DATA TYPES, not tables/keys;
> map sensitivity → the org classification per the EDIT-ME table below);
> Section 4 → Threat Scenarios: under each CIA heading list the 1–3
> highest-residual rows carrying that tag, each restated in plain language
> and prefixed with its risk label; Section 8 → Recommendations, risk-labeled;
> Section 6 → open questions woven into Service Notes ("People who
> participated" stays empty until the owner interview) or Recommendations.
>
> **Risk-label mapping (EDIT-ME if your org's levels differ)** — from the
> corporate bands to Mozilla Standard Levels
> (https://wiki.mozilla.org/Security/Standard_Levels):
> residual 80–100 ("Mitigate before next release") → **MAXIMUM**;
> residual 40–79 ("Mitigate by following release") → **HIGH**;
> Acceptable band but pre-mitigation was 40+ → **MEDIUM**;
> everything else worth listing → **LOW**.
> Recommendation urgency semantics (verbatim house meaning): MAXIMUM = fix
> right now; HIGH = fix within a week; MEDIUM = look at within 3 months;
> LOW = interesting to do or look at.
> Render each label as a bold link:
> `[**MAXIMUM**](https://wiki.mozilla.org/Security/Standard_Levels)`.
>
> **Data-classification mapping (EDIT-ME)** — observed house vocabulary
> (https://wiki.mozilla.org/Security/Data_Classification): Public /
> Staff Confidential / Workgroup Confidential. Default mapping from Section 2
> sensitivity: critical → Workgroup Confidential; high → Workgroup or Staff
> Confidential (Staff when the audience is "all employees", Workgroup when
> tighter); medium+low → Staff Confidential or Public per content.
> **Highest Risk Impact** in the header = the Standard Level mapped from the
> maximum PRE-mitigation risk in Section 4.

```markdown
# RRA for {{service name}}

| Service Owner(s) | {{owning team / owner if stated — never invent}} |
| :---- | :---- |
| **Owner's Director** | {{if known, else blank}} |
| [**Service Data Classification**](https://wiki.mozilla.org/Security/Data_Classification) | {{highest classification from the Data Dictionary}} |
| **Highest Risk Impact** | [**{{MAXIMUM/HIGH/MEDIUM/LOW}}**](https://wiki.mozilla.org/Security/Standard_Levels) |

# Service Notes

*How does the service work? Do we have diagrams, demos, examples? Is the service in production yet?*
*Can we break this service down per component?*

RRA Request bug URL: {{ticket link if supplied at kickoff, else blank}}
Site and API endpoint URLs: {{public hosts from Section 1/3 — public-edition facts only}}
Service aliases & historical names (aka search keywords): {{aliases}}
People who participated in the RRA: Mozilla security review (automated bootstrap; owner interview {{pending/done}})

{{3–8 sentences from Section 1: what it does, components, where it runs, key
integrations. If prior RRAs/reviews are known (kickoff Q4/prior links), list
them here — the house style keeps an "RRAs and reviews" link list.}}

{{Decision-record variant — use INSTEAD of the paragraph above when the TOE
is a dependency/vendor choice, mirroring the hpke record:}}
### Background
{{what is being adopted and why, 2–4 sentences, links to specs}}
Reasoning for picking {{chosen}} over {{alternative(s)}}:
* **Supply chain:** {{dependency count, pinning behavior, install scripts}}
* **Auditability:** {{size/file count, license}}
* **Correctness:** {{spec conformance facts, test-vector validation}}
* **Misuse resistance:** {{API shape that prevents footguns}}
* **Accepted risk:** {{e.g. single maintainer — state it plainly}}
* **Mitigation:** {{exact pin, lockfile, vendoring, monitoring}}

# Data Dictionary

| Data name / type | [Classification](https://wiki.mozilla.org/Security/Data_Classification) | Comments |
| :---- | :---- | :---- |
| {{rolled-up data type}} | [**{{level}}**](https://wiki.mozilla.org/Security/Data_Classification) | {{one clause: where it lives / why this level}} |

# Threat Scenarios

*For each threat, ask yourself these questions:*
*In the shoes of the attacker, what would you take advantage of? What is the easiest attack vector? Are the threats already mitigated?*
*Does it affect Mozilla's or your team's reputation? Tweets, bugs, or gets us in the news?*
*Does it affect Mozilla's workforce productivity? How many are affected?*
*Does it cost Mozilla more than a few thousand USD? How much?*
*Did this happen before? How often per year?*

## **Affecting confidentiality**

* How does this affect Mozilla's reputation?
  * [**{{label}}**](https://wiki.mozilla.org/Security/Standard_Levels) {{top residual C-tagged Section 4 row, plain language, one line}}
  * [**{{label}}**](https://wiki.mozilla.org/Security/Standard_Levels) {{second C row if within one band of the top; max 3}}
* How does this affect Mozilla's productivity?
  * {{one line, or "^" when same as above}}

## **Affecting integrity**

* How does this affect Mozilla's reputation?
  * [**{{label}}**](https://wiki.mozilla.org/Security/Standard_Levels) {{top residual I-tagged row, plain language}}
* How does this affect Mozilla's productivity?
  * {{...}}

## **Affecting availability**

* How does this affect Mozilla's reputation?
  * [**{{label}}**](https://wiki.mozilla.org/Security/Standard_Levels) {{top residual A-tagged row}}
* How does this affect Mozilla's productivity?
  * {{...}}

# Recommendations

*Do we follow [Mozilla's Security Principles](https://infosec.mozilla.org/fundamentals/security_principles)? Order items [by how much risk we're taking](https://wiki.mozilla.org/Security/Standard_Levels) by not implementing the recommendation.*

* [**{{label}}**](https://wiki.mozilla.org/Security/Standard_Levels) {{Section 8 control, one line: what to do — what class it closes}}
* [**{{label}}**](https://wiki.mozilla.org/Security/Standard_Levels) {{...top 3–6 by (band desc, closes_class, effort asc)}}
* {{unanswerable-by-code Section 6 items become recommendation bullets phrased as "Confirm/verify ..." with a label}}
```

> fill rules for the scenarios: past incidents from Section 4 `evidence`
> answer "did this happen before?" — cite them inline ("happened before:
> <commit/CVE>, see threat model Tn"). If a dimension has no scenario above
> Acceptable, write "None identified above Acceptable" under it rather than
> inventing one. Keep every scenario one line; the full detail lives in
> THREAT_MODEL.md — link the Tn id.

## Living-log entry format (mode 2)

Emit exactly this block, nothing else, for the owner to paste into their
"[main]" RRA doc (newest entries go at the top of the mini-review list):

```markdown
## [{{YYYY-MM-DD}}] {{one-line change/review title}}

RRA request: {{ticket link or blank}}
Documentation: {{links supplied at kickoff}}

Notes:

* {{3–8 bullets: what changed, what the drift pass / new rows found, framed
   as observations — house voice is terse meeting-note bullets}}
* {{include "happened before" evidence and any panel-refuted claims worth
   recording as considered-and-rejected}}

Recommendations:

* {{1–4 bullets, risk-labeled where a band applies; actionable, owner-directed}}
```

> fill: a living-log entry corresponds to ONE reviewed change (a drift run's
> Section 9 verdicts + newly minted rows, or a focused re-run). Title it after
> the change, not the service. Never include restricted-class infra detail —
> living docs circulate wider than trackers.
