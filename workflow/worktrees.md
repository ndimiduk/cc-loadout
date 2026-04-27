# Worktrees

Git worktrees let multiple branches share one repo without re-cloning. The point isn't
elegance — it's keeping unrelated changes from contaminating each other when several
sessions (human or agent) run in parallel. The conventions below exist because every one
of them, ignored, has caused a real cleanup.

## Worktrees live under `.worktrees/` at the repo root

**Rule.** Always create worktrees at `.worktrees/<name>` relative to the repo root. Add
`.worktrees/` to the repo's `.gitignore` once.

**Example.**

```sh
cd ~/src/github/myrepo
git worktree add .worktrees/feature-x -b myname-feature-x
```

**Anti-pattern.** Letting an agent harness pick the path. Several harnesses default to
something under a system temp dir or an opaque cache directory. Those paths are unstable
across runs and don't match permission allowlist rules written against a known prefix.
You then can't rerun the same command tomorrow without re-approving every tool call.

## Branch names use hyphens, not slashes

**Rule.** No `/` in branch names. Hyphens only. Match the worktree directory name to the
branch name.

**Example.** `myname-auth-client` (good). The worktree at `.worktrees/myname-auth-client`
checks out branch `myname-auth-client`.

**Anti-pattern.** `myname/auth-client`. Slashes break some tooling that uses the branch
name as a path component (e.g. CI artifact paths, tmux session names, shell completion).
Pre-existing slash-named branches are fine; don't create new ones.

## CWD discipline: prefix every command with `cd /absolute/path && …`

**Rule.** When working in a worktree, every shell invocation either uses absolute paths
throughout, or starts with `cd /absolute/path/to/worktree &&`. Never assume the shell's
cwd persists between turns or across tool calls.

**Example.**

```sh
cd ~/src/github/myrepo/.worktrees/feature-x && git status
cd ~/src/github/myrepo/.worktrees/feature-x && go test ./...
```

**Anti-pattern.** Running `cd .worktrees/feature-x` once and assuming subsequent commands
inherit the directory. In an agent harness each Bash invocation starts fresh; the cwd
silently snaps back to the repo root or the original session start dir. Builds run, tests
pass — against the wrong tree. You only notice when the diff doesn't match what you
thought you'd changed.

## Subagent dispatch: pass the absolute path explicitly

**Rule.** When a subagent should operate in a worktree, create the worktree first at a
known path, then put the absolute path in the agent's prompt. Don't use harness features
that auto-create a worktree in some opaque location.

**Example.** Parent creates `.worktrees/refactor-foo`, then dispatches the agent with a
prompt like: "Working tree: `~/src/github/myrepo/.worktrees/refactor-foo`. Run all
commands prefixed with `cd <that path> &&`. Do not `git worktree add` — it's already
created."

**Anti-pattern.** Telling the harness to "isolate the agent in a worktree" without
controlling the path. The agent runs in some `/private/var/.../tmp.XYZ` directory; your
permission allowlist doesn't cover that prefix; every command prompts; the worktree
doesn't get cleaned up; you have no way to inspect what it did.

## Cleanup

When done with a worktree:

```sh
cd ~/src/github/myrepo
git worktree remove .worktrees/feature-x
git branch -D myname-feature-x   # if the branch is no longer needed
```

Stale worktree metadata (`.git/worktrees/<name>`) sometimes lingers if the directory was
deleted out from under git. Run `git worktree prune` to clear it.

## See also

- `agents-md/AGENTS.md` — Git Workflow section, the short version of these rules.
- `workflow/subagents.md` — briefing subagents that operate inside a worktree.
