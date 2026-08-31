# Write lock contract (example)

This contract governs how cooperating AI sessions use `write-lock-state.md`. The lock is a cooperative collision control, not technical enforcement. It carries no approval, scope, ownership, or truth authority.

```markdown
# Write Lock Contract

The write lock is a cooperative control that reduces collision risk among
cooperating AI sessions. It is not a filesystem mutex, atomic compare-and-swap,
or hostile-writer boundary. Human Authority remains responsible for avoiding
simultaneous canonical write-heavy sessions when practical.

## When it applies

Acquire the lock before changing canonical project, opportunity, area,
decision, dashboard, governance, or other durable shared state. It also
applies to the canonical human-facing question queue and formal
reconciliation writeback.

The lock is not required for read-only work or writes confined to a
Provisional Contributor's owned outbox or exclusive working domain, unless
that session will also change canonical state.

## What it never changes

- Holding the lock grants no approval, authority, scope, truth status, or
  permission to write.
- Existing ownership boundaries remain in force.
- One participant may not edit another participant's owned files merely
  because it holds the lock.
- Current canonical state and direct evidence outrank working notes,
  handoffs, reports, and outboxes.

## Acquire

1. Read the lock state immediately before a consequential canonical write
   session.
2. If `status` is `locked` and `expires_at` is in the future, make no
   canonical change. Report the owner, task, targets, and expiry.
3. If the lock is malformed or expiry cannot be determined, fail closed and
   ask Human Authority to inspect it.
4. If the lock is unlocked or expired, replace its operational fields with:
   - `status: locked`;
   - the writing role or agent as `owner`;
   - a collision-resistant `session` token;
   - a one-line `task`;
   - `locked_at` in ISO 8601 with offset;
   - `expires_at` 60 minutes after acquisition; and
   - the exact intended target paths.
5. Reread the lock and proceed only if `status`, `owner`, and `session` still
   match. Recheck ownership immediately before every canonical file write.
   Add newly discovered exact targets to the lock before editing them.

An expired lock may be replaced, but the new owner reports that it recovered
an expired lock. Long sessions renew their own expiry before it passes.

## Freshness and writing

After acquiring the lock, reread each live target immediately before editing
it. If a target changed after the plan or evidence review was formed,
reconcile the difference and replan; do not overwrite from stale context.

For consequential replacements or multi-file reconciliation, compare a
last-read hash when the tool surface supports it. This is an additional
freshness check, not proof that the lock is technically exclusive.

Apply only changes authorized by Human Authority or an explicit governing
rule. Verify the intended result and report the exact changed-file ledger.

## Release and recovery

After verification, reread the lock. Only the matching `owner` and `session`
may release it. Restore `status: unlocked`, set scalar operational fields to
null, and restore an empty target list.

On failure or interruption, make a best-effort release if ownership still
matches and report any unreleased lock. Never unlock another active session.
Human Authority may manually clear an abandoned or malformed lock after
confirming that no writer remains active.

## Reassessment trigger

Keep the cooperative design unless two material collision or overwrite
failures occur despite correct lock use, or one failure causes serious
irreversible harm. Those events justify reassessing stronger technical
locking; architectural neatness alone does not.
```

## Concurrency and freshness are different

**Concurrency failure:** two writers collide. Single-writer ownership and the cooperative lock reduce this risk.

**Freshness failure:** a writer has a valid lock but is executing a plan formed from stale state. The required post-lock reread and reconciliation address this separate failure mode.

A valid cooperative lock therefore does not prove that the writer's plan is current, and a freshness check does not create technical mutual exclusion.
