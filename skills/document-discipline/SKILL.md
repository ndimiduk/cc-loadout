---
name: document-discipline
description: Use whenever writing or revising prose that other people will read in a file or tracker — research and design docs, README/markdown, issue and PR bodies, commit messages, review notes, code comments, changelogs. Keeps the artifact standalone and free of revision residue: no self-correction narration, no warnings against framings the text no longer contains, no meta-commentary about your own editing process. Triggers on drafting or editing any prose-bearing file, and especially on any multi-pass revision where an earlier draft could leak into the final text. If the `writing-clearly-and-concisely` skill is available, load and use it too.
---

# Document Discipline

The document analog of showing your final position, not your journey — applied to
durable written artifacts.

A document is a standalone artifact for a fresh reader with no access to its edit
history, the conversation that produced it, or any earlier draft. Every sentence
must earn its place for that reader. Keep revision reasoning and arguments with
earlier drafts in your thinking or in chat — never in the artifact.

## Delete these when you see them

When revising, never leave in language that only makes sense against a prior
version:

- **Revision narration or self-correction** — "correcting an earlier misread",
  "this used to say", "as noted above", "on reflection".
- **Warnings against framings the text no longer contains** — "don't read this as
  X", "this is easy to misquote"; the warning only rebuts a draft the reader never
  saw.
- **"Not X, but Y" where X is your own deleted error** rather than a misreading the
  reader would reach independently. State Y positively.
- **Meta-commentary about the document's construction or your process.**

## Don't over-correct into mush

This is not a mandate to strip substance. Keep confidence/provenance notes ("high
confidence — straightforward statutory language"), genuine reader-guidance ("not X
but Y" when X is a tempting *independent* misreading), and acknowledged strengths
("credit where due"). The test: does the sentence serve a first-time reader, or
only answer a draft they never saw?

## Verify by reading, not grep

This pollution is semantic, not lexical — grep will not catch it. Before finalizing
an edited document, re-read the changed sections as a fresh reader and cut anything
that only parses relative to a prior version.

## Examples

Bad (self-correction leaks in):

> Correcting an earlier misread of my own: the endpoint returns a list, not a map.

Good:

> The endpoint returns a list.

Bad (warns against a framing the reader can't see):

> The source assigns low confidence here — worth stating carefully, since it's easy
> to misquote as a low probability.

Good:

> The source assigns low confidence here (no precedent on point), which is not a low
> probability of success.

Bad ("not X" where X is your own deleted claim):

> The problem is not that they ignored the edge case — they named it. It's that they
> never handled it.

Good:

> They named the edge case but never handled it.

## Companion skill

If the `writing-clearly-and-concisely` skill is available, load and use it
alongside this one — it covers prose clarity and concision; this skill covers
keeping revision residue and meta-commentary out of the artifact.
