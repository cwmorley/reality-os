# Reality OS runtime dispatcher (example)

This is a genericized version of the root dispatcher every cooperating AI session reads first. In the reference deployment, this file is under 1,000 tokens and is the only governance file loaded before the session resolves to a scope. Replace `Project Alpha` and the example paths with your own registered scopes and canonical anchors.

The dispatcher governs context loading; it is not an access-control mechanism. A tool may technically retain access to files outside the resolved bootstrap.

```markdown
# Vault runtime dispatcher

This vault is the durable system of record. Human Authority retains decision
authority. Current canonical state and direct evidence outrank AI proposals,
reviews, handoffs, working notes, generated packets, and outboxes. Do not
invent facts or authority. Fail closed when scope, target, ownership, or
evidence is ambiguous.

## Session resolution

This file is the sole active-area and router registry. Resolve each session in
this order: an explicit `vaultless` instruction; an explicit registered scope;
one unambiguous substantive match to an active scope below; broad, governance,
or cross-scope work; otherwise `unscoped-vault-aware`. A passing mention is not
a match. State the resolved mode when it changes.

`unscoped-vault-aware` is the default. Technical vault access may exist, but
load no named bootstrap, keep question routing off, and make no consequential
canonical write until the owning scope and target are resolved or the full
governance reference is loaded.

## Bounded retrieval

For a resolved named scope, load only its bootstrap. Treat `Path#H2` as exact:
read through the next H2. If the anchor is missing or ambiguous, report it and
do not silently load the whole file.

Expand only when:

- a loaded source points to needed unloaded evidence;
- facts conflict or look stale;
- the task affects authority, money, or another scope;
- the owner of a fact is unclear;
- the work is broad or audit-oriented; or
- answering would otherwise require guessing.

Name the trigger and load the narrowest resolving source.

## Active area registry

Add, pause, or change a persistent area only in this registry after validating
its anchors.

### Project Alpha

- Status: `active`
- Activation: `semantic-or-explicit`; only substantively Project Alpha work qualifies
- Context: `bounded`
- Question router: `active`
- Write policy: `governed`; use the compact path only when scope, ownership,
  target, evidence, and authority are explicit
- Bootstrap:
  - `Opportunities/Project Alpha.md#Current state`
  - `Opportunities/Project Alpha.md#Current decision and next trigger`
- Likely escalation:
  - `Opportunities/Project Alpha.md#Evidence log`
  - `Opportunities/Project Alpha.md#Key risks`
  - the linked decision note

## Broad work and writes

Read the full governance reference for whole-life, broad, cross-domain,
governance, audit, cold-recovery, structural, or high-stakes work. A routine
same-scope write may skip it only when scope, owner, target, evidence, and
implementation authority are explicit and no escalation trigger applies.

Before any consequential canonical write, follow the write-lock contract:
acquire the lock, confirm ownership again immediately before each file write,
reread the live target for freshness, and release the lock after verification.
```

## Why this shape

Two ideas do most of the work:

1. **Resolve before load.** The session selects a scope before loading domain content.
2. **Load by exact anchor, not by file.** `Note.md#Heading` identifies the registered section; a broken anchor fails closed.

The escalation list is the safety valve. Cooperating agents must name the trigger and report the expansion instead of drifting toward either extreme: guessing from too little context or routinely reloading everything.
