---
name: toki
description: Use when tracking work that should persist across sessions - project milestones, deliverables, multi-day tasks, or anything that must survive context resets; NOT for ephemeral session work
---

# Toki: Persistent Task Management

## Overview

**Toki is for work that persists. Built-in tasks are for work that doesn't.**

Use toki when the task should survive beyond your current session.
Use built-in TaskCreate for ephemeral work within a single session.

## When to Use Toki

**USE toki for:**
- Project milestones and deliverables
- Tasks that span multiple sessions
- Work another session might pick up
- Anything that should appear in "where were we?"

**USE built-in TaskCreate for:**
- Checklist items for current work
- Research steps within a session
- Temporary reminders
- Sub-tasks of a larger toki task

```
Persistent (toki)                 Ephemeral (built-in)
─────────────────────────────     ─────────────────────────
"Implement auth system"           "Check if JWT library exists"
"Fix production bug #123"         "Read the error logs"
"Phase 2 of refactor"            "Try approach A first"
"Review security audit"           "Note: found issue in line 42"
```

If you'd put it in a handoff document, use toki.
If it's just for right now, use built-in tasks.

## CLI Reference

Toki is driven through its CLI. Storage is plain markdown at `~/.local/share/toki/<project>/todo-<id>.md`, so `cat`, `grep`, and `Read` work directly on todo files whenever that's faster than a subcommand.

```bash
# Create
toki add "Task description" --priority high --tags feature -p myproject
toki add "Task with big notes" --notes-file /tmp/claude-notes.md

# Read
toki list                        # Pending todos in the current project context
toki list --done                 # Completed
toki list --tag waiting          # Filter by tag
toki list --project myproject    # Scope to a project
toki view <id-prefix>            # Full details including notes
cat ~/.local/share/toki/<project>/todo-<id>.md   # Raw markdown (fine)

# Update
toki update <id-prefix> --priority high
toki update <id-prefix> --description "sharper description"
toki update <id-prefix> --notes-file /tmp/claude-notes.md   # Multi-line markdown
toki update <id-prefix> --due 2026-05-01
toki update <id-prefix> --clear-due

# Workflow
toki tag add <id-prefix> started
toki tag remove <id-prefix> started
toki done <id-prefix>
toki undone <id-prefix>
toki remove <id-prefix>

# Projects
toki project list
toki project add <name> [--path /abs/path]
```

`<id-prefix>` can be any unique prefix of a todo UUID — the 6-character prefix printed by `toki list` works.

### Multi-line notes and descriptions

`--notes-file` and `--description-file` read their payload from disk, so markdown with backticks, `$dollars`, quotes, and newlines stays intact without shell quoting. Write to a unique temp file first (see the global `/tmp/claude-<id>-*` convention), then pass the path:

```bash
# Write the note to a unique temp path (no subshells needed)
# (use the Write tool to create /tmp/claude-<id>-notes.md)
toki update 8a3b12 --notes-file /tmp/claude-<id>-notes.md
```

`--notes` and `--notes-file` are mutually exclusive, same for `--description` / `--description-file`.

## Conventions

### Prefer filing over doing

When you spot work that needs doing, prefer creating a toki task over doing it immediately.
This lets parallel sessions pick up work and prevents scope creep in the current session.

### Task quality

Every task must be actionable on its own by a fresh session with no prior context:
- What to do and why it matters
- Acceptance criteria (how to know it's done)
- Pointers to relevant files, PRs, or design docs

**Flag tasks lacking sufficient context** for user review rather than guessing.

### Toki IDs are internal only

Toki todo UUIDs (e.g., `b2596b6c-7c45-4367-9250-6fc74efb7017`) have no meaning outside
our local tracker. **NEVER** reference toki IDs in code comments, commit messages, PR
descriptions, or any artifact visible to colleagues. Describe the intent instead.

### Status via tags

Toki has binary done/not-done. Use tags to express workflow state:

| State | How | Meaning |
|-------|-----|---------|
| Pending | (default) | Ready to work on, equivalent to TODO |
| In progress | tag `started` | Actively being worked on |
| Blocked | tag `waiting` | Blocked on external input |
| Done | `toki done` | Complete |

### Classification tags

Use tags for task type: `feature`, `bug`, `task`, `epic`, `milestone`.

### Concept and project tags (cross-linking)

Use descriptive kebab-case slugs as tags:

- **Concept tags**: name the idea — `cert-based-auth`, `role-reconciler`,
  `query-planner`. Use the same slug across related tasks in different toki projects
  AND on related permanent notes in your personal notes vault. An agent queries both
  systems by the same slug to surface all open work and settled knowledge on the
  concept.
- **Project tags**: name the repo, team, or workstream — `myrepo`, `auth-service`,
  `data-platform`. Use for grouping all tasks touching one external artifact family.

**Tags are categories, not identifiers.** Don't tag individual issues, PRs, or commits.
Put full URLs in the task description or notes body — they're clickable there, carry
state, and survive renames. `toki list --tag auth-service` returns every task touching
that workstream; drill into notes for specifics.

**Do NOT use numeric local IDs** like `proj-NNN` as tags — they collide with real
issue numbers in project trackers.

See your global agent instructions (e.g. `~/.claude/CLAUDE.md` for Claude Code, or the
cc-loadout `agents-md/AGENTS.md` fragment that merges into it) for the companion
tagging convention notes.

### Priority

Use `high`, `medium`, `low` (maps to old A/B/C).

### Projects

Toki auto-detects the git repo and creates a project on first use. One project per repository. Use `--project` (or `toki project add`) to scope operations explicitly.

## Workflow

```bash
# 1. Session startup — see what's open
toki list

# 2. Start work
toki tag add <id> started

# 3. Log progress (write notes to a temp file, then flush in)
toki update <id> --notes-file /tmp/claude-<id>-notes.md

# 4. Open PR, move to waiting
toki tag remove <id> started
toki tag add <id> waiting

# 5. After PR merges
toki done <id>
```

## When to Close vs. When to Wait

**Code-change tasks stay open until the PR merges.** A local commit or even an open PR is not "done" — the work isn't delivered until it lands in the target branch.

| Milestone | Action |
|-----------|--------|
| Implementation done locally | `toki update <id> --notes-file ...` describing "Implemented in commit abc123" |
| PR opened | Update notes with "PR opened: URL", `toki tag add <id> waiting` |
| PR merged | `toki done <id>` |
| PR closed without merge | `toki tag remove <id> waiting`, update notes with reason |

**Non-code tasks** (research, decisions, design docs) can be closed as soon as the deliverable exists.

**Rule of thumb:** If the task produces a code change, it's not done until that change is in the target branch. If the task produces knowledge or a document, it's done when delivered.

## Closing Tasks Well

Before closing, update notes to preserve what matters:

**Keep:**
- Requirements that drove the work
- Key decisions and why
- What was delivered (commits, PRs, files changed)
- Gotchas for future reference

**Discard:**
- Dead-end exploration
- Intermediate debugging steps
- Verbose research notes

A closed task should be a useful historical record, not a dump of working notes.

## Data Location

`~/.local/share/toki/` — markdown files organized by project, one file per todo. Config at `~/.config/toki/config.json`.

Reading from these files directly (with `cat`, `grep`, or `Read`) is a supported workflow — for example, `grep -r "my-search" ~/.local/share/toki/` finds mentions across every todo without invoking the CLI.
