---
name: code-review
description: >-
  Code review with judge filtering and source attribution. Use when reviewing a
  diff, PR, or set of changes for correctness, architecture, and risk. Triggers
  on "review this", "code review", "check my changes", "review the diff", or
  before merging. Supports --comment (post to PR), --fix (apply fixes to working
  tree), and --re-review (focus on changes since last review). Pressure-tested
  against production PRs: caught 6/6 known bugs from a commercial review bot
  plus 5 additional findings with 0 false positives. For prose review use
  `ndimiduk:prose-review`; for design review use `ndimiduk:design-challenge`.
---

# Code Review

Review pipeline: context gathering, one tool-augmented reviewer, judge-filtered for
precision, source attribution on every finding.

## Architecture

```
  ┌─────────────┐
  │  0. Context  │  Gather project docs, CLAUDE.md, REVIEWING.md, memex
  └──────┬──────┘
         │
  ┌──────▼──────┐
  │  1. Review   │  One reviewer agent with tool access
  │              │  (+ optional risk agent for large diffs)
  └──────┬──────┘
         │
  ┌──────▼──────┐
  │  2. Judge    │  Verify every finding: CORRECT / INCORRECT / UNVERIFIABLE
  └──────┬──────┘
         │
  ┌──────▼──────┐
  │  3. Output   │  Filtered findings with source citations
  └─────────────┘
```

The quality comes from giving one reviewer deep context and tool access, then
filtering aggressively for precision. Not from multiplying shallow opinions.

## Flags

- `--comment` — post findings as inline PR comments via `gh`
- `--fix` — apply fixes to working tree after review
- `--re-review` — focus on changes since last review; don't re-raise resolved issues

## Process

### Phase 0: Gather Context (coordinator does this, not a subagent)

Collect project context before dispatching the reviewer. This is what makes the
review grounded rather than vibes-based. Inject all of it into the reviewer prompt.

**Always gather:**

1. **Project instructions**: `CLAUDE.md`, `REVIEWING.md`, `CONTRIBUTING.md`,
   `.github/CODEOWNERS` — read from repo root and from directories touched by
   the diff.
2. **Diff scope**: `git diff --stat {BASE}..{HEAD}`.
3. **Full diff**: `git diff {BASE}..{HEAD}`. For large diffs (>2000 lines
   changed), provide a file list and instruct the reviewer to fetch per-file
   diffs via tool calls instead.

**Gather when available:**

4. **Memex/fieldbook**: If a vault exists (e.g., `~/src/braindump/`), grep for
   notes related to the project, libraries, or patterns touched by the diff.
   Prior positions on conventions and architectural patterns are review context.
5. **Project documentation**: README, architecture docs, ADRs in `docs/` or
   `design/`.
6. **Recent git history**: `git log --oneline -20 {BASE}..{HEAD}` for commit
   narrative; `git log --oneline -10 -- <changed-files>` for recent history
   on touched files.

**Gather for broader context:**

7. **CI config**: Check `.github/workflows/`, `Makefile`, `pom.xml`,
   `package.json` to understand what automated checks already run. The reviewer
   must NOT duplicate what CI catches.
8. **Project conventions**: Style guides, coding standards, linting config. For
   well-known projects, use `WebSearch` to find relevant conventions, recent
   API changes, or known pitfalls — but only when the diff touches areas
   where project-specific knowledge matters.

**Scope the review:**

9. **Eligibility check**: Skip review if the diff is (a) empty, (b) purely
   mechanical (formatting, dependency bumps with no code changes), or (c) already
   reviewed this session. If `--re-review`, identify what changed since last
   review and scope accordingly.

### Phase 1: Review

Dispatch a single reviewer agent. It receives the full diff (or file list for
large diffs), all project context from Phase 0, and tool access.

**Reviewer prompt must include:**

- The full gathered context (project docs, memex excerpts, git history)
- The diff or file list
- The review focus areas below
- Explicit tool permissions: Read files, Bash (grep, git blame, git log), WebSearch
- Instruction to cite sources for every finding

**Review focus areas** (all checked by the single reviewer):

- **Correctness**: Logic errors, off-by-one, race conditions, incorrect API
  usage, null/undefined hazards, resource leaks, error handling gaps on
  critical paths. Pay close attention to Optional/nullable chaining, lambda
  scoping, and semantic meaning of return values (e.g., empty vs. absent).
