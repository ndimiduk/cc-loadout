# external/tools.md

Tools the loadout assumes are on `PATH`. None are bundled. Install whichever you don't
already have before expecting the full workflow to function.

## git

Assumed available. Worktree discipline, scratch-dir conventions, and several skills lean
on it. Any modern version (2.x) is fine.

Install: ships with most OSes; `brew install git` on macOS for a current version.

## gh

GitHub CLI. The planning skills (`write-a-prd`, `prd-to-issues`) shell out to it for
issue creation, and the loadout's AGENTS.md fragment standardizes on `gh api` for any
GitHub interaction.

Install: `brew install gh` (macOS), or see https://github.com/cli/cli for other
platforms. Authenticate with `gh auth login`.

## toki

Git-aware CLI todo manager with an MCP server for AI-agent integration. Powers the
"Session and Task Management" section of the AGENTS.md fragment — task lifecycle,
project tagging, cross-session continuity.

Source and install: https://github.com/harperreed/toki

The companion `ndimiduk:toki` skill lives at the upstream toki repo (see
`external/skills.md`).

## jq

JSON processor. Used by the `settings/` README's install snippet to merge the loadout's
`settings.fragment.json` into a personal `~/.claude/settings.json` without clobbering
upstream-managed keys:

```sh
jq -s '.[0] * .[1]' ~/.claude/settings.json ./settings.fragment.json > /tmp/merged.json
```

Install: `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu), or
https://jqlang.github.io/jq/.

## defuddle

CLI for extracting clean markdown from web pages. Backs the `defuddle` skill referenced
in `external/skills.md`; useful on its own for one-off web-content reduction in
scratch sessions.

Install: `npm install -g defuddle-cli` or run on demand with `npx defuddle-cli`.
Source: https://github.com/kepano/defuddle

## obsidian-cli (optional)

Useful only if you keep an Obsidian vault and want the loadout's session-log and
zettelkasten cross-references to be navigable from the command line. The AGENTS.md
fragment's "Session Logs" and "Tagging Convention" sections assume some such target
exists; without a vault, those sections degrade gracefully and `obsidian-cli` is
unnecessary.

Source: https://github.com/Yakitrak/obsidian-cli (verify against your Obsidian version
before installing — there are several similarly-named projects).
