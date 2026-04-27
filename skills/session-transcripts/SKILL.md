---
name: session-transcripts
description: Use when analyzing, reviewing, diffing, or auditing Claude Code session transcripts — extracting messages, tool uses, subagent invocations, or cross-session patterns for skill extraction, post-mortems, or toil audits. Triggers on "review this session", "diff these transcripts", "what went wrong in session X", "find sessions where…", "look through recent sessions", or when the user references a session UUID.
---

# session-transcripts

Query Claude Code session JSONL transcripts with `session-tx`, a bundled Python CLI. Prefer this over ad-hoc `python3 -c` / `jq` scripts so permissions can be allowlisted once.

## Tool location

`session-tx` (must be on `$PATH` — see CLAUDE.md install section).

The script is bundled with the skill at `skills/session-transcripts/session-tx`
in the source repo and copied to the plugin cache on install. To get it on
`$PATH`, symlink the source path into a `$PATH` directory:

```sh
ln -s ~/src/github/cc-loadout/skills/session-transcripts/session-tx \
      ~/.local/bin/session-tx
```

Stdlib only. Bare `session-tx` is the canonical invocation; absolute paths
and `SX=…` env shims are no longer required.

## Session path resolution

Every subcommand that takes a `<path>` accepts:
- An absolute or relative path to a `.jsonl` file.
- A bare session UUID or prefix (e.g., `2ecd14e0`). Resolves by searching `~/.claude/projects/**`.

## Subcommands

```
session-tx list [--dir PATH] [--project ENCODED] [--limit N]
    Recent sessions in a project. Default: cwd-encoded project.
    Columns: filename, size, mtime, first user prompt.

session-tx title <path>
    First user prompt of a session.

session-tx summary <path>
    Counts: top-level types, roles, block types, tool frequency, timestamps.

session-tx messages <path> [--role user|assistant] [--sidechain]
                           [--start N] [--end N] [--max-chars N] [--full]
    Text messages. Sidechain excluded by default.

session-tx thinking <path> [--start N] [--end N] [--full]
    Thinking blocks.

session-tx tools <path> [--name TOOL] [--grep REGEX] [--with-results]
                        [--start N] [--end N] [--full]
    Tool uses. --with-results pairs each call with its result.

session-tx bash <path> [--grep REGEX] [--with-results] [--start N] [--end N] [--full]
    Bash invocations with description + command.

session-tx agents <path> [--with-results] [--start N] [--end N] [--full]
    Agent (subagent) tool calls with prompts.

session-tx subagents <path>
    List subagent JSONL files for a main session.

session-tx range <path> <start> <end>
    One line per entry in [start, end]. Useful for navigating to a pain point.

session-tx grep <path> <regex> [-i] [--thinking]
    Regex search across text, tool_use inputs, tool_result contents.
    Omits thinking by default.

session-tx find <keyword> [--days N] [--limit N]
    Cross-project search of session titles. --days defaults to 30.
```

Line numbers are 1-based and correspond to `wc -l` line counts.

## Recipes

**Skim a session before deep-diving.**
```
session-tx summary 2ecd14e0
session-tx title   2ecd14e0
```

**Find the first user message across recent sessions in this project.**
```
session-tx list --limit 10
```

**Extract all subagent dispatches from a session.**
```
session-tx agents 2ecd14e0 --with-results --max-chars 500
```

**Review what the agent actually did (just user + assistant text, no tools).**
```
session-tx messages 2ecd14e0
```

**Find the pain-point window then zoom in.**
```
session-tx grep 2ecd14e0 'permission denied|operation not permitted' -i
session-tx range 2ecd14e0 1380 1600
```

**List bash commands against a specific subsystem.**
```
session-tx bash 2ecd14e0 --grep 'kubectl|docker' --with-results
```

**Find all sessions that touched a topic.**
```
session-tx find 'heap dump'
session-tx find blazar --days 90
```

**Audit repeated Python-scripting toil (the motivating use case for this skill).**
```
session-tx bash <path> --grep 'python3|jq|jsonl'
```

## Format notes

Session JSONL layout (as of Claude Code current):
- One JSON object per line; top-level `type` can be `user`, `assistant`, `attachment`, `system`, `permission-mode`, `last-prompt`, `queue-operation`, `file-history-snapshot`, `summary`.
- For `user`/`assistant`: `message.role`, `message.content` (string, list of blocks, or null).
- Content blocks: `text`, `thinking`, `tool_use` (`name`, `input`, `id`), `tool_result` (`tool_use_id`, `content` — itself string or list-of-blocks).
- `isSidechain: true` marks subagent messages that also appear in the parent log.
- Subagent transcripts: `~/.claude/projects/<proj>/<session-uuid>/subagents/agent-*.jsonl`.

If the format drifts, update `session-tx`. All parsing lives in that one file.

## Permissions

Allowlist:
- `Bash(session-tx:*)`
