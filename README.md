# Reality OS

**A serverless, file-based governance architecture that lets multiple independent AI systems collaborate safely on one knowledge base — with no framework, no database, and no shared runtime.**

Reality OS started as a personal operating system for one person's knowledge base, built entirely in Markdown inside Obsidian. This repo documents the coordination architecture it converged on: how several independent AI products (in the original deployment, Claude, OpenAI's Codex, ChatGPT, and Gemini) read from and write to one shared file store without a database, an orchestration framework, or a background service — and without stepping on each other.

It's a pattern, not a product. Nothing here requires Obsidian specifically; it requires a shared filesystem and AI sessions willing to read a contract file before they act.

## What's in here

- **[`ARCHITECTURE.md`](./ARCHITECTURE.md)** — the full write-up: bounded, anchor-based context loading (with the empirical before/after numbers, and why the design deliberately keeps the *routine* case cheap rather than minimizing tokens uniformly), the cooperative write lock, cross-agent question routing and reconciliation (the capture filter that keeps the queue from becoming noise, and the inference rule that stops an AI's confident guess from quietly becoming treated as settled fact), epistemic discipline, and an honest account of where the system's own rules were tested and where they slipped.
- - **[`examples/`](./examples/)** — genericized, working templates of the actual governance files: the runtime dispatcher, the write-lock contract and state file, the question-outbox contract, and the canonical-queue format. These are the real mechanism with a placeholder scope substituted for the original's live personal and business content.
 
  - ## Why this exists
 
  - Every multi-agent AI system runs into the same handful of problems: agents overwrite each other's work, agents burn enormous context loading files they don't need, agents propose duplicate or stale changes, and one agent's confident interpretation quietly becomes another agent's assumed fact. Reality OS solves each of these with a written convention instead of code — and, critically, doesn't trust a convention just because it sounds right. Every mechanism here was validated with an empirical before/after test before being adopted, including a documented case where that discipline wasn't applied consistently and the resulting gap was caught and named rather than smoothed over.
 
  - That validate-before-trust practice — not the file format — is the actual point.
 
  - ## Status
 
  - This is a working architecture extracted from a live personal deployment, not a packaged tool. Adopting it means writing your own contract files following the patterns in `examples/`, pointed at your own vault or repo.
