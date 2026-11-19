# cc-loadout

Portable AI-agent loadout — a generic AGENTS.md fragment, a user-authored
settings.json fragment, and a small set of skills that I find generally useful.
The skills install as a plugin in Claude Code and Codex; `make install` sets up
the rest, and symlinks everything for local editing. The prose is tool-agnostic
where it can be.

## What's in here

- **`agents-md/`** — generic AGENTS.md fragment to merge into your global agent-instruction
  file (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, etc.)
- **`settings/`** — user-authored permissions/hooks fragment (no upstream-managed keys)
- **`skills/`** — generic skills, each in its own bare-named directory, published as
  the `ndimiduk` plugin so they appear as `ndimiduk:<skill>`
- **`agents/`** — subagent definitions, shipped in the Claude Code plugin
- **`tools/`** — standalone scripts for Claude Code and tmux integration (statusline,
  usage sparkline). Not skills — invoked by settings.json or shell config.
- **`external/`** — pointers to upstream content I rely on but don't redistribute
- **`workflow/`** — pattern notes (worktrees, scratch dirs, subagents, planning, tasks)

Skills and agents install as a plugin, or by `make install` for local editing. The
settings fragment and other modules install via plain `ln -s` per their READMEs.

## What's NOT in here

- Anything employer-internal. The repo passes a leak lint that greps for tokens of my
  employer's tool ecosystem; zero hits is the bar.
- A handful of skills that are too tightly coupled to a specific employer's infrastructure
  to generalize meaningfully.

## Install

### Skills as a plugin

The repo is both the `ndimiduk` plugin and a marketplace named `cc-loadout`.

Claude Code:

```sh
claude plugin marketplace add ndimiduk/cc-loadout
claude plugin install ndimiduk@cc-loadout
```

Codex:

```sh
codex plugin marketplace add ndimiduk/cc-loadout
codex plugin add ndimiduk@cc-loadout
```

Skills appear as `ndimiduk:<skill>`; in Claude Code the plugin also adds the
`ndimiduk:prose-reviewer` agent. An installed plugin moves to a new release only
when the plugin version changes:

- Claude Code: `claude plugin marketplace update cc-loadout`, then
  `claude plugin update ndimiduk@cc-loadout` and restart; or turn on auto-update
  for the marketplace in the `/plugin` menu.
- Codex: `codex plugin marketplace upgrade cc-loadout` updates the installed
  plugin too.

To stay on one release, add the marketplace at its tag:
`ndimiduk/cc-loadout#v0.1.0` for Claude Code, `--ref v0.1.0` for Codex.

The `session-transcripts` and `research-lint` skills call the `session-tx` and
`rklint` scripts they bundle by bare name, so put those on your `PATH`: clone
the repo and run `make install-bins`.

### Everything else, or editing the skills

```sh
git clone https://github.com/ndimiduk/cc-loadout ~/src/github/cc-loadout
make install
```

`make install` symlinks the skills, agents, and context files into each harness
and the bundled scripts into `~/.local/bin`, so edits in the checkout are live
on the next session start. Don't combine it with the plugin install for the same
harness; each skill would be listed twice. Idempotent — safe to re-run after
adding skills. The aggregate target installs every destination:

- Claude Code: `~/.claude/skills/ndimiduk:<name>` and `~/.claude/agents/`
- Shared skills: `~/.agents/skills/ndimiduk:<name>`, the open agent-skills user
  location that both Codex and Pi scan. Pi gets its skills only from here, so
  each skill is listed once.
- Pi: `~/.pi/agent/agents/` and `~/.pi/agent/AGENTS.md`
- Codex: `~/.codex/AGENTS.md`. Codex's `config.toml` isn't installed from here.
- Shared CLI tools: `~/.local/bin/session-tx` and `~/.local/bin/rklint`

Use `make install-claude`, `make install-pi`, or `make install-codex` to install
for one agent runtime. Override the destination when needed, for example:

```sh
make install-pi PI_USER=/path/to/pi/agent
```

Each skill's `name:` equals its bare directory name. Plugin installs add the
`ndimiduk:` prefix as the plugin namespace. Symlink installs carry the prefix in
the link name, which Claude Code uses as the skill name; Codex and Pi name a
symlinked skill from `name:`, so there it appears unprefixed.

To remove all symlinks managed by this repo:

```sh
make uninstall
```

Use `make uninstall-claude`, `make uninstall-pi`, `make uninstall-codex`,
`make uninstall-shared`, or `make uninstall-bins` to remove only one destination.

### Releasing

```sh
make bump VERSION=0.2.0   # sets the version in both plugin manifests, then checks them
git commit -am "release 0.2.0"
git tag v0.2.0 && git push origin main v0.2.0
```

CI validates the plugin on every push and pull request, and turns a `v*` tag
that matches the manifest version into a GitHub release.

### Other modules (via `ln -s`)

`agents-md/`, `settings/`, and `workflow/` each have their own per-module
README with the one-line `ln -s` to wire them in.

## Posture

- Silent on LLM ethics. The artifact has no editorializing.
- Not advocacy. Take what fits, leave the rest.
- Not autobiography. Patterns are the point.