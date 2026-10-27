---
name: ndimiduk-code-review
description: >-
  Use when reviewing a diff, PR, or set of changes for correctness,
  architecture, and risk: "review this", "code review", "check my changes",
  "review the diff", or before merging. Also use when the user questions
  findings from a code review already reported in the session: "are you
  sure", "pressure-test the findings", "double-check those", "is that real".
  Flags: --comment, --fix, --re-review. For prose use
  `ndimiduk:prose-review`; for documents and designs use
  `ndimiduk:argument-audit` or `ndimiduk:design-challenge`.
---

# Code Review

Four phases: the coordinator gathers context, a reviewer agent with tool
access finds issues, a judge agent tries to refute each one, and the
coordinator reports what survives with citations. Questions about reported
findings go through the Re-check Protocol.

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
3. **Full diff**: `git diff {BASE}..{HEAD}`. For large diffs (>1000 lines
   changed), provide a file list instead. Instruct reviewers and judges to
   read per-file diffs, never print the full diff, and write findings to a
   file as they go so a context overflow doesn't lose the work.

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

The reviewer returns a list of findings. Each finding states these claims
separately, each with a source (diff line, `file:line`, doc, command output)
or `UNCHECKED`:

- **Location**: file and line range
- **Mechanism**: what the code does wrong
- **Trigger**: the production caller chain from an entry point (RPC, worker,
  job, deploy step). Test, fixture, and dead callers don't count.
- **Impact**: what breaks, for whom, how often, how long. Each bound
  ("permanently", "every run", "30 days") is a separate claim.
- **Mitigations**: retries, recovery paths, guards, and the PR's own docs or
  comments that address the issue
- **Novelty**: base-branch behavior for the same trigger
- **Fix**: concrete, or "no obvious fix"

The reviewer does not assign severity; the judge does.

**Risk focus areas** (also checked by the primary reviewer):

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

For diffs >1000 lines or >20 files, the primary reviewer's context may not fit
the full diff plus risk analysis. In that case, dispatch a separate risk agent
in parallel with the same focus areas above. Merge outputs before the judge.

### Phase 2: Judge

Dispatch a judge with the full diff and all Phase 1 findings. The judge tries
to refute each claim; a confirmed mechanism alone does not confirm a finding.
Mark each claim VERIFIED or REFUTED with a citation, or UNCHECKED. No hedging.
A citation is a `file:line`, doc, or command output that shows the claim
directly. "Follows from the mechanism" is an inference, so the claim is
UNCHECKED. An UNCHECKED claim records the searches that were run and why
they were inconclusive. A claim whose required search wasn't run is not
UNCHECKED; run the search. A claim that depends on an UNCHECKED claim is
UNCHECKED too.

**Required searches:**

- **Trigger**: trace callers to an entry point, ignoring tests and fixtures.
- **Impact**: find the code that sets each bound (naming, TTLs, retry counts,
  thresholds, client timeouts). Trace what happens after the failure: the
  operation's own cleanup and retries, and the next run. A claim of
  "permanent", "only", or "no other" requires searching for the alternative,
  such as a recovery path or a second guard.
- **Mitigations**: read the PR description, changed docs, and nearby comments.
  If the author addressed the issue, the finding is the gap in that mitigation
  and is rated as that gap.
- **Novelty**: check the base branch.
- **Fix**: check the suggested fix against the code it touches: visibility
  and package of every member it uses or adds, signatures, callers it would
  break, and whether the change makes the test fail when the bug is present.
  A wrong fix doesn't drop the finding; replace it with a fix that passes
  these checks, or mark it "needs research".

**Verdict:**

- Report only if mechanism, trigger, impact, and novelty are all VERIFIED.
  Drop findings with an UNCHECKED claim, unless the user asked for a
  thorough review; then report them labeled and rated low.
- Drop if the mechanism, trigger, or novelty is REFUTED. If the impact as
  worded is REFUTED, restate it as the consequence the code shows; drop only
  if no consequence survives.
- Drop if the behavior is the design's intent, as stated in docs or
  comments. A hazard the docs warn about is a mitigation, not intent.
- There is no informational tier.
- Merge findings that share a root cause, such as two paths into the same
  non-idempotent handler.
