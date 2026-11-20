---
name: code-review
description: >-
  Use when reviewing a diff, PR, or set of changes for correctness,
  architecture, and risk: "review this", "code review", "check my changes",
  "review the diff", or before merging. Also use when the user questions
  findings from a code review already reported in the session: "are you
  sure", "pressure-test the findings", "double-check those", "is that real".
  Also use to re-review a PR already reviewed: "take another look", "check
  the latest", "any updates?". Invoke it again for each code review,
  re-review, or question about its findings, even when it is already loaded.
  Flags: --comment, --fix, --re-review. For prose use `ndimiduk:prose-review`;
  for documents and designs use `ndimiduk:argument-audit` or
  `ndimiduk:design-challenge`.
---

# Code Review

The coordinator gathers context. A reviewer agent finds defects. When the
change adds a surface other code is built against, a design reviewer raises
design questions alongside it. A judge agent tries to refute every finding
and question, and the coordinator reports what survives, with citations.
Questions about reported findings go through the Re-check Protocol.

Every review runs the reviewer as its own agent, and the judge whenever there
are findings, design questions, or outside claims to test, whatever the diff
size. The coordinator never substitutes its own read for either.

Start each agent with a fresh context and everything it needs in its prompt;
it must not inherit this conversation (in Codex, spawn it with
`fork_turns: "none"`). A judge that has read the coordinator's reasoning tests
that reasoning instead of the code. Tell each agent its role, and that it must
not load this skill or start agents of its own.

## Flags

- `--comment` — post the findings the user picks (see "Posting")
- `--fix` — apply fixes to the working tree after the review
- `--re-review` — review only what changed since the last reviewed commit
  (see "Re-review")

## Phase 0: Gather Context

The coordinator collects this itself and puts all of it in the reviewer's
prompt.

**Always:**

1. **Project instructions**: `CLAUDE.md`, `REVIEWING.md`, `CONTRIBUTING.md`,
   `.github/CODEOWNERS`, at the repo root and in directories the diff touches.
2. **Diff**: `git diff --stat {BASE}..{HEAD}` and `git diff {BASE}..{HEAD}`,
   where BASE is the merge-base with the PR's base branch. Over 1000 changed
   lines, pass a file list instead. Tell every agent to read per-file diffs,
   never print the whole diff, and write its results to a file as it goes.
3. **Intent**: the issue or task text and the PR description. For a PR, also
   its conversation (`gh pr view --comments` and review threads) and its head
   checked out in a worktree. Fetch any other local clone the review will
   read, at the ref the PR builds against.
4. **Prior decisions**, for a PR in a stack (its base is another open PR's
   branch, or its description lists a stack): from every PR in the stack, the
   earlier ledgers, review threads, and stack-level comments, each with how it
   ended (fixed, declined with a reason, deferred to a named PR or phase); and
   the deferrals in the plan or design doc the stack implements.

**When available:**

5. **Vault notes**: if a vault exists (e.g., `~/src/braindump/`), grep it for
   the project, libraries, and patterns the diff touches.
6. **Project docs**: README, architecture docs, ADRs in `docs/` or `design/`.
7. **History**: `git log --oneline -20 {BASE}..{HEAD}`, and
   `git log --oneline -10 -- <changed-files>`.
8. **CI config**: `.github/workflows/`, `Makefile`, `pom.xml`, `package.json`,
   for the automated checks that already run; the reviewer doesn't duplicate
   them.
9. **Conventions**: style guides and lint config. For well-known projects,
   `WebSearch` for conventions, recent API changes, or known pitfalls, only
   where the diff touches areas that need project-specific knowledge.

**Skip the review** if the diff is empty, purely mechanical (formatting,
dependency bumps with no code changes), or already reviewed at this head with
no uncommitted changes or new comments since. A reviewed PR with changes gets
a re-review.

## Phase 1: Review

Dispatch one reviewer with the Phase 0 context, the diff or file list, the
focus areas below, and these tools: Read, Bash (grep, git blame, git log),
WebSearch, and, for decision-logic mutants, Edit and the module's test command
in the scratch worktree only. It cites a source for every claim.

