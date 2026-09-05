# Reality OS

**A filesystem-native governance protocol for multiple independent AI systems operating on shared durable knowledge—with no framework, database, or shared runtime.**

Reality OS began as a personal operating system built in Markdown inside Obsidian. This repository documents the coordination architecture that emerged from that deployment: how independent AI products can work over one shared file store while keeping context bounded, writes governed, inference labeled, and reconciliation durable.

It is a pattern, not a packaged product. Nothing here requires Obsidian specifically. It requires a shared filesystem, explicit governance contracts, and cooperating AI sessions that read and follow those contracts before acting.

The protocol's four shorthand invariants are:

> **Load narrowly.**  
> **Write singly.**  
> **Infer explicitly.**  
> **Reconcile durably.**

The deeper rule beneath all four is that an AI proposal or interpretation does not become reality merely because another AI encounters it later.

The transferable result is not merely a set of Markdown schemas. It is a practice: use independent review to challenge AI-generated designs, keep a complexity budget, and require targeted falsification before trusting a mechanism with durable state. Reality OS is one application of that practice, not a substitute for validating it in a new environment.

## What's in here

- **[`ARCHITECTURE.md`](./ARCHITECTURE.md)** explains bounded anchor-based context loading, cooperative write governance, cross-agent question routing, epistemic provenance, trust boundaries, and the reference deployment.
- **[`VALIDATION.md`](./VALIDATION.md)** defines a falsification matrix and separates behavior that has measured evidence from behavior that is specified but not yet empirically tested.
- **[`examples/`](./examples/)** contains genericized templates of the runtime dispatcher, write-lock contract and state, question-outbox contract, and canonical operational queue.

## What this looks like in practice

The scenarios below are genericized from recurring patterns in the reference deployment. They illustrate how the protocol is used; they are not additional validation results.

This is also the part that matters most day to day, not just architecturally. Real life doesn't pause for a clean handoff—you're mid-thread in one chat when something else pulls you away, and by the time you're back there are four other conversations that happened in between. Without a mechanism for this, an open question either gets silently dropped or you're the one stuck scrolling back through a pile of chat histories trying to reconstruct what was still unresolved. The canonical queue is what remembers instead of you: pick any session back up and the open loop is sitting there, sorted by whether it's actionable now, waiting on something external, or blocked on something else—not buried in a transcript you'd have to go dig for. That's the actual point of calling this an operating system rather than a chat log.

**Let several AI systems contribute without giving them identical authority.** One AI may audit a project, another may propose an answer, and a third may maintain canonical state. Each contributes through its assigned role and owned files. Agreement among the AIs does not make a proposal true, and no contributor gains canonical authority merely by sounding confident. The protocol preserves useful parallel contribution while keeping the human-visible decision boundary intact.

**Keep routine context cheap without pretending every task is routine.** A session answering a normal status question loads only the registered current-state sections. If it encounters a conflicting fact, an unclear owner, a financial consequence, or another named escalation trigger, it loads the narrowest additional source needed to resolve the issue. Common work stays lightweight; consequential ambiguity earns more context instead of a guess.

## The state model

Reality OS keeps three layers distinct:

1. **Provisional proposal state**—agent outboxes, audits, and working interpretations.
2. **Canonical operational state**—human-facing queues used to coordinate unresolved work.
3. **Durable domain truth**—the owning canonical project, decision, opportunity, or other source-of-truth record.

In shorthand: **proposal ≠ operational queue ≠ durable domain truth**.

A Canonical Reconciler may import a proposal into the operational queue, but that does not make the proposal true. Likewise, an answered queue item is not safely complete until its durable consequence has been written to the owning canonical source.

## What the protocol does

Reality OS specifies cooperative controls for recurring multi-agent failure modes:

- anchor-based bootstraps keep routine context small and name when expansion is required;
- single-writer domains and a cooperative lock reduce collision risk;
- post-lock rereads address plans formed from stale state;
- provisional outboxes let agents propose without direct authority over a shared queue;
- answer-basis metadata keeps inference from masquerading as explicit evidence;
- reconciliation receipts keep reviewed candidates from being silently dropped or repeatedly re-litigated.

These are governance conventions, not hostile-agent containment. Cooperating agents are required to follow them; the files do not themselves provide filesystem permissions, cryptographic isolation, or a technical mutex. See [Trust Boundaries](./ARCHITECTURE.md#5-trust-boundaries-bounded-context-is-not-access-control).

## What has actually been validated

One documented two-case experiment compared a legacy full-orientation path with a scoped anchor-based path. The scoped run loaded approximately **4,811 tokens** of source text versus approximately **50,036 tokens** for the control—a **90.4% reduction**—while answering the in-bootstrap question correctly and correctly escalating for an intentionally out-of-bootstrap question.

That result validates those two behaviors for the tested scope and tasks. It does **not** establish a universal per-request reduction, validate every scope, or prove the rest of the protocol empirically. The architecture optimizes the floor of routine context cost, not a fixed token ceiling. A second scope was activated without the same deliberate escalation probe; that lapse remains disclosed rather than retroactively relabeled as validation.

The full status and untested failure probes are in [`VALIDATION.md`](./VALIDATION.md).

## Reference deployment

The original deployment runs in an Obsidian vault across Claude, OpenAI's Codex, ChatGPT, and Gemini as independent collaborating sessions, with a human retaining final authority over canonical change. In that deployment, Codex currently fills the **Canonical Reconciler** role. Those product assignments are examples, not protocol requirements.

## Status

Reality OS is a working architecture extracted from a live personal deployment, not a packaged tool. Adopting it means adapting the contracts in `examples/` to your own scopes, canonical sources, ownership boundaries, and evidence requirements—and validating the resulting behavior in your environment before relying on it.

