# agents-md/

A genericized fragment of a global agent-instruction file — the per-user instructions
your AI agent reads at session start. This fragment captures the portions that have no
employer- or project-specific dependency: tone, planning skills, scratch-dir
conventions, worktree discipline, research permissions, working style, tagging, session
logs.

The filename `AGENTS.md` follows the emerging cross-tool convention. The content is
tool-agnostic by default; sections that depend on a specific agent's features (Claude
Code's tool names or permission rule format, for example) are flagged inline.

What's deliberately not included:

- Build/test conventions tied to a specific stack (Maven, npm, Gradle).
- Auth-token recipes (those belong in a `runbooks/` directory, not in agent instructions).
- Project cross-references (those rot; keep them in project-local agent files).
- Anything that names a specific employer's tools or infrastructure.

## Install

Two reasonable approaches. Adjust the install target to your agent — Claude Code reads
`~/.claude/CLAUDE.md`, Codex reads `~/.codex/AGENTS.md`, others have their own paths.

### Option A: Append (lowest friction)

```
cat ./AGENTS.md >> ~/.claude/CLAUDE.md       # Claude Code
cat ./AGENTS.md >> ~/.codex/AGENTS.md        # Codex
```

Then open the destination file and dedupe / re-order sections to taste. The fragment is
section-headed; conflicts are obvious.

### Option B: Maintain in-place via this repo (Claude Code)

Keep `~/.claude/CLAUDE.md` as your hand-authored top, then end it with:

```
@~/src/github/cc-loadout/agents-md/AGENTS.md
```

The `@<path>` syntax tells Claude Code to load the referenced file as additional
instructions. Updates flow when you `git pull` this repo.

(Confirm your version of Claude Code supports `@<path>` includes. If not, prefer
Option A. Other agents may not support an include syntax — check your tool's docs.)

## What's in the fragment

- **Personality** — direct, ruthlessly honest, no pleasantries.
- **System Design Guidance** — pointers to the planning skills in `../skills/`.
- **Rendering References as Links** — full URLs for PRs/issues, never bare numbers.
- **Code Conventions** — comment WHY not WHAT, sign agent-authored PR comments.
- **Tool Usage** — bare command names on PATH, no subshells in Bash invocations.
- **Git Workflow** — branch naming (no `/`), worktree discipline, no implicit cwd.
- **Research and Exploration Permissions** — blanket allowance for read-only git, file
  inspection, and scratch-dir work.
- **OSS Projects** — pointer to `oss-project-setup` for OSS repo configuration.
- **Working Style** — iterative, scope-minimal, checkpointed; tasks vs. knowledge.
- **Session and Task Management** — task-tracker discipline (toki).
- **Tagging Convention** — concept tags as the bridge between task tracker and zettelkasten.
- **Session Logs** — `collaboration/` directory pattern for cross-session memory.

## Customizing

Walk it once and personalize:

- The **OSS Projects** section assumes you have `oss-project-setup` available; remove if not.
- The **Tagging Convention** section assumes a paired task tracker + zettelkasten setup. If
  you don't run a zettelkasten, drop the cross-system framing and keep just the
  category-vs-identifier rule.
- The **Session Logs** section assumes a `collaboration/` directory in a notes vault. Adjust
  the path or drop the section if you don't keep one.
- The **Avoid Subshells** subsection under Tool Usage and the **No `isolation: "worktree"`**
  bullet under Git Workflow are Claude Code-specific. Drop them if you're installing into a
  non-Claude agent.
