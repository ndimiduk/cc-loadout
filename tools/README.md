# tools/

Standalone scripts for Claude Code and tmux integration. Not skills — these are
invoked by settings.json or shell config, not by Claude as agent capabilities.

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

## claude-usage-spark

Unicode sparkline of Claude CLI usage for tmux `status-right`. Parses
`~/.claude/projects/*.jsonl` session files and caches the results.

```
▁▂▃▅▇▃▂ 4.8M tok
▁▂▃▅▇▃▂ $1.4k
```

Two modes:

- **Token count** (default) — total input+output tokens, no network calls
- **Cost estimate** (`--cost`) — estimated USD via LiteLLM pricing data (cached daily)

### Install

Add to `~/.tmux.conf`:

```tmux
set -g status-right '#(/path/to/cc-loadout/tools/claude-usage-spark) | %H:%M '
# or with cost:
set -g status-right '#(/path/to/cc-loadout/tools/claude-usage-spark --cost) | %H:%M '
set -g status-right-length 60
set -g status-interval 300
```

## Requirements

- Python 3.10+
- No third-party dependencies
