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

## pr-watch

Delivers pull request events (reviews, comments, CI results, conflicts, merges)
to the Claude Code sessions that subscribed to the PR, waking an idle session
without an LLM polling. A session subscribes with `pr-watch add <pr-url>`; an
event source records what it observes with `pr-watch ingest`; each session with
new wake-worthy events gets a one-line doorbell message on its messaging socket
(`$CLAUDE_CODE_MESSAGING_SOCKET`) telling it to run `pr-watch inbox`. The message
carries no event data, so a lost or repeated doorbell is harmless.

The inbox is one SQLite database,
`~/.local/state/cc-loadout/pr-watch/inbox.db` (`$XDG_STATE_HOME` and
`$PR_WATCH_DB` override it), in WAL mode with every write in a transaction, so
the source, hooks and CLI can write concurrently. Many sessions can watch one PR,
and one session many PRs.

Events are edge-detected and level-delivered:

- An event is recorded once per natural key (`key`, unique within its PR), so a
  source can report the same review or check result on every poll.
- Events in the first `ingest` run that reports a PR, or recorded before a
  session subscribed, are history and are never delivered.
- `inbox` shows only events that are still current. An event about a head the PR
  has moved past is superseded. A `slot` names one thing whose successive results
  replace each other, such as one check (`ci:build`) or one reviewer's verdict
  (`review:<login>`); an event is superseded by a newer one in its slot on the
  current head. A CI failure on an old head reported after a success on the new
  head does not wake anyone.
- Reading a merge or close unsubscribes the session from that PR.

Only `changes_requested`, `review_comment` (an inline comment on the diff),
`issue_comment`, `ci_failure` and `conflict` ring the doorbell; other kinds wait
in the inbox. `issue_comment` is any top-level comment on the PR: a
conversation comment, or the non-empty body of a review left as a plain comment.
Some CI automation reports this way instead of through checks. Keep a review
body out of its reviewer's verdict slot, so a comment doesn't replace an
earlier change request. When a session exits, the next ring
finds its socket gone and unregisters it, keeping its subscriptions; when it is
resumed, `register` records the new socket and the next ingest rings it for
anything it missed.

```
pr-watch add https://github.com/o/r/pull/1   # this session ($CLAUDE_CODE_SESSION_ID)
pr-watch list [--all]
pr-watch inbox [--peek]
pr-watch rm https://github.com/o/r/pull/1
```

`ingest` reads one JSON object per line on stdin (the example below is wrapped
for reading): a PR's current head and the events observed on it. A line that isn't valid UTF-8 JSON of this shape is
skipped and reported.
PR URLs are compared in one canonical form (lower case, no trailing path), in
`add` and `rm` as well as `ingest`.

```json
{"pr": "https://github.com/o/r/pull/1", "head": "abc123",
 "events": [{"kind": "ci_failure", "key": "ci:abc123:build:8812:2026-11-26T10:58:00Z", "slot": "ci:build", "head": "abc123",
             "data": {"check": "build"}}]}
```

A `key` already recorded is ignored, so it must change whenever the reported
result does. A check run's id alone is not enough: a run reports several states
over its life, and a re-requested run can be updated in place. The example keys
on the run's id and its completion time. Among a slot's events on the current
head, the one recorded last wins, and within one line that is the later entry
in `events`, so list a slot's results oldest first. `slot` and `head` are optional; an empty string for either
is rejected.

No real event source is wired up yet; events come only from `ingest`.

### Install

Add a SessionStart hook group to `~/.claude/settings.json`:

```json
"SessionStart": [{ "matcher": "startup|resume|clear|compact", "hooks": [{ "type": "command", "timeout": 5, "command": "/path/to/cc-loadout/tools/pr-watch register" }] }]
```

Delivery has been tested in auto-mode sessions, where the doorbell starts a turn
in an idle session and the session runs `pr-watch inbox` on its own.

## Requirements

- Python 3.10+ (claude-tmux-state: POSIX `sh` and tmux; claude-tmux-restore and pr-watch also run on 3.9)
- claude-tmux-restore: tmux 3.x and a Claude Code with `claude agents --json`
- No third-party dependencies
