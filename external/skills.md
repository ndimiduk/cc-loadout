# external/skills.md

Pointers to standalone skills this loadout references but does not redistribute. Install
each from its canonical source; the loadout's `agents-md/AGENTS.md` fragment names them
as if they exist.

## grill-me

Interview-style skill that stress-tests a plan or design by walking the decision tree
one branch at a time, asking one question per turn, and recording answers to a session
file. Sits downstream of `ndimiduk:validate-idea` — once an idea is concrete enough to
have decisions, `grill-me` surfaces the ones you've been avoiding.

Multiple forks exist; the canonical one this loadout's wording matches is in Matt
Pocock's skills directory: https://github.com/mattpocock/skills/tree/main/grill-me

## ubiquitous-language

DDD-style glossary skill. Scans the current conversation for domain-relevant terms,
flags ambiguity and synonym drift, and writes a `UBIQUITOUS_LANGUAGE.md` for the
project. Use when overloaded terms are causing miscommunication across roles or when
seeding terminology for a new domain.

Source: https://github.com/mattpocock/skills/tree/main/ubiquitous-language

## defuddle

Markdown extraction from web pages. Strips navigation and chrome, returns the article
body as clean markdown — far cheaper in tokens than feeding raw HTML to a model. The
underlying CLI lives at https://github.com/kepano/defuddle (see also
`external/tools.md`); skill wrappers exist that wire the CLI into Claude Code.

A widely-used skill wrapper: https://github.com/joeseesun/defuddle-skill — see its README
for install. If you just want the CLI without a skill wrapper, see `external/tools.md`.

## Planning skills (Matt Pocock's collection)

The planning workflow referenced in `agents-md/AGENTS.md` uses four skills from the same
upstream collection. Install from https://github.com/mattpocock/skills.

- **`write-a-prd`** — Interview the user, explore the codebase, design modules, and
  submit a PRD as a GitHub issue. Use when scoping a new feature or framing a
  build-vs-buy decision.
- **`prd-to-plan`** — Convert a PRD into a multi-phase implementation plan structured as
  tracer-bullet vertical slices. Output saved to `./plans/`. Pairs with
  `ndimiduk:writing-plans` (use the override for the actual phase ordering).
- **`prd-to-issues`** — Break a PRD into independently-grabbable GitHub issues, each
  classified as needing human interaction or runnable autonomously.
- **`improve-codebase-architecture`** — Friction-based exploration to find shallow
  modules worth deepening. Produces a refactor RFC.

Each lives in its own directory under that repo; install per the repo README.

## ndimiduk:toki (note)

The skill itself ships in this repo at `skills/toki/` (public name `ndimiduk:toki`) — it's an opinionated
workflow layer (persistent-vs-ephemeral framing, status-via-tags, concept-tag bridge to
a notes vault, when-to-close vs. when-to-wait). Listed here only to point out the
distinction from the upstream toki tool's own SKILL.md.

The upstream toki tool ships its own bare reference SKILL.md at
`cmd/toki/skill/SKILL.md` in https://github.com/harperreed/toki. That one documents the
MCP tools and CLI commands; this loadout's `ndimiduk:toki` adds personal conventions on
top of that. The two are intentionally different in purpose — install whichever fits
your needs (or both).
