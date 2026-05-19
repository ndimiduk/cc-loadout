---
name: trade-study-audit
description: Use when reviewing a comparative evaluation document (ADR, build-vs-buy, vendor comparison, migration-vs-maintain) where discrete alternatives are assessed against shared criteria to inform a decision. Triggers on "audit this ADR", "pressure-test this evaluation", "are these claims grounded", "review this trade study", "check this comparison", or when an ADR or evaluation doc is open and the user questions specific claims.
---

# Trade Study Audit

Systematic audit of a comparative evaluation document. A trade study evaluates discrete alternatives against shared criteria to inform a decision. This skill pressure-tests each claim in the document to verify it's grounded, differentiating, and fairly weighted.

The audit process draws from structured analytic techniques: Key Assumptions Check (challenge each claim independently), Analysis of Competing Hypotheses (test each dimension for diagnosticity — does it actually distinguish between options?), and Toulmin argument analysis (verify that the grounds support the claim).

## When to use

- ADRs comparing two or more options
- Build-vs-buy evaluations
- Vendor comparisons
- Migration-vs-maintain decisions
- Any document where alternatives are evaluated against criteria

Do NOT use for: design docs (single proposed approach), RFCs (proposal + feedback), requirements docs (no alternatives — use `ndimiduk:requirements-hardening` instead).

## Audit process

### Phase 1: Extract claims

Scan the entire document and extract every comparative claim — any assertion that one option is better, worse, or different from another. The shape of a claim is: "[Option X] [is/does/has] [property] [that Option Y lacks/doesn't]."

Claims hide in:
- **Net/summary statements** — the strongest formulations, what decision-makers read
- **Dimension body paragraphs** — supporting arguments
- **Feature/comparison tables** — each row is a claim with an attributed weight
- **Decision summary** — the rolled-up assessment
- **Complications/constraints** — per-option impact statements
- **Range of outcomes** — implicit claims about what each option enables or risks

Number each claim (C1, C2, ...) so tests can reference them. Extract from strongest-formulation locations first (Net statements, decision summary, feature/comparison tables) — these are what decision-makers read. Then fill in from body text, complications, and range of outcomes. This list is the audit's work product — document structure doesn't matter, claims do.

### Phase 2: Test each claim

For each extracted claim, apply the five tests below. Not every test applies to every claim — skip tests that don't apply, but always start with diagnosticity.

#### 1. Diagnosticity test

> Does this claim differentiate between the options, or is it true regardless of which option we choose?

If the claim is true on both paths, it's not a differentiator. Downgrade or remove it. Examples of non-differentiating claims that commonly appear as advantages:
- Operational fixes that work on either option (config changes, cron job improvements)
- Engine-layer concerns that are catalog/platform independent (audit logging, query optimization)
- Future capabilities gated on a separate migration (not the decision at hand)

#### 2. Grounding test

> What is the primary source for this claim? Has anyone verified it?

For each claim, identify whether the evidence is:
- **Confirmed**: verified from primary source (code, API docs, production data, Slack thread with named person)
- **Inferred**: reasonable but not verified (architecture diagrams, analogies to similar systems)
- **Assumed**: no evidence cited, stated as fact

Challenge assumed claims first. Inferred claims second. Research as needed — don't accept summaries when primary sources are accessible.

#### 3. Completeness test

> What does this claim cost on *each* option? Are hidden costs surfaced?

Every claim should show per-option impact. Common hidden costs:
- **Operational overhead** not captured in the technical comparison (governance processes, team dependencies, onboarding friction)
- **Ongoing costs** framed as one-time migration costs
- **Dependencies on immature features** presented as available capabilities
- **Scope omissions** — work required by an option but not listed in its workstream table

#### 4. Internal consistency test

> Does this claim agree with other sections of the same document?

Check the claim against: open questions (does the claim assume something listed as unresolved?), the feature-specific pulls table (does it agree with the weight assigned there?), the requirements section (does the claim match the requirement it references?), and the decision summary (does the conclusion reflect the dimension analysis?). Internal contradictions are the most common error in iteratively-written documents — sections get updated but downstream references don't.

