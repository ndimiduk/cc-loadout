---
name: ndimiduk-argument-audit
description: >-
  Use when reviewing a research or design PR, or any document that makes
  arguments: design docs, research analyses, ADRs, trade studies, decision
  records, build-vs-buy or vendor comparisons, phased plans. Triggers on
  "pressure-test this doc", "audit this document", "check the logic", "are
  these claims grounded", "poke holes in this doc", "is it logically sound",
  "run the audit again", or before committing to a direction based on written
  analysis. Also use when the user questions findings from an audit already
  reported in the session. For findings from a code review use
  `ndimiduk:code-review`; for prose use `ndimiduk:prose-review`; for design
  viability use `ndimiduk:design-challenge`.
---

# Argument Audit

Pressure-test the logical construction of a document. Reviewers read it from
several angles in parallel, each extracting and testing claims; a judge tries to
refute every finding before it is reported. The audit asks: does the argument
hold up? Are the claims grounded? Does the conclusion follow from the evidence?

Works on any document that makes arguments: research designs, trade studies, ADRs,
decision records, system analyses, migration proposals, single-proposal designs.

Draws from structured analytic techniques: Key Assumptions Check (challenge each
claim independently), Analysis of Competing Hypotheses (test dimensions for
diagnosticity), and Toulmin argument analysis (verify that grounds support claims).

## Architecture

```
  +---------------+
  |  0. Context   |  Read the doc, cross-references, project docs
  +-------+-------+
          |
  +-------v-------+
  |  1. Review    |  Angle reviewers in parallel: cold reader, systems
  |               |  expert, plus adversary / builder / evaluator by signal
  +-------+-------+
          |
  +-------v-------+
  |  2. Judge     |  Refute every finding: CORRECT / INCORRECT / UNVERIFIABLE
  +-------+-------+
          |
  +-------v-------+
  |  3. Output    |  Findings with citations and site lists
  +---------------+
```

Each angle gets the full context and tool access, and reports only what its
reader would catch. The judge filters the merged findings for precision.

## Flags

- `--edit` — apply corrections to the document after the audit (second pass)
- `--comment` — post findings as inline PR comments via `gh`

Default is audit mode: report findings without modifying the document.

## Process

### Phase 0: Gather Context (coordinator does this)

Before dispatching the reviewers, collect everything they need to evaluate the
document's claims against reality.

**Always gather:**

1. **The document under audit**: full text.
2. **All files in scope**: if auditing a PR or diff, include ALL changed files —
   not just the "primary" document. Supporting files (audit findings, appendices,
   companion docs) are part of the argument and may contain claims or references
   that need testing.
3. **Document metadata**: what kind of document is this? (trade study, design doc,
   research analysis, ADR, decision record, other). This determines which tests
   apply.
4. **Cross-referenced documents**: anything the document cites or depends on.
   Requirements docs, prior analyses, referenced designs. Read them. Also verify
   that references in the document are resolvable — a citation pointing to a local
   filesystem path, a dead link, or an internal-only resource that collaborators
   can't access is a grounding problem.
5. **Project context**: README, CLAUDE.md, directory structure of the surrounding
   project. Reviewers need to understand what the document is part of.

**Gather when available:**

6. **Git history on the document**: `git log --oneline -10 -- <doc-path>` to
   understand how it evolved. Recent changes often introduce inconsistencies
   with earlier sections. Documents with repeated correction commits
   (`git log --grep="fix\|correct\|update" -- <doc-path>`) are higher-risk
   for residual errors — flag them for more thorough cross-doc checking.
7. **Related documents in the same project**: other designs, research notes, or
   analyses that cover the same domain. Grep the project for key terms from the
   document.
8. **External sources**: if the document makes claims about external systems,
   APIs, or tools, reviewers verify against primary sources using
   WebSearch or project documentation tools.

**Classify the document:**

- **Comparative**: evaluates alternatives against shared criteria (trade study,
  ADR with options, build-vs-buy, vendor comparison, migration-vs-maintain).
  Diagnosticity test applies.
- **Argumentative**: proposes or analyzes a single approach (design doc, research
  analysis, system description, decision record without structured alternatives).
  Evidence-claim linkage and reasoning chain tests apply.
