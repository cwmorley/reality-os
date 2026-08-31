# Reality OS: A Multi-Agent Vault Governance Architecture

**A serverless, file-based coordination protocol that lets multiple independent AI systems collaborate safely on one personal knowledge base — with no framework, no database, and no shared runtime.**

## Summary

Reality OS is an Obsidian vault that four separate AI products — Claude (via Cowork), OpenAI's Codex, ChatGPT, and Gemini — read from and write to as ongoing collaborators, not one-off assistants. There is no orchestration framework underneath it (no LangGraph, no CrewAI, no vector database, no background daemon). Every coordination primitive — mutual-exclusion locking, message transport, staged context loading, conflict reconciliation — is implemented as a convention enforced through plain Markdown files and one governing contract document that every session reads first.

The interesting part isn't the file format. It's that the coordination problems this setup runs into — agents overwriting each other's edits, agents burning enormous context on files they don't need, agents proposing duplicate or stale changes, one agent's convenient interpretation becoming another agent's assumed fact — are the same problems any multi-agent system has to solve. This architecture solves them with conventions instead of code, and validates each one empirically before trusting it, rather than assuming a design works because it sounds right.

## 1. Bounded, Anchor-Based Context Loading

The default failure mode for an AI system working against a large personal knowledge base is loading far more than it needs. A routine "what's the current state of X" question doesn't require the full history of X — but without an explicit mechanism to prevent it, every session tends toward loading everything, just in case.

Reality OS routes each session through a compact root dispatcher (`AGENTS.md`, under 1,000 tokens) that resolves the session to a named, registered scope — e.g. a specific active project — before any content loads. For a resolved scope, the agent loads only pre-registered sections of canonical notes, addressed by exact heading (`Path/Note.md#Heading Name`), not the whole file. A 19,000-token canonical note might have a 270-token "Current state" section; routine work reads that section and stops.

This only works if bounded loading doesn't quietly turn into bounded *blindness* — an agent confidently answering from too little context instead of recognizing a gap. So the design includes named escalation triggers (conflicting facts between sources, a task touching money or another scope, a loaded source that looks stale, an owner that can't be determined) that require the agent to expand beyond its bootstrap and explicitly report the expansion — never silently guess, never silently reload everything.

**This wasn't accepted on the strength of the design.** Before the first scope was activated, it was tested with a clean two-task control: one task ran the old full-context path, a second ran the new scoped path, with no shared history between them. Both answered the same two questions — one answerable entirely within the bootstrap, one deliberately not.

| | Loaded source text | Result |
|---|---:|---|
| Control (legacy full orientation) | ~50,036 tokens | Correct |
| Scoped (bounded + anchors) | ~4,811 tokens | Correct, and identified the gap in question 2 and escalated to load exactly the missing section |

That's a 90.4% reduction in loaded context with no loss of correctness, and — the part that actually matters — proof that the escalation mechanism fires when it's supposed to, instead of just working on paper. The scope was only marked active after this test passed.

**Cost tracks the actual shape of the question, not a fixed budget.** The 90.4% figure is the reduction for a routine, in-bootstrap question — that's the common case, and it's cheap by design. A question that trips an escalation trigger costs more, because the agent deliberately loads the extra section it needs and says so; the system isn't tuned to minimize tokens on every request, it's tuned to keep the *floor* low so that ordinary work doesn't carry the weight of the rare complex case. That's the actual design bet: most sessions are routine, so the routine path should be the cheap one, and the expensive path should only ever be paid for by the sessions that genuinely need it — not amortized across every session as a fixed tax. A flat token budget applied uniformly would have made the routine case cheaper still, at the cost of making the escalation path unreliable exactly when it matters most; this trades a slightly higher ceiling for a floor that's trustworthy.

## 2. Multi-Agent Write Governance

Multiple AI systems editing a shared file store need rules about who can write what, and a way to avoid two agents editing the same file at once.

