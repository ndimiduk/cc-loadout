---
name: research-lint
description: Use when checking health of a markdown knowledge base — orphan docs, missing frontmatter, tag drift, or when the user says "lint", "health check", or "what needs attention" in a research/wiki repo
---

# Research Lint

Health check for markdown knowledge bases that follow the convention: YAML frontmatter
(`title`, `<date-field>`, `tags`), a `README.md` document map, and a `docs/` directory.
The tool recurses into subdirectories under `docs/`.

## Workflow

1. **Run `rklint all`** against the repo root. If the docs directory is not `docs/`,
   pass `--docs <prefix>`. If the date field is not `updated` (e.g., `date` in a
   zettelkasten), pass `--date-field <name>`.
2. **Review tag list** for near-synonyms, consolidation candidates, and coverage gaps.
   This is a judgment call — the script gives you the distribution, you spot the drift.
   Heuristics: look for tags that share a stem (`cert-auth` / `certificate-auth`), tags
   that always co-occur (candidates for merging), singleton tags (typo or legitimate
   niche?), and prominent themes in the README that lack a corresponding tag.
3. **Compile the report** using the format below.
4. **List candidate actions.** Do not rank or prioritize. The user decides.

## Report Format

```
## Repo Health — <date>

### Tag Distribution (top 15)
<tag: count>

### Tag Observations
<near-synonyms, consolidation candidates, coverage gaps — your judgment>

### Orphan Docs (<count>)
<docs not referenced from README.md — archived docs are filtered out by the tool>

### Frontmatter Issues (<count>)
<docs missing required fields>

### Candidate Actions (unranked)
- <action>
```

## Rules

- **Read-only.** This skill reports. It does not modify files.
- **No scoring.** Facts and observations. The user decides priority.
- **Archived docs** (those with a `> **Archived` banner) are excluded from the orphan
  check — they are intentionally absent from README. The tool reports a count of how
  many were skipped.

## CLI Reference

```
rklint [--root <path>] [--docs <prefix>] [--date-field <name>] <command>

Commands:
  tags          Tag distribution from YAML frontmatter
  orphans       Docs not referenced from README.md (excludes archived)
  frontmatter   Docs missing required fields (title, <date-field>, tags)
  all           Run all checks

Defaults: --root = git toplevel, --docs = docs, --date-field = updated
```

Only git-tracked files are checked. Untracked files are excluded from all commands.

`rklint` must be on `$PATH`. Symlink after install:

```sh
ln -s ~/src/github/cc-loadout/skills/research-lint/rklint ~/.local/bin/rklint
```