- **Mixed**: some sections compare options, others argue for a specific approach.
  Apply all tests; note which mode each section is in.

### Phase 1: Review

**Choose the angles.** Each angle is a reviewer reading the document as one
kind of reader. Run them in parallel:

1. **Cold reader** (always): Steps 1–3 below.
2. **Systems expert** (always, when the document names any code, service,
   or external system): see "Systems expert" below.
3. **Every angle below** that the user's request names or whose signal
   appears in the document. A signal is structural (a section, table, or
   diagram about the topic), not a word that happens to appear:
   - **Adversary**: signals are authorization, ACLs, credentials, consent,
     trust boundaries, "fail closed". Reads as someone trying to get access,
     authority, or data they shouldn't, using only what the document says
     the system allows.
   - **Builder**: signals are phases, "Depends on", milestones, rollout
     steps, mermaid or graph blocks. Reads as the engineer who has to
     execute it in order: what's missing, mis-ordered, or blocked by
     something the plan doesn't schedule.
   - **Evaluator**: signals are an options table, alternatives, a decision
     matrix. Reads as the decision-maker checking that the comparison is
     fair and diagnostic.

Detect signals with grep and the heading list. Name the chosen angles and
the signals that chose them in the output.

The adversary, builder, and evaluator reviewers each get their reader
description as their goal, plus the finding format and the Step 1–3 tests
that serve that goal, and report only findings from their angle.

Every angle, including the cold reader and the systems expert, ends by
asking: what didn't I check? It lists the sections it read only in passing,
goes back through them, and reports what it found there.

