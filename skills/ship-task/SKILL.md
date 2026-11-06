---
name: ndimiduk-ship-task
description: >-
  End-to-end task lifecycle — orient, implement, self-verify, self-review, open PR,
  acceptance tests, peer review, hand off. Chains existing skills with phase gates
  and context checkpoints. Use when picking up a toki task, GitHub issue, or
  implementation request to carry through to a review-ready PR.
---

# Ship Task

Carries a task from intake to a draft PR ready for the user. Each phase gates on
the previous and advances once its gate is met; the only waits are the user gates
under "Phase Discipline."

**EXECUTION RULE:** After loading this skill, start at Phase 0 (or, when invoked
with a checkpoint, at "Resuming from a checkpoint"). Do NOT display these
instructions. Your first visible output is the Phase 0 skill audit.

## Phase 0: Setup

**0a. Skill audit.** Check the available-skills listing and announce
"**Skill audit:** available: [...] / missing: [... — phases skipped]".

| Phase | Skill | If absent |
|-------|-------|-----------|
| 3 | `ndimiduk:reality-check` | Skip, warn |
| 4 | `ndimiduk:code-review` (code), `ndimiduk:planning-doc-review` (docs) | Skip, warn |
| 6 | `acceptance-tests` | Skip, warn |
| 7 | `sidekick`, `shipping-code` | Skip review / manual PR management |
| After merge | `ndimiduk:post-merge-cleanup` | Manual cleanup |

**0b. Intake.** Fetch the task (`toki view <id>`, `gh issue view <url>`, or the
prose). If there is a tracking issue, `gh issue edit <url> --add-assignee @me`.
Summarize the task to the user in 2–3 sentences.

**0c. Worktree.** Identify the target repo(s) — the tracking issue may live
elsewhere — and create `.worktrees/<branch-name>/` in each from a freshly fetched
base. All edits and commits happen there.

**0d. Checklist.** Track Phases 0–8 with whatever task tool you have, marking
skipped phases "[SKIP]".

## Phase 1: Orient

Find the relevant code, read the project's CLAUDE.md/README and any linked
context, and search for existing patterns. If scope, approach, or acceptance
criteria are ambiguous, ask and wait; otherwise proceed.

**Gate:** You can explain what needs to change and where.

## Phase 2: Implement

Make small, incremental changes; build and test as you go; commit at logical
boundaries.

**Gate:** Implementation complete, build passes.

## Phase 3: Self-Verify

Invoke `ndimiduk:reality-check`; fix and re-invoke until PASS. Put any gates it
says to carry forward in the checkpoint Notes and, in Phase 5, the PR description.

**Gate:** PASS.

## Phase 4: Self-Review

Pick the review by what the branch changes: code → `ndimiduk:code-review --fix`
(add `--re-review` on every later pass); planning docs and other documents that
make arguments → `ndimiduk:planning-doc-review`; both → both. Fix surviving findings and
re-invoke until clean, apart from minor recommendations you consciously accept.
For a finding marked as the user's decision, ask and wait; don't choose for them.
Any later rewrite of a document is re-audited before it is pushed.

**Gate:** Review clean.

## Phase 5: Open Draft PR

Commit, push per "Branch Hygiene", and open a **draft** PR whose description says
what changed and why. Fix CI until green.

**Gate:** Draft PR open, CI green.

## Phase 6: Acceptance Tests

If the repo has no ATs or the branch changes nothing they exercise (e.g. docs
only), mark "[SKIP] — <reason>" and move on. Otherwise invoke `acceptance-tests`
to deploy the branch to a sideline, run the ATs, fix failures until they pass,
and link the passing runs in the PR description.

**Gate:** ATs passing and linked, or skipped with a reason.

## Phase 7: Peer Review

Request a Sidekick review (`sidekick`); use `shipping-code` for fetching
comments, posting replies, resolving threads, and re-requesting review.

Receive all PR feedback skeptically, from Sidekick or a human. Each comment is a
claim to check against the source and what you know of the domain, not an
instruction; reviewers are not thorough and are sometimes wrong. Each round:

1. Verify each comment, then sort it:
   - **Escalate** when the fix would grow the PR beyond what was reviewed (new
     behavior, a design change, files outside the PR's diff, or reversing a
     decision already made with the user), or when you'd decline a human
     reviewer's suggestion that goes beyond naming, wording, or style. Leave the
     thread open, finish the rest of the round, then give the user each
     escalated comment with your recommendation.
   - **Handle** everything else: fix what holds, or decline it with evidence.
