# Canonical operational question queue (example)

This is the single human-facing operational queue for unresolved consequential questions. One **Canonical Reconciler** writes it. Other agents contribute through provisional outboxes.

The queue is canonical operational state, not durable domain truth. Every question names what it blocks and where its confirmed consequence must be written; otherwise the queue becomes another inbox rather than a reconciliation mechanism.

```markdown
# Open Questions

Canonical operational queue for consequential questions requiring Human
Authority, another person, external evidence, or a future event. Provisional
Contributors submit candidates through their owned outboxes. Completed
decisions and durable domain truth belong in their owning canonical notes.

## Answer now

_None._

## Waiting

### Project Alpha

- [ ] **Q-2026-08-30-01 — Will the counterparty confirm the renewal terms?**
  - Question: Does the vendor confirm the quoted renewal rate, and does that
    response change scope, timeline, or budget?
  - Why now: This is the central unresolved external fact; no internal
    planning can substitute for it.
  - Blocks: Signing, declining, or renegotiating the renewal.
  - Waiting on: Vendor's promised response by Friday. If no response arrives,
    send one follow-up the following Monday.
  - Answer / evidence:
  - Apply to: `Opportunities/Project Alpha.md`
  - Source candidate: CONTRIBUTOR-A-20260830T051545-A1F2

## Later

### Project Alpha

- [ ] **Q-2026-08-30-02 — Does the renewal justify the added scope?**
  - Depends on: Q-2026-08-30-01
  - Why later: No confirmed terms exist yet; evaluating imagined terms would
    be speculative.
  - Trigger: Move to Answer now once the vendor sends confirmed terms.
  - Blocks: Committing to the added scope.
  - Answer / evidence:
  - Apply to: `Opportunities/Project Alpha.md`

## Answered — awaiting processing

_None._
```

## The two rules that make this queue trustworthy

**A question under Later names the event that returns it to action.** “Revisit sometime” is not a trigger; it is how queues accumulate dead weight without an explicit decision to retain or remove it.

**A question leaves only after durable writeback.** An explicit answer may move an item to `Answered — awaiting processing`, but the item does not disappear until the confirmed consequence reaches its `Apply to:` target. Queue completion cannot substitute for canonical domain truth.