#### 5. Framing test

> Is this claim weighted proportionally to its actual impact on the decision?

Watch for:
- **Structural vs. operational**: a config change framed as a structural architectural advantage
- **Convenience vs. capability gap**: a nice-to-have framed as a blocking differentiator
- **Future-option vs. current-requirement**: something that *could* work someday framed as something that *does* work now

## Error taxonomy

Common errors found in trade studies, ordered by frequency. Use as a checklist.

### Claims

| Error | Test | Example |
|-------|------|---------|
| **Ungrounded claim** | Can you trace this to a primary source? | "Fork maintenance is unbounded" (actual: 7-8 patches) |
| **Non-differentiating dimension** | Does this distinguish between options? | Maintenance jobs framed as an advantage when they're standard cron on either path |
| **Overstated advantage** | Is this a structural gap or a convenience? | "No path exists" when a standard ETL pattern works |
| **Hidden cost** | What does this cost on the supposedly simpler option? | IAM governance per consumer not captured in migration estimate |
| **Stale framing** | Was this true when written but no longer? | Migration described as pending when it already shipped |
| **Internal contradiction** | Does this claim agree with other sections of the same doc? | Dimension says "Glue advantage" but open questions list it as unresolved; feature table assigns different weight than dimension text |

### Structure

| Error | Test | Example |
|-------|------|---------|
| **Phantom constraint** | Does this actually bound the solution space? | A scope statement or unsubstantiated future input listed as a governing variable |
| **Missing constraint** | Is there a real constraint not listed? | Multi-environment topology that shapes what architectures work |
| **Conflated problems** | Are two separate issues presented as one? | Two different credential dependencies described as a single "auth problem" |
| **Incomplete option scope** | Is all required work listed? | Prerequisite migration missing from the workstream table |

### Presentation

| Error | Test | Example |
|-------|------|---------|
| **Fabricated precision** | Are estimates scoped or guessed? | "5-8 weeks" presented as scoped when it's a rough guess |
| **Asymmetric framing** | Is each option described with equal rigor? | One option's complications explored in detail; the other's glossed over |
| **Stale downstream references** | Do later sections reflect upstream corrections? | Decision summary still claiming advantages that were disproven in the evaluation |
| **Per-option impact missing** | Can a reader see what each option costs for each claim? | A complication described in prose without explicit per-option bullets |

### Phase 3: Report and remediate

## Audit output

For each claim audited, record:
- **Claim**: the assertion as stated
- **Verdict**: confirmed / overstated / wrong / non-differentiating
- **Evidence**: what you found (source link if available)
- **Action**: keep as-is / tone down / reframe / drop / needs research
- **Issue filed** (if the finding is actionable work): link to the issue

**Two modes:**
- **Audit mode** (first pass): report findings without modifying the document. Target the strongest formulation of each claim (Net statements, decision summary) — that's what decision-makers read.
- **Edit mode** (second pass): apply corrections to the document. Update downstream sections (decision summary, feature tables) immediately after correcting a dimension so stale references don't persist.

**Separate findings from recommendations.** The audit often correctly identifies a problem but reaches the wrong fix — especially when two sections of the document contradict each other and the agent picks the wrong side. For each finding, report:
- **What's wrong** (the inconsistency, the missing evidence, the overstated claim) — this is usually reliable
- **What to do about it** — flag whether the recommendation requires external verification. If the document contradicts itself, say which sections conflict and that research is needed to determine which is correct. Don't pick a side without evidence.

## Relationship to other skills

- **`ndimiduk:requirements-hardening`**: audits the requirements doc (are these real requirements?). Run this *before* the trade study audit — the trade study evaluates options against requirements, so the requirements must be solid first.
- **`ndimiduk:design-challenge`**: stress-tests a design *decision*. Use after the trade study audit has validated the evaluation, when you're ready to commit to an option.
- **`writing-clearly-and-concisely`**: editorial quality. Orthogonal — run after the substantive audit to tighten prose.
