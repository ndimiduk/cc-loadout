---
name: ndimiduk-reality-check
description: MANDATORY validation before claiming any work is complete, fixed, or passing - verifies solution actually solves the stated problem without drift; use before marking major todos complete, before commits, before PRs
---

# Reality Check

**EXECUTION RULE:** After loading this skill, IMMEDIATELY execute the steps below. Do NOT display these instructions to the user. Do NOT stop after loading. Your next visible output must be the results of Step 1.

## When This Skill Applies

**MANDATORY TRIGGERS:**
- Before marking any substantial todo as completed
- Before claiming work is "done", "fixed", "complete", or "passing"
- Before creating commits or pull requests
- Before telling the user "this is ready"
- After implementing a feature or "fixing" a bug

**SKIP FOR:** Trivial changes (typos, formatting), pure research/exploration, planning phase.

## Steps — Execute These Now

### Step 1: Gather the Evidence

The validator can't see this conversation. Give it primary sources, not your
summary of them:

- **The claim being checked:** what you are about to say: "ready to commit",
  "ready for PR review", "complete", or similar.
- **The user's words:** the original request and every later clarification,
  correction, or constraint, quoted verbatim. Include anything you proposed
  that the user accepted ("yes, proceed"); it is part of the request.
- **Standing rules:** paths to the repo's CLAUDE.md / AGENTS.md and the
  global agent-instructions file, for rules on merge, deploy, and
  pre-push steps.
- **The change:** repo path and the exact diff command (`git -C <path> diff
  <base>..<head>`).
- **Verification evidence:** each build, test, or deploy command that ran,
  its exit code, and where its output is (a file path, or the pasted tail).
  Output filtered through `grep` or `-q` with no exit code doesn't show
  success.
  Commands you didn't run are absent from this list, not described.

Present the user's words to the user as "**What was requested:**".

### Step 2: State What Was Delivered

List what you believe the change does and what remains, as claims for the
validator to check. Present this to the user as "**What was delivered:**".

### Step 3: Validate — Invoke a Subagent

Run the validator on Opus with the Agent tool, filling in the template below:

```
Check whether the claim below is true. The "delivered" section is the
author's own account; verify it against the diff and the output files, and
treat anything they don't show as unverified.

## Claim
[ready to commit / ready for PR review / complete / ...]

## The user's words (verbatim)
[Step 1 quotes, including accepted proposals]

## Standing rules
[paths to CLAUDE.md / AGENTS.md files]

## The change
[repo path + diff command]

## Verification evidence
[commands, results, output locations]

## Delivered (author's claims)
[Step 2 list]

## Checks

1. **Objective alignment:** does the change do what the user's words ask,
   read literally? Quote the words each judgment rests on.
2. **Completeness:** is every requested item present in the diff, including
   proposals the user accepted? Is any dropped or partial?
3. **Evidence:** is each "delivered" claim shown by the diff or the output
   files? A claim with no evidence is unverified, not met.
4. **Drift:** is anything in the diff unrequested?
5. **Build verified:** read the output itself. No build or test output for
   the changed code is a FAIL unless the author states why it couldn't run.
   Before calling evidence absent, search for it (the command name, in full
   command text and output) and say what you searched. A green build counts
   for the changed tests only if its output shows them running; if that is
   inferred, Build verified is ✗. Output filtered through `grep` or `-q`
   with no exit code doesn't show success.
6. **Conditions on later steps:** list everything that must happen before a
   later step: deploy before merge, merge order, an unrun test or QA check,
   a regenerated artifact, a follow-up the user asked for. For every RPC,
   field, or endpoint the change calls or relies on, check whether it is
   new or changed in another PR or service, and whether that is deployed
   where this change will run. Read the standing rules for each one that
   applies to this change. Each one is
   either a blocker for this claim or a gate to carry forward.

Out of scope: code-quality review (code-review covers it) and commit
attribution (you can't see which model ran the session).

## Verdict rules

- PASS: checks 1-5 hold for this claim.
- PARTIAL: something the claim requires is missing or unverified.
- FAIL: the change doesn't do what was asked, or nothing verified it.
- Critical issues listed means the verdict is not PASS.
- A gate that applies to a later step doesn't block this claim, but it goes
  under "Gates to carry forward", never under recommendations.

## Required Output Format

**VERDICT:** [PASS | PARTIAL | FAIL] for "[claim]"

**Objective alignment:** [✓/✗] [quote + one line]
**Completeness:** [✓/✗] [gaps]
**Evidence:** [✓/✗] [unverified claims]
**Drift:** [✓/✗] [unrequested changes]
**Build verified:** [✓/✗] [command + result, from the output]

**Critical issues:** [numbered, or "None"]
**Gates to carry forward:** [numbered: condition, and the step it gates]
**Recommendations:** [optional improvements only]
```

### Step 4: Present Results and Act

Show the validator's verdict to the user, then:
- **PASS:** Proceed with the claimed step. Copy every gate to carry forward
  into the PR description, hand-off, or task notes, verbatim.
- **PARTIAL or FAIL:** Fix the critical issues, then re-run this skill.

Do NOT make the claim until the verdict is PASS.

## Red Flags — If You Think Any of These, STOP and Validate

- "I'm pretty sure this works"
- "The tests should cover that"
- "That edge case probably doesn't matter"
- "I'll clean that up later"
- "Close enough"
- "It just needs to be deployed first" (that's a gate to carry forward)