Every angle gets the full document, all gathered context, and tool access
(Read, Bash for grep/git/wc/sort, WebSearch, and the project's source tools).

**Tool use is not optional.** Reviewers verify claims against primary sources
with tools, not by reasoning from the document text. Read cross-referenced
files. Grep the project for corroborating or contradicting evidence. If the
document cites a repo, file, or artifact, read it and check whether the
document's description matches. If it states counts, line numbers, or sizes,
verify mechanically (wc, grep -c, ls). A finding that rests only on the
document's text is weaker than one a tool confirmed.

The cold reader performs three steps: extract claims, test the argument's
structure, then test individual claims.

#### Step 1: Extract Claims

Scan the entire document and extract every substantive claim. A claim is any
assertion that could be true or false — not opinions, goals, or definitions.

**Claim shapes by document type:**

Comparative documents:
- "[Option X] [is/does/has] [property] [that Option Y lacks/doesn't]"
- "[Dimension] favors [Option X] because [reason]"
- "[Option X] costs [amount] while [Option Y] costs [different amount]"

Argumentative documents:
- "[System/approach] [has/does/enables] [property]" (capability claim)
- "[Because X], [therefore Y]" (causal/inferential claim)
- "[X] is required for [Y]" (dependency claim)
- "[X] will take [time/effort]" (estimation claim)
- "[X] is not possible / not feasible" (impossibility claim)
- "[We must do X before Y]" (ordering/prerequisite claim)

**Where claims hide:**

- Executive summary / introduction — strongest formulations, what readers act on
- Section topic sentences — the claim each section exists to support
- Comparison tables — each cell is a claim
- Decision/conclusion sections — rolled-up assessment
- Scope/constraint statements — implicit claims about what bounds the solution
- Footnotes and parentheticals — hedged claims that may be load-bearing
- Diagrams and their captions — architectural claims

Number each claim (C1, C2, ...) for reference. Extract from strongest-formulation
locations first (summary, conclusions, tables) — those are what decision-makers read.

#### Step 2: Test Argument Structure

Before testing individual claims, evaluate the document's argument as a whole.
Per-claim testing catches grounding and consistency errors; structural testing
catches flow and coherence errors that only appear when you look at how claims
relate to each other.

##### Logical ordering

> Do the argument's steps appear in the right order? Are there prerequisites
> that must hold before a later claim makes sense?

Map the dependency graph of claims. If Claim B depends on Claim A being resolved,
but the document evaluates B without addressing A, that's a structural gap — even
if both claims are individually well-grounded. Common pattern: a document evaluates
"expected case" and "worst case" but skips a logically prior question whose answer
determines which case applies.

##### Document posture coherence

> Does the document's stated posture (TBD, decided, recommendation, analysis)
> match its content?

A document that says "TBD" but presents four assessments all pointing the same
direction is de facto a recommendation. A document that says "decided" but lists
unresolved open questions is de facto deferred. Readers infer posture from content,
not labels. When label and content diverge, flag it — the mismatch erodes the
document's credibility as an input to a formal decision process.

##### Argument completeness

> Does every analytical thread reach a conclusion? Are there threads the document
> opens but never closes?

A dimension or open question introduced in the analysis section that doesn't appear
in the decision/conclusion section is a dropped thread. The reader doesn't know
whether it was resolved, deemed irrelevant, or forgotten.

#### Step 3: Test Each Claim

Apply the test battery below. Not every test applies to every claim — skip tests
that don't apply, but always start with grounding.

##### 1. Grounding test

> What is the primary source for this claim? Has anyone verified it?

Classify the evidence as:
- **Confirmed**: verified from primary source (code, API docs, production data,
  measurements, named references)
- **Inferred**: reasonable but not verified (architecture diagrams, analogies to
  similar systems, extrapolation from partial data)
- **Assumed**: no evidence cited, stated as fact

Challenge assumed claims first. Inferred claims second. **Use tools to verify** —
read the referenced file, query the repo, count the items. Don't reason about
whether a count "seems right" when you can run `wc -l` or `grep -c`. Don't
accept the document's description of a file when you can read the file. Every
claim you verify by tool becomes a finding or a confirmed pass.

Claims that name code are the systems expert's, not the cold reader's.

##### 2. Evidence-claim linkage

> Does the cited evidence actually support the claim being made?

Common failures:
- Evidence supports a weaker version of the claim (quantitative claim supported
  by qualitative evidence)
- Evidence is from a different context (different scale, different constraints)
- Evidence supports the claim but also supports the opposite conclusion
- Circular reasoning (claim A supports claim B which supports claim A)

##### 3. Reasoning chain completeness

> Are there missing steps between the evidence and the conclusion?

Map the inferential chain: Evidence -> Intermediate conclusion -> ... -> Final
claim. Flag gaps where the reader must supply an unstated inference to connect
two steps.

##### 4. Assumption surfacing

> What unstated premises does this argument depend on?

Every argument rests on assumptions. The important ones to surface are those that:
- Could reasonably be false
- If false, would invalidate the conclusion
- Are not obvious to the intended audience
- Are load-bearing but presented as background

##### 5. Internal consistency

> Does this claim agree with other parts of the same document?

Check against: other claims in the document, open questions sections (does the
claim assume something listed as unresolved?), scope statements (does the claim
exceed the stated scope?), earlier analysis (does the conclusion reflect the
analysis or diverge from it?). Internal contradictions are the most common error
in iteratively-written documents — sections get updated but downstream references
don't.

**Table validation** (high-yield sub-test): For every table row that states a
count alongside a list of examples, verify the count matches the number of
examples actually listed. For tables claiming categories are mutually exclusive,
verify that no item appears in multiple categories — if it does, totals won't
reconcile. These are mechanical checks but catch errors in every second document
that contains an inventory or classification table.

##### 6. Scope consistency

> Does the document solve what it claims to solve?

Check whether: the stated problem matches what the analysis actually addresses,
constraints listed in the introduction are respected throughout, the conclusion
answers the question the document set out to answer, work listed as "out of scope"
doesn't quietly sneak back in.

##### 7. Diagnosticity (comparative documents only)

> Does this claim differentiate between the options, or is it true regardless?

If the claim is true on all options, it's not a differentiator — downgrade or
remove it. Common false differentiators:
- Operational fixes that work on either option
- Capabilities gated on a separate migration (not the decision at hand)
- Properties of the underlying platform that both options share

##### 8. Completeness

> What does this claim cost? Are hidden costs surfaced?

For comparative docs: every claim should show per-option impact. For argumentative
docs: every proposed approach should surface its costs, not just its benefits.

Common hidden costs:
- Operational overhead not in the technical comparison
- Ongoing costs framed as one-time
- Dependencies on immature features presented as available
- Scope omissions — required work not listed

##### 9. Framing

> Is this claim weighted proportionally to its actual impact?

Watch for:
- Structural vs. operational: a config change framed as a structural advantage
- Convenience vs. capability gap: nice-to-have framed as blocking
- Future-option vs. current-requirement: "could work someday" framed as "works now"
- Fabricated precision: "5-8 weeks" presented as scoped when it's a guess
- Asymmetric treatment: one side explored in detail, the other glossed over

**Finding format (every angle):**

For each claim audited, return:
- **Claim ID**: C1, C2, ...
- **Claim**: the assertion as stated (quote from document)
- **Location**: section heading + approximate position
- **Tests applied**: which tests from the battery (including Step 2 structural tests)
- **Verdict**: confirmed / overstated / unsupported / wrong / non-differentiating / inconsistent / structural-gap
- **Evidence**: what the angle found (source if available)
- **Suggested action**: keep as-is / tone down / reframe / add evidence / drop / needs research / user decision
- **Source basis**: what evidence supports the *finding* (document section, cross-reference, web search, codebase grep)

#### Systems expert (grounding agent)

Its only job is the document's claims about code and external systems. It
covers every claim that names a class, method, validator rule, config key,
data store, service, or library behavior, including sections the change
didn't touch. The document's own labels ("source-confirmed", "verified") are
not evidence.

Its output is a table with one row per claim: claim and location, the search
or file read that settles it, and the result (matches / wrong, with what the
source says / not found, with the searches tried).

- Every row names a search that was run.
- A row checks the claim's relationship, not just that the names exist: "X is
  backed by Y" needs the code where X reads Y, and "runs on a Kafka worker"
  needs the code that runs it.
- Build the row list by walking the document line by line, not from memory of
  what it covers.
- If the source says something different from the claim, even in part, the
  row is wrong. "Not found" is only for claims whose source couldn't be
  located.
- Read source as of the document's date where history is available; when only
  the current branch is, say so on rows whose result could have changed since.

Before returning, ask of every "matches" row: are you sure? Quote the source
line that proves the claim's relationship. A row without that quote becomes
"wrong" (if what you read says otherwise) or "not found".

Wrong rows become findings with verdict `wrong`, merged with the other
angles' findings before the judge.

### Phase 2: Judge

Dispatch a judge agent with the full document, the systems expert's table, and
the merged findings from every angle. The judge merges duplicates across
angles and tries to refute each finding.

**Judge instructions:**

Use definitive language. No hedging ("could", "might", "perhaps"). Each finding
rests on claims: what the document says (quote and location), what the
evidence shows, and that the document doesn't resolve it elsewhere. Mark each
VERIFIED or REFUTED with a citation (document line, cross-ref, `file:line`,
command output), or UNCHECKED. "Follows from" is an inference, so the claim
is UNCHECKED. An UNCHECKED claim lists the searches that were run; a claim
whose search wasn't run is not UNCHECKED, so run it. A claim about how an
external system behaves needs that system's source or docs, not the
document's own account of it.

**Classify each finding:**

- **CORRECT** — Keep. All of its claims are VERIFIED.
- **INCORRECT** — Remove. One of its claims is REFUTED, or:
  - Finding misreads the document (the claim actually says something different)
  - Finding applies a test that doesn't fit (e.g., diagnosticity on a
    non-comparative section)
  - Finding is a style/editorial concern, not a logical one
  - Finding raises a valid point but the document already addresses it
    elsewhere
  - Finding is based on the reviewer's domain opinion, not on evidence
  - Finding duplicates another finding
