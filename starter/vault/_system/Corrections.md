# Corrections

This is how a correction becomes a standing rule. The AI follows these steps; only the owner approves.

1. When the owner corrects you, add an entry below with the next three-digit ID (`C-001`, `C-002`, ...): the date, what you did, what the owner wanted instead, and a proposed rule in one sentence. Set the status to `proposed`. This change needs no approval. Commit it.
2. Show the owner the proposed wording. They may reword it, approve it, or reject it.
3. Only when the owner approves wording they have seen or written, copy it **exactly** into AGENTS.md under **Standing rules** as `- **R-<n>** (<date>, from C-<nnn>): <exact wording>`. Their approval of the wording is the approval for this edit; don't ask a second time. Commit it, and set the entry's status to `approved as R-<n>`.
4. There are at most 10 standing rules. To add an 11th, the owner retires one first.
5. A candidate that has not been approved within 14 days expires. Set its status to `expired` during the weekly review.
6. Never write a standing rule yourself, rephrase an approved one, or add a rule that makes you check less, question less or agree more.

## Entries

_None yet._

<!--
Entry format:

### C-001 (YYYY-MM-DD) - proposed
- What happened:
- What the owner wanted:
- Proposed rule:
-->