**Focus areas:**

- **Correctness**: logic errors, off-by-one, races, incorrect API usage, null
  hazards, resource leaks, error-handling gaps on critical paths. Watch
  Optional and nullable chaining, lambda scoping, and what return values mean
  (empty vs. absent).
- **Completeness**: every place the intent says the change applies, including
  code the diff doesn't touch: other callers of what it replaces, other entry
  points to the same behavior. A path the description or commits defer is not
  a gap.
- **Changed behavior**: deleted code with side effects, changed semantics
  callers depend on, weakened preconditions, removed error handling. Trace
  callers of changed interfaces with `git blame` and `grep`.
- **Backwards compatibility**: existing callers, stored data, and in-flight
  requests when this ships. When the diff replaces a heuristic or algorithm,
  ask whether the old behavior should stay as a rollout fallback.
- **Conventions**: violations of the project instructions, documented
  conventions, or patterns established in adjacent code; not generic best
  practice.
- **Architecture**: design issues, wrong abstractions, coupling, security
  concerns,
  responsibilities added in the wrong place. Trace data flow across files; for
  API changes, check consumers.
- **Test correctness**: inputs that miss the path under test, assertions that
  would pass with the code broken, setup that lands on a fallback path,
  security invariants (auth checks, permission guards) not asserted on every
  path.
- **Decision-logic mutants**: when the diff changes logic whose wrong answer
  grants access, loses data, or routes a request, message, or job to the
  wrong tenant, cluster, or destination (authorization rules, policy tables,
  combinators over per-item results, state machines), mutate its decision
  points on changed lines.
  - Use a scratch worktree at the reviewed state (HEAD plus any uncommitted
    diff), never the review worktree, a log directory no other review
    shares, and the narrowest test selector that covers the code. Run the tests unmutated first; if they fail, run no
    mutants and say so.
  - One mutant per decision point, with the operator most likely to survive:
    move a value between sets, flip a comparison, loosen a match (exact to
    substring, prefix, or case-insensitive), swap all/any, drop a branch, swap
    which outcome wins. Prefer the mutant that fails open: admits more,
    keeps more, or routes more widely. At most 15 per review, those nearest
    the access, data, or routing outcome first; list the rest as not run.
  - Survivors in one function or table make one finding. Its mechanism is
    the mutants and the test output, its trigger the caller chain to the
    decision point, its impact what the mutant would do on that chain.
  - Return every mutant run, with the test that killed it or SURVIVED.
- **Indistinguishable failure**: on a path in the mutants' scope, an error or
  a state only a bug produces gets the same outcome as a legitimate case
  (deny, skip, default), or several distinct causes collapse into one
  outcome, and the logs, the metrics, and the response all look the same
  across them. Impact is the cases a caller or operator can't tell apart; cite the
  log, metric, and response lines for each.
- **Efficiency**: expensive operations (RPCs, network calls, disk I/O) before
  a guard that would skip them.
- **Runtime resilience**: new external dependencies on hot paths: timeouts,
  behavior when they're slow or down, cache refresh failures, blocking calls
  per request in degraded mode.
- **Rollout risk**: missing fallbacks or feature flags for behavior changes;
  degraded-mode operation that logs and metrics can't tell from real failure.
- **Bug hotspots**: untested changes in files with a high bug-fix history
  (`git log --grep="fix\|bug\|revert" -- <file>`).

For diffs over 1000 lines or 20 files, a separate risk agent may take runtime
resilience, rollout risk, and bug hotspots in parallel; merge its output
before the judge.

**Each finding** states these claims separately, each with a source (diff
line, `file:line`, doc, command output) or `UNCHECKED`:

- **Location**: file and line range
- **Mechanism**: what the code does wrong
- **Trigger**: the production caller chain from an entry point (RPC, worker,
  job, deploy step); test, fixture, and dead callers don't count. For an
  entry point whose callers live outside the repo (a library, public API, or
  CLI), the trigger is a call made the way its signature and docs describe;
  having no callers in the repo doesn't refute it.
