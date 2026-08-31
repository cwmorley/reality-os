# Reality OS: A Multi-Agent Knowledge Governance Architecture

**A filesystem-native coordination protocol for multiple independent AI systems operating on shared durable knowledge—with no framework, database, or shared runtime.**

## Summary

Reality OS specifies how independent AI sessions can coordinate through plain files while preserving human authority, bounded context, write ownership, epistemic provenance, and durable reconciliation. The original deployment uses an Obsidian vault, but the protocol itself depends only on a shared filesystem and cooperating participants that read and follow its contracts.

There is no orchestration framework underneath it: no agent runtime, database, vector store, central server, background daemon, or technical lock service. Context routing, proposal transport, write coordination, and reconciliation are expressed through Markdown contracts and operational state files.

That distinction matters. Reality OS **governs** cooperating agents; it does not technically compel hostile or noncompliant ones. Its controls should be described as requirements, conventions, and risk reductions except where direct measurement or a tool-level mechanism supports a stronger claim.

The protocol can be summarized as:

> **Load narrowly.**  
> **Write singly.**  
> **Infer explicitly.**  
> **Reconcile durably.**

Its deeper epistemic invariant is:

> An AI proposal or interpretation does not become reality merely because another AI encounters it later.

## Roles and authority

Reality OS requires only a small role vocabulary:

- **Human Authority** retains final decision and implementation authority over canonical state.
- **Canonical Writer / Scope Writer** may modify a defined canonical domain under the governing contract. Holding a lock does not create this authority.
- **Provisional Contributor** may propose candidates through an owned outbox or working domain but does not directly modify the canonical operational queue.
- **Canonical Reconciler** owns reconciliation into the canonical operational queue and records a disposition for each reviewed candidate version.

These are architectural roles, not product identities. In the reference deployment, the human vault owner fills Human Authority; Codex currently fills the Canonical Reconciler role; and Claude, Codex, ChatGPT, and Gemini may act as Provisional Contributors or scoped Canonical Writers where explicitly authorized.

## The three state layers

The architecture keeps three layers separate:

1. **Provisional proposal state**—outboxes, audits, handoffs, working interpretations, and candidate answers.
2. **Canonical operational state**—human-facing queues that coordinate unresolved questions and next processing steps.
3. **Durable domain truth**—the owning canonical project, opportunity, decision, or other source-of-truth record.

Therefore: **proposal ≠ operational queue ≠ durable domain truth**.

Reconciliation can move a qualifying proposal into the operational queue without making it true. Marking a queue item answered does not complete the work; its durable consequence must first reach the owning canonical source. This separation is designed to keep proposal transport or queue administration from silently substituting for real canonical writeback.

## 1. Bounded, anchor-based context loading

The default failure mode for an AI working against a large knowledge base is loading far more than the task needs. A routine “what is the current state of X?” request rarely requires the full history of X, but sessions tend to load everything unless a contract makes the routine path narrower.

Reality OS routes each session through a compact root dispatcher (`AGENTS.md`, under 1,000 tokens in the reference deployment). The dispatcher resolves the session to a registered scope before content loads. For a resolved scope, the agent loads only pre-registered sections of canonical notes, addressed by exact heading (`Path/Note.md#Heading Name`), rather than whole files. A 19,000-token note may expose a 270-token “Current state” section for routine work.

Bounded loading must not become bounded blindness. Named escalation triggers require cooperating agents to expand context when, for example, loaded facts conflict or look stale, money or another scope is affected, ownership is unclear, or answering would otherwise require guessing. The agent names the trigger and loads the narrowest resolving source instead of silently guessing or silently reverting to a full-vault load.

### The measured experiment

Before the first scope was activated, a clean two-task experiment compared the legacy full-context path with the new scoped path. The tasks shared no history and answered the same two questions: one wholly inside the bootstrap and one deliberately outside it.

| Path | Loaded source text | Observed result |
|---|---:|---|
| Control: legacy full orientation | ~50,036 tokens | Correct answers |
| Scoped: bounded bootstrap plus anchors | ~4,811 tokens | Correct in-bootstrap answer; recognized the second question's gap and loaded the missing section |

