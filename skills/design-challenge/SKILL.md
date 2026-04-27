---
name: design-challenge
description: Use when stress-testing a design, plan, or technical decision BEFORE committing to it. Triggers on "grill me", "challenge this", "poke holes", "stress test this design", "is this the right approach", or when about to commit to any design direction. Also use for system design sessions where NFRs, failure modes, and operational concerns must be surfaced. For requirements documents specifically, use `ndimiduk:requirements-hardening` instead.
---

# Design Challenge

Structured adversarial review of a design or technical decision. Surfaces gaps, challenges
assumptions, and forces concrete answers before committing to a direction.

This replaces generic "interview me relentlessly" with specific dimensions to probe.

## When to Use

- Before committing to any design direction or architecture
- "Grill me on this", "poke holes", "challenge this design"
- System design sessions where NFRs and failure modes matter
- Before writing a PRD (validates the problem framing)
- After writing a PRD (validates the proposed solution)
- When a decision feels too easy or uncontested
- For requirements documents, use `ndimiduk:requirements-hardening` instead

## When NOT to Use

- Validating whether to build something at all: use `validate-idea`
- Already have an approved design and need an implementation plan: use `prd-to-plan`
- Exploring a codebase for refactor opportunities: use `improve-codebase-architecture`

## Process

### 0. Establish the User's Position

Before probing, ask what the user is most worried about and what they're most
confident in. Their self-assessment reveals where to push hardest — and where
they've already done the work. Skip this if the user opened with "challenge this
[specific artifact]" and their concerns are already stated.

### 1. Understand the Design

If there's a codebase, explore it. Read relevant files, recent commits, existing docs.
If the user is presenting a design verbally, ask them to state it completely before
you start challenging.

Restate the design in your own words in 3-5 sentences. Ask: "Is this accurate?"
Don't proceed until the user confirms you understand what you're evaluating.

### 2. Probe Dimensions

Work through these dimensions ONE AT A TIME. For each, ask the hardest question you
can think of. Provide your recommended answer. Skip dimensions that clearly don't
apply (e.g., skip "Scaling" for a CLI tool used by one team).

#### Requirements Clarity

- What are the concrete NFRs? Get numbers, not vibes.
  - Latency: p50, p99, and under what load?
  - Throughput: requests/sec, messages/sec, rows/sec?
  - Consistency: strong, eventual, causal? What's the actual requirement?
  - Durability: what data loss is acceptable? RPO/RTO?
  - Availability: what's the SLA? What happens during maintenance?
- Which requirements are hard constraints vs. nice-to-haves?
- What's explicitly out of scope? (Unstated scope is the most dangerous scope.)
- If requirements are already written, use `ndimiduk:requirements-hardening` to
  verify each one actually belongs to this system.

#### Failure Modes

- What fails first under load? What's the bottleneck?
- What happens when each dependency is unavailable? (Go through them one by one.)
- What's the blast radius of the worst failure?
- How do you detect the failure? What alerts fire?
- How do you recover? Manual intervention or automatic? How long?
- What's the degraded mode? Can you serve partial results?

#### Operational Complexity

- How does this deploy? Blue-green, rolling, canary?
- Can you roll back? How fast? What state do you lose?
- What does the on-call burden look like? New runbooks needed?
- How do you observe this in production? What metrics, logs, traces?
- What's the migration path from current state to this design?
- Does this add a new dependency to the operational graph?

#### Scaling

- Where does this break at 10x current load? 100x?
- What's the scaling unit? (Horizontal pods, partitions, shards?)
- Are there shared resources that become bottlenecks?
- What's the cost curve? Linear, superlinear, step-function?

#### Maintainability

- Can someone unfamiliar with the design debug it at 3am?
- Where are the abstraction boundaries? Are they clean?
- What's the testing strategy? Can you test failure modes?
- What happens when requirements change? (Pick the most likely change and trace it.)

#### Right-Sizing

Probe whether the proposed scope is justified by the actual problem. Over-engineering is the most common silent failure mode — the design is correct, just for a problem 10× the size of the one you have.

- What's the smallest scope that solves the user-visible pain? (Not "the smallest design that includes everything we want" — the smallest that removes the actual pain.)
- Is the proposed design within ~2× the scope of that minimum? If it's 5-10×, what justifies the additional engineering investment?
- What's the equivalent targeted-patch solution to the existing system? Why isn't that sufficient?
- If the targeted patch would work, what value does the bigger design add that the patch doesn't? State it concretely, in user-visible terms.
- How many existing consumers does the proposed design require to migrate? Each migration is risk and cost. Is the migration count proportional to the value gained?

Calibration data point: design-challenges this dimension is calibrated against include projects where a 10×-LOC new system was built when targeted patches to the existing system would have shipped in days and solved the same user problem. The bigger system was reverted; the patches stuck.

#### Security and Data

- What data flows through this? Classification?
- What's the auth model? Who can access what?
- What are the trust boundaries? Where does validated data become unvalidated?
- Audit trail? Compliance requirements?

### 3. Synthesize

After probing, summarize:

```
STRENGTHS:
- [what's solid about this design]

GAPS:
- [what's missing or underspecified, with severity: BLOCKING / SIGNIFICANT / MINOR]

RISKS:
- [what could go wrong, with likelihood and impact]

VERDICT: [READY / NEEDS WORK / RETHINK]
```

**READY**: Design is sound. Gaps are minor and can be resolved during implementation.
**NEEDS WORK**: Design is directionally correct but has significant gaps. List what
needs to be resolved before committing.
**RETHINK**: Fundamental assumption is wrong or a better approach exists. State what
and why.

### 4. Iterate

If NEEDS WORK or RETHINK, work with the user to resolve the gaps. Re-probe the
affected dimensions after changes. Don't re-probe dimensions that were clean.

When READY, state it clearly and suggest the next step (usually `write-a-prd` or
`prd-to-plan`).

## Anti-Sycophancy Rules

Same rules as `validate-idea`. During probing:

- Take a position on every answer. State what evidence would change your mind.
- Never say "that could work" -- say whether it WILL work and what's missing.
- If the design has a problem, say so directly. Don't hint.
- Push back on "we'll figure that out later" -- if it's a blocking gap, it blocks now.
- The user has deep technical experience. Don't soften. Don't hand-hold.
- Admit when a dimension is outside your experience. "I don't have good signal on
  this" is more useful than a plausible-sounding analysis built on inference.

## Escape Hatch

If the user wants to focus on specific dimensions only: respect that, but name what
you're skipping and flag if any skipped dimension looks risky from what you can see.
