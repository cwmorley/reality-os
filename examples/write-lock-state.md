# Write lock state file (example)

This operational coordination file carries state only. Cooperating writers are required by `write-lock-contract.md` to read it immediately before a consequential canonical write, honor an active claim, reread targets for freshness, and release their own claim after verification.

## Unlocked: default state

```markdown
---
status: unlocked
owner: null
session: null
task: null
locked_at: null
expires_at: null
targets: []
---

# Write Lock

Operational coordination state for consequential canonical writes. Follow
the Write Lock Contract. Holding this lock grants no approval, authority,
scope, ownership, or guarantee of technical exclusivity.
```

## Locked: a cooperating writer has claimed it

```markdown
---
status: locked
owner: Canonical Writer A
session: writer-a-a19f3e2c
task: Reconcile Q-2026-08-30-01 into the canonical decision note
locked_at: 2026-08-30T09:12:00-06:00
expires_at: 2026-08-30T10:12:00-06:00
targets:
  - Decisions/2026-08-30 - Example Decision.md
---

# Write Lock

Operational coordination state for consequential canonical writes. Follow
the Write Lock Contract. Holding this lock grants no approval, authority,
scope, ownership, or guarantee of technical exclusivity.
```

The 60-minute default expiry provides a recovery convention for an abandoned claim; it does not itself clear the file or stop a process from writing. The contract permits Human Authority to clear a lock only after confirming that no writer remains active.
