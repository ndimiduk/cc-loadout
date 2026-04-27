# settings/

A user-authored fragment of `~/.claude/settings.json`. Permissions only — no personal-preference
keys, no upstream-managed entries.

## What this fragment is

A `permissions.allow` and `permissions.deny` set you can merge into your own
`~/.claude/settings.json` as a starting point — common bash commands, file inspection
tools, web fetches to public docs sites, and skill/edit/read/write paths that come up in
normal exploration work.

## What this fragment is NOT

- **Not personal preferences.** Theme, model, effort level, thinking-mode, etc. don't ship.
  Those belong in `/config`, not in someone else's settings.
- **Not employer-managed entries.** I work at a company that runs an automated tool which
  injects company-specific permission allowlists into `~/.claude/settings.json` on my
  machine. Those entries are excluded by deriving the authoritative list from the tool's
  source (a published rules artifact + a hooks-injection dryrun) and subtracting them.
  See `.scratch/build-fragment.py` for the script if you want to see the mechanism.
- **Not employer-internal tools.** Any entry referencing tools tied to a single employer's
  infrastructure (kubectl wrappers, internal RPC CLIs, internal log-fetch tools) is filtered
  out before publish.

## Install (merge by hand)

The fragment is a partial `settings.json`. Merge it into yours:

```sh
jq -s '.[0] * .[1]' ~/.claude/settings.json ./settings.fragment.json > /tmp/merged.json
# Review /tmp/merged.json carefully, then:
mv /tmp/merged.json ~/.claude/settings.json
```

`jq -s '.[0] * .[1]'` does a shallow deep-merge — top-level keys union, but list values
on conflicting keys are NOT concatenated. If you have your own `permissions.allow` already,
you'll need to merge those lists by hand or with a small script.

## Customizing

- The `WebFetch(domain:...)` entries reflect sites I commonly read documentation on (Apache
  projects, GitHub docs). Trim or add to taste.
- The `Bash(...)` entries are biased toward shell-style data exploration (text processing,
  archive extraction, checksumming). If you don't do much of that, the list won't shrink
  meaningfully — just remove individual entries you don't want.
- The `deny` entries protect SSH private keys from being read. Keep these.

## Pairing with employer-managed setups

If you also work at a company with an automated tool that maintains its own permissions in
your settings.json, do this in order: install whatever your company tool wants first, then
merge this fragment on top. The merge is additive at the list level — neither side
overwrites the other unless they collide on the same scalar key.
