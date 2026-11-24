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

## claude-tmux-restore

Rebuilds tmux sessions and windows after a restart or crash and resumes the Claude
Code session that was running in each window, in its directory and on its model.

`snapshot` joins `tmux list-panes -a` with `claude agents --json`, matching each
interactive Claude process to its pane by walking up the process tree, and writes
`~/.local/state/cc-loadout/tmux-restore/snapshot.json` (`$XDG_STATE_HOME` and
`$CC_RESTORE_DIR` override the location). Windows without Claude are recorded too
and come back as a shell in their directory. A snapshot is written only when
something changed; the previous 20 layouts are kept in `history/` (a `cd` that
only renames an auto-named window updates the snapshot without using a history
slot). A window shared by several sessions is recorded once: under the session
that names its group (or the group's oldest session), and a `link-window` window
under one of the sessions it is linked into.

Snapshots are taken on events rather than on a timer: tmux hooks for session and
window creation, renames, moves and closes, and a Claude SessionStart hook for
`/resume`, `/clear` and new sessions. A window keeps its last Claude session after
Claude exits, so quitting Claude before closing windows during a shutdown doesn't
lose it (and a window where you quit Claude on purpose resumes it on restore). A
window you close drops out of the next snapshot; if a teardown closed windows you
wanted back, `list` and `restore --from` recover an earlier one. Errors are logged
to `snapshot.log` in the same directory and never shown in a pane.

```
claude-tmux-restore restore --dry-run   # print the tmux commands
claude-tmux-restore restore             # rebuild and resume
claude-tmux-restore list                # current snapshot and history
claude-tmux-restore restore --from ~/.local/state/cc-loadout/tmux-restore/history/snapshot-….json
```

`restore` types `claude --resume <id> --model <model>` into each new window's
shell, so a shell alias or wrapper for `claude` applies. Windows keep their
recorded index (falling back to the next free one in a session that already has
it) and each new session's active window is reselected. It skips Claude sessions
that are already running and plain-shell windows already open with the same name
and directory, adds windows to tmux sessions that already exist, and suppresses
snapshots for two minutes so the half-built layout doesn't replace the one being
restored. A second `restore` within those two minutes refuses unless `--force`,
since the sessions the first one typed may not be listed as running yet.
Background sessions (`claude --bg`) are not covered.

### Install

Add a SessionStart hook group to `~/.claude/settings.json`, using the
`claude-tmux-state` hooks above:

```json
"SessionStart": [{ "matcher": "startup|resume|clear|compact", "hooks": [{ "type": "command", "timeout": 5, "command": "/path/to/cc-loadout/tools/claude-tmux-state start" }] }]
```

Then in `~/.tmux.conf`:

```tmux
set-hook -g 'session-created[10]' "run -b '/path/to/cc-loadout/tools/claude-tmux-restore snapshot'"
set-hook -g 'session-closed[10]'  "run -b '/path/to/cc-loadout/tools/claude-tmux-restore snapshot'"
set-hook -g 'session-renamed[10]' "run -b '/path/to/cc-loadout/tools/claude-tmux-restore snapshot'"
set-hook -g 'window-linked[10]'   "run -b '/path/to/cc-loadout/tools/claude-tmux-restore snapshot'"
set-hook -g 'window-renamed[10]'  "run -b '/path/to/cc-loadout/tools/claude-tmux-restore snapshot'"
set-hook -g 'window-closed[10]'   "run -b '/path/to/cc-loadout/tools/claude-tmux-restore snapshot'"
```

The `[10]` index keeps these from replacing other hooks on the same events.

## Requirements

- Python 3.10+ (claude-tmux-state: POSIX `sh` and tmux; claude-tmux-restore also runs on 3.9)
- claude-tmux-restore: tmux 3.x and a Claude Code with `claude agents --json`
- No third-party dependencies
