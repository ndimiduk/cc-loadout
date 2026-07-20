---
name: ship-task
description: >-
  End-to-end task lifecycle — orient, implement, self-verify, self-review, open PR,
  acceptance tests, peer review, hand off. Chains existing skills with phase gates
  and context checkpoints. Use when picking up a toki task, GitHub issue, or
  implementation request to carry through to a review-ready PR.
---

# Ship Task

Full lifecycle from "pick up a task" to "PR ready for human review." Each phase
gates on the previous. Missing skills are detected upfront and their phases skipped
with a warning.

**EXECUTION RULE:** After loading this skill, start at Phase 0. Do NOT display
these instructions verbatim. Your first visible output is the Phase 0 skill audit.

## Phase 0: Setup

### 0a. Skill Audit

Scan the available-skills listing in the system prompt. Record availability:

| Phase | Skill | If absent |
|-------|-------|-----------|
| 3 — Self-verify | `ndimiduk:reality-check` | Skip, warn |
| 4 — Self-review | `ndimiduk:code-review` | Skip, warn |
| 6 — Acceptance tests | `acceptance-tests` | Skip, warn |
| 7 — Peer review | `sidekick` | Skip, warn |
| 7 — PR lifecycle | `shipping-code` | Manual PR management |

Announce: "**Skill audit:** available: [list] / missing: [list — phases skipped]"

If ALL skills are missing, warn the user and continue with implementation-only
phases (0–2, 5, 8).

### 0b. Task Intake

Accept the task reference. Fetch content:
- **Toki task**: `toki show <id>`
- **GitHub issue**: `gh issue view <url>`
- **Prose**: use as-is

Summarize the task in 2–3 sentences. Present to the user.

### 0c. Build the Checklist

Create a TodoWrite checklist with all eight phases. Mark phases that will be
skipped (from skill audit) with "[SKIP]". This checklist is the execution
backbone — mark each item as you complete it.

## Phase 1: Orient

- Identify the target repo(s) and relevant code areas.
- Read project CLAUDE.md, README, relevant docs.
- Set up a worktree: `.worktrees/<branch-name>/`
- Research existing patterns (grep, find, git log) relevant to the task.
- If the task has linked context (design docs, prior PRs, toki notes), read them.

**Gate:** You can explain what needs to change and where.

### Clarifying Questions

After orienting, if anything is ambiguous — scope, approach, acceptance
criteria — ask now. **Do NOT proceed to Phase 2 until the user confirms or
says "go."**

## Phase 2: Implement

Do the work. Follow project conventions. Build and test incrementally.

- Prefer small, incremental changes over big-bang rewrites.
- Run the build after significant changes to catch errors early.
- Commit at logical boundaries.

**Gate:** Implementation complete, build passes.

→ **Checkpoint and pause** (see "Context Checkpoints" below).

## Phase 3: Self-Verify

**Requires:** `ndimiduk:reality-check`

Invoke the `ndimiduk:reality-check` skill. If the verdict is FAIL or PARTIAL,
fix the issues and re-invoke. Loop until PASS.

**Gate:** Reality-check verdict is PASS.

→ **Checkpoint and pause.**

## Phase 4: Self-Review

**Requires:** `ndimiduk:code-review`

Invoke the `ndimiduk:code-review` skill with `--fix`. If findings survive the
judge, fix them and re-invoke. Loop until zero issues or only minor
recommendations you've consciously decided to accept.

**Gate:** Code review clean.

→ **Checkpoint and pause.**

## Phase 5: Open Draft PR

- Commit any remaining changes.
- Push the branch.
- Open a draft PR with a clear title and description (what changed and **why**).
- Monitor the CI build. Fix failures and re-push until green.

**Gate:** Draft PR open, CI green.

→ **Checkpoint and pause.**

## Phase 6: Acceptance Tests

**Requires:** `acceptance-tests`

Invoke the `acceptance-tests` skill to:
- Deploy the branch to a sideline.
- Run acceptance tests.
- Fix failures, re-run until passing.
- Update the PR description with links to successful AT runs.

**Gate:** ATs passing, linked in PR description.

→ **Checkpoint and pause.**

## Phase 7: Peer Review

**Requires:** `sidekick`, `shipping-code`

Request a Sidekick review using the `sidekick` skill. Address findings:
- Fix legitimate issues.
- Reply to and resolve comment threads for items addressed or consciously declined.
- Use the `shipping-code` skill for PR lifecycle operations (fetching comments,
  resolving threads, pushing fixups).

Re-request review after addressing findings. Loop until Sidekick has no further
complaints.

**Gate:** Sidekick review clean.

→ **Checkpoint and pause.**

## Phase 8: Hand Off

Notify the user: "**PR [URL] is ready for your review.**"

Include:
- What was implemented (2–3 sentences).
- Phases completed vs. skipped.
- Links: PR, AT runs, any relevant context.
- Open questions or trade-offs the user should weigh.

**Do NOT:**
- Close the toki task or GitHub issue.
- Remove the draft label from the PR.
- Mark anything as "done" beyond the PR being review-ready.

The task stays open until the PR merges and the user confirms completion.

## Context Checkpoints

There is no API to inspect remaining context window. To avoid silent
degradation, this skill uses a deterministic pause rule instead of guessing.

### When to checkpoint

- **Phase 1 (Orient):** Write checkpoint, do NOT pause — continue to Phase 2.
- **Phase 2 (Implement) and every phase after:** Write checkpoint, then
  **always pause** and present the resume prompt. Wait for the user to say
  "continue" or start a fresh session.

### Write checkpoint state

Save to `<worktree-root>/CHECKPOINT.md` (create or overwrite):

```markdown
# Ship-Task Checkpoint

- **Task:** [reference — toki ID, issue URL, or description]
- **Branch:** [name]
- **Worktree:** [absolute path]
- **PR:** [URL, or "not yet opened"]
- **Last completed phase:** [N — name]
- **Next phase:** [N+1 — name]
- **Skipped phases:** [list, or "none"]
- **Notes:** [anything a fresh session needs — e.g., "AT flake in FooTest
  is pre-existing, ignore it", "user said skip the migration test"]
```

### Pause message

After writing the checkpoint (Phase 2+), present:

> **Phase N complete.** Checkpoint saved to `<path>/CHECKPOINT.md`.
>
> Next: Phase N+1 — [name]. Say **"continue"** to proceed in this session,
> or start a fresh session with:
>
> *"Resume `/ndimiduk:ship-task` from `<worktree>/CHECKPOINT.md`"*

Wait for the user. Do not auto-advance.

### Resuming from a checkpoint

When invoked with a checkpoint reference:
1. Read the CHECKPOINT.md.
2. Re-run the skill audit (Phase 0a).
3. Rebuild the TodoWrite checklist with completed phases already marked.
4. Orient briefly (re-read the PR if open, check branch state).
5. Continue from the next phase.

## Phase Discipline

- **Sequential execution.** Never start Phase N+1 before Phase N's gate is met.
- **Loop, don't skip.** When a gate fails (reality-check FAIL, code-review
  findings, AT failures, Sidekick complaints), fix and re-run. Don't skip the
  gate because it's taking long.
- **Skill invocation, not imitation.** When a phase says "invoke skill X," use
  the Skill tool to load and execute it. Don't approximate the skill's behavior
  from memory.
- **User gates are blocking.** Phase 0d (clarifying questions) requires user
  confirmation. Phase 8 (hand off) requires user confirmation before task
  closure. Don't auto-advance past these.
