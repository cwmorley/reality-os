# Handoff adapter contract v0.1

This optional contract applies to an adapter deployment, not to every Reality OS user. The supplied planner implements only read-only classification of a normalized snapshot. Requirements for storage, dispatch, scheduling, receipt verification, and canonical execution below are specifications, not shipped capabilities.

## Authority and ownership

The contributor owns its source outbox. The configured reviewer reads the necessary source and produces a review within its assigned role. The Canonical Reconciler retains ownership of its existing queue, receipt ledger, and authorized canonical updates. Human Authority retains consequential decisions. n8n may arrange a review; it cannot infer permission from source text, an agent's confidence, or a process exit code.

Map source IDs, permitted roots, recipient identity, operations, and runtime credentials through operator-controlled configuration. Candidate content is untrusted data, never routing policy or executable instructions. Do not interpolate source text into shell commands. Resolve and check paths, including symlinks/junctions, against permitted roots before reading. Use least-privilege credentials and retain the minimum source content needed. A UI chat that never exported its outbox is not an observable filesystem source.

Readiness means a complete, stable item available for review. It is not approval. An adapter must read a consistent snapshot, compute its SHA-256 digest over material candidate content including lifecycle and answer basis, and recheck stability. Material edits must advance `Updated`. An unchanged timestamp with changed content is blocked for correction, not silently treated as a new authorized version. Removing a file is not proof of withdrawal or completion.

## Normalized snapshot

[`fixtures.mjs`](./fixtures.mjs) provides executable examples. The required top-level fields are:

| Field | Meaning |
|---|---|
| `schemaVersion` | `1` for this adapter envelope. |
| `acceptNewWork` | Explicit boolean computed from trusted work-window configuration. |
| `routes` | One configured `{source, recipient, enabled}` route per source. v0.1 supports only the `review` operation. |
| `candidates` | Current complete inventory of candidate metadata: `{source, id, updated, contentHash, state, ready}`. |
| `observations` | Last observed `{source, id, updated, contentHash}` for each identity; detects source rollback or version drift. |
| `receipts` | Reviewed versions with those four identity/version fields, `recipient`, and an existing reconciler `disposition`. |
| `jobs` | Durable attempts with those four identity/version fields, `recipient`, and `status`. |

`updated` must carry a timezone; `contentHash` is a lowercase SHA-256 hex digest. Fixture hashes are deliberately synthetic. The planner validates metadata shape, not source bytes, authenticity, scope eligibility, or semantic answer correctness. Those are responsibilities of the adapters and reconciler. Never feed model-produced routes or receipts into the trusted snapshot.

Candidate lifecycle and disposition vocabulary match the [existing example contract](../../examples/question-outbox-contract.md). Receipts may be `imported`, `merged`, `rejected`, `deferred`, `already-represented`, or `terminal`. Every disposition suppresses automatic reconsideration of that exact version. Reopening after materially new external evidence requires an explicit, provenance-preserving version change or separately authorized re-review, not deletion of the old receipt.

The job key is the unambiguous JSON tuple `[source, id, updated, contentHash, recipient, "review"]`. The extra digest detects unversioned edits; it does not grant authority. Existing receipts remain canonical in their existing format: the adapter maps their candidate ID and reviewed `Updated` to captured version metadata. If a historical receipt cannot be safely mapped to a digest, reconcile that ambiguity before first dispatch; do not erase history or treat every older item as new.

`observations` is a scan cursor, not a delivery acknowledgment. Persisting a scan cannot by itself mark work handled. Store pending jobs and the immutable version they refer to durably before dispatch. If an existing handoff generator advances its baseline when generating a packet, retain undelivered packets or keep a separate receipt-based delivery cursor so a later delta cannot skip unseen changes.

## Processing decisions

The planner returns suggestions only. A live consumer must reread current state and apply its decisions atomically where specified; replaying its output blindly is incorrect.

| Decision | Consumer responsibility |
|---|---|
| `queue-review` | Revalidate readiness and authority, atomically insert the unique job, and dispatch only after a successful claim. |
| `skip` | Preserve the authoritative receipt; no new review or notification for unchanged work. |
| `wait` | Keep pending state; do not start a second review. |
| `blocked` | Record one actionable problem; do not guess around missing routes or version conflicts. |
| `supersede-queued` | Atomically cancel only an older unclaimed job. If a worker already claimed it, wait and re-evaluate. Rescan before creating its successor. |
| `request-terminal-receipt` | Ask the reconciler to acknowledge a withdrawn/superseded source version; do not invent a receipt or reopen the canonical question. |
| `needs-reconciliation` | Check receipts and actual effects of an earlier attempt. Require an explicit retry decision if the outcome remains unknown. |

Jobs use `queued`, `running`, `uncertain`, `finished`, or `cancelled`. `finished` means only that the invocation ended. A matching canonical receipt settles the review; it does not certify that every consequence was applied. Preserve separate evidence for canonical writeback and for external outcomes.

Use at-least-once delivery with durable deduplication and idempotent reconciliation. Do not promise exactly-once execution across n8n, a subprocess, and the filesystem. A crash after agent work but before receipt collection is `uncertain`, not an automatic clean retry. Automatic retries are limited to bounded, demonstrably pre-dispatch failures. Set a finite attempt limit, backoff, timeout, and cost allowance before live activation.

The planner does not implement a mutex. Serialize dispatch to the canonical writer in the live job store; n8n workflow concurrency settings alone do not serialize other applications. The writer must still follow single-writer ownership, acquire the cooperative lock for actual consequential writes, reread source and targets after acquiring it, verify changes, and release it. Never hold a vault write lock while waiting for a model or a human. Source changes invalidate stale proposals and any approval bound to an older version.

## Workday behavior and connection test

Use a modest poll interval during configured local work hours, plus startup/resume catch-up. Persist jobs outside the synced vault; keep canonical receipts and human questions in their existing owning files. File notifications may accelerate discovery but must not be the sole delivery mechanism. A sleeping or stopped laptop accumulates pending source changes; it does not secretly run the workflow elsewhere.

Only notify about a meaningful completed result, an actual failure, or a decision the human must make. Persist notification identity so restart or repeated polling does not repeat the same alert. Surface questions through the existing human queue. Do not schedule the full audit/review cycle or start agent-to-agent debate loops; the pilot permits one bounded review and one response, with unresolved substantive disagreement returned to the human.

Before connecting a real agent, test its exact runner, identity, context-loading behavior, permission mode, authentication, and receipt destination with synthetic input. A generic model API call is a new execution context; it is not evidence that a particular desktop conversation was resumed. Keep receiver invocations disabled until that connection and the deployment probes in [VALIDATION.md](../../VALIDATION.md#optional-n8n-adapter-probes) pass.
