# Write lock state file (example)

The operational coordination file every agent reads immediately before a consequential canonical write. It carries no logic itself — it's just state — but agents are contractually required to check it, honor it, and clear it correctly. See `write-lock-contract.md` for the rules governing how this file is used.

**Unlocked (default state):**

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
scope, or ownership.
```

**Locked (an agent has claimed it):**

```markdown
---
status: locked
owner: Codex
session: codex-a19f3e2c
task: Reconcile Q-2026-08-30-01 into the canonical decision note
locked_at: 2026-08-30T09:12:00-06:00
expires_at: 2026-08-30T10:12:00-06:00
targets:
  - Decisions/2026-08-30 - Example Decision.md
  ---

  # Write Lock

  Operational coordination state for consequential canonical writes. Follow
  the Write Lock Contract. Holding this lock grants no approval, authority,
  scope, or ownership.
  ```

  A 60-minute default expiry means an abandoned lock self-clears rather than permanently blocking every other session — the contract also lets the vault owner manually clear a lock they've confirmed is stale.
