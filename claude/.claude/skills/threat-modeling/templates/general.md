---
name: general
output: THREAT_MODEL_narrative.md
consumes: [1, 2, 3, 3b, 4, 4b, 5, 6, 8]
audience: engineers and design reviewers who read prose, wikis, and design docs — not 16-column tables
disclosure: restricted
---

# General narrative profile

A prose walkthrough of the threat model, in the register of a good design
document. Same content as the schema tables, restructured for reading
top-to-bottom. Render from the finished model; do not re-analyze.

> fill: Write flowing prose with short subsections; tables only where a list
> genuinely reads better as one (max 4 columns). Every threat mentioned keeps
> its Section 4 id in parentheses so readers can jump to the canonical row. Plain
> English; gloss any acronym on first use.

```markdown
# Threat Model (narrative): {{system name}}

## What this system is and what we're protecting

{{Section 1 prose + TOE, then the Section 2 assets grouped into 2-4 plain-language
buckets ("user data", "keys and credentials", "the update pipeline", ...)
with a sentence each on why they matter.}}

## How an attacker sees it

{{Section 3 + Section 3b as a guided tour of the attack surface: start at the internet-
facing edges, move inward across each trust boundary. Name the boundary,
what crosses it, and what an attacker standing there can reach.}}

## What could go wrong

{{Section 4 grouped by theme (not by row): 3-6 subsections, each covering a cluster
of related threats in prose — the story of the attack, who does it, what
they get, what stands in their way today (verified controls only), and the
residual band. Ids in parentheses.}}

### Chains that matter

{{Section 4b as short narratives: "an attacker who X can then Y, then Z — broken
by <control>".}}

## What we decided not to worry about (and why)

{{Section 5 as prose, one sentence per parked item.}}

## What we'd do about it

{{Section 8 as a prioritized to-do list: the class-closing controls first, effort
tagged, threats referenced by id.}}

## What we still don't know

{{Section 6 as direct questions, grouped by who can answer them (owner, infra
team, upstream).}}

---
*Produced by Mozilla security review ({{mode}}, {{date}}, commit
{{commit}}); static analysis only. Canonical model: {{path}}.*
```
