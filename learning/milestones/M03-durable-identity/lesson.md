# M03 — Durable identity

## Outcome

Synthetic account-scoped contacts, conversations, and inbound messages persist with foreign-key relationships.

## Why now

The first slice proved one path. Now the database needs enough identity structure to keep related facts from different accounts separate.

## Mental model

Think of the database as linked index cards: each card has its own identity and a reference to the card it belongs with.

## New terms

- **Primary key:** a stable identity for one record.
- **Foreign key:** a checked reference to another record.
- **Tenant scope:** the account boundary for a record.

## Your task

Add the next migration and persist one synthetic inbound message through its account, contact, and conversation relationships. Before changing the schema, predict which relationship prevents a message from belonging to an account that does not exist. Make one schema-or-path change, then stop and share the focused evidence for review.

## Constraints

- M02 must be complete.
- Keep every example synthetic and local.
- Preserve immutable inbound evidence after it is stored.
- Scope contacts, conversations, and messages to an account.
- Do not implement replay races, leases, or later delivery behavior.

## Check

Run the M03 focused checkpoint after the related records persist. It verifies account scope, foreign-key relationships, and immutable inbound evidence.

## Explain

Explain the persistence flow, why one relationship uses a foreign key, and one failure mode that account scope prevents.

## Transfer

Given a second synthetic account with a similar contact identifier, explain how your structure keeps its conversation separate from the first account’s conversation.
