# M04 Hints

## Hint 1 — Diagnostic question

What stable identity can tell the system that two arrivals represent the same inbound event?

## Hint 2 — Concept

At a coat check, two attendants may reach for the same numbered ticket. The ticket number lets the desk decide that there is one claim, not two coats to release.

## Hint 3 — Location

Inspect the inbound-evidence storage introduced in M03 and the focused test that exercises duplicate or concurrent event delivery.

## Hint 4 — Structure

Choose a replay identity, enforce one logical record or action at the durable boundary, and map the losing concurrent attempt to a typed, deterministic result.

## Hint 5 — Pseudocode

Use a non-executable outline:

```text
receive event with identity [____]
attempt durable claim for [____]
if already claimed: return [typed ____]
otherwise: record [one logical ____]
```
