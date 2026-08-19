# M07 Hints

## Hint 1 — Diagnostic question

Which failures are proven temporary, and which outcomes are uncertain enough that another attempt could duplicate the effect?

## Hint 2 — Concept

A retry policy is like a call schedule with a maximum number of attempts and increasing pauses. A missing answer is different from proof that the previous call failed.

## Hint 3 — Location

Inspect the persisted attempt state, callback transition boundary, claim-expiry comparison, and synthetic adapter lookup on the learner branch.

## Hint 4 — Structure

Classify retryable failures, compute the next eligible time within a fixed limit, reject backward callback transitions, recover only elapsed claims, and compare uncertain work with external observations.

## Hint 5 — Pseudocode

Use this incomplete recovery sketch:

```text
if failure is [retryable ____] and attempts below [____]: schedule [later ____]
if callback advances [____]: store it
if claim expired [____]: make eligible
if outcome uncertain [____]: compare by stable identity
```
