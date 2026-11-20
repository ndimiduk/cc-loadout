---
name: post-merge-cleanup
description: Use when the user reports that a PR or branch has been merged, shipped, or landed — "merged", "both merged", "shipped", "landed", "PR landed", "it's in", or similar terminal status reports about work done in this session.
---

# Post-Merge Cleanup

When the user reports work merged upstream, clean up without being asked again.
The merge report is the authorization. You know the repo paths, branches, and
worktrees from the conversation — don't ask the user to repeat them. Clean up
every PR reported merged; a failed check stops only that PR's cleanup.

For each merged branch, work from the repo's main checkout (`git worktree list`
shows it), never with the worktree as the current directory. The base remote
below is the one whose URL is the PR's repository: `upstream` in a fork
workflow, else usually `origin`, and `origin` when there is no PR.

1. **Confirm nothing is lost.** `gh pr view <url> --json number,state,baseRefName,commits`
   must show `MERGED`, and the local branch tip (`git rev-parse <branch>`) must be
   one of the PR's commits (`.commits[].oid`). If it isn't, the branch was
   probably rebased on GitHub ("Update branch" before merging), which rewrites
   every commit. Fetch the PR head, which GitHub keeps after the branch is
   deleted, from the base remote: `git fetch <base-remote> refs/pull/<number>/head`.
   Then run `git cherry -v FETCH_HEAD <branch>`. A `-` line is a local commit
   whose change is in the PR head. A `+` line is one whose exact change isn't:
   never pushed, or altered by a conflict resolution. Any `+` line, or a failed
   fetch, means stop and tell the user, showing those lines. With no PR, skip
   this check.
2. **Remove the worktree**, if there is one. Git won't delete a branch that a
   worktree has checked out, so this comes first. Run `git -C <worktree> status
   --short --ignored`: if anything besides build output or a ship-task
   `CHECKPOINT.md` is listed, show it and ask, since removal deletes ignored
   files too. Then `git worktree remove <worktree>`; never `--force`.
3. **Update the base.** `git fetch --prune <base-remote>`, and `git fetch
   --prune origin` too if that is a different remote. If the main checkout is
   on the base or the merged branch and `git status --porcelain
   --untracked-files=no` is empty, `git switch <base> && git merge --ff-only
   <base-remote>/<base>`; otherwise leave it, since another session may be
   using it. In a fork workflow this leaves the fork's own base branch stale;
   mention it rather than pushing.
4. **Delete the branch:** `git branch -d <branch>`. If it refuses because the
   branch is not fully merged (a squash or rebase merge does this) and step 1
   passed, use `git branch -D <branch>`. Any other refusal, including any
   refusal when there was no PR, means stop and tell the user.

Don't push or change remote state. If the remote branch still exists, mention it.
