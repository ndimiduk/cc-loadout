# cc-loadout

Portable AI-agent loadout — a generic AGENTS.md fragment, a user-authored
settings.json fragment, and a small set of skills that I find generally useful.
Plain `git clone` + `make install`. No stow. Aimed at Claude Code first
since that's what I run, but the prose is tool-agnostic where it can be.

## What's in here

- **`agents-md/`** — generic AGENTS.md fragment to merge into your global agent-instruction
  file (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, etc.)
- **`settings/`** — user-authored permissions/hooks fragment (no upstream-managed keys)
- **`skills/`** — generic skills, each in its own bare-named directory; symlink into
  `~/.claude/skills/` with `ndimiduk:` prefix to namespace them
- **`tools/`** — standalone scripts for Claude Code and tmux integration (statusline,
  usage sparkline). Not skills — invoked by settings.json or shell config.
- **`external/`** — pointers to upstream content I rely on but don't redistribute
- **`workflow/`** — pattern notes (worktrees, scratch dirs, subagents, planning, tasks)

Skills install via `make install`; other modules install via plain `ln -s` per
their READMEs.

## What's NOT in here

- Anything employer-internal. The repo passes a leak lint that greps for tokens of my
  employer's tool ecosystem; zero hits is the bar.
- A handful of skills that are too tightly coupled to a specific employer's infrastructure
  to generalize meaningfully.

## Install

```sh
git clone https://github.com/ndimiduk/cc-loadout ~/src/github/cc-loadout
```

### Skills

```sh
make install
```

Idempotent — safe to re-run after adding skills. Creates `ndimiduk:`
prefixed symlinks under `~/.claude/skills/` (`ndimiduk:writing-plans`,
`ndimiduk:reality-check`, etc.) and symlinks `session-tx` into
`~/.local/bin/`. Source directories stay bare-named; the prefix is
applied only at the symlink level.

Edits to source files are immediately live; `/reload-plugins` in active
Claude Code sessions to pick up changes.

To remove all symlinks managed by this repo:

```sh
make uninstall
```

### Other modules (via `ln -s`)

`agents-md/`, `settings/`, and `workflow/` each have their own per-module
README with the one-line `ln -s` to wire them in.

## Posture

- Silent on LLM ethics. The artifact has no editorializing.
- Not advocacy. Take what fits, leave the rest.
- Not autobiography. Patterns are the point.