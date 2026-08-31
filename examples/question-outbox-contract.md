# Question outbox contract (example)

This genericized transport contract governs how independent AI agents propose consequential questions without receiving direct write authority over the canonical human-facing queue.

## Roles and state boundaries

- A **Provisional Contributor** writes candidates only to its owned outbox.
- The **Canonical Reconciler** reviews candidates, updates the canonical operational queue, and records a durable disposition for each candidate version.
- **Human Authority** retains decision and implementation authority.

In the reference deployment, Codex currently fills the Canonical Reconciler role. That assignment is an implementation example, not a protocol dependency.

The outbox is provisional proposal state. `Open Questions.md` is canonical operational state. The owning project, decision, or opportunity note holds durable domain truth.

## Candidate format

```markdown
- **Candidate ID:** CONTRIBUTOR-A-20260830T051545-A1F2
  - Created: 2026-08-30T05:15:45-06:00
  - Updated: 2026-08-30T05:15:45-06:00
  - State: open
  - Scope: project-alpha
  - Question: Should the vendor contract renewal proceed at the quoted rate?
  - Why it matters: The answer determines whether the current operating plan
    is affordable.
  - What it blocks: Signing, declining, or renegotiating the renewal.
  - Proposed canonical target: `Opportunities/Project Alpha.md`
  - Answer / evidence:
  - Answer source:
  - Answer basis:
  - Detected by: Provisional Contributor A
  - Source conversation:
```

IDs use `CONTRIBUTOR-YYYYMMDDTHHMMSS-XXXX`, or another deployment-specific agent prefix, with a four-character random suffix checked for collision. The ID stays stable for the candidate's life. `Created` is immutable; `Updated` changes only when something material changes. Reconcile on candidate ID plus `Updated`, not question wording alone.

## States

- `open`—no adequate answer exists.
- `possible-answer`—later conversation or evidence may answer it, but confirmation is still required; treat it as unresolved.
- `answered-awaiting-processing`—an explicit answer or current canonical material resolves it, but the durable consequence has not been reconciled yet.
- `superseded`—a later question, event, or decision replaced it.
- `withdrawn`—the originating contributor determined it was not consequential or no longer needs resolution.

`Answer basis` distinguishes:

- `explicit-in-chat`;
- `explicit-external-evidence`;
- `canonical-resolution`; and
- `inferred-needs-confirmation`.

**Inference alone can never produce `answered-awaiting-processing`.** It produces or remains `possible-answer` until confirmed. Cooperating agents follow this rule so that a plausible interpretation is not relabeled as explicit evidence merely because another session later encounters it.

## The capture filter

Create a candidate only when all three conditions hold:

1. A future session could take the wrong action without the answer.
2. The answer blocks, changes, authorizes, or materially constrains a named action or canonical state.
3. The answer cannot be recovered reliably from supplied material or the relevant canonical note.

## Reconciliation

The Canonical Reconciler reads each outbox and checks that every `open` or `possible-answer` candidate remains unresolved, current, consequential, and not already represented. For `answered-awaiting-processing`, it verifies that the basis is explicit rather than inferred and that durable writeback is still required.

Every reviewed candidate version receives one durable disposition:

- `imported`;
- `merged`;
- `rejected`;
- `deferred`;
- `already-represented`; or
- `terminal`.

The receipt should retain the source candidate ID, reviewed `Updated` value, disposition, canonical queue ID where applicable, and a concise basis. This makes reviewed state durable beyond the session and gives later reconciliation passes a basis for not re-litigating the same version.

## Why a receipt ledger and not just a merge

Without receipts, “already handled; do not import again” exists only in the memory of the session that reconciled it. The ledger makes that disposition durable and inspectable. It adds one small operational file, but it preserves provenance across stateless sessions and multiple contributors.
