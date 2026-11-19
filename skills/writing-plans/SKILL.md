---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step implementation and need to create a phased, risk-ordered plan with validation gates. OVERRIDES superpowers:writing-plans — use this version instead.
---

# Writing Implementation Plans

**Announce at start:** "Using ndimiduk:writing-plans to create the implementation plan."

**This skill overrides `superpowers:writing-plans`.** When both are available, use this one. The
superpowers version produces structurally sound individual tasks but has no guidance on task
ordering — it defaults to "build the architecture first, validate last," which is waterfall. This
skill fixes that.

**Save plans to:** User-specified location, or `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Ordering Principles

These govern how tasks are sequenced. They are non-negotiable.

### 1. Prove Before Restructuring

Never move, extract, or reorganize code that hasn't been validated in its current location. If the
plan creates new modules/packages and populates them before proving the core technical approach
works, the plan is wrong.

**Wrong:** Create module skeleton -> Define interfaces -> Implement -> Test
**Right:** Implement in existing location -> Validate -> Extract into modules

### 2. Risk-First Sequencing

The task with the highest technical uncertainty goes first — not the one that's most
architecturally "foundational." Module skeletons and SPIs are low-risk busywork. Novel
integrations, unfamiliar library APIs, and performance-critical paths are high-risk. Prove the
hard thing works before spending time on scaffolding.

Ask: "What is the single technical assumption that, if wrong, invalidates the most downstream
work?" That goes in Phase 1.

### 3. Validation Gates

Every phase ends with a passing test — existing acceptance test, new acceptance test, or
meaningful integration test. If you can't run the test suite until the last task, the plan needs
reordering.

```
Phase 1: [prove risky thing] -> AT gate
Phase 2: [next increment]    -> AT gate
Phase 3: [restructure]       -> AT gate
...
```

### 4. Existing Test Harnesses Are Sacred

If there's a working acceptance test or integration test suite, the first phase MUST end with that
suite still passing. Don't restructure the test's dependencies out from under it. The AT is your
proof that you haven't broken anything — destroying it early means flying blind.

### 5. Additive Over Replacement

Prefer adding new code alongside existing code, validating, then removing the old code — over
replacing in place. This keeps the AT green throughout and gives a rollback point.

## Anti-Patterns

Specific failure modes to recognize and reject. Each is named, grounded in a real case study, and disqualifying.

### Build-the-Tower-First

The plan lands the entire architecture (interfaces, factories, providers, config plumbing) before any task wires the new code to an existing consumer. Each individual PR is small and clean, but the project ships nothing until everything is built.

**How to spot:** Phase 1 is named "Interface Introduction" / "Foundations" / "Setup" / "Infrastructure." The first task that touches an existing consumer is in Phase 2 or later. The plan can be partially executed without producing any user-visible change.

**Why it fails:** when the design has a flaw, you don't find out until deep in the work. By then sunk cost makes admitting failure painful, and reverting is expensive because the integration is everywhere at once.

**Fix:** the first consumer integration goes in Phase 1, even if it's behind a feature flag. The new code must touch an existing call site in the first phase, period.

**Calibration data point:** a project this skill is calibrated against shipped 14 PRs and ~9,000 LOC of new infrastructure before the first task wired anything into an existing consumer. The integration four months in revealed a design flaw; the work was reverted. Targeted patches to the existing system that actually solved the customer problem were ~8% of the failed-tower's volume and shipped in days.

### Plans That Only Grow

The current plan is a revision of a previous plan, and the revision only added detail — no ideas were killed. Every section of v1 still appears in v2, just expanded.

**How to spot:** if there's a previous plan version, compare. If nothing was deleted, the plan isn't engaging with reality. If the project has multiple plan documents stacked over time, each one larger than the last, it's growing not iterating.

**Why it fails:** elaboration without deletion means no information was acquired between revisions. The plan is being decorated.

**Fix:** identify what reality contradicted in v1. State explicitly what was deleted and why. If nothing, ask whether the previous plan was actually engaged with at all.

### Comprehensive-Sounding Enumerations

The plan has a "Key Benefits" / "Implementation Tasks 1-7" / "Phase 1-4" structure that reads thorough but doesn't engage with risk.

**How to spot:** "Key Benefits" sections with bullets like "Zero Conflict / Clean Abstraction / Rollback Safety" — phrasings no one would object to. Numbered task lists where every task sounds equally important. Phases sequenced by build order rather than risk order.

**Why it fails:** comprehensive enumeration is waterfall in formal dress. It signals thoroughness without forcing the writer to identify what's risky vs. what's busywork.

**Fix:** rewrite Phase 1 to validate the riskiest assumption. If you can't name what's riskiest, the plan isn't ready.

### Class Skeletons In the Plan

The plan contains class interfaces, method signatures, and module boundaries before any implementation task validates them.

**How to spot:** Java class definitions, TypeScript interfaces, or similar code shapes embedded in the plan body. A "Component Architecture" or "Class Hierarchy" section before any task.

**Why it fails:** these are design decisions, not delivery decisions. Embedding them in the plan conflates "what shape should the code be" with "how should we ship the code." The shape can shift during implementation; baking it into the plan locks in choices that haven't been validated.

**Fix:** put the design in a separate design doc. The plan references the design and contains tasks that produce code matching it. If the design isn't done yet, finish the design before writing the plan.

## Phase Structure

Plans are organized into phases, not a flat task list. Each phase has:

- **Goal**: One sentence — what capability exists after this phase that didn't before?
- **Gate**: Which test(s) must pass to exit this phase?
- **Tasks**: The individual implementation steps

```markdown
## Phase N: [Goal in ~5 words]

