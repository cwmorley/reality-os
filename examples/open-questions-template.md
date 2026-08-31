# Canonical question queue (example)

The single human-facing operational queue. One writer only. Every question names what it blocks and what to do with the answer once it lands — a queue of bare questions with no consequence attached just becomes another inbox nobody clears.

```markdown
# Open Questions

Canonical operational queue for consequential questions that require the
vault owner, another person, or a future event. Other agents contribute
through provisional question outboxes. Completed decisions and project
truth belong in their owning canonical notes.

## Answer now

_None._

## Waiting

### Project Alpha

- [ ] **Q-2026-08-30-01 — Will the counterparty confirm the renewal terms?**
  - Question: Does the vendor confirm the quoted renewal rate, and does
      that response change scope, timeline, or budget?
        - Why now: This is the central unresolved external fact; no internal
            planning can substitute for it.
              - Blocks: Signing, declining, or renegotiating the renewal.
                - Waiting on: Vendor's promised response by Friday. If no response
                    arrives, send one follow-up the following Monday.
                      - Answer / evidence:
                        - Apply to: `Opportunities/Project Alpha.md`
                          - Source candidate: CLAUDE-20260830T051545-A1F2
                          ```

                          ## The two rules that make this queue trustworthy

                          **A question placed under Later must name the event that brings it back**, not just "revisit sometime." Vague resurfacing triggers are how a queue silently fills with dead weight that nobody actively decided to drop — it just never had a reason to come back up.

                          **A question only leaves the queue after its answer is durably recorded somewhere else** — the `Apply to:` target — not when it's merely marked done. Deleting a resolved question without confirming its answer landed in the owning canonical note is the single easiest way to lose a decision that took real effort to reach.
