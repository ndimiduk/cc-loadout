---
name: post-merge-cleanup
description: Use when the user reports that a PR or branch has been merged, shipped, or landed — clean up the corresponding local tracking branch, prune remote refs, and remove the worktree if one was used. Triggers on "merged", "both merged", "shipped", "landed", "PR landed", "it's in", or similar terminal status reports about work done in this session.
---

# Post-Merge Cleanup

When the user signals that the work is integrated upstream, do the cleanup
without being asked again.

## What to do

For each repo whose branch was merged in this session:

1. Switch off the merged branch onto its base (usually `master` or `main`).
2. Fast-forward pull.
3. Delete the local tracking branch.
4. Prune deleted remote refs.
5. If the work happened in a `.worktrees/<name>` worktree, remove the
   worktree after the branch is gone.

You already know the repo paths and branch names from earlier in the
conversation — don't ask the user to repeat them. If multiple PRs across
multiple repos are reported merged in one message, clean each one up.

## Don't

- Don't ask permission to clean up — the merge report IS the
  authorization.
- Don't force-delete (`git branch -D`) unless `-d` refused on a known-
  merged branch and you've confirmed it's actually merged upstream.
- Don't push or touch remote state beyond `fetch --prune`.