For that tested scope and task pair, the scoped path reduced loaded source context by **90.4%** while preserving correctness and correctly triggering escalation.

That is bounded evidence, not a universal benchmark. It does not imply that every request receives a 90.4% reduction, that every scope behaves identically, or that one experiment proves universal reliability. The design optimizes the **floor** of routine context cost: common in-bootstrap work stays cheap, while legitimate escalation deliberately pays for additional context. It does not impose a universal fixed token ceiling.

## 2. Multi-agent write governance

Multiple AI systems editing a shared file store need explicit write ownership and a way to reduce overlapping writes.

**Single-writer domains.** Each canonical domain has one authorized writer at a time. Provisional Contributors write only to their owned transport or working domains. The canonical human-facing question queue has one Canonical Reconciler; other agents propose through outboxes rather than editing the queue directly.

**A cooperative write lock.** Before a consequential canonical write, an authorized writer reads the lock state, checks that it is unlocked or expired, claims it with a collision-resistant session token and exact targets, and rereads the claim before proceeding. Where supported, the writer may also compare a target hash with the last-read version.

The lock is a cooperative control, not a filesystem mutex or atomic compare-and-swap. It reduces practical collision risk among complying agents; it cannot guarantee exclusivity against races, noncompliant agents, or external writers.

### Concurrency is not freshness

These are distinct failure modes with distinct controls:

| Failure mode | What goes wrong | Protocol response |
|---|---|---|
| **Concurrency failure** | Two writers collide on shared state. | Single-writer ownership plus the cooperative lock reduce overlap. |
| **Freshness failure** | A writer holds a valid lock but acts on a plan formed from stale state. | After acquiring the lock, reread each live target, reconcile differences, and replan before writing. |

Treating the lock as a freshness guarantee would be a category error. Post-lock rereading is independently required because a perfectly valid lock says nothing about when the plan was formed.

## 3. Cross-agent question routing and reconciliation

Reality OS lets agents surface consequential open questions without giving every agent direct access to the canonical queue or forcing every session to load every unresolved issue.

**The capture filter.** A Provisional Contributor creates a candidate only when all three conditions hold: a future session could take the wrong action without the answer; the answer blocks, changes, authorizes, or materially constrains something concrete; and the answer is not already recoverable from supplied or canonical material. This keeps the outboxes from becoming a second undifferentiated inbox.

**The inference rule.** Candidates carry a stable ID, a lifecycle state, and answer-basis metadata distinguishing `explicit-in-chat`, `explicit-external-evidence`, `canonical-resolution`, and `inferred-needs-confirmation`. Inference alone can never produce `answered-awaiting-processing`; it remains `possible-answer` until confirmed. Confidence does not change provenance.

**Reconciliation and receipts.** The Canonical Reconciler checks each candidate for currency, consequence, duplication, and valid answer basis. Every reviewed candidate version receives a durable disposition such as `imported`, `merged`, `rejected`, `deferred`, `already-represented`, or `terminal`. The receipt ledger moves “already handled” from expired session context into inspectable durable state.

The canonical operational queue sorts unresolved work by actionability—answer now, waiting on an external event, or later behind a dependency. A question leaves the queue only after its confirmed consequence reaches the durable canonical target named by `Apply to:`.

## 4. Epistemic discipline

The protocol requires participants to distinguish fact, observation, interpretation, belief, hypothesis, evidence, and inference. Direct evidence and real-world outcomes outrank AI interpretation or internal narrative. Restatements of one underlying source are one source, not independent corroboration. AI-generated reports remain interpretations unless Human Authority or an explicit governing rule reconciles supported changes into canonical state.

The protocol reduces epistemic drift by making provenance and transition rules inspectable. It does not make an AI's classification automatically correct, and it does not replace human judgment about ambiguous evidence.

## 5. Trust boundaries: bounded context is not access control

Bounded context loading governs what a cooperating session is instructed to load. The underlying tool may still retain technical access to a larger filesystem. A narrow bootstrap therefore provides **context minimization and scope discipline**, not a confidentiality or authorization boundary.

Reality OS currently provides:

- context minimization through registered anchors and named escalation;
- write governance among cooperating agents;
- provenance rules for proposals, answers, and canonical writeback;
- durable reconciliation records.

