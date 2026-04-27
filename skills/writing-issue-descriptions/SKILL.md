---
name: writing-issue-descriptions
description: MANDATORY when producing any text destined for an issue tracker — JIRA descriptions, GitHub issue bodies, bug reports, feature requests, follow-up tickets. Triggers on "draft/write/open an issue", "file a ticket/bug/follow-up", "write the JIRA", "put together a JIRA", "ticket description", "body text for the issue", "write up something for JIRA", or any request whose output will be pasted into an issue tracker.
---

# Writing Issue Descriptions

The audience is developers who maintain the code. They can find the root cause and figure out the fix themselves.

Always produce a **title** (short, scannable, searchable — under 70 chars) and a **body**.

## Formatting by Target Tracker

Match the markup to the target tracker:

- **GitHub Issues**: Markdown — `` `code` ``, `[text](url)`, `**bold**`
- **JIRA** (Server/Data Center, including ASF JIRA): Wiki renderer notation:
  - Inline code: `{{code}}`
  - Code block: `{code}...{code}` or `{noformat}...{noformat}`
  - Link: `[title|https://example.com]` or bare `https://example.com`
  - Bold: `*bold*`
  - Italic: `_italic_`
  - Bullet list: `* item` (with leading `*`)
  - Numbered list: `# item` (with leading `#`)

Infer the target from context: "file a JIRA", mention of an Apache project, or a `issues.apache.org` URL → JIRA wiki notation. "GitHub issue" or `gh` CLI → markdown. When ambiguous, ask.

## Rules

- **DO**: State the situation and why it matters. Ground the motivation in something concrete and known — not speculative examples. Link to the triggering issue/PR/build when one exists.
- **DON'T**: Quote source code they already own, provide reproduction steps for obvious bugs, suggest fixes, or explain alternative approaches. If they need that, they'll ask.
- Target 2-5 sentences total. If your draft is longer, cut it.

## Red Flags

If your draft contains any of these, delete them:

- "Changes:" or "Fix:" sections
- File paths or line numbers from their own repo
- "The fix is to..." or "This can be resolved by..."
- Implementation details or code snippets
- Bullet lists of what to change
- Root cause analysis beyond identifying the symptom
- Speculative use cases or examples you invented to justify the change

## Examples

Bad (too much):

> The GCR workflow fails because checkmake is compiled from source in Dockerfile line 211-215 and hits a Go runtime fault on arm64. The project moved from mrtazz/checkmake to checkmake/checkmake and now publishes pre-built binaries for v0.3.2. Changes: update Dockerfile to download binaries, update COPY path, update docs link.

Good (just right):

> The `Github Container Registry` workflow fails on arm64 because `checkmake` is compiled from source during the Docker build and crashes with a Go runtime fault. This has blocked multi-arch image pushes since Feb 21. Same class of problem that YETUS-1267 fixed for `revive`.

Bad (over-specified):

> YETUS-983 hardcoded `dryrun_both_files` to prefer cumulative `.diff` over per-commit `.patch`. This fixed the stale-file bug but removed user choice. Some workflows may need the old `.patch`-first behavior — for example, projects that rely on per-commit application semantics. Add a flag to let users choose which format is tried first, with the other as fallback. Expose it in `action.yml` for GitHub Actions workflows.

Good (just right):

> YETUS-983 hardcoded dryrun_both_files to prefer cumulative .diff over per-commit .patch. This fixed the stale-file bug but hard-coded the new preference. Since this may not work for everyone (binary handling seems to be an issue), let's make the behavior configurable.
