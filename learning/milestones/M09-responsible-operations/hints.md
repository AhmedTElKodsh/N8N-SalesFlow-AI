# M09 Hints

## Hint 1 — Diagnostic question

Which duties can be proven by an observed state change, and which are currently only configuration claims?

## Hint 2 — Concept

A configured retention value describes when data should expire; it does not prove that an enforced purge selected eligible records, removed or minimized them, and recorded a non-sensitive result.

## Hint 3 — Location

Inspect the learner branch's operational evidence records, deletion path, age-based purge entry point, exported artifacts, release selector, and alert assertions.

## Hint 4 — Structure

Carry one non-secret trace identity, store purpose-limited facts, execute deletion and age-based removal, verify sensitive values stay outside artifacts, identify release changes, and bind alerts to actionable evidence.

## Hint 5 — Pseudocode

Use this incomplete operations outline:

```text
trace request by [____]
retain only purpose-required [____]
purge records older than [____]
record non-sensitive result [____]
activate reviewed release [____]
alert when condition [____]
```
