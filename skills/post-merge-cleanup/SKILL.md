---
name: ndimiduk-post-merge-cleanup
description: Use when the user reports that a PR or branch has been merged, shipped, or landed — "merged", "both merged", "shipped", "landed", "PR landed", "it's in", or similar terminal status reports about work done in this session.
---

# Post-Merge Cleanup

When the user reports work merged upstream, clean up without being asked again.
The merge report is the authorization. You know the repo paths, branches, and
worktrees from the conversation — don't ask the user to repeat them. Clean up
every PR reported merged; a failed check stops only that PR's cleanup.

For each merged branch, work from the repo's main checkout (`git worktree list`
shows it), never with the worktree as the current directory:

1. **Confirm nothing is lost.** `gh pr view <url> --json state,baseRefName,commits`
   must show `MERGED`, and the local branch tip (`git rev-parse <branch>`) must be
   one of the PR's commits (`.commits[].oid`). Otherwise stop and tell the user.
   With no PR, skip this check.
2. **Remove the worktree**, if there is one. Git won't delete a branch that a
   worktree has checked out, so this comes first. Run `git -C <worktree> status
   --short --ignored`: if anything besides build output or a ship-task
   `CHECKPOINT.md` is listed, show it and ask, since removal deletes ignored
   files too. Then `git worktree remove <worktree>`; never `--force`.
3. **Update the base.** `git fetch --prune origin`. If the main checkout is on
   the base or the merged branch with a clean tree, `git switch <base> && git
   pull --ff-only`; otherwise leave it, since another session may be using it.
4. **Delete the branch:** `git branch -d <branch>`. If it refuses as not fully
   merged (a squash or rebase merge does this) and step 1 passed, use
   `git branch -D <branch>`. With no PR, or if the branch is still checked out,
   stop and tell the user.

Don't push or change remote state. If the remote branch still exists, mention it.
