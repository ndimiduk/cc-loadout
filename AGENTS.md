# AGENTS.md — instructions for agents working in this repo

Canonical agent-instruction file for cc-loadout. Applies to any AI agent working in
this repo — Claude Code, Codex, or otherwise. `CLAUDE.md` is a symlink to this file
so Claude Code keeps finding instructions under that name.

This file does NOT replace your global agent-instruction file (`~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md`, etc.). The genericized fragment that's meant to be merged into
that global file lives at [`agents-md/AGENTS.md`](./agents-md/AGENTS.md) — different
file, different purpose.

## What this repo is

A portable agent loadout. Five modules, all in plain markdown except for one JSON
fragment:

- [`agents-md/AGENTS.md`](./agents-md/AGENTS.md) — generic fragment to merge into your
  global agent-instructions file.
- [`settings/settings.fragment.json`](./settings/settings.fragment.json) — user-authored
  permissions/hooks fragment for Claude Code.
- [`skills/<name>/`](./skills/) — generic skills, each in its own bare-named directory
  with a `SKILL.md`.
- [`external/{plugins,skills,tools}.md`](./external/) — pointers to upstream content
  this loadout assumes, not redistributed here.
- [`workflow/<topic>.md`](./workflow/) — pattern notes (worktrees, scratch dirs,
  subagents, planning, tasks).

## Install model

`make install` symlinks skills into `~/.claude/skills/ndimiduk:<name>/` and
`session-tx` into `~/.local/bin/`. Idempotent. `make uninstall` reverses it.
Non-skill modules (`agents-md/`, `settings/`, `workflow/`) still use plain
`ln -s` per-module READMEs. Edits to source files are immediately live, picked
up on the next session start or `/reload-plugins` in an active session.

## Editing rules

- **Run lint before any commit.** `bash .scratch/lint-leaks.sh` must report
  `PASS: zero leaks` across all tracked files. The lint script is gitignored
  (`.scratch/`); regenerate from this repo's history if missing.
- **Skill source directories MUST be bare** — `skills/writing-plans/`, not
  `skills/ndimiduk:writing-plans/`. The `ndimiduk:` prefix is applied only at the
  symlink level: `~/.claude/skills/ndimiduk:<name>/ -> .../skills/<name>/`.
- **Skills install via `make install`.** Non-skill modules use `ln -s` per
  their READMEs.
- **Settings fragment is user-authored only.** Never paste in keys that an upstream
  tool manages on this machine — see [`settings/README.md`](./settings/README.md) for
  the rule and the derivation-from-source method.
- **Posture is silent on LLM ethics.** No advocacy, no autobiography. Patterns are
  the point.

## Adding a skill

1. Drop the new skill at `skills/<name>/SKILL.md` (bare dir, no prefix).
2. Frontmatter `name:` field matches the dir name.
3. `make install` — picks up the new directory automatically.
4. Add a one-line description to the skill index below, pulled from the skill's
   frontmatter.
5. Run lint.
6. `/reload-plugins` in any Claude session. Verify the skill appears as
   `ndimiduk:<name>` and invokes.

## When the spec changes

The spec for this repo is an external artifact (the design doc that produced the
original plan). Substantive changes to structure or scope warrant a separate plan, not
in-repo edits. Small refinements (tightening prose, fixing typos, adding a workflow
note) are fine to commit directly.

## Skill index

For full triggers and execution rules, see each skill's own `SKILL.md`.

- **`ndimiduk:design-challenge`** — Stress-test a design, plan, or technical decision
  before committing to it. Adversarial review across NFRs, failure modes, operational
  complexity, scaling, maintainability, security.
- **`ndimiduk:reality-check`** — Mandatory validation before claiming any work is
  complete, fixed, or passing. Verifies the solution actually solves the stated
  problem without drift. Use before commits, before PRs, before marking todos done.
- **`ndimiduk:research-dispatch`** — Use before dispatching any subagent whose
  findings will be input to downstream work. Prevents poisoning implementation
  decisions with incorrect research.
- **`ndimiduk:session-transcripts`** — Analyze, review, diff, or audit agent session
  transcripts. Extract messages, tool uses, subagent invocations, or cross-session
  patterns for skill extraction, post-mortems, or toil audits. Bundles an executable
  `session-tx` Python script alongside the SKILL.md; symlink it into `$PATH`
  (`~/.local/bin/session-tx`) once after plugin install — the permissions
  allowlist bare `session-tx`.
- **`ndimiduk:validate-idea`** — Structure vague product ideas into concrete ones at
  any stage of clarity. Triggers on "I've been thinking about building…",
  demand-validation questions, and "should I bother" decisions. Sits upstream of
  `write-a-prd` and `grill-me`.
- **`ndimiduk:writing-issue-descriptions`** — Draft bug reports, JIRA issues, GitHub
  issues, or issue descriptions for upstream projects.
- **`ndimiduk:writing-plans`** — Create phased, risk-ordered implementation plans
  with validation gates from a spec. **Overrides `superpowers:writing-plans`** — adds
  risk-first task ordering, phase structure, and prove-before-restructure discipline.
- **`ndimiduk:research-lint`** — Health check for markdown knowledge bases: tag
  distribution, orphan docs not in README, missing frontmatter. Bundles an executable
  `rklint` Python script alongside the SKILL.md; symlinked into `$PATH`
  (`~/.local/bin/rklint`) by `make install`.
- **`ndimiduk:toki`** — Opinionated workflow conventions for the `toki` task tracker:
  persistent-vs-ephemeral framing, status-via-tags, concept-tag bridge to a notes
  vault, when-to-close vs. when-to-wait. Distinct from the upstream toki tool's bare
  reference SKILL.md at `cmd/toki/skill/`; this is a personal-conventions layer on
  top of that.

## Skills assumed available

The fragment in `agents-md/AGENTS.md` and several of the skills above name a few
upstream skills that aren't shipped here but are easy to install separately. See
[`external/skills.md`](./external/skills.md) and
[`external/plugins.md`](./external/plugins.md) for pointers:

- `superpowers:*` (the superpowers plugin) — `brainstorming`, `executing-plans`,
  `subagent-driven-development`, etc.
- `grill-me`, `ubiquitous-language`, `defuddle` — standalone skills.
- `write-a-prd`, `prd-to-plan`, `prd-to-issues`, `improve-codebase-architecture` —
  standalone skills used in the planning workflow.
- `oss-project-setup` — for setting up OSS repo configurations.