- Impact is VERIFIED at the furthest consequence that has a citation, such
  as "publishes a duplicate Kafka event". Cut everything past that point,
  such as "consumers double-count", and rate what remains.
- Assign severity from VERIFIED claims only. A test-coverage gap is low,
  unless the code it fails to cover is broken today.
- End each finding with a gate line, e.g.
  `Gate: mechanism ✓ trigger ✓ impact ✓ novelty ✓ fix ✓ → REPORT, medium`,
  where `fix ✗` means the fix was replaced and says why.

**Also drop:**

- Issues automated tooling catches (linter, compiler, type checker, CI)
- Generic quality suggestions not grounded in project conventions
- API claims the reviewer didn't check
- Nitpicks a senior engineer wouldn't raise
- Filler ("great use of X")
- Duplicates
- Suggestions on lines the author didn't modify

The judge may reword or merge findings but must not invent new ones.

**Ledger.** The judge returns every claim with its status and citation. The
coordinator writes this to a scratch file (`review-ledger-<pr>-<sha>.md`) and
cites the path in the output. Re-checks start from the ledger.

### Phase 3: Output

**Report the ledger as is.** The coordinator does not raise severity, add
impact bounds, or reach a merge verdict the ledger doesn't support. To overrule
the judge, it records new evidence in the ledger first. "I verified this" names
and cites the claims it covers.

**Re-check high or blocking findings** with the protocol below before
presenting them.

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

   Trigger: production caller chain
   Impact: verified bounds only
   Mitigations: what was checked, what was found
   Fix: concrete suggestion

...

Ledger: <path to claim ledger>
Sources consulted:
- [project docs, codebase files, web URLs read during review]
```

Zero issues is a valid outcome. Report "No issues found" with a summary of what
was checked and which project docs were consulted.

**`--fix` mode**: Apply reported findings that have a concrete fix. Show what
was applied.

**`--comment` mode**: Post findings as inline PR comments via `gh`. Use full SHA
in file links. Sign comments with `(~Claude)`. Never post an UNCHECKED claim.

## Re-check Protocol

For "are you sure", "pressure-test", "double-check", and the Phase 3 self-check:

1. Re-read the ledger file, not your summary. If the PR head has moved past
   the reviewed SHA, say so and check whether later commits changed the
   finding.
2. Rerun the judge's searches, weakest claims first: UNCHECKED, impact bounds,
   triggers, mitigations.
3. Change a claim's status only with cited evidence not already in the
   ledger, or by showing its existing citation doesn't support it. The
   question itself is not evidence. A surviving claim keeps its status and
   citation; "all findings hold" is a valid answer.
4. Report only the changes: finding, claim, before, after, new evidence, and
   resulting severity. List unchanged findings in one line. Update the ledger.
5. For each change, name the search the first pass skipped.

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

- **Reviewer**: Sonnet by default. Use Opus when the diff's risk lies in
  caller chains across files or in domain semantics (empty vs. absent).
- **Judge**: Opus. The required searches trace past the diff into callers,
  libraries, and live config; Sonnet judges skip them and disagree with each
  other on the same findings.
- Context quality (Phase 0) matters more than model choice.

## Anti-Patterns

- Skipping review because "it's simple"
- Ignoring confirmed findings
- Coordinator inventing findings the reviewer didn't surface
- Presenting unverified API suggestions ("use method X" without confirming X exists)
- Treating a confirmed mechanism as a confirmed finding
- Severity or wording stronger than the VERIFIED claims
- Changing a verdict on re-check without new evidence
- A re-check that rewrites the review instead of listing changes

## Red Flags

Any of these in a judge's ledger or the coordinator's output means a claim
needs its citation found or its status set to UNCHECKED:

- "I verified this myself", where only the mechanism was checked
- "Follows from the mechanism" or "structural consequence" as a citation
- "Permanently", "for up to N days", "can't be carried out", "the only
  guard", or "no recovery" without the code that sets the bound
- A severity identical to the reviewer's proposal, with no reason given
- A mitigation found in the PR's docs, and the finding's severity unchanged
- UNCHECKED with no searches listed, or "not verified" in place of reading
  the code that would settle it
