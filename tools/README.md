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

## claude-tmux-state

Per-window Claude Code state for the tmux window list. Claude Code hooks record
the state as the `@cc` window option; the window formats render it as one
character in place of the `:` between index and name, so it costs no width.

| Glyph | State |
|-------|-------|
| `?` | blocked on you (permission prompt) |
| `●` | turn finished, not yet seen |
| `○` | working |
| `:` | idle, or seen |

Visiting a window clears `?` and `●`. A turn that finishes in the window you are
looking at leaves no mark. Plain `sh` rather than Python because it runs on every
tool call (~28ms, almost all tmux round-trip).

The working-state argument is `busy`, not `run`: some hook managers that also
write settings.json take the word after a `run` token as one of their own hook
names when deciding which entries they own.

### Install

Add hook groups to `~/.claude/settings.json`, alongside any existing ones:

```json
"hooks": {
  "Notification":     [{ "hooks": [{ "type": "command", "timeout": 5, "command": "/path/to/cc-loadout/tools/claude-tmux-state notify" }] }],
  "PostToolUse":      [{ "matcher": "*", "hooks": [{ "type": "command", "timeout": 5, "command": "/path/to/cc-loadout/tools/claude-tmux-state busy" }] }],
  "SessionEnd":       [{ "hooks": [{ "type": "command", "timeout": 5, "command": "/path/to/cc-loadout/tools/claude-tmux-state clear" }] }],
  "Stop":             [{ "hooks": [{ "type": "command", "timeout": 5, "command": "/path/to/cc-loadout/tools/claude-tmux-state done" }] }],
  "UserPromptSubmit": [{ "hooks": [{ "type": "command", "timeout": 5, "command": "/path/to/cc-loadout/tools/claude-tmux-state busy" }] }]
}
```

Then in `~/.tmux.conf`:

```tmux
setw -g window-status-format '#I#{?#{==:#{@cc},wait},#[fg=red bold]?#[default],#{?#{==:#{@cc},done},#[fg=yellow bold]●#[default],#{?#{==:#{@cc},run},#[fg=colour244]○#[default],:}}}#W#{?window_flags,#{window_flags}, }'
setw -g window-status-current-format '#I#{?#{==:#{@cc},wait},?,#{?#{==:#{@cc},done},●,#{?#{==:#{@cc},run},○,:}}}#W#{?window_flags,#{window_flags}, }'
set-hook -g session-window-changed 'if -F "#{||:#{==:#{@cc},wait},#{==:#{@cc},done}}" "set -wu @cc"'
```

## Requirements

- Python 3.10+ (claude-tmux-state: POSIX `sh` and tmux)
- No third-party dependencies
