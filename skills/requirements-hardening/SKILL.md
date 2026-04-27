---
name: requirements-hardening
description: Use when reviewing or writing a requirements document to verify each statement is actually a requirement of the system under evaluation. Triggers on "harden these requirements", "are these actually requirements", "review these requirements", "spot-check these requirements", or when a requirements doc is being written or revised. Classification audit, not design interrogation — for design stress-testing, use `ndimiduk:design-challenge` instead.
---

# Requirements Hardening

Audit a requirements document to verify every statement is actually a requirement
of the system under evaluation. Separate requirements from evidence and evaluation
criteria.

This is a classification workflow: read each statement, apply three tests, reclassify
items that fail. It is NOT an interrogation workflow — for probing designs across
dimensions (failure modes, scaling, operational complexity), use `design-challenge`.

## When to Use

- Reviewing a requirements document before it drives an ADR or design
- "Are these actually requirements?" / "Harden these requirements"
- Writing requirements and wanting to verify rigor as you go
- Spot-checking whether a doc conflates requirements with complaints, evidence, or preferences

## When NOT to Use

- Stress-testing a design or architecture decision: use `ndimiduk:design-challenge`
- Validating whether to build something at all: use `validate-idea`
- Writing a PRD from scratch: use `write-a-prd`

## Process

### 1. Identify the System Under Evaluation

Before testing any requirement, state clearly: **what is the system these requirements
are for?** A requirement of "the API gateway" is different from a requirement of
"the platform" or "the auth infrastructure." Misidentifying the system boundary
is the #1 cause of requirements that belong to a different layer.

Ask the user to confirm the system boundary if it's ambiguous.

### 2. Test Each Statement

For every statement that claims to be a requirement, apply three tests:

#### Layer Test

Is this a requirement of *this* system, or does it belong to a different layer?

Common layers that absorb misplaced requirements:
- **Auth infrastructure** (identity provider, credential store, session management)
- **Deployment infrastructure** (K8s, CI/CD, multi-region topology)
- **Storage layer** (databases, object stores, replication)
- **Network layer** (load balancers, service mesh, TLS termination)
- **Client layer** (SDK, CLI, UI — requirements of the consumer, not the service)
- **Integration layer** (message queues, webhooks, third-party APIs)

If another system is responsible for satisfying this need, it's not a requirement
of the system under evaluation — even if the choice affects how easy it is to
satisfy. That makes it an evaluation dimension, not a requirement.

#### Verb Test

Can you phrase it as "the system must [verb]"? If not, it's one of:
- A **signal** — evidence that the requirement is real (who needs it, where, when)
- An **evaluation dimension** — affects the decision but isn't a system capability
- A **design preference** — "we'd like X" but the system doesn't fail without it
- A **usage policy** — an obligation on users, not on the system

#### Failure Test

If the system doesn't do this, does the system fail to meet the need? Or does
something else handle it?

Watch for:
- Table-stakes features of the underlying spec (e.g., "must support transactions"
  for any SQL database — every conformant database does this by definition)
- "Must not block X" where the system has no mechanism to block X
- Redundant restatements of other requirements

### 3. Classify Each Item

Every item in the document should be one of:

| Classification | Definition | Where it belongs |
|----------------|-----------|------------------|
| **Requirement** | Passes all three tests. "The system must [verb]." | Requirements section — numbered, testable |
| **Signal** | Evidence that a requirement is real — who needs it, where raised, when | Signals table — traceability, not prescription |
| **Evaluation dimension** | Affects the decision between options but isn't a system capability | Evaluation dimensions section — feeds ADR comparison matrix |
| **Design preference** | Desirable but system doesn't fail without it | Note in evaluation dimensions or cut |
| **Usage policy** | Obligation on users, not on the system | Cut from requirements doc — belongs in operational docs |

### 4. Report

For each item that fails a test, state:
- Which test it fails
- What it actually is (signal, evaluation dimension, preference, policy)
- Where it should go instead

Summarize:
```
REQUIREMENTS: N statements pass all three tests
RECLASSIFIED: N items moved to signals / evaluation dimensions / cut
ISSUES: [any items that are ambiguous or need user judgment]
```

## Common Failure Modes

Calibrated against actual requirements documents reviewed with this process:

- **Complaint logs disguised as requirements** — tables of "who hit this problem"
  are signals, not requirements. Valuable for traceability, wrong section.
- **Design preferences stated as musts** — "the system must not enforce engine-level
  authz" is a preference, not a requirement. The system doesn't fail if it offers
  engine-level authz that you don't use.
- **Implementation mechanisms stated as requirements** — "the system must vend STS
  credentials" constrains the solution space. The requirement is "authorized clients
  can access data"; how they get credentials is an evaluation dimension.
- **Table stakes stated as differentiators** — "must support transactions" for a
  SQL database is like "must support GET" for an HTTP server.
- **"Must not block X"** — if the system has no mechanism to block X, this isn't a
  requirement. It's a non-issue dressed up as a constraint.
- **Cross-layer requirements** — "must encrypt data at rest" sounds like a database
  requirement but is actually a storage-layer requirement. The database requirement
  is "must delegate encryption to the configured storage backend."

## Anti-Sycophancy Rules

- If a statement fails a test, say so. Don't soften with "this could be interpreted as..."
- If the entire document is mostly signals and evaluation dimensions with few actual
  requirements, that's the finding. Don't pad.
- The user has deep technical experience. Explain your reasoning, not your conclusion.
  They'll override you when you're wrong — that's the process working.
