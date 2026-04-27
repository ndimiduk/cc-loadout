# Subagents

Subagents are independent processes. They share none of the parent's context — not the
conversation, not the cwd, not the open files. Treat them like a smart colleague who
just walked into the room: they need the goal, the constraints, and the exact paths.
Vague briefings produce confidently-wrong work.

## Spawn for one of two reasons

**Rule.** Spawn a subagent only when one of these is true:

1. **Genuinely independent work that can run in parallel.** Two file authoring tasks at
   non-overlapping paths. Two read-only surveys of separate codebases. The wall-clock
   savings are real.
2. **High-context-cost work that would pollute the parent's context.** Reading a 2000-line
   file just to extract three function signatures. Running 30 tool calls to map out a
   directory tree. The parent gets back a summary, not the noise.

**Example.** Spawn five subagents in parallel, each authoring one file in this `workflow/`
directory at a non-overlapping path. The parent stitches the results together and runs
the lint.

**Anti-pattern.** Spawning a subagent for "go check what's in `foo.go`." That's one Read
tool call. The dispatch overhead, the round-trip, the briefing prompt — all cost more
than just reading the file.

## Brief like a smart colleague who just walked in

**Rule.** The agent has zero session context. State the goal in one sentence. List the
hard constraints. Point at exact paths and line numbers. Reference artifacts by their
location, not by "what we discussed earlier."

**Example.** Good prompt:

> Goal: rewrite the retry logic in
> `~/src/github/myrepo/internal/client/retry.go` to use exponential backoff with jitter.
> Current implementation is fixed-interval (line 42-71). Use the
> `github.com/cenkalti/backoff/v4` library, already in `go.mod`. Tests at
> `internal/client/retry_test.go` must continue to pass; add new test cases for the
> jittered behavior. Do not change the public API of the `Retry` function.

**Anti-pattern.** "Fix the retry logic we talked about." The agent has no idea what was
discussed. It guesses. It ships something close to but not actually what you wanted.

## Don't delegate understanding

**Rule.** If your prompt says "based on your findings, fix the bug," you've punted
synthesis to the agent. The agent doesn't have the synthesis context either; it makes
something up. Either *do* the synthesis yourself and dispatch a focused fix task, or
dispatch a research task and review the findings before dispatching the fix.

**Example.** Two-step:

1. Dispatch a research subagent: "Investigate why test `TestRetryBackoff` fails
   intermittently. Read `internal/client/retry.go` and `internal/client/retry_test.go`.
   Run the test 50 times with `go test -count=50 -run TestRetryBackoff ./internal/client/`.
   Report: flake rate, the failure mode (panic? assertion? timeout?), and the suspected
   root cause."
2. Read the report. Form a hypothesis. Dispatch the fix subagent with explicit
   instructions: "Change line X to Y because Z."

**Anti-pattern.** A single dispatch: "Investigate and fix the flaky test." The agent
investigates, forms a half-correct hypothesis, ships a fix that masks the symptom, and
the bug recurs three weeks later.

## Parallel vs. sequential

**Rule.** Parallel for independent reads, parallel for file authoring at non-overlapping
paths, parallel for surveys across separate codebases. **Sequential** for any task whose
output is input to the next task. Git commits to the same branch are inherently
sequential.

**Example.** Authoring 5 files in `workflow/` at distinct paths — parallel. Authoring
5 commits on a branch — either dispatch *one* subagent that does all 5 commits
sequentially, or have the parent commit and dispatch only the file-authoring portion in
parallel.

**Anti-pattern.** Spawning 5 parallel agents that each commit to the same branch.
They race; some of their commits land on stale heads; rebases cascade; the branch is a
mess. Or worse, they all push at once and the remote rejects 4 of them, but the
authoring work stays on disk in inconsistent states.

## Load the briefing into a file when it's long

**Rule.** When the briefing exceeds a few paragraphs (constraints, examples, paths),
write the prompt itself to `/tmp/claude-<hex>-briefing.md` and reference it from the
dispatch command. Keeps the parent's tool-call output readable and avoids re-typing the
same briefing across multiple parallel agents.

## See also

- `ndimiduk:research-dispatch` skill — checklist for research-style subagent dispatches.
- `workflow/scratch-dirs.md` — where briefings and intermediate artifacts live.
- `workflow/worktrees.md` — running subagents inside a worktree.