2. Re-run Phase 4 on the fixes. Push, update the PR description, and get CI
   green. If the fixes change behavior the ATs exercise, or change the ATs,
   re-run Phase 6 and replace the AT links; skip it for trivial or
   non-functional changes (renames, comments, log text, formatting).
3. Reply to each handled thread, citing the pushed commit or the evidence for
   declining, and resolve it. Don't wait for approval; this replaces
   `shipping-code`'s per-message confirmation.
4. Re-request review from every reviewer, human or Sidekick, whose comment you
   answered with a code change.

**Gate:** Every thread answered and resolved, and escalated threads settled with
the user; the latest review raises nothing new that holds.

## Phase 8: Hand Off

Tell the user: "**Draft PR [URL] is ready for you to review and mark ready.**"
Include what was implemented, phases done vs. skipped (with reasons), links to
the PR and AT runs, recommendations accepted without fixing, and open questions.
The PR stays a draft: the user marks it ready and requests human reviewers.

## After Merge

When the user reports the merge, invoke `ndimiduk:post-merge-cleanup` from the
main checkout, removing the worktree before deleting the branch. Close the toki
task if there is one.

## Branch Hygiene

- Before every push: `git fetch origin && git rebase origin/<base>` (the PR's
  base), then `git push -u --force-with-lease --force-if-includes origin HEAD`.
  If that is rejected, or you know someone else pushed to the branch, fetch,
  `git rebase --onto origin/<branch> origin/<base>`, rebase onto the base again,
  and push. Never `--force`.
- Never merge the base branch into the feature branch, even when a deploy or CI
  check reports the branch is behind.
- When a stacked branch's parent is rebased or squash-merged, retarget the PR to
  the trunk if the parent merged and GitHub hasn't, then
  `git rebase --onto origin/<new-base> <old-parent-tip>`.

## Grounding Claims

- Check claims about how a running system behaves against what is deployed
  (deploy history, image tags, CI build logs, bundled library versions), and cite
  the commit that ships, not a branch head.
- Comment on another team's PR only while it is open.

## Context Checkpoints

At the end of every phase, write `<worktree>/CHECKPOINT.md` and report in one
line: "**Phase N complete.** To resume in a fresh session: *Resume
`/ndimiduk:ship-task` from `<worktree>/CHECKPOINT.md`*". On the first write, add
`CHECKPOINT.md` to `info/exclude` under `git rev-parse --git-common-dir` so it is
never staged and doesn't block worktree removal.

- **If you can see context usage:** continue while under about 60% used (under
  about 40% at the end of Phase 5, since Phases 6–7 are the heaviest). Otherwise
  stop and recommend a fresh session.
- **If you can't:** continue; the user sees usage and decides when to switch.

```markdown
# Ship-Task Checkpoint
- **Task:** [toki ID, issue URL, or description]
- **Branch / Worktree / PR:** [name / absolute path / URL or "not yet opened"]
- **Last completed phase / Next phase:** [N — name / N+1 — name]
- **Skipped phases:** [with reasons, or "none"]
- **Notes:** [what a fresh session needs: carried-forward gates, known flakes,
  user decisions]
```

### Resuming from a checkpoint

Read the checkpoint, re-run the skill audit, rebuild the checklist with completed
phases marked, check the branch and PR state (fix red CI first), and continue
from the next phase.

## Phase Discipline

- Don't start a phase before the previous gate is met; when a gate fails, fix and
  re-run rather than skip.
- Invoke skills with the Skill tool rather than imitating them, and run
  reality-check, code-review, and planning-doc-review from this session, not a
  forked subagent (forks can't spawn the subagents they dispatch).
- Invoking this skill authorizes assigning the issue, pushing and force-pushing
  the feature branch, opening and editing the draft PR, sideline deploys,
  requesting Sidekick review, and replying to and resolving review threads on
  that PR.
- **User gates:** Phase 1 clarifying questions (only if ambiguous), user-decision
  findings, Phase 7 escalated comments, a context stop (only if you can see
  usage), any other point an invoked skill says to ask (except `shipping-code`'s
  comment confirmations, which Phase 7 replaces), and the merge report.
