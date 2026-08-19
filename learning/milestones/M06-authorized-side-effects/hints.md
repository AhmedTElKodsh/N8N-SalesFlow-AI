# M06 Hints

## Hint 1 — Diagnostic question

What durable fact must exist before a worker is allowed to attempt an external effect?

## Hint 2 — Concept

A database transaction cannot include a remote provider call because the database controls only its own commit, while the remote system can succeed, fail, or time out independently. Think of two clerks with separate ledgers: neither can make both ledgers commit atomically.

## Hint 3 — Location

Inspect the learner branch where the governed decision becomes a persisted outbound intent and where the local adapter is invoked.

## Hint 4 — Structure

Separate durable intent creation from worker execution. Give one worker temporary ownership, recheck current authority immediately before the external attempt, reuse one stable remote request identity, and record the observed finish.

## Hint 5 — Pseudocode

Use this incomplete outline:

```text
persist approved intent [____]
claim with expiry [____]
recheck current authority [____]
call adapter with stable key [____]
record observed result [____]
```
