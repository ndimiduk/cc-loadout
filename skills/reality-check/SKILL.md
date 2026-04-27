---
name: reality-check
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

### Step 1: Extract the Problem Statement

Review the conversation history and produce a concise summary of:
- The original user request
- All clarified requirements and acceptance criteria
- Any constraints or preferences stated by the user

Present this to the user as "**What was requested:**" followed by the summary.

### Step 2: Summarize What Was Delivered

Review the work done in this session and summarize:
- Files changed and how
- Behavior added or modified
- What remains incomplete (if anything)

Present this to the user as "**What was delivered:**" followed by the summary.

### Step 3: Validate — Invoke a Subagent

Use the Agent tool to run a validation check. Fill in the template below with the details from Steps 1 and 2, then pass it as the Agent prompt:

```
Validate this implementation against the original problem statement.

## Original Problem Statement
[Insert Step 1 summary here]

## Delivered Solution
[Insert Step 2 summary here]

## Validation Checks

Perform these checks in order:

1. **Objective Alignment** — Does the solution address the core problem? Any obvious mismatches?

2. **Completeness** — Are all explicit requirements met? Any partial implementations or silently dropped requirements?

3. **Correctness** — Read the actual changed code. Does it work as intended? Bugs, edge cases, integration issues?

4. **Drift Detection** — Were features added that weren't requested? Unnecessary refactoring? Scope expansion without user approval?

5. **Build Verification** — Was the project's build/test suite actually run against the changes? Check for build tool output in the conversation. If no build was run, this is an automatic FAIL. If the build couldn't be run (no build system, missing credentials), was that stated explicitly?

## Required Output Format

**VERDICT:** [PASS | FAIL | PARTIAL]

**Objective Alignment:** [checkmark or x] [one-line explanation]
**Completeness:** [checkmark or x] [list any gaps]
**Correctness:** [checkmark or x] [list any issues]
**Drift:** [checkmark or x] [list any scope creep]
**Build Verified:** [checkmark or x] [build tool + result, or why it wasn't run]

**Critical Issues:**
[Numbered list of must-fix problems, or "None" if PASS]

**Recommendations:**
[Optional improvements that don't block completion]
```

### Step 4: Present Results and Act

Show the agent's verdict to the user, then:
- **PASS:** Proceed with the next action (commit, PR, marking complete).
- **PARTIAL or FAIL:** List what needs to be fixed. Fix critical issues, then re-run this skill.

Do NOT tell the user work is complete until the verdict is PASS.

## Red Flags — If You Think Any of These, STOP and Validate

- "I'm pretty sure this works"
- "The tests should cover that"
- "That edge case probably doesn't matter"
- "I'll clean that up later"
- "Close enough"
