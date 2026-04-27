# external/plugins.md

Pointers to Claude Code plugins this loadout depends on but does not redistribute.

## superpowers

A skills-driven software-development methodology for Claude Code, distributed as a plugin
through the `superpowers-marketplace`. Authored by Jesse Vincent (obra). Provides a library
of process skills covering planning, execution, debugging, code review, and worktree
discipline — invoked by name as `superpowers:<skill>` once installed.

### Why this loadout depends on it

The genericized fragment in `agents-md/AGENTS.md` names several `superpowers:*` skills
directly, and `ndimiduk:writing-plans` is explicitly an override of
`superpowers:writing-plans` rather than a from-scratch replacement. The core planning
loop (brainstorm a spec, write a phased plan, execute it with subagents, verify before
calling done) leans on the upstream plugin's framing.

The dispatch and worktree skills also do load-bearing work: `dispatching-parallel-agents`
sets the bar for when work is parallelizable, `using-git-worktrees` enforces the same
worktree discipline this loadout's AGENTS.md fragment assumes, and
`subagent-driven-development` is the harness for executing plans piece by piece.

### Install

Inside Claude Code, register the marketplace and install the plugin:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Marketplace: https://github.com/obra/superpowers-marketplace
Plugin source: https://github.com/obra/superpowers

Confirm the canonical install command in the marketplace README before running — the
plugin ecosystem is young and command shapes can drift.

### Skills most relevant to this loadout's workflow

- `superpowers:brainstorming` — upstream of plan-writing.
- `superpowers:writing-plans` — overridden by `ndimiduk:writing-plans`; install both, use
  the override.
- `superpowers:executing-plans` — phased execution with review checkpoints.
- `superpowers:subagent-driven-development` — execute independent plan tasks via subagents.
- `superpowers:dispatching-parallel-agents` — parallelism criterion.
- `superpowers:using-git-worktrees` — matches this loadout's worktree conventions.
- `superpowers:test-driven-development` — RED-GREEN-REFACTOR enforcement.
- `superpowers:systematic-debugging` — pairs with `ndimiduk:reality-check`.
- `superpowers:verification-before-completion` — pairs with `ndimiduk:reality-check`.
- `superpowers:requesting-code-review`, `superpowers:receiving-code-review`.
- `superpowers:writing-skills` — for authoring new skills.
- `superpowers:finishing-a-development-branch` — merge/PR/cleanup decision.
- `superpowers:using-superpowers` — session-start skill discovery.