- **UNVERIFIABLE** — A claim is UNCHECKED. Keep only if the document's claim
  is load-bearing (the argument collapses without it), labeled as unverified.
  Otherwise remove.

**Problem and fix are judged separately.** A reviewer often identifies a real
problem but proposes the wrong fix, especially when two sections contradict
each other and it picks the wrong side. For each finding, the judge evaluates:
- Is the *problem identification* correct? (usually yes)
- Is the *suggested action* correct? (verify independently)

If the problem is real but the fix is wrong, keep the finding, mark the
suggested action as "needs research", and note which sections conflict.

If the fix depends on a choice the user hasn't made (options put to them,
an open question the document leaves to them), the judge states the
constraint each option has to meet and marks the action "user decision". It
does not pick an option. In `--edit` mode the coordinator asks the user
about those findings and doesn't edit them.

**Sites.** For a contradiction or a wrong fact, grep the whole document for
every other place that states the same thing, and list them all in the
finding. A fix applied only where the reviewer looked leaves the rest.

End each finding with a gate line, e.g.
`Gate: quote ✓ evidence ✓ unresolved ✓ fix ✓ sites: L275, L694, Q14 → CORRECT`.

**Spot-check the matches.** The grounding table's "matches" rows are claims
nobody else re-examines. Pick the five most load-bearing (validator rules,
backing stores, authorization checks, anything the argument depends on) and
re-verify each against source, quoting the line that proves or disproves
it. A row that doesn't hold becomes a finding.

