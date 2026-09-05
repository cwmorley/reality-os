# Contributing to Reality OS

Reality OS asks for independent review, a complexity budget, and targeted falsification before trusting mechanisms that affect durable state. Changes to this repository should apply the same practice without adding ceremony that no one will follow.

Every pull request must mark every change class that applies and meet every applicable verification bar. A primary class may be named for summary purposes, but it does not waive another bar.

## Change classes

### 1. Protocol or contract change

A change to required behavior, authority, state transitions, boundaries, mechanisms, or failure conditions is a protocol or contract change regardless of which file contains it. This normally includes `ARCHITECTURE.md` and `examples/`. The pull request must name a falsification test: the observation that would show the proposed behavior, boundary, or mechanism is wrong.

If the test was run, preserve and report the observed result. If it was not run, say so; `VALIDATION.md` must gain a corresponding **Specified—not yet empirically tested** row. Formatting, internal consistency, or reviewer agreement does not validate protocol behavior.

### 2. Validation record change

A semantic change to a test, run record, result, status, or disposition in `VALIDATION.md` is a validation record change. Adding or updating a result requires the run artifacts listed in **Recording future runs**: scope and date, contract revision, exact setup and task, clean-session or control conditions, loaded sources and measurement method, observed behavior, disposition, and any resulting reassessment. A purely editorial change must explicitly state that no validation meaning changed.

Record a failed or inconclusive result before revising the protocol or test. Do not promote a status beyond the evidence preserved with the run.

### 3. Documentation or framing change

A documentation or framing change alters explanatory prose without changing protocol or validation meaning. This normally includes `README.md` and `CONTRIBUTING.md`. It must state the intended reader outcome and how it was checked. The check should test comprehension or interpretation—for example, whether a cold reader can identify the problem, boundary, or next action—not merely whether the prose is clean.

Markdown rendering, link validity, and terminology consistency are necessary checks, but they do **not** satisfy this bar on their own.

## Independent review

Independent review means review by someone or some session that did not author the change. For a solo maintainer, this can be a separate AI session run adversarially against the diff. The reviewing session should look for overclaiming, missing falsification conditions, contradictory contracts, avoidable complexity, and evidence that does not support the stated status.

The pull request must record who or what reviewed it, what was challenged, and what changed as a result. A second pass by the authoring session is self-review, not independent review. Agreement between author and reviewer is not evidence of correctness; like restatements of one underlying source, it does not create independent empirical support.

## Self-merge

A solo maintainer may self-merge when obtaining independent review is disproportionate to the change or the cost of delay, provided the pull request says **`Independent review: none, self-merged`** and gives the reason. Self-merge does not waive the change-class verification bar, count as independent review, or turn specified behavior into validated behavior.

Use the pull request template. Keep the change and its evidence small enough to inspect.
