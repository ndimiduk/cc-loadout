# workflow/

Pattern notes — concrete cookbook entries for the conventions referenced at a high level
in `agents-md/AGENTS.md`. Read these when you want examples and anti-patterns rather than
just the rule.

## When to read each note

In rough order of when they come up over the lifecycle of a piece of work:

1. **`planning.md`** — before you write code. Phased plans, risk-first ordering,
   prove-before-restructure, validation gates.
2. **`worktrees.md`** — when starting work that needs isolation from your current
   workspace. The `.worktrees/<name>` convention, branch naming, cwd discipline.
3. **`scratch-dirs.md`** — for everything that shouldn't end up in commits. Per-repo
   `.scratch/` and per-session `/tmp/claude-*`. Plus the rule against shell subshells.
4. **`subagents.md`** — when the work has independent pieces or a research step that would
   pollute the parent's context. Briefing-style prompts, parallel vs. sequential dispatch.
5. **`toki.md`** — for the longer arc. Task tracker discipline, tag taxonomy as a bridge
   to a zettelkasten, the task-vs-knowledge separation.

These are independent — read whichever matches the situation.

## Relationship to the skills

Several of the patterns here have a corresponding skill that automates the discipline:

- `planning.md` ↔ `ndimiduk:writing-plans` (overrides `superpowers:writing-plans`)
- `subagents.md` ↔ `ndimiduk:research-dispatch` (for research-style subagent work)
- `toki.md` ↔ `ndimiduk:toki` (shipped in `skills/`)

The skill is the runtime; the workflow note is the pattern. Read both when you're learning
the convention; once it's habit, the skill is enough.
