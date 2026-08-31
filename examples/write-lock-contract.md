# Write lock contract (example)

Genericized from the working contract. This governs *how* the write-lock state file (`write-lock-state.md`) gets used — it is a cooperative collision and stale-context guard for AI sessions, not technical enforcement. The vault owner remains responsible for avoiding simultaneous canonical write-heavy sessions when practical.

```markdown
The write lock is a cooperative collision and stale-context guard for AI
sessions. It is not technical enforcement. The vault owner remains
responsible for avoiding simultaneous canonical write-heavy sessions when
practical.

## When it applies

Acquire the lock before changing canonical project, opportunity, area,
decision, dashboard, governance, or other durable shared state. It also
applies to the canonical human-facing question queue and formal
reconciliation writeback.

The lock is not required for read-only work or for writes confined to an
agent's existing provisional/exclusive domain, unless that session will also
change canonical state.

## What it never changes

- Holding the lock grants no approval, authority, scope, truth status, or
  permission to write.
  - Existing ownership boundaries remain in force. One agent may not edit
    another agent's owned files just because it holds the lock.
    - The lock itself cannot authorize canonical implementation.
    - Current canonical state and direct evidence outrank working notes,
      handoffs, reports, and outboxes.

      ## Acquire

      1. Read the lock state file immediately before a consequential canonical
         write session.
         2. If `status` is `locked` and `expires_at` is still in the future, do not
            overwrite it. Stop before canonical changes and report the owner, task,
               targets, and expiry.
               3. If the lock is malformed or expiry cannot be determined, fail closed and
                  ask the vault owner to inspect it.
                  4. If unlocked or expired, replace the operational fields with `status:
                     locked`, the writing agent's name as `owner`, a collision-resistant
                        `session` token, a one-line `task`, `locked_at` (ISO 8601 with offset),
                           `expires_at` (60 minutes after acquisition), and the exact intended
                              target paths.
                              5. Reread the lock and proceed only if `status`, `owner`, and `session`
                                 still match. Recheck ownership immediately before every canonical file
                                    write. Add newly discovered exact targets to the lock before editing
                                       them.

                                       An expired lock may be replaced, but the new owner must report that it
                                       recovered an expired lock. Long sessions must renew their own expiry before
                                       it passes.

                                       ## Freshness and writing

                                       After acquiring the lock, reread each live target immediately before editing
                                       it. If it changed since the plan or evidence review was formed, reconcile
                                       the difference and replan; do not overwrite from stale context. For
                                       consequential replacements or multi-file reconciliation, compare a last-read
                                       hash when the tool surface supports it.

                                       Apply only changes already authorized by the vault owner or an existing
                                       explicit governance rule. Verify the intended result and report the exact
                                       changed-file ledger.

                                       ## Release and recovery

                                       After verification, reread the lock. Only the matching `owner` and
                                       `session` may release it. Restore `status: unlocked`, set scalar
                                       operational fields to null, and restore an empty target list.

                                       On failure or interruption, make a best-effort release if ownership still
                                       matches and report any unreleased lock. Never unlock another active
                                       session. The vault owner may manually clear an abandoned or malformed lock
                                       after confirming no writer is still active.

                                       ## Reassessment trigger

                                       This cooperative design is the default. Reconsider technical enforcement
                                       only after two material collision or overwrite failures occur despite
                                       correct lock use, or one failure causes serious irreversible harm.
                                       ```

                                       ## The distinction worth keeping

                                       A lock stops two sessions from writing to the same file *at the same time*. It does nothing about a session that formed its plan five minutes ago, before the file changed underneath it, and is now about to commit stale reasoning under a perfectly valid lock. That's why "freshness and writing" is its own numbered section rather than folded into "acquire" — concurrency and staleness are different failure modes with different fixes, and conflating them is an easy design mistake to make.
