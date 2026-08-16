# M04 — Safe repetition

## Outcome

Duplicate and concurrent synthetic inbound events produce one logical action or a typed conflict.

## Why now

Networks can repeat requests and two requests can arrive together. The system must give a predictable result instead of silently doing work twice.

## Mental model

Imagine a ticket gate: the same ticket should admit one logical entry, even when two scanners see it at nearly the same time.

## New terms

- **Idempotency:** repeating a request has the same logical effect.
- **Uniqueness:** a rule that rejects duplicate identities.
- **Serialization:** arranging concurrent work into a safe order.

## Your task

Add behavior for one duplicated synthetic inbound event and one concurrent attempt so that the observable outcome is one logical action or a typed conflict. Before editing, predict what identity the system can use to recognize the replay. Make one focused change, then stop and share race-check evidence for review.

## Constraints

- M03 must be complete.
- Use deterministic synthetic events and focused race tests.
- Preserve the original inbound evidence; do not hide a conflict as success.
- Make conflict results typed and deterministic.
- Do not add provider retries, callbacks, or lease behavior.

## Check

Run the M04 focused checkpoint after duplicate and concurrent attempts have observable outcomes. It verifies replay handling, one logical action, and typed conflict behavior.

## Explain

Explain the event flow, the rule that prevents duplicate work, and one realistic race failure your design addresses.

## Transfer

Describe how the same rule would behave if a client repeated the event after a timeout, without introducing provider retry logic.
