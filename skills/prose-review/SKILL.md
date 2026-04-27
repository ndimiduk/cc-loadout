---
name: prose-review
description: Use when reviewing, editing, or giving feedback on someone else's prose — essays, articles, blog posts. Triggers on "review my writing", "edit this essay", "give me feedback", "is this overwritten", "am I overworking this", "does this flow", "one more pass". For drafting, use `writing-clearly-and-concisely`. For code review, use `review`.
---

# Prose Review

Read the piece before judging the edits. Evaluate against the piece's own voice,
not generic style heuristics.

## Process

### 1. Characterize Voice and Intent

Read the full piece before evaluating anything. Then state in 2-3 sentences:
- **Voice** — register, and whether there's deliberate architecture under the surface
- **Intent** — argue, narrate, teach, reflect?
- **Structure** — arc, turns

Present the characterization with "correct me if I'm wrong" as a hedge. If the
user already asked for a review, proceed to Step 2 in the same turn — don't block
on confirmation.

### 2. Scope and Review

If the user signaled a specific scope ("does the flow work?" → structural; "is this
overwritten?" → edit triage), confirm and focus there. Otherwise ask or default to
a full pass covering: mechanics, voice/register, structure/arc, and content.

For each observation, state the category so the author knows what lens you're using.

First-pass recommendations are questions, not verdicts. State your position and what
would change your mind. After the author responds, second-pass can be direct.

### CriticMarkup

When the user asks for tracked changes or "checkmark edits," use CriticMarkup in the
file rather than direct edits: `{++insert++}`, `{--delete--}`, `{~~old~>new~~}`.

## Red Flags — Stop and Re-read

- About to say "cut this" but haven't read the full piece yet
- Applying Strunk or a simplicity heuristic to prose that's deliberately constructed
- Calling a sentence redundant without mentally removing it to check
- Flagging register mismatch based on one sentence, not the paragraph

## Anti-Patterns

| Pattern | What goes wrong | Fix |
|---------|----------------|-----|
| Editing the diff, not the piece | Evaluate changes in isolation against generic rules; reject edits that serve the piece's voice | Step 1 exists to prevent this — don't skip it |
| Defaulting to simplicity | Assume shorter is always better; call deliberate rhetorical construction "showy" | Test against the piece's register, not a minimalism heuristic |
| Confident first-pass verdicts | Declare "cut this" before understanding what cutting breaks | Questions first, verdicts after the author responds |
| Missing structural necessity | Call a sentence redundant with the title or an earlier passage when the text doesn't actually make that connection without it | Remove it mentally, re-read the paragraph — if the connection breaks, it's load-bearing |
| Register policing | Flag one sentence as mismatched against a global style preference, not its paragraph | Zoom out to the paragraph, not the sentence |
