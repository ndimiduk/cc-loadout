# Planning

Implementation plans that survive contact with reality look the same: phased, risk-first,
each phase ending with a passing test. Plans that don't follow this shape collapse the
moment the first novel integration goes wrong — usually around phase 4 of a 7-phase
"foundation first" build.

The `ndimiduk:writing-plans` skill (at `../skills/writing-plans/SKILL.md`)
overrides `superpowers:writing-plans` and codifies the rules below.

## Phases, not flat task lists

**Rule.** Group work into phases. Each phase has a one-sentence goal and an exit gate:
which test(s) must pass to declare the phase done. Phases are independently valuable —
if work is abandoned at phase N, phases 1..N leave the codebase in a working state.

**Example.**

```
Phase 1: Prove the auth flow against the staging endpoint.
  Gate: integration test `TestAuthHappyPath` passes against staging.

Phase 2: Wire the auth client into the existing query path.
  Gate: existing acceptance suite passes; one new test exercises the auth header.

Phase 3: Replace the stub credential store with the real keystore.
  Gate: full acceptance suite passes; new test for credential rotation.
```

Each phase ships something that works. If the team gets pulled away after phase 2, the
codebase has a working integration against staging — not a half-wired skeleton.

**Anti-pattern.** A flat 23-task list ordered by file. Tasks 1-8 create empty modules
and interfaces. Task 9 is "implement the actual logic." Task 23 is "write tests." When
something fails at task 9, you have no way to localize whether the bug is in your code
or in your assumptions, because nothing has been validated end-to-end yet.

## Risk-first sequencing

**Rule.** The task with the highest *technical uncertainty* goes first. Not the most
"foundational" or the most architecturally upstream — the riskiest. Prove the hard thing
works before scaffolding around it.

**Example.** Building a new sync between two systems? The first phase is *"send one
message end-to-end through both systems against real instances and assert receipt."* Not
"design the message envelope," not "create the worker module skeleton." If the
end-to-end roundtrip is impossible (auth doesn't work, the protocols don't compose, a
firewall blocks the traffic), you find out on day one with three lines of throwaway
code, not on day twelve with three thousand lines of investment.

**Anti-pattern.** "Foundation first" — phase 1 is interfaces, phase 2 is module
skeletons, phase 3 is the wire format, phase 4 is finally an integration. The
integration fails. Now you have to redesign all the upstream choices because they
assumed the integration would work the way you guessed.

## Prove before restructuring

**Rule.** Never move, extract, or reorganize code that hasn't been validated in its
current location. Validate first; *then* extract.

**Example.** A 400-line function looks like it wants to be split into three. Before
splitting: get the function under a passing test that exercises the behavior you care
about. *Then* extract. The test catches regressions during the split.

**Anti-pattern.** "I'll clean this up while I'm in here." Refactoring untested code is
how regressions ship. The "cleanup" commit is impossible to review because every line
moved; reviewers wave it through; the regression lands in production three weeks later.

## Validation gates: every phase ends with a passing test

**Rule.** Every phase exits with a passing test. Existing acceptance test, new
acceptance test, or a meaningful integration test. If the plan can't run *any* test
suite until the last phase, the plan needs to be reordered.

**Example.** "Phase 2 exit: `go test ./internal/auth/...` passes, including the new
`TestStagingAuthHandshake` integration test that hits the real staging endpoint."

That's a gate. It's checkable. The next phase doesn't start until the gate is green.

**Anti-pattern.** "Phase 2 exit: code compiles." Compilation is not validation. A plan
where compilation is the only gate has no feedback signal — you can be six phases deep
before the first runtime exercise of any of the new code.

## Additive over replacement

**Rule.** Prefer adding new code alongside existing code, validating the new path, then
removing the old code — over editing the old code in place. Keeps tests green
throughout. Gives you a rollback point.

**Example.** Replacing a retry policy:

1. Add `RetryV2(...)` next to existing `Retry(...)`. New tests cover `RetryV2`.
2. Migrate one caller to `RetryV2`. Acceptance suite passes.
3. Migrate remaining callers. Acceptance suite passes after each.
4. Delete `Retry` and rename `RetryV2` → `Retry`.

At every step, the suite is green. If step 2 reveals a flaw in `RetryV2`, you fix
`RetryV2` without disturbing `Retry`.

**Anti-pattern.** Editing `Retry` in place across 17 callers in one commit. Tests fail.
You don't know which caller broke. You don't have a clean baseline to revert to. The
only path forward is to fix everything at once, which is exactly the situation the plan
should have prevented.

## See also

- `ndimiduk:writing-plans` skill — full plan-authoring conventions.
- `prd-to-plan` skill — convert a PRD into tracer-bullet vertical slices.
- `ndimiduk:design-challenge` skill — adversarial review *before* committing to a plan.
- `workflow/subagents.md` — dispatching plan execution to subagents.
