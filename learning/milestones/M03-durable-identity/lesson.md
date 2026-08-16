# M03 — Durable identity

## Outcome

Synthetic account-scoped contacts, conversations, and inbound messages persist through migrations with primary keys, foreign keys, composite account scope, and immutable inbound evidence.

## Why now

The first slice proved one path. Now the database needs identity structure that keeps related facts from different accounts separate.

## Mental model

The database is a set of linked index cards: each card has an identity and checked links to the cards it belongs with.

## New terms

- **Primary key:** a stable identity for one record.
- **Foreign key:** a checked reference to another record.
- **Composite account scope:** a record identity or relationship that includes its account boundary.

## Your task

M02 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.
At each stage, begin the teaching exchange with one mental model and at most three new terms.

### Stage 1 — Prediction

**One action:** State which relationship should reject a conversation whose account does not exist.

**Wait:** Stop and inspect the prediction before discussing the migration.

### Stage 2 — Schema location

**One action:** Identify the next migration location on the learner branch.

**Wait:** Stop and inspect the location before asking for a schema change.

### Stage 3 — Account

**Mental model:** The account is the outer folder for every later record.

**One action:** Make one change that persists the account record.

**Wait:** Stop and inspect the working diff before asking about a contact.

### Stage 4 — Contact

**Mental model:** A contact belongs inside one account folder.

**One action:** Make one change that persists an account-scoped contact record.

**Wait:** Stop and inspect the diff before asking about a conversation.

### Stage 5 — Conversation

**Mental model:** A conversation links related messages.

**One action:** Make one change that persists a conversation through its required foreign key.

**Wait:** Stop and inspect the diff before asking about an inbound message.

### Stage 6 — Inbound message

**Mental model:** An inbound message is evidence attached to its conversation.

**One action:** Make one change that persists an inbound message through its required foreign key.

**Wait:** Stop and inspect the diff before discussing immutability.

### Stage 7 — Immutable evidence

**Mental model:** Evidence should not be rewritten after it is recorded.

**One action:** Make one change that prevents normal persistence from replacing stored inbound evidence.

**Wait:** Stop and inspect the diff before running the focused check.

### Stage 8 — Evidence

**Mental model:** A focused check is evidence about one milestone boundary.

**One action:** Run the M03 focused check.

**Wait:** Stop and inspect the result before advancing.

## Constraints

- Keep every example synthetic and local.
- Account, contact, conversation, and inbound message links must retain composite account scope.
- Preserve immutable inbound evidence: after storage, the normal persistence path must not replace its received content or identity.
- Do not implement replay races, leases, or delivery behavior.

## Check

The M03 focused checkpoint verifies composite account scope, foreign-key records, and immutable inbound evidence.

## Explain

Explain the persistence flow, why a relationship uses a foreign key, and one failure that composite account scope prevents.

## Transfer

Given a second synthetic account with the same contact reference, explain how the composite account scope keeps its conversation separate.