- **Changed behavior**: Deleted code with side effects, changed semantics that
  callers depend on, weakened preconditions, removed error handling. Use
  `git blame` and `grep` to trace callers of changed interfaces.
- **Backwards compatibility**: What happens to existing callers, stored data,
  or in-flight requests when this ships? If the diff replaces a heuristic or
  algorithm, ask whether the old behavior should be preserved as a fallback
  during rollout. If the diff changes a public interface, check who consumes
  it.
- **Project conventions**: Violations of CLAUDE.md, REVIEWING.md, CONTRIBUTING.md,
  or patterns established in adjacent code. Only flag documented or clearly
  established conventions — not generic "best practices."
- **Architecture**: Design issues, wrong abstractions, coupling, security
  concerns. Trace data flow across file boundaries; for API changes, check
  consumers. Ask whether new responsibilities belong in the file where they
  were added or should be encapsulated elsewhere.
- **Test correctness**: Do the tests actually test what they claim? Check that
  test inputs exercise the code path under test and that assertions would
  fail if the code were broken. Watch for tests that pass vacuously due to
  setup that matches a fallback path. Verify that security invariants
  (auth checks, permission guards) are asserted in all test paths.
- **Efficiency**: Are expensive operations (RPCs, network calls, disk I/O)
  performed before a guard that would skip them? If a filter or skip
  condition exists, check whether it's applied early enough in the call
  chain to avoid wasted work.

The reviewer returns findings as a structured list. Each finding must include:
- File path and line range
- Description of the issue
- Why it matters (impact)
- Suggested fix (concrete, or "no obvious fix" if none)
- Source basis: what evidence supports this finding (diff line, project doc,
  codebase grep, git history, web search result)

**Risk focus areas** (integrated into the primary reviewer prompt):

The primary reviewer also checks these. In pressure testing, a single
reviewer with tool access caught runtime-dependency risk, cache resilience
gaps, and rollout concerns — a separate risk agent added no value for diffs
under ~1000 lines. Folding risk into the primary reviewer keeps context
unified and avoids deduplication overhead.

- **Runtime resilience**: New external dependencies in hot paths — what happens
  when they're slow or down? Is there a timeout? Does the cache handle refresh
  failures gracefully? How many blocking calls per request in degraded mode?
- **Rollout risk**: Missing fallbacks for behavior changes, missing feature
  flags for gradual rollout, no way to distinguish planned degraded-mode
  operation from real failures in logs/metrics.
- **Bug hotspot awareness**: `git log --grep="fix\|bug\|revert" -- <file>` for
  changed files with high bug-fix history. Flag untested changes in hotspot
  files.

**Optional: Split risk agent** (for very large diffs only)

For diffs >1500 lines or >20 files, the primary reviewer's context may not fit
the full diff plus risk analysis. In that case, dispatch a separate risk agent
in parallel with the same focus areas above. Merge outputs before the judge.

### Phase 2: Judge

Dispatch a judge agent that receives the full diff AND all findings from Phase 1.
The judge independently evaluates each finding.

**Judge instructions:**

Use definitive language. No hedging ("could", "might", "perhaps"). Either the
finding is real and verified, or it's not.

**For each finding, classify as:**

- **CORRECT** — Keep. Technical claim verified against the diff, project docs,
  or codebase. Finding is actionable and non-trivial.
- **INCORRECT** — Remove. Reasons include:
  - Pre-existing issue not introduced by this diff
  - False positive that doesn't survive scrutiny
  - Automated tooling already catches it (linter, compiler, type checker, CI)
  - Generic quality suggestion not grounded in project conventions
  - Unverified claim about an API or method (reviewer assumed without checking)
  - Nitpick a senior engineer wouldn't raise
  - Sycophantic or filler content ("great use of X")
  - Duplicate of another finding
  - Suggestion on lines the author didn't modify
- **UNVERIFIABLE** — Keep only if potential impact is high (data loss, security,
  correctness). Otherwise remove.

**Confidence scoring** (0-100):
- 0-25: Likely false positive
- 25-50: Might be real, can't verify
- 50-75: Probably real, verified against diff but not full codebase
- 75-100: Verified against diff AND project context

