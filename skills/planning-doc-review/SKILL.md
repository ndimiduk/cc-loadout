---
name: ndimiduk-planning-doc-review
description: Use when reviewing a planning artifact before it is shared or finalized — RFCs, plans, milestone docs, design proposals, OKR and tracker sheets, focus maps and timelines — wherever it lives (repo file, GitHub issue, Google Doc or Sheet, Claude artifact, paste). Triggers on "review this plan", "run the skeptics over it", "pressure-test this RFC", "check the milestones doc", "review the OKRs", or a request to iterate on a doc until the reviews come back clean. For essays use `ndimiduk:prose-review`; to audit only the logic of one document use `ndimiduk:argument-audit`.
---

# Planning Doc Review

Runs the review skills that fit a planning artifact, in order, until they raise
nothing that holds, then shows the user the proposed changes before anything is
written back.

## 1. Read the whole artifact

Read it in a form that keeps its meaning, with the tool for its medium:

- **Prose** (repo file, issue, Google Doc, artifact, paste): the full text.
- **Cell-based sheet**: the cell export.
- **Visual sheet**, where color, bold, or layout carry meaning: a screenshot,
  plus the cell export for its text. Capture the screenshot or ask for it; the
  export drops formatting.

Also read what it cites or depends on: linked issues and PRs, earlier plans,
notes. Every reviewer you dispatch reads the whole artifact and its citations,
not line ranges; confirm it did before using its findings.

Work on a copy (a scratch file, or the doc branch under `ndimiduk:ship-task`),
not the original.

## 2. Review by kind

In every kind, a status ("done", "on track", a checked box) must be backed by
something checkable: a merged PR, an issue's state, a deploy.

**Prose and argument** (RFC, plan, milestone doc, design proposal, research
note, issue body):

1. `ndimiduk:argument-audit --edit` on the whole document; recent edits are
   context, not scope.
2. `ndimiduk:design-challenge` when the document proposes a design, plan, or
   decision. Run it against the text, skipping its asks of the user (its
   sections 0, 1, and 4): take answers from the document and collect the
   questions it can't answer for the user. A requirements document goes to
   `ndimiduk:requirements-hardening` instead.
3. Fix what holds and re-run 1–2 until the audit's judge keeps only user
   decisions and design-challenge returns READY. Ask the user-decision
   findings and collected questions when the loop ends.
4. Prose passes: `ndimiduk:document-discipline`, then
   `writing-clearly-and-concisely` if available. If they change a claim,
   re-run step 1.

**Cell-based sheet** (OKRs, trackers). For each row: a measurable target, an
owner, a baseline or current value, one result per row, and no unresolved
question left in its notes. Across rows: one name per objective, no
duplicates.

**Visual sheet** (focus maps, timelines). Each format has one meaning, and a key
says what it is; every span leads to a milestone; every goal has work and an
owner; dates match the tab or period; spans don't collide with holidays or
on-call.

## 3. Show changes first

Present the findings and the proposed changes — a diff for text, a list of
findings or cell changes for a sheet — and wait. Write back only what the user
approves, with the medium's tool, after re-reading the original; if it changed
meanwhile, carry the approved changes onto the new version and show the result.
Where no tool can make a change (sheet formatting, say), give the user the
change to apply. Under ship-task, the draft PR is where the changes are shown:
commit them to the doc branch.