Goal: [What's true after this phase that wasn't before]
Gate: [Which test(s) pass to exit]

### Task N.1: [Component Name]
...
```

Phases should be independently valuable. If the project is abandoned after Phase 2, Phases 1-2
should represent usable, tested work — not half-built scaffolding.

## Task Structure

Same as superpowers:writing-plans — bite-sized steps, exact file paths, complete code, exact
commands with expected output, frequent commits.

````markdown
### Task N.M: [Component Name]

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext:123-145`
- Test: `tests/exact/path/to/test.ext`

- [ ] **Step 1: Write the failing test**

```java
// exact test code
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn verify -pl Module -Dtest=TestClass#testMethod -Dsurefire.failIfNoSpecifiedTests=false`
Expected: FAIL with "specific error"

- [ ] **Step 3: Write minimal implementation**

```java
// exact implementation code
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn verify -pl Module -Dtest=TestClass#testMethod -Dsurefire.failIfNoSpecifiedTests=false`
Expected: PASS

- [ ] **Step 5: Commit**

```
feat(scope): concise description of what and why
```
````

## Plan Document Header

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence]

**Architecture:** [2-3 sentences]

**Tech Stack:** [Key technologies]

**Risk ordering rationale:** [Why Phase 1 is Phase 1 — what's the riskiest assumption?]

**Design doc:** [Link or path]

**Guiding principle:** Never restructure unproven code. Prove the new approach works with
existing tests, then extract proven code into the target architecture.

---
```

## No Placeholders

Every step must contain the actual content needed. These are plan failures:
- "TBD", "TODO", "implement later"
- "Add appropriate error handling"
- "Write tests for the above" (without test code)
- "Similar to Task N" (repeat — tasks may be read out of order)
- Steps that describe what to do without showing how

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans. Each
plan should produce working, testable software on its own.

## Self-Review

After writing the plan, run these checks. Fix issues inline.

### 1. Ordering Check

Walk through the tasks in sequence. At which task can you first run the existing test suite and
get a green result? If the answer is "the last task" or "not until restructuring is complete,"
the plan needs reordering. The first validation gate should be as early as possible — ideally
within the first 3-4 tasks.

### 2. Risk Sequencing Check

What is the highest-risk technical assumption in this project? Is it validated in Phase 1? If
it's buried in Phase 2 or later, explain why — there may be a legitimate dependency, but "it
felt more natural to build the foundation first" is not a reason.

### 3. Phase Independence Check

If the project were abandoned after Phase N, would Phases 1..N represent usable, tested work? Or
would they be half-built scaffolding that doesn't compile or pass tests? Each phase must leave
the codebase in a working state.

### 4. Spec Coverage

Skim each section/requirement in the spec. Can you point to a task that implements it? List gaps.

### 5. Placeholder Scan

Search for "TBD", "TODO", vague steps. Fix them.

### 6. Type Consistency

Do types, method signatures, and names used in later tasks match what's defined in earlier tasks?

### 7. Anti-Pattern Sweep

Walk through the Anti-Patterns section. Does the plan exhibit any of:

- Build-the-Tower-First
- Plans That Only Grow
- Comprehensive-Sounding Enumerations
- Class Skeletons In the Plan

If yes, fix before saving. These are not stylistic preferences; each one is calibrated against a real project failure.

### 8. First Consumer Integration Check

Find the first task that wires new code to an existing call site, endpoint, or consumer. What phase is it in? If it's not in Phase 1, explain why — is there a legitimate dependency, or is the plan a tower? Build-the-Tower-First is the most common waterfall failure mode and the hardest to see from inside the plan.

## Execution Handoff

After saving the plan, decide what to do next based on signals from the session. **Do not
ask the user "which execution mode?"** — the upstream skills describe their own fit
(`superpowers:subagent-driven-development` is for "executing implementation plans with
independent tasks in the current session"; `superpowers:executing-plans` is for "a written
implementation plan to execute in a separate session with review checkpoints"). Pick.

### Decision rubric

Read the conversation for these signals, in order:

1. **Plan-as-artifact signals → stop.** The plan is the deliverable; execution is a
   separate decision the user will make later. Announce the save path and stop. Signals:
   - The spec or task notes contain a "fresh session" / "session entry prompt" / "hand
     off" framing.
   - The user filed the plan into a long-lived location (e.g. `plans/`, `docs/plans/`)
     rather than a scratch dir.
   - The user is mid-design and the plan is feedback for the spec, not an order to
     execute.
   - The session is already long, context-heavy, or focused on planning across multiple
     workstreams.

2. **Execute-now signals → dispatch.** The user wants progress this session. Signals:
   - User said "let's start", "execute it", "go", "run it", "do phase 1", or similar.
   - Plan was saved to a per-feature scratch path and the conversation is otherwise
     short and focused.
   - The first phase is small, low-risk, and clearly worth doing inline.

   Within "dispatch", pick between the two upstream skills:
   - **`superpowers:subagent-driven-development`** — default. Fresh subagent per task,
     two-stage review, stays in this session. Best when tasks are mostly independent
     (most plans authored by this skill, since phases are deliberately decoupled).
   - **`superpowers:executing-plans`** — pick when tasks are tightly coupled (decisions
     in task N inform task N+1's interface), when subagents aren't available on this
     platform, or when the user has said they want to review each task themselves
     before the next one starts.

3. **Ambiguous → stop, don't ask.** If neither set of signals dominates, default to
   plan-as-artifact: announce the save path and a one-line summary of structure, and
   stop. The user can issue a follow-up turn to start execution; that's cheaper than a
   reflexive "which mode?" question that pushes a non-decision back at them.

### What to output

- **Plan-as-artifact / ambiguous:** one short paragraph — save path, phase count, the
  Phase 1 risk being validated. No question, no execution-mode menu.
- **Execute-now:** announce the chosen skill ("Using
  `superpowers:subagent-driven-development` to execute Phase 1 inline") and start.

### Anti-patterns

- Asking "subagent-driven or inline?" reflexively. The user already knows both modes
  exist; the question is busywork.
- Choosing inline execution when subagents are available and tasks are independent
  (the default plan structure ensures they are). Subagent-driven is almost always the
  right pick for execute-now.
- Starting execution without a clear "execute now" signal. Plans authored from a spec
  are usually intended as artifacts — let the user trigger execution explicitly.
