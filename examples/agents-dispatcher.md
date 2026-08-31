# Reality OS runtime dispatcher (example)

This is a genericized version of the root dispatcher file every agent session reads first. In the original deployment this file is under 1,000 tokens and is the *only* thing loaded before a session resolves to a scope — everything else is staged on demand. Replace `Project Alpha` with your own registered scopes.

```markdown
# Vault runtime dispatcher

This vault is the durable system of record. The vault owner retains decision
authority. Current canonical state and direct evidence outrank AI proposals,
reviews, handoffs, working notes, generated packets, and outboxes. Do not
invent facts or authority; default deny when scope, target, ownership, or
evidence is ambiguous.

## Session resolution

This file is the sole active-area and router registry. Resolve each session
in this order: an explicit `vaultless` instruction; an explicit registered
scope; one unambiguous substantive match to an active scope below; broad,
governance, or cross-scope work; otherwise `unscoped-vault-aware`. A passing
mention is not a match. State the resolved mode when it changes.

`unscoped-vault-aware` is the default. Technical vault access may exist, but
load no named bootstrap, keep question routing off, and make no consequential
canonical write until the owning scope and target are resolved or the full
governance reference is loaded.

## Bounded retrieval

For a resolved named scope, load only its bootstrap. Treat `Path#H2` as
exact: read through the next H2; if missing or ambiguous, report the broken
anchor and do not silently load the whole file. Expand only when a loaded
source points to needed unloaded evidence, facts conflict or look stale, the
task affects authority, money, or another scope, the owner of a fact is
unclear, the work is broad or audit, or answering would otherwise require
guessing. Name the trigger and load the narrowest resolving source.

## Active area registry

Add, pause, or change a persistent area only in this registry after
validating its anchors.

### Project Alpha

- Status: `active`
- Activation: `semantic-or-explicit`; only substantively Project Alpha work
  qualifies
  - Context: `bounded`
  - Question router: `active`
  - Write policy: `governed`; use the compact path only when scope, ownership,
    target, evidence, and authority are explicit
    - Bootstrap:
      - `Opportunities/Project Alpha.md#Current state`
        - `Opportunities/Project Alpha.md#Current decision and next trigger`
        - Likely escalation: `Project Alpha.md#Evidence log`,
          `Project Alpha.md#Key risks`, or the linked decision note

          ## Broad work and writes

          Read the full governance reference for whole-life, broad, cross-domain,
          governance, audit, cold-recovery, structural, or high-stakes work. A routine
          same-scope write may skip it only when scope, owner, target, evidence, and
          implementation authority are explicit and no escalation trigger applies.

          Before any consequential canonical write, follow the write-lock contract:
          acquire the lock, confirm ownership again immediately before each file
          write, re-read the live target for freshness, and release after verification.
          ```

          ## Why this shape

          Two ideas do almost all the work: **resolve before you load** (the session picks a scope before touching any content) and **load by exact anchor, not by file** (`Note.md#Heading`, read through the next heading, nothing more). Everything else in this file exists to keep bounded loading from becoming silent blindness — the escalation-trigger list is the safety valve, and it only works if agents actually name the trigger and report the expansion instead of quietly reverting to either extreme (guessing, or reloading everything).
