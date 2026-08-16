# M00 Hints

## Hint 1 — Diagnostic question

After an n8n execution ends, which component must still be able to answer what inbound event was received?

## Hint 2 — Concept

Think about a restaurant: a waiter coordinates an order, while the receipt system retains the order record. The waiter is not the long-term record.

## Hint 3 — Location

Start with the repository root documentation, then locate the n8n workflow area and the PostgreSQL or database configuration area on the learner branch.

## Hint 4 — Structure

Draw three boxes: inbound event, coordinator, and durable ledger. Add one arrow for handoff and label who owns the stored fact.

## Hint 5 — Pseudocode

Use incomplete notes, not code:

```text
[synthetic event] -> [____ coordinates execution] -> [____ retains fact]
owner after execution: [____]
```
