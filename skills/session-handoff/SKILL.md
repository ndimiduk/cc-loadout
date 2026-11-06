---
name: ndimiduk-session-handoff
description: Use when the session is running out of context or the user wants to hand the work to a later session — "make ready for compaction", "we're out of context", "write a handoff note", "checkpoint this session", "give me the compaction argument", "give me a prompt for resuming", "starting prompt for a new session".
---

# Session Handoff

Leave the next session, whether it starts after `/compact` or fresh, able to
continue without this conversation. Durable state goes where it belongs; the
user gets two short texts to paste.

1. **Settle the work in flight.** Commit what's ready. Push it if this session
   already pushes that branch (as under `ndimiduk:ship-task`); otherwise note it
   as unpushed. Note what is uncommitted and where. If ship-task is running,
   write its checkpoint and name its path in both texts.
2. **Route what you'd carry forward:**
   - Task state, next steps, and follow-ups go where the work is already
     tracked: its GitHub issue or project doc for shared work, its toki task
     for private work. If nothing tracks it, they go in the session log's open
     section; file a new tracker entry only if the user asks.
   - Improvements to a skill, including corrections to how it behaves, go to
     the open toki task collecting that skill's improvements; file one if none
     is open.
   - Judgment calls, user decisions, other corrections, conventions, and
     domain facts go to the session log.
3. **Write the session log** if step 2 left anything for it, in the notes
   vault's `collaboration/` directory, following the vault's own rules for
   session logs. If this session started from a log or already wrote one, add
   a dated section to it; otherwise create `<YYYY-MM-DD>-<topic>.md` linking
   the log it succeeds. Record lessons and decisions, not an action list.
   Apply `ndimiduk:document-discipline`. Then commit only the log
   (`git add <log>; git commit <log>`), `git pull --rebase --autostash`, and
   push in the vault repo; invoking this skill authorizes that.
4. **Give the user two texts**, each in its own code block:
   - `/compact <argument>`: what the compacted context must keep — PR and
     issue URLs, worktree paths and branches, the current step, files not to
     commit, the log's path, and the skills to re-invoke.
   - A resume prompt for a fresh session: read the log (name the section)
     and the work's tracker entry; re-invoke the skills the work needs, because
     compaction truncates loaded skill text; check the branch, PR, and CI
     state; continue from the named step.

   Both point at the durable notes rather than repeating them.