Reality OS does **not** inherently provide:

- filesystem permissions or cryptographic isolation;
- confidentiality boundaries between scopes;
- hostile-agent or compromised-tool containment;
- protection from an agent deliberately ignoring the protocol;
- a technical guarantee that only one process can write.

Deployments with confidentiality, adversarial, regulatory, or multi-user security requirements need controls outside this protocol.

## 6. Read-only mobile access

The reference deployment can mirror the vault one-way into a cloud drive and consolidate it into a text artifact for a read-only mobile tool. This is a convenience mechanism, not a general security architecture. The useful property is directional: no write from the mobile side is designed to flow back into canonical state.

## 7. Validation status and the disclosed lapse

The first governed scope was activated after the two-case bounded-context experiment passed. A second scope was activated the same day after an anchor-existence check and token estimate, but without the deliberate out-of-bootstrap question needed to verify its escalation behavior.

That is a real validation gap. Anchor existence and estimated cost are not substitutes for behavioral evidence. The second scope remains **specified but not empirically validated** until the same in-bootstrap plus deliberate-escalation probe is run and recorded.

[`VALIDATION.md`](./VALIDATION.md) exposes the current falsification matrix. Only measured behavior is labeled **Validated**; the remaining protocol claims are **Specified—not yet empirically tested**.

## 8. What this demonstrates

The transferable result is not merely a set of Markdown schemas. It is a practice: use independent review to challenge AI-generated designs, keep a complexity budget, and require targeted falsification before trusting a mechanism with durable state.

The original design was revised after adversarial review found it overbuilt. The first scope then required a test aimed directly at the feared failure mode—an agent answering confidently from too little context. The disclosed second-scope lapse shows that the practice itself can fail operationally and therefore also needs durable gates and evidence.

## Architecture at a glance

| Component | Reference file(s) | Purpose |
|---|---|---|
| Runtime dispatcher | `AGENTS.md` | Resolve a session to a scope before loading content |
| Section-anchored bootstrap | Heading-addressed canonical notes | Keep routine source context narrow |
| Escalation triggers | `AGENTS.md`, governance reference | Require narrow expansion when the bootstrap is insufficient |
| Single-writer domains | Ownership rules | Assign canonical write authority by scope |
| Cooperative write lock | `WRITE LOCK.md`, lock contract | Reduce concurrent write collisions among cooperating agents |
| Post-lock freshness check | Lock contract | Prevent a valid lock from carrying a stale plan into a write |
| Question outboxes | Per-contributor outboxes | Transport provisional proposals without canonical queue authority |
| Canonical Reconciler | Reconciliation contract | Apply the capture, duplication, and answer-basis rules consistently |
| Reconciliation ledger | Receipt state | Preserve dispositions across stateless sessions |
| Canonical operational queue | `Open Questions.md` | Coordinate unresolved human-facing work without becoming domain truth |

See [`examples/`](./examples/) for genericized templates of the core files.

## Reassessment and possible next steps

These are candidates, not current protocol requirements.

### Protocol-version metadata

Lightweight fields such as `reality_os_protocol: 1.0` or `contract_revision: 2026-08-31` could identify incompatible contract revisions. They are not mandatory in the current design because no demonstrated multi-version failure yet earns the migration and maintenance cost. Reassess if agents begin operating concurrently under incompatible revisions or a real reconciliation ambiguity cannot be resolved from file history.

### Optional mechanical validator

A future optional validator could check that registered anchors and targets exist, schemas parse, candidate IDs are unique, and lock state is structurally valid. No CLI or mandatory validator is included here. Reassess after repeated structural errors produce material incorrect action or enough recovery cost that a small check is cheaper than continued manual verification.

### Stronger technical locking

No stronger lock is implemented. Reassess only after two material collision or overwrite failures occur despite correct cooperative lock use, or one failure causes serious irreversible harm. Until then, technical enforcement would add infrastructure and new failure modes without demonstrated need.

---

*The reference deployment runs on Obsidian using Claude, OpenAI's Codex, ChatGPT, and Gemini as independent collaborating sessions. Those products demonstrate one deployment; they do not define the protocol. Human Authority retains final decision authority over canonical change.*
