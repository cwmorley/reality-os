# Reality OS: A Multi-Agent Vault Governance Architecture

**A serverless, file-based coordination protocol that lets multiple independent AI systems collaborate safely on one personal knowledge base — with no framework, no database, and no shared runtime.**

## Summary

Reality OS is an Obsidian vault that four separate AI products — Claude (via Cowork), OpenAI's Codex, ChatGPT, and Gemini — read from and write to as ongoing collaborators, not one-off assistants. There is no orchestration framework underneath it (no LangGraph, no CrewAI, no vector database, no background daemon). Every coordination primitive — mutual-exclusion locking, message transport, staged context loading, conflict reconciliation — is implemented as a convention enforced through plain Markdown files and one governing contract document that every session reads first.

The interesting part isn't the file format. It's that the coordination problems this setup runs into — agents overwriting each other's edits, agents burning enormous context on files they don't need, agents proposing duplicate or stale changes, one agent's convenient interpretation becoming another agent's assumed fact — are the same problems any multi-agent system has to solve. This architecture solves them with conventions instead of code, and validates each one empirically before trusting it, rather than assuming a design works because it sounds right.

## 1. Bounded, Anchor-Based Context Loading

The default failure mode for an AI system working against a large personal knowledge base is loading far more than it needs. A routine "what's the current state of X" question doesn't require the full history of X — but without an explicit mechanism to prevent it, every session tends toward loading everything, just in case.

This only works if bounded loading doesn't quietly turn into bounded *blindness* — an agent confidently answering from too little context instead of recognizing a gap. So the design includes named escalation triggers (conflicting facts between sources, a task touching money or another scope, a loaded source that looks stale, an owner that can't be determined) that require the agent to expand beyond its bootstrap and explicitly report the expansion — never silently guess, never silently reload everything.

**This wasn't accepted on the strength of the design.** Before the first scope was activated, it was tested with a clean two-task control: one task ran the old full-context path, a second ran the new scoped path, with no shared history between them. Both answered the same two questions — one answerable entirely within the bootstrap, one deliberately not.

| | Loaded source text | Result |
|---|---:|---|
| Control (legacy full orientation) | ~50,036 tokens | Correct |
| Scoped (bounded + anchors) | ~4,811 tokens | Correct, and identified the gap in question 2 and escalated to load exactly the missing section |

That's a 90.4% reduction in loaded context with no loss of correctness, and — the part that actually matters — proof that the escalation mechanism fires when it's supposed to, instead of just working on paper. The scope was only marked active after this test passed.

## 2. Multi-Agent Write Governance

Multiple AI systems editing a shared file store need rules about who can write what, and a way to avoid two agents editing the same file at once.

**Single-writer domains.** Certain folders belong to exactly one agent. Claude writes independent audits to one folder; Codex writes its dispositions and implementation reports to another; each reads the other's domain but never edits it. The canonical human-facing queue (`Open Questions.md`) has exactly one writer — Codex — and every other agent proposes into its own transport file instead of touching that queue directly.

**A cooperative write lock**, not a technical one. Before a consequential canonical write, an agent reads a lock file, checks it's unlocked or expired, and claims it with an owner name, a session token, an explicit list of target files, and a 60-minute expiry. It rereads the lock immediately before writing and again before release, and — where the tool surface supports it — compares a hash of the target against what it last read, to catch a target that changed underneath the plan. This is explicitly a convention, not a filesystem-level lock: it prevents most practical collisions between cooperating agents, and it does not claim more reliability than that. The design has a named reassessment trigger — move to real technical enforcement only after two actual collisions despite correct use, or one collision that causes irreversible harm — rather than assuming the cooperative version is sufficient forever.

A separate, harder question got explicitly *not* folded into this: a lock prevents two agents writing at once, but it doesn't prevent one agent committing a plan it formed *before* it acquired the lock, based on information that's since gone stale. That's a freshness problem, not a concurrency problem, and treating them as the same thing was identified and corrected as a design mistake before it shipped.

## 3. Cross-Agent Question Routing and Reconciliation

Agents surface open questions across sessions without polluting every session's context with every question ever raised, and without five different agents each maintaining their own contradictory idea of what's still unresolved.

Each source agent holds a personal, provisional "outbox" of candidate questions — not authoritative, just proposed. A candidate only gets created if it passes a three-part test: a future session could act wrongly without the answer, the answer actually blocks or changes something concrete, and the answer isn't already recoverable from existing material. Candidates carry a stable ID, a state (`open`, `possible-answer`, `answered-awaiting-processing`, `superseded`, `withdrawn`), and metadata distinguishing an explicit answer from an inferred one — inference alone can never mark something answered.

One agent (Codex, in the original deployment) owns reconciliation: it reads every outbox, checks each candidate against admission criteria — still current, not already represented, not duplicative — and either promotes it into the single canonical queue or logs why not, in a receipt ledger keyed to the exact candidate version. That ledger means a candidate that hasn't materially changed is never re-litigated. The canonical queue itself sorts by actionability — answer now, waiting on an external event, later and dependent on something else — rather than a flat undifferentiated list.

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
