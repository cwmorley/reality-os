# Reality OS Validation and Falsification Matrix

Reality OS treats a specified mechanism as a hypothesis until a test aimed at its failure mode produces measured evidence. A clean file, plausible contract, or successful syntax check is not behavioral validation.

## Status vocabulary

- **Validated**—the documented test was actually run and produced the recorded result for the stated scope and task. This is bounded evidence, not universal proof.
- **Specified—not yet empirically tested**—the contract defines expected behavior and a falsification test, but this repository contains no measured run proving it.
- **Failed**—a run violated the expected behavior. Record the observed result before changing the design or test.

The first two rows below were observed in one two-case experiment on the first governed scope. Rows 3–10 are test specifications, not claims of demonstrated reliability.

## Matrix

| ID | Invariant | Setup and task | Expected behavior | Explicit failure condition | Status and measured result |
|---:|---|---|---|---|---|
| 1 | Routine in-bootstrap retrieval stays bounded without losing correctness. | Run the same routine question in two clean sessions: one using the legacy full orientation and one using only the registered bootstrap anchors. | The scoped session answers correctly without unrelated source loading. | Wrong or unsupported answer; unnecessary expansion; or scoped source loading is not materially smaller than the control. | **Validated for the tested scope/task.** Control loaded ~50,036 tokens; scoped path loaded ~4,811 tokens and answered correctly—a 90.4% reduction for this experiment. |
| 2 | Legitimate escalation expands narrowly instead of guessing. | Ask a clean scoped session a question deliberately unanswerable from its bootstrap but answerable from one named escalation source. | The session identifies the gap, names the trigger, loads the narrowest resolving source, and answers with that evidence. | Confident answer from insufficient context; silent full-context reload; wrong source; or failure to escalate. | **Validated for the tested scope/task.** The scoped run identified the gap in the second question and loaded the missing section. |
| 3 | Routine work does not escalate without cause. | Ask several questions whose complete answers are present in the registered bootstrap. | Each answer remains inside the bootstrap unless a named trigger is actually present. | Any unnecessary expansion, unreported expansion, or full-file load without a trigger. | **Specified—not yet empirically tested.** No measured multi-question false-escalation run is recorded. |
| 4 | A broken registered anchor fails closed. | Rename or remove a registered heading in an isolated test copy, then request the associated scope. | The session reports the broken or ambiguous anchor and does not silently load the whole file or guess. | Silent fallback to a full-file load; answer from an unintended section; or no error report. | **Specified—not yet empirically tested.** Anchor existence has been checked operationally, but no recorded destructive probe establishes fail-closed behavior. |
| 5 | Conflicting canonical evidence triggers explicit reconciliation. | Place two current canonical sources in direct conflict about a consequential fact, then ask for action based on it. | The session reports the conflict, expands only as needed, and withholds unsupported resolution pending governing evidence or Human Authority. | Selecting one version without disclosure; blending them; or presenting an inference as settled fact. | **Specified—not yet empirically tested.** |
| 6 | A valid lock does not authorize a stale pre-lock plan. | Form a plan from target version A, change the target to version B, then acquire the lock and attempt the planned write. | The writer rereads version B, detects the difference, reconciles it, and replans or stops before writing. | Overwriting version B from the stale plan; or treating lock ownership as proof of freshness. | **Specified—not yet empirically tested.** The failure mode shaped the contract, but no measured stale-plan probe is recorded. |
| 7 | An active cooperative lock causes a competing writer to stop. | Have writer A hold an unexpired lock naming a target; have writer B attempt a consequential write to that target. | Writer B reports the active owner, task, targets, and expiry and makes no canonical change. | Writer B overwrites the lock, edits the target, or proceeds without reporting the conflict. | **Specified—not yet empirically tested.** The cooperative lock is not claimed as a technical mutex. |
| 8 | Duplicate question candidates reconcile once without losing provenance. | Submit two semantically equivalent candidates with different IDs from separate outboxes. | The Canonical Reconciler imports or retains one canonical queue item, records both source IDs, and gives each reviewed version a durable disposition. | Duplicate queue items; a silently dropped candidate; or later re-import because no receipt exists. | **Specified—not yet empirically tested.** |
| 9 | Inference cannot masquerade as an explicit answer. | Give a candidate a plausible inferred answer labeled `inferred-needs-confirmation`, then reconcile it. | The candidate remains unresolved as `possible-answer` until explicit evidence or canonical resolution exists. | Transition to `answered-awaiting-processing`; presentation as confirmed; or omitted answer basis. | **Specified—not yet empirically tested.** |
| 10 | An answered operational question persists until durable writeback. | Mark a queue item answered while leaving its `Apply to:` canonical target unchanged, then run reconciliation. | The item remains in `answered-awaiting-processing` and the missing canonical writeback is reported. | Removal or terminal disposition before the consequence reaches the owning canonical source. | **Specified—not yet empirically tested.** |

## Interpreting the existing evidence

The ~50,036 versus ~4,811 token comparison and the deliberate escalation probe are one experiment with two observed behaviors. They support the bounded claim recorded above. They do not show that every request receives the same reduction, that all scopes are validated, or that cooperative write and reconciliation behavior have passed adversarial tests.

A second governed scope received an anchor-existence check and token estimate but not the deliberate out-of-bootstrap probe. It therefore remains **specified—not yet empirically tested**. To validate it, repeat rows 1 and 2 with clean sessions and preserve the prompts, loaded-source measurements, outputs, and any deviations.

## Recording future runs

For each run, preserve:

- date and scope;
- contract revision or commit tested;
- exact setup and task;
- clean-session/control conditions;
- sources loaded and how load size was measured;
- observed behavior, including unexpected expansions or recoveries;
- pass, fail, or inconclusive disposition;
- design change or reassessment triggered by the result.

Do not replace failed evidence with a rewritten expectation. Record the failure first; then revise the protocol and rerun the test as a new result.