**Single-writer domains.** Certain folders belong to exactly one agent. Claude writes independent audits to one folder; Codex writes its dispositions and implementation reports to another; each reads the other's domain but never edits it. The canonical human-facing queue (`Open Questions.md`) has exactly one writer — Codex — and every other agent proposes into its own transport file instead of touching that queue directly.

**A cooperative write lock**, not a technical one. Before a consequential canonical write, an agent reads a lock file, checks it's unlocked or expired, and claims it with an owner name, a session token, an explicit list of target files, and a 60-minute expiry. It rereads the lock immediately before writing and again before release, and — where the tool surface supports it — compares a hash of the target against what it last read, to catch a target that changed underneath the plan. This is explicitly a convention, not a filesystem-level lock: it prevents most practical collisions between cooperating agents, and it does not claim more reliability than that. The design has a named reassessment trigger — move to real technical enforcement only after two actual collisions despite correct use, or one collision that causes irreversible harm — rather than assuming the cooperative version is sufficient forever.

A separate, harder question got explicitly *not* folded into this: a lock prevents two agents writing at once, but it doesn't prevent one agent committing a plan it formed *before* it acquired the lock, based on information that's since gone stale. That's a freshness problem, not a concurrency problem, and treating them as the same thing was identified and corrected as a design mistake before it shipped.

## 3. Cross-Agent Question Routing and Reconciliation

Agents surface open questions across sessions without polluting every session's context with every question ever raised, and without five different agents each maintaining their own contradictory idea of what's still unresolved.

**The capture filter.** Not every uncertainty an agent notices deserves to become a tracked question — a queue that captures every passing doubt just becomes a second inbox nobody clears. A candidate only gets created if it passes a three-part test, all of which must hold: a future session could take the wrong action without the answer; the answer actually blocks, changes, authorizes, or materially constrains something concrete; and the answer isn't already recoverable from existing material. Each source agent holds a personal, provisional "outbox" of these candidates — not authoritative, just proposed — rather than writing into the shared queue directly.

**The inference rule.** Candidates carry a stable ID, a five-state lifecycle (`open`, `possible-answer`, `answered-awaiting-processing`, `superseded`, `withdrawn`), and — critically — metadata distinguishing an explicit answer from an inferred one: `explicit-in-chat`, `explicit-external-evidence`, `canonical-resolution`, or `inferred-needs-confirmation`. Inference alone can never move a candidate to `answered-awaiting-processing`; it downgrades to `possible-answer` instead, no matter how confident the inference looks. This is the single load-bearing rule in the whole mechanism: without it, an AI's own plausible-sounding guess would quietly become treated as settled fact the next time a session reads the queue, and nothing downstream would know the difference.

**Reconciliation and the receipt ledger.** One agent (Codex, in the original deployment) owns reconciliation: it reads every outbox, verifies each candidate is still current, still consequential, not already represented, and — for anything claiming `answered-awaiting-processing` — that its basis is genuinely explicit and not an inference wearing that label. Every candidate version it reviews gets a disposition logged to a receipt ledger: `imported`, `merged`, `rejected`, `deferred`, `already-represented`, or `terminal`. Without that ledger, "already handled, don't re-import" exists only in the memory of whichever session last reconciled — which evaporates the moment that session ends, and the next reconciliation pass re-litigates candidates that were already settled. The ledger makes that state durable and inspectable instead, at the cost of one more file to maintain — a trade that's worth it well before it feels necessary, once more than two or three agents are contributing. The canonical queue itself then sorts by actionability — answer now, waiting on an external event, later and dependent on something else — rather than a flat undifferentiated list, and a question only leaves it once its answer is confirmed to have landed in the canonical note it was meant to update, not merely when it's marked done.

## 4. Epistemic Discipline

