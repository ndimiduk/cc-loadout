# Scratch directories

Two scratch conventions, two different lifetimes. `.scratch/` lives in a repo and
survives across sessions; `/tmp/claude-*` is per-invocation ephemera. Both exist to keep
junk out of commits and to dodge security prompts on every shell invocation.

## Per-repo scratch: `.scratch/`

**Rule.** A `.scratch/` directory at the repo root, gitignored, holds repo-tied
artifacts that you want to keep across sessions but never commit: helper scripts,
generated diagnostic output, throwaway reproductions, tool outputs you'll consult later
in the same session. Add `.scratch/` to `.gitignore` once.

**Example.**

```
.scratch/
  gen-test-fixtures.sh   # populates test data from a local database dump
  benchmark-report.json  # output of last perf run, consulted across sessions
```

Neither is part of the published artifact, but both are pinned to *this* repo's state
and are useless elsewhere. They live in `.scratch/`, not in `~/bin` or `/tmp`.

**Anti-pattern.** Putting scratch artifacts in the repo root or under `tools/`. They
show up in `git status`, get accidentally committed, and pollute the diff. Or — worse —
deleting them at session end and rewriting them from scratch next time, with subtle
differences each round.

## Per-session scratch: `/tmp/claude-<8-hex>-<purpose>.txt`

**Rule.** For ephemeral content — commit messages, PR bodies, multi-line arguments to
CLI tools — write to a unique path under `/tmp/`. Format:
`/tmp/claude-<8 hex chars>-<short purpose>.txt`. The 8-hex suffix avoids collisions when
multiple sessions run in parallel.

**Example.**

```sh
# Write the commit message with the Write tool first, then:
git commit -F /tmp/claude-a3f7b912-commit-msg.txt
```

```sh
gh pr create \
  --title "fix(retry): switch to exponential backoff" \
  --body-file /tmp/claude-a3f7b912-pr-body.txt
```

**Anti-pattern.** A bare `/tmp/commit-msg.txt`. Two sessions running concurrently both
write to that path; the second clobbers the first. The first session then commits with
the second session's message, or worse, both commit identical messages with mismatched
diffs.

## Avoid shell subshells: `$()` and backticks

**Rule.** Don't use `$(...)` or backticks in Bash tool invocations. Most agent harnesses
treat any subshell expansion as a security event and prompt for approval per call. The
prompt fatigue trains people to click through; that's the failure mode.

**Example.** Instead of:

```sh
git commit -m "$(cat /tmp/msg.txt)"
```

write the message to a unique file with the Write tool, then:

```sh
git commit -F /tmp/claude-a3f7b912-commit-msg.txt
```

The `-F` (and `--body-file`, `--from-file`, `--input-file`, …) flag exists on every CLI
that accepts multi-line input. Find it. Use it.

**Anti-pattern.** Embedding multi-line content via `printf` or here-strings inside the
Bash invocation. It works once, then breaks the moment the content has a quote, a
backtick, or a `$` in it. Quoting hell is the #1 source of "the agent broke my commit
message."

## When to clean up

`.scratch/` — leave it alone unless it's getting cluttered. The whole directory is
gitignored, so the cost of keeping it is roughly zero.

`/tmp/claude-*` — the OS reaps `/tmp` on reboot. No active cleanup needed. If you really
want, batch-delete `/tmp/claude-*` at session end, but don't burn cycles on it.

## See also

- `agents-md/AGENTS.md` — Avoid Subshells and Scratch Directories sections.
- `workflow/subagents.md` — subagents writing to scratch paths the parent will read.
