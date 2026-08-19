# M10 Hints

## Hint 1 — Diagnostic question

Which local invariant does each failing check protect, and which evidence location identifies the first broken boundary?

## Hint 2 — Concept

A complete synthetic run can prove reproducibility, internal state transitions, and local adapter behavior. It cannot prove external provider delivery, selected model behavior, Handoff integration, managed database controls, privacy approval, or production-owner approval.

## Hint 3 — Location

Inspect the M10 preflight output, complete harness result, scenario evidence identities, release manifest, and documented external-gate list.

## Hint 4 — Structure

Separate the capstone into full-run proof, one identity-linked scenario trace, invariant-based failure analysis, and an external evidence inventory. Keep every production category as an unresolved gate until its own evidence exists.

## Hint 5 — Pseudocode

Use this incomplete capstone outline:

```text
preflight local boundary [____]
run complete check [____]
trace event identity [____] to terminal evidence [____]
explain failed invariant [____]
list unresolved external categories [____]
```
