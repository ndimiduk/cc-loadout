# tools/

Standalone scripts for coding-agent and tmux integration. Not skills — these are
invoked by settings.json, shell config, or agent harness integration, not as agent
capabilities.

## agent-usage-spark

Unified usage sparkline for supported coding agents. It currently aggregates Claude
Code sessions from `~/.claude/projects/` and Pi sessions from `~/.pi/agent/sessions/`.
Both stores are scanned recursively. Assistant records are de-duplicated within each
agent by record ID, so resumed sessions do not recount copied history. When a provider
writes multiple usage snapshots for one record, the snapshot with the largest recorded
usage is retained.
Pi's recorded usage includes provider-reported cost data; Claude uses cached
LiteLLM pricing data. Neither is a statement of the final invoice: provider billing,
credits, routing, and pricing revisions can differ. The output is deliberately labeled
as an estimate.

The default is a cost estimate, marked with `~` and `est`. Sessions whose model
cannot be priced are excluded from the estimate and shown as `+?` rather than being
silently counted as zero. Parsed records are cached per file using its modified time
and size, so unchanged transcripts are not reparsed. Cache rebuilds use a Unix
advisory lock; concurrent invocations reuse the previous cache instead of scanning
in parallel. The lock is released automatically if the rebuilding process exits.

```
agent-usage-spark                  # estimated cost
agent-usage-spark --tokens          # input + output token total
agent-usage-spark --days 30         # 12 buckets covering the same 30-day window
```

Install in tmux:

```tmux
set -g status-right '#(/path/to/cc-loadout/tools/agent-usage-spark) | %H:%M '
set -g status-right-length 60
set -g status-interval 300
```

## claude-statusline

Status line for the Claude Code input bar. Shows model name, a context-window
progress bar, token count, and session cost.

```
Opus 4.6 (1M context)  █░░░░░░░░░░░░░░░░░░░ 5% (52k)  $1.12
```

### Install

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 /path/to/cc-loadout/tools/claude-statusline"
  }
}
```

## claude-ratelimit-tmux

Rate-limit reset indicator for tmux `status-right`. Reads the cache written by
`claude-statusline` and shows how long until each rate-limit bucket resets.

```
5h 73%→1.4h  7d 40%→2.3d
```

Usage % is shown only if `claude-statusline` has run within the last 30 minutes
(i.e., an active Claude Code session). The reset time is always accurate because
it's an absolute timestamp.

### Install

First install `claude-statusline` (it writes the cache this script reads). Then
add to `~/.tmux.conf`:

```tmux
set -g status-right '#(/path/to/cc-loadout/tools/claude-ratelimit-tmux) | %H:%M '
set -g status-right-length 60
set -g status-interval 60
```

## Requirements

- Python 3.10+
- No third-party dependencies