**Ledger.** The coordinator writes the judge's output (every finding, claim,
status, citation, and site list) to a scratch file. Re-runs and follow-up
questions start from it.

### Phase 3: Output

**Format:**

```
### Argument Audit: [Document Title]

**Document type:** [comparative / argumentative / mixed]
**Angles:** [each angle run, with the signal that chose it]
**Claims extracted:** N
**Findings after judge:** M

#### Findings

1. **[VERDICT]** C3: "[quoted claim]" (section: [heading])

   **Problem:** [what's wrong with this claim]
   **Evidence:** [what the reviewer found]
   **Action:** [keep / tone down / reframe / add evidence / drop / needs research / user decision]
   **Source:** [DOCUMENT "section X" | CROSS_REF "other-doc.md" | WEB "url" | CODEBASE "file:line"]
   **Sites:** [every location stating the same thing]

...

#### Summary

- Claims confirmed: X
- Claims overstated: Y
- Claims unsupported: Z
- Claims wrong: W
- Needs research: R
- Awaiting user decision: U

#### Sources Consulted
- [list of documents, URLs, files read during the audit]
```

Zero findings is a valid outcome. Report what was checked and which sources were
consulted.

**`--edit` mode**: After the audit, apply corrections to the document. Update
downstream sections (conclusions, summaries, tables) immediately after correcting
a claim so stale references don't persist. Fix every site in the finding's
site list, then grep for the corrected concept's old wording to catch sites
the judge missed. Each edit adds claims, so list them; a re-run audits those
too and always includes the judge phase.

**`--comment` mode**: Post findings as inline PR comments via `gh`. Sign with
`(~Claude)`.

## NEVER Comment On

Hard exclusion list. The judge rejects these even if a reviewer flags them:

- Grammar, spelling, formatting, or prose style (use `ndimiduk:prose-review`)
- Presentation choices that don't affect argument clarity
- Missing sections that aren't relevant to the argument
- Generic "you should also consider X" without grounding in evidence
- Domain opinions not supported by cited sources
- Aesthetic preferences about document organization
- Suggestions to add caveats or hedging language

The audit is about logical construction, not editorial quality.

## Error Taxonomy

Common errors by category, ordered by frequency. Use as a checklist.

### Claims

| Error | Test | Example |
|-------|------|---------|
| **Unsupported claim** | Grounding | "This approach is infeasible" with no evidence |
| **Ungrounded claim** | Grounding | "Fork maintenance is unbounded" (actual: 7-8 patches) |
| **Unresolvable reference** | Grounding | Citation points to local filesystem path, dead link, or inaccessible resource |
| **Broken evidence link** | Evidence-claim | Cited source supports a weaker or different claim |
| **Missing inferential step** | Reasoning chain | Jumps from observation to conclusion without connecting logic |
| **Unstated load-bearing assumption** | Assumption | Argument depends on X being true but never states X |
| **Non-differentiating dimension** | Diagnosticity | Framed as an advantage when it's true on all options |
| **Overstated advantage** | Framing | Structural gap language for a convenience difference |
| **Hidden cost** | Completeness | Per-option costs not surfaced for the "simpler" option |
| **Stale claim** | Internal consistency | Was true when written but no longer reflects the analysis |
| **Internal contradiction** | Internal consistency | Conclusion says X, analysis says Y |
| **Count-list mismatch** | Internal consistency | Row claims count of 3 but lists 2 examples; total claims 26 but table enumerates 22 |
| **Category overlap** | Internal consistency | Item appears in multiple "mutually exclusive" categories; totals don't reconcile |

