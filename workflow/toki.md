# Task tracking

Notes on using a task tracker (specifically `toki`, but the patterns generalize) without
turning it into a wiki. The tracker holds *status*; the filesystem holds *knowledge*.
Conflating them produces tasks that grow into novellas and notes systems that no one
trusts because the real content is in some closed task somewhere.

`toki` is a local-first CLI task tracker — upstream at https://github.com/harperreed/toki.
The `ndimiduk:toki` skill (shipped in this loadout under `skills/`) documents the
opinionated workflow layer on top.

## Tasks track status; the filesystem holds knowledge

**Rule.** A task tracks *what state this work is in* and *where the artifacts live*. It
does not contain the artifacts. Research goes in `research/` or `designs/` in the
relevant repo. Operational recipes go in `runbooks/`. Permanent ideas go in a
zettelkasten. Tasks point at all of those.

**Example.** A task titled "Auth-service token rotation" with body:

```
Goal: ship automatic token rotation for the auth-service client.
Design: ~/src/projects/auth-service/designs/2026-04-15-rotation-shape.md
PR: https://github.com/myorg/myrepo/pull/812
Runbook: ~/src/projects/auth-service/runbooks/refresh-token.md
```

Five lines. Anyone (including future-you) can navigate from the task to everything that
matters in under ten seconds.

**Anti-pattern.** A task with 400 lines of accumulated investigation notes, half of which
contradict each other because they were written across three sessions. The findings are
buried; nobody re-reads them; they get rewritten next quarter. If you catch yourself
writing more than ~15 lines in a task body, stop and move the content to a file.

## Tags are categories, not identifiers

**Rule.** Tags answer *what kind of thing this is about* — never *which specific
thing*. A task on PR #504 doesn't get tagged `pr-504`. It gets tagged with the project
slug and the concept the PR is about; the PR URL goes in the description.

**Concept tags** — descriptive kebab-case nouns naming a recurring concept: `cert-based-auth`,
`role-reconciler`, `query-planner`, `sensitive-data`. Use the *same* slug across tasks
and across the zettelkasten. Drift kills the cross-reference.

**Project tags** — name a repo, team, or workstream: `myrepo`, `auth-service`,
`data-platform`. One per external artifact family.

**Mechanical tags (tracker-only)** — workflow state and task type: `started`, `waiting`,
`bug`, `feature`, `epic`, `milestone`. Don't propagate these into a notes system; they
mean nothing there.

**Anti-pattern.** Numeric tags styled like tracker references — `proj-NNN`, `issue-1234`.
They collide with real issue numbers, carry no semantic weight, and rot the moment the
underlying issue is renumbered or moved.

## Concept tags bridge the tracker to the notes system

**Rule.** Use the same concept tag on a task and on a permanent note in your
zettelkasten. An agent (or a `grep`) can then surface the intersection: "what tasks and
what notes touch `cert-based-auth`?"

**Example.** Tag `cert-based-auth` on:

- A toki task: "Implement mTLS for service X"
- A permanent note: `~/notes/permanent/cert-based-auth-tradeoffs.md`
- A runbook: `~/runbooks/rotate-mtls-cert.md`

Now when starting fresh work on this concept, one query lights up the whole context.

**Anti-pattern.** Inventing a near-synonym in each system: `mtls`, `mutual-tls`,
`cert-auth`, `tls-client-cert`. The bridge breaks. Pick one slug and stick with it.

## File tasks first, do work later

**Rule.** When a request arrives, default to filing a task before starting work. The act
of writing a one-line title and a 2-3 sentence description forces clarity about scope.

**Example.** "Hey can you look at the slow query on the dashboard?" → file a task with
title "Investigate slow dashboard query (foo metric)" and body pointing at the dashboard
URL and the user's message. Then pick it up. If the work turns out to be 30 seconds, the
task is closed in 30 seconds; the cost was minimal. If the work turns out to be six
hours, you have a thread to pull on next session.

**Anti-pattern.** Diving in immediately, getting paged away halfway through, then losing
both the request and the partial investigation. The tracker is the seatbelt.

## Closing a task

**Rule.** A closed task's note is 5-15 lines: why it existed, the outcome, pointers to
artifacts produced. Not a transcript of the session.

**Example.**

```
Why: PR #812 reviewer flagged the retry policy as too aggressive.
Outcome: shipped in PR #815 — switched to exponential backoff with jitter.
Artifacts: ~/src/projects/auth-service/designs/2026-04-22-retry-policy.md
```

That's it. The PR diff, the design doc, and the commit history hold everything else.

## See also

- `agents-md/AGENTS.md` — Knowledge Management and Tagging Convention sections.
- `skills/toki/SKILL.md` — the opinionated layer this note pairs with (public name `ndimiduk:toki`).