The vault enforces a distinction most personal knowledge systems don't bother with: fact, observation, interpretation, belief, hypothesis, evidence, and inference are not the same category, and collapsing them is treated as an error, not a shortcut. Direct evidence and real-world outcomes outrank AI interpretation or an internally coherent narrative, deliberately — an elegant explanation from a model is not evidence, no matter how many times it gets restated. Restatements of the same underlying source across five different notes count as one source, not five independent corroborations; each AI-generated report (a daily digest, a deep audit) is treated as one more interpretation of the vault as written, never as automatic canonical truth just because an AI produced it.

## 5. Read-Only Mobile Access

For access away from the desk, the vault can be mirrored one-way into a cloud drive and consolidated into a single text file that a tool like NotebookLM can ingest, giving mobile access to current vault state without carrying a full sync client or exposing the live vault to a second write path. It's a convenience mechanism, not a security architecture — but the one-way direction is a genuinely useful property regardless of intent: nothing written on that side can flow back into the canonical vault. There's no reconciliation step to design because there's nothing to reconcile.

## 6. What Actually Failed, and What That's Worth

The first governed scope was activated only after the A/B-plus-escalation-probe test described above passed. A second scope was activated the same day without that same test being run against it — an anchor-existence check and a token estimate, but no deliberate out-of-bootstrap question to confirm the escalation trigger actually fires for that scope before it was trusted with a live governed write path.

That's a real gap, not a hypothetical one, and it's included here on purpose. A system whose entire premise is "verify before trusting a design" is more credible for catching its own lapse than for claiming it never had one. The fix is mechanical: run the same two-case test against the second scope — one question fully inside its bootstrap, one deliberately outside it — before treating its compact-write path as validated.

## 7. What This Actually Demonstrates

The file conventions here — the dispatcher syntax, the anchor list, the lock schema, the outbox ledger — were designed and implemented by an AI coding agent, working inside its own proposal-and-revision loop. That's worth being precise about, because the more interesting and more transferable part of this project isn't the schema.

It's the process that produced it: nothing here shipped on the strength of a single AI's first proposal. The initial design for this architecture was put in front of a second, independent AI system for adversarial review, was found overbuilt, and was substantially revised as a result. Neither scope went live on the strength of a plausible design — each required a falsification test built specifically to catch the failure mode being guarded against (an agent confidently wrong from too little context), with the design activated only after that test passed and the result measured, not assumed. And the one place that discipline slipped got caught and is being corrected under the same standard, not quietly left alone.

That's a directable, repeatable practice: hold AI-generated designs to an adversarial-review-plus-empirical-falsification standard before trusting them with real state, across multiple independent AI systems, applied consistently enough that a lapse in it stands out as a lapse. The vault schema is one artifact of that practice. It isn't the practice itself, and it isn't the part that doesn't generalize to the next system.

## Architecture at a Glance

| Component | File(s) | Problem it solves |
|---|---|---|
| Runtime dispatcher | `AGENTS.md` | Resolve a session to a scope before loading any content |
| Section-anchored bootstrap | Heading-addressed canonical notes | Load only what a routine task needs, exactly |
| Escalation triggers | `AGENTS.md`, full governance reference | Prevent bounded context from becoming bounded blindness |
| Cooperative write lock | `WRITE LOCK.md`, `Write Lock Contract.md` | Reduce collision risk between concurrent agent sessions |
| Question outbox contract | `Question Outbox Contract.md`, per-agent outboxes | Let agents propose without granting write authority |
| Reconciliation ledger | `Question Reconciliation State.md` | Avoid reprocessing the same candidate twice |
| Canonical question queue | `Open Questions.md` | One human-facing, single-writer source of truth |
| Mobile mirror | One-way cloud sync → NotebookLM | Read-only access to current vault state from a phone |

See [`examples/`](./examples/) for genericized, working templates of the core files.

---

*The original deployment runs on Obsidian with no plugins beyond standard note-linking, coordinated across Claude (Cowork), Codex, ChatGPT, and Gemini as independent collaborating sessions, with a human retaining final decision authority over every canonical change.*
