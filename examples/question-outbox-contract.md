# Question outbox contract (example)

Genericized transport contract governing how independent AI agents propose questions without any of them getting direct write access to the canonical, human-facing queue.

## The core rule

One file — here, `Open Questions.md` — is the single canonical, human-facing operational queue. Exactly one agent (in the original deployment, Codex) is its writer. Every other agent proposes into its own outbox file instead.

## Candidate format

```markdown
- **Candidate ID:** CLAUDE-20260830T051545-A1F2
  - Created: 2026-08-30T05:15:45-06:00
    - Updated: 2026-08-30T05:15:45-06:00
      - State: open
        - Scope: project-alpha
          - Question: Should the vendor contract renewal proceed at the quoted rate?
            - Why it matters:
              - What it blocks:
                - Proposed canonical target:
                  - Answer / evidence:
                    - Answer source:
                      - Answer basis:
                        - Detected by: Claude
                          - Source conversation:
                          ```

                          IDs use `AGENT-YYYYMMDDTHHMMSS-XXXX` — a four-character hex suffix checked for collision. The ID stays stable for the candidate's entire life. `Created` is immutable; `Updated` changes only when something material changes. Deduplicate on ID + `Updated`, not question wording.

                          ## States

                          - `open` — no adequate answer exists.
                          - `possible-answer` — later conversation or evidence may answer it, but confirmation is still required; treat as unresolved.
                          - `answered-awaiting-processing` — an explicit answer or current canonical material resolves it, but the durable consequence hasn't been reconciled yet.
                          - `superseded` — a later question, event, or decision replaced it.
                          - `withdrawn` — the originating agent determined it was not consequential or no longer needs resolution.

                          `Answer basis` distinguishes `explicit-in-chat`, `explicit-external-evidence`, `canonical-resolution`, and `inferred-needs-confirmation`. **Inference alone can never produce `answered-awaiting-processing`** — it downgrades to `possible-answer` instead. This is the single most important rule in the contract: it's what stops an AI's own confident guess from quietly becoming treated as settled fact.

                          ## The capture filter

                          Not every uncertainty an agent notices deserves to become a candidate. Create one only when all three are true:

                          1. A future session could take the wrong action without the answer.
                          2. The answer blocks, changes, authorizes, or materially constrains a named action or canonical state.
                          3. The answer cannot be recovered reliably from supplied material or the relevant canonical note.

                          ## Reconciliation

                          The owning agent reads every outbox, verifies each `open`/`possible-answer` candidate is still unresolved, current, consequential, and not already represented — and verifies each `answered-awaiting-processing` candidate has an explicit (not inferred) basis and a durable consequence still requiring reconciliation. Every reviewed candidate version gets a disposition logged in a reconciliation-receipt file: `imported`, `merged`, `rejected`, `deferred`, `already represented`, or `terminal`. That receipt is what prevents the same candidate from being re-litigated every time outboxes get reconciled.

                          ## Why a receipt ledger and not just a merge

                          Without the receipt file, "already handled, don't re-import" state lives only in the memory of whichever session last reconciled — which disappears the moment that session ends. The ledger makes that state durable and inspectable, at the cost of one more file to maintain. For a system with more than two or three collaborating agents, that trade is worth it well before it feels necessary.