- **Impact**: what breaks, for whom, how often, how long. Each bound
  ("permanently", "every run", "30 days") is a separate claim.
- **Mitigations**: retries, recovery paths, guards, and the PR's own docs or
  comments on the issue
- **Novelty**: base-branch behavior for the same trigger; for a completeness
  gap, the intent text that asks for different behavior
- **Fix**: concrete, or "no obvious fix"

The reviewer returns every issue with a mechanism, minor ones included.
Severity and dropping belong to the judge.

## Design Lane

**Runs when** the diff adds a declaration, or changes the name, type, or
signature of one, that code outside its module compiles against or parses, or
is meant to (a library's public API): API and model types; wire schemas
(JSON, CHIRP, protobuf, Avro, REST, Kafka); config schemas and CRDs; database
schemas other services read. For generated code, the declaration is in the
schema file. Questions are raised only on the declarations that qualify and
the logic behind them. Otherwise the output says in one line that the lane
didn't run.

**Vocabulary sources.** The coordinator fetches the spec or design doc the
change implements and the source of each system whose values cross the
declaration, at the version the build resolves, and cites those versions. A
source it can't fetch is listed as missing, and no class 1 question is raised
against it.

**Design reviewer.** A separate agent, dispatched in parallel with the
reviewer. It returns design questions, not findings; a defect it notices goes
in a note, which the coordinator passes to the judge as an outside claim.
Each question has:

- **Location**: the `file:line` its evidence class cites
- **Question**: one sentence to the author, as a question
- **Evidence class**: one of the five below
- **Evidence**: the citations the class requires, each a path or URL with a
  line or section; citations from memory don't count

A question that fits no class is not raised. Each class names the search the
judge runs to refute it.

1. **Vocabulary conflict**: a value flows between this declaration and
   another system, which calls it something else or uses the declaration's
   name for something else. Cite the line where the value passes to or from
   that system, and that system's definition.
   Refuted if the name matches the term on the side the value flows to, or
   the module is a translation layer that documents its own vocabulary.
2. **Misleading name**: the question states, as a concrete prediction, what a
   caller reading the name would expect, and cites the code that makes it
   false: `maxRetries = 3` reads as three retries; `Client.java:88` makes
   three attempts.
   Refuted if the code doesn't contradict the prediction, or the name is the
   spec's term for the value.
3. **Weaker type than one in use**: a string, primitive, or bare collection
   carries a value this repo already converts to or from a type (cite the
   conversion site), or that an integrated system produces from a closed enum
   (cite the producing line). At a wire boundary, the question says what an
   unknown value would do.
   Refuted if the conversion site is test or dead code, the type isn't
   reachable from this module under the repo's layering rules, or the string
   is a documented
   forward-compatibility choice.
4. **Unstated precedence**: decision logic in the mutants' scope picks
   between outcomes when more than one applies (precedence, exception,
   default), and neither the code, its doc, nor the PR names the rule. Cite
   the line that picks, and the spec section if one exists.
   Refuted if the code, its doc, or the PR names the rule.
5. **Behavior outside its type**: two or more sites branch the same way on a
   value of a type this diff adds. Cite each site.
   Refuted if the sites branch differently, or the type can't hold behavior
   (generated code, or a project rule forbids it; cite the rule).

Phase 2 judges and ranks the questions.

## Phase 2: Judge

Skip the judge when there are no findings, no design questions, and no
outside claims (PR comments asserting a defect, or the user's question): it
tests claims and adds none. Write an empty ledger and go to Phase 3.

Otherwise dispatch it with the diff, the Phase 0 intent and prior decisions,
every finding and design question, the outside claims, and, for design
questions, the evidence classes with their refutation searches and the
vocabulary sources at their cited versions. It tries to refute each claim
and marks it VERIFIED or REFUTED with a citation, or UNCHECKED. No hedging. A citation is a `file:line`, doc, or command output that shows the
claim directly; "follows from the mechanism" is an inference, so that claim
is UNCHECKED. An UNCHECKED claim lists the searches run and why they were
inconclusive. A claim whose required search wasn't run is not UNCHECKED: run
the search. A claim that depends on an UNCHECKED claim is UNCHECKED too. A
confirmed mechanism alone does not confirm a finding.

**Required searches:**

- **Trigger**: trace callers to an entry point, ignoring tests and fixtures;
  for callers outside the repo, check the call its signature and docs
  describe.
- **Impact**: find the code that sets each bound (naming, TTLs, retry counts,
  thresholds, client timeouts), and trace what happens after the failure: the
  operation's own cleanup and retries, and the next run. "Permanent", "only",
  or "no other" requires searching for the alternative, such as a recovery
  path or a second guard.
- **Mitigations**: read the PR description, changed docs, and nearby
  comments. If the author addressed the issue, the finding is the gap in that
  mitigation, rated as that gap. For an indistinguishable failure, failing
  closed is not a mitigation, and documented intent to fail closed is not
  intent to be indistinguishable.
- **Mutants**: rerun each survivor and show an input on which its output
  differs from the original's; with none, drop it as equivalent. A mutant the
  judge can't run is UNCHECKED, with the build error.
- **Novelty**: the base branch, or for a completeness gap, the intent.
- **Fix**: check it against the code it touches: visibility and package of
  every member it uses or adds, signatures, callers it would break, and
  whether it makes the test fail with the bug present. A wrong fix doesn't
  drop the finding; replace it with one that passes these checks, or mark it
  "needs research".
- **Design questions**: open each citation at the cited version and
  location, then run the class's refutation search.

**Findings:**

- Report only if mechanism, trigger, impact, and novelty are VERIFIED. Drop a
  finding with an UNCHECKED claim, unless the user asked for a thorough
  review; then report it labeled and rated low.
- Drop if the mechanism, trigger, or novelty is REFUTED. If the impact as
  worded is REFUTED, restate it as the consequence the code shows; drop only
  if none survives.
- Drop if the behavior is the design's intent as stated in docs or comments.
  A hazard the docs warn about is a mitigation, not intent.
- Impact is VERIFIED at the furthest consequence with a citation ("publishes
  a duplicate Kafka event"). Cut what lies past it ("consumers double-count")
  and rate what remains.
- Assign severity from VERIFIED claims only. A test-coverage gap is low unless
  the code it fails to cover is broken today. There is no informational tier.
- Merge findings that share a root cause, such as two paths into the same
  non-idempotent handler.
- End each with a gate line:
  `Gate: mechanism ✓ trigger ✓ impact ✓ novelty ✓ fix ✓ → REPORT, medium`,
  where `fix ✗` means the fix was replaced and says why.

Drop these findings even when the reviewer flags them (these rules don't
apply to design questions):

- Issues that linters, formatters, compilers, type checkers, or CI catch
- Missing documentation or Javadoc, unless the project's CLAUDE.md or the
  spec the change implements requires it
- Renaming or minor style not in project conventions
- Generic quality suggestions not grounded in project conventions
- Generic security advice not specific to the actual code path
- "Consider adding tests" for trivial cases (null checks, guard clauses)
- API claims the reviewer didn't check
- Intentional functionality changes the PR states (cite the text)
- Pre-existing issues on lines the author didn't modify, and suggestions
  about those lines, except completeness gaps. A defect the diff causes in
  unmodified code is a finding.
- Nitpicks a senior engineer wouldn't raise, filler, and duplicates

**Design questions:**

- Keep a question when its citations open as cited and its refutation search
  finds nothing, and end it with a gate line:
  `Gate: evidence ✓ refutation (layering rules, consumers) ✗ → KEEP`.
- Drop questions on declarations or logic the diff doesn't add or change, on
  declarations that don't qualify the lane, on anything tooling enforces, and
  duplicates. When a finding and a question
  share a location and cause, keep the finding. Questions on the same
  declaration merge, keeping each class's evidence line.
- A question stays a question. When its evidence shows a defect, the judge
  says so, and the coordinator sends that to the reviewer.
- Questions carry no severity. Rank them one-way doors first, by how hard the
  answer is to change after merge, citing where the declaration is parsed,
  stored, or compiled against:
  1. A wire format, persisted data, or a schema another service reads
  2. A declaration code in another repo compiles against
  3. A declaration another module in this repo compiles against
  4. Anything else

  Within a tier, an answer that changes a name, type, or signature comes
  before one that adds a doc; then the declaration with more consumers.
  Report the top five; the rest stay in the ledger, one line each, with their
  tier.

**Prior decisions.** Drop a finding or question with the same root cause as a
prior decision on any PR in the stack, or as a deferral in the plan or design
doc, unless this diff changes what the decision rested on; then report it,
citing the decision and the change. An item deferred to this PR or phase is
part of its intent: check it as a completeness gap. A diff that undoes a prior
fix is a finding.

The judge may reword or merge findings and questions as above, but must not
invent either.

**Ledger.** The judge returns every claim with its status and citation. The
coordinator writes it to `review-ledger-<pr>-<sha>.md` in scratch and cites
the path; re-checks start from it. After the user decides, the coordinator
records each decision with its reason and source (the user's call in the
conversation, the author's reply, or the thread's resolution), and each
design question's outcome: posted, dropped, or reworded.

## Phase 3: Output

Report the ledger as is: no severity, impact bound, or merge verdict the
ledger doesn't support. To overrule the judge, record new evidence in the
ledger first; "I verified this" names and cites the claims it covers.
Re-check high or blocking findings with the Re-check Protocol before
presenting them.

Every finding cites its basis: `DIFF` (diff lines), `PROJECT_DOC` (which
document), `CODEBASE` (`file:line`), `GIT_HISTORY` (commit or blame), or `WEB`
(URL).

```
### Code Review

Found N issues:

1. **[SEVERITY]** Brief description (source: PROJECT_DOC "CONTRIBUTING.md says X")

   file.py:42-45

   Trigger: production caller chain
   Impact: verified bounds only
   Mitigations: what was checked, what was found
   Fix: concrete suggestion

Mutants: each one run, with the test that killed it or SURVIVED, or why none ran

### Design Questions

N questions (M more in the ledger), or "Design lane: not run (no public surface)":

1. **[tier 1: wire format]** file.java:12 — Question to the author?
   Evidence (vocabulary conflict): <citation> vs <citation>
   Evidence (<another class>, when merged): <citations>
   Tier: <where it is parsed, stored, or compiled against>

Ledger: <path>
Sources consulted:
- [project docs, codebase files, web URLs read during review]
```

Zero issues is a valid outcome: report "No issues found" with what was
checked and which project docs were consulted.

`--fix` applies the reported findings that have a concrete fix and shows what
changed.

On a PR the user doesn't own, present the results and wait; the user decides
what, if anything, is posted, with or without `--comment`.

## Posting

After the user picks:

1. Refresh the PR and the review worktree. If the head moved or new comments
   arrived, re-review the delta; if that changes a picked item, report back
   before posting.
2. Post with `shipping-code`'s `post-comment` script (`--file`/`--line` for
   lines in the diff, `--general` otherwise), not its PR workflow, with full
   SHAs in file links. Never post an UNCHECKED claim.
3. Write as the user, applying `ndimiduk:document-discipline`: the problem and
   its evidence; no "we", no account of how the review ran. Leave the fix to
   the author unless the user asks for one. Sign per the user's convention.
4. Post a design question as a question, with its evidence. Name a term or
   type only when the evidence cites an existing one; leave new names to the
   author.

Replies drafted for threads the user started follow steps 3 and 4. When the
user's comment may rest on a wrong premise, send the premise to the judge as
an outside claim. The reply corrects it only when the judge REFUTES it with a
citation, and keeps the point that survives.

## Re-review

For `--re-review` and "take another look" on a reviewed PR:

1. Check out the PR head in the review worktree and fetch its comments. Take
   the last reviewed commit from the ledger, else the commit of the user's
   last comment on the PR; with neither, run a full review.
2. Run Phases 1–2, and the Design Lane when it runs, on `git diff <T>` plus
   the new comments, with the earlier ledger as context. T is the first line of
   `git merge-tree --write-tree <last-reviewed> <BASE>`: the reviewed state
   replayed onto the current base, so rebases, base merges, and uncommitted
   fixes reduce to the real change. Bot comments go to the judge as claims.
   Resolved, declined, and dropped items follow the prior-decisions rule.
3. Report what's new or changed, and write a ledger at the new head.

## Re-check Protocol

For "are you sure", "pressure-test", "double-check", and the Phase 3
self-check:

1. Re-read the ledger file, not your summary. If the head has moved past the
   reviewed SHA, say so and check whether later commits changed the finding.
2. Rerun the required searches, weakest claims first: UNCHECKED, impact
   bounds, triggers, mitigations; for a design question, its citations and
   refutation search. When the user questioned a finding, a judge reruns
   them, given the ledger, the current head, the question, and steps 3 and 5;
   for the self-check, run them yourself.
3. Change a claim's status only with cited evidence not already in the
   ledger, or by showing its citation doesn't support it. The question itself
   is not evidence. A surviving claim keeps its status and citation; "all
   findings hold" is a valid answer.
4. Report only the changes: finding, claim, before, after, new evidence, and
   resulting severity. List unchanged findings in one line. Update the
   ledger.
5. For each change, name the search the first pass skipped.

## Calibration

- **Precision over recall.** Three real findings and no false ones build
  trust; three real and five false destroy it. When in doubt, drop the
  finding or question.
- **Scale the comments, not the process, to the diff.** A 5-line fix gets 0–2
  comments; a 500-line feature gets full coverage.
- **Senior audience.** Direct, specific, brief; no basic explanations.
- **Project conventions beat generic advice.** "The project dev guide says X"
  outweighs "best practice suggests X".

## Model Selection

- **Reviewer**: mid-tier (Claude Sonnet class) by default; the strongest
  available (Claude Opus class) when the risk lies in caller chains across
  files or in domain semantics (empty vs. absent).
- **Design reviewer**: the strongest available. Its classes trace a value
  across modules and into integrated systems' source; mid-tier design
  reviewers stop at the declaration and raise questions the judge drops.
- **Judge**: the strongest available. Its required searches trace past the
  diff into callers, libraries, and live config; mid-tier judges skip them
  and disagree with each other on the same findings.
- When the agent tool can't choose a model, every agent runs on the session's
  model; run the review in a session on the strongest model available.
- Phase 0 context matters more than model choice.

## Anti-Patterns

- Skipping the review, the reviewer, or the judge because the diff is small
  or simple ("overkill", "I reviewed it myself", "checked the load-bearing
  claims myself")
- Answering "take another look" with an ad hoc read instead of a re-review
- Ignoring confirmed findings
- The coordinator inventing findings the reviewer didn't surface
- Unverified API suggestions ("use method X" without confirming X exists)
- Treating a confirmed mechanism as a confirmed finding
- Severity or wording stronger than the VERIFIED claims
- Changing a verdict on re-check without new evidence, or a re-check that
  rewrites the review instead of listing changes

## Red Flags

Each of these, in a judge's ledger or the coordinator's output, means a claim
needs its citation found or its status set to UNCHECKED:

- "I verified this myself", where only the mechanism was checked
- "Follows from the mechanism" or "structural consequence" as a citation
- "Permanently", "for up to N days", "can't be carried out", "the only
  guard", or "no recovery" without the code that sets the bound
- A severity identical to the reviewer's proposal, with no reason given
- A mitigation found in the PR's docs, and the finding's severity unchanged
- UNCHECKED with no searches listed, or "not verified" in place of reading
  the code that would settle it