### Structure

| Error | Test | Example |
|-------|------|---------|
| **Scope drift** | Scope consistency | Document solves a different problem than it claims |
| **Phantom constraint** | Assumption | Listed constraint doesn't actually bound the solution |
| **Missing constraint** | Completeness | Real constraint not listed |
| **Conflated problems** | Reasoning chain | Two separate issues presented as one |
| **Incomplete option scope** | Completeness | Required work missing from a workstream |
| **Circular dependency** | Reasoning chain | Claim A supports B, B supports A |

### Argument Flow (Step 2 structural tests)

| Error | Test | Example |
|-------|------|---------|
| **Misordered prerequisites** | Logical ordering | Expected case evaluates Q2 without resolving Q1, which Q2 depends on |
| **Posture-content mismatch** | Posture coherence | Section says "TBD" but four assessments all point to Option A |
| **Dropped analytical thread** | Argument completeness | Dimension analyzed in body but absent from conclusion |
| **Implicit sequencing** | Logical ordering | Two claims have a dependency but the document doesn't acknowledge it |

### Presentation (only when it affects argument validity)

| Error | Test | Example |
|-------|------|---------|
| **Fabricated precision** | Framing | Unscoped guess presented as an estimate |
| **Asymmetric treatment** | Framing | One option explored in detail, the other glossed over |
| **Stale downstream reference** | Internal consistency | Summary still claims something the analysis disproved |
| **Per-option impact missing** | Completeness | Complication described in prose without explicit per-option costs (comparative docs) |

## Relationship to Other Skills

- **`ndimiduk:requirements-hardening`**: audits the requirements doc. Run *before*
  this skill if the document evaluates options against requirements.
- **`ndimiduk:design-challenge`**: stress-tests a design *decision*. Use *after*
  this skill validates the evaluation, when committing to an approach.
- **`ndimiduk:prose-review`**: editorial quality. Orthogonal — run after the
  argument audit to tighten prose.
- **`ndimiduk:code-review`**: code, not documents.
- **`ndimiduk:reality-check`**: implementation vs. requirements validation.
  Different scope — this skill audits the document's arguments, reality-check
  audits whether the implementation matches what was asked for.

## Model Selection

**Angle reviewers**: Opus. Argument analysis turns on implicit assumptions,
unstated premises, and multi-step inferential chains.

**Judge**: Opus. Verifying a finding means checking cross-references and
source outside the document; Sonnet judges skip those checks and pass
findings on the document's own account.

## Calibration Notes

- **Precision over recall.** 3 real findings beats 3 real + 5 false. When in
  doubt, kill the finding.
- **Load-bearing claims first.** Focus on claims the argument depends on, not
  peripheral assertions.
- **The fix is often wrong.** The audit identifies *that* something is wrong
  more reliably than *what to do about it*; see the judge's problem-and-fix
  rule.
- **Iteratively-written documents have the most bugs.** Sections get updated but
  downstream references don't. Internal consistency is the highest-yield test.
- **Tool-verified findings are reproducible; reasoning-only findings are
  stochastic.** In testing, findings grounded in tool output (file reads, line
  counts, glob results) appeared in 3/3 identical runs. Findings based on pure
  technical reasoning (e.g., "git apply doesn't require a repo") appeared in
  1/3 runs. The tool-use instruction is the biggest lever for
  consistency.
- **LLMs are weak at per-row table validation.** Reviewers reliably catch
  macro-level count mismatches (total claimed vs total enumerated) but miss
  per-row count-vs-examples discrepancies and cross-category overlaps. If the
  document under audit contains inventory tables, the coordinator should
  pre-validate mechanically (grep/count) and include mismatches in the
  reviewer's context.