**Threshold**: Findings scoring < 75 are dropped. Lower to ≥ 50 if the user
explicitly requests a thorough/paranoid review.

The judge may also revise finding descriptions for clarity or merge near-duplicate
findings, but must NOT invent new findings.

### Phase 3: Output

**Source attribution**: Every surviving finding cites its basis:
- `DIFF` — specific diff lines exhibiting the issue
- `PROJECT_DOC` — which document (CLAUDE.md, CONTRIBUTING.md, style guide, etc.)
- `CODEBASE` — file:line in the repo that informs the finding
- `GIT_HISTORY` — commit or blame output providing context
- `WEB` — URL of external documentation consulted

**Format:**

```
### Code Review

Found N issues:

1. **[SEVERITY]** Brief description (source: PROJECT_DOC "CONTRIBUTING.md says X")

   file.py:42-45

   Why: explanation of impact
   Fix: concrete suggestion

...

Sources consulted:
- [project docs, codebase files, web URLs read during review]
```

Zero issues is a valid outcome. Report "No issues found" with a summary of what
was checked and which project docs were consulted.

**`--fix` mode**: Apply CORRECT findings (confidence ≥ 75) with concrete fix
suggestions to the working tree. Show what was applied.

**`--comment` mode**: Post findings as inline PR comments via `gh`. Use full SHA
in file links. Sign comments with `(~Claude)`.

## NEVER Comment On

Hard exclusion list. The judge rejects these even if the reviewer flags them:

- Issues linters, formatters, type checkers, or CI catch
- Missing documentation/javadoc/docstring (unless CLAUDE.md requires it)
- Generic security advice not specific to the actual code path
- Renaming or minor style not in project conventions
- "Consider adding tests" for trivial cases (null checks, guard clauses)
- Intentional functionality changes evident from PR context
- Pre-existing issues on unmodified lines

## Calibration

- **Precision over recall.** 3 real findings + 0 false positives builds trust.
  3 real + 5 false destroys it. When in doubt, kill the finding.
- **Scale to diff size.** 5-line fix: 0-2 comments. 500-line feature: full
  coverage. Don't over-comment small changes.
- **Senior audience.** Skip basic explanations. Be direct, specific, brief.
- **Project conventions beat generic advice.** "The project dev guide says X"
  is 10× more useful than "best practice suggests X."

## Workflow Integration

**Iterative development**: Review at natural checkpoints. Use `--re-review` for
subsequent passes.

**Before merge**: Full review. Consider `--comment` for the PR record.

**When stuck**: Review your own changes for a fresh perspective.

## Model Selection

The reviewer and judge agents can run on different models. The tradeoffs:

**Sonnet (default)**: Fast, cheap, and in pressure testing produced the
strongest reviews. On a ~350-line feature PR that migrated an authorization
heuristic to a proper API, Sonnet caught: a test exercising the wrong
scenario, an untested code path, a cache resilience gap with multiplied
blocking calls in degraded mode, indistinguishable log levels for planned
vs. unplanned fallback, and an encapsulation concern that matched what a
human reviewer independently raised. Sonnet's strength is thorough
systematic checking when given good context.

**Opus (for precondition tracing)**: In pressure testing, Opus went deeper
on upstream analysis — tracing whether a transformer could strip metadata
before a downstream adapter consumed it, a precondition concern Sonnet
missed. Use Opus when the diff has subtle upstream/downstream implications
requiring chains of callers traced across files. Also stronger for
domain-level semantic reasoning (e.g., "does this return value mean absent
or empty?"). But Opus is slower, more expensive, and on one test PR its
output truncated — reliability matters for a review pipeline.

**Judge model**: Sonnet. The judge's task is verification against concrete
evidence, not creative analysis.

**Recommended defaults**:
- Most diffs: Sonnet reviewer + Sonnet judge
- Diffs with subtle precondition chains or domain semantics: Opus reviewer
- When in doubt: Sonnet. Context quality (Phase 0) matters more than model.
  A well-briefed Sonnet outperforms a context-starved Opus.

## Anti-Patterns

- Skipping review because "it's simple"
- Ignoring confirmed findings
- Coordinator inventing findings the reviewer didn't surface
- Presenting unverified API suggestions ("use method X" without confirming X exists)
