# M03 — Durable identity

## Outcome

Four related synthetic record types persist through a versioned database change, retain their ownership boundary, reject invalid relationships, and preserve the original received evidence.

## Why now

The first slice proved one path. Now the database needs identity structure that keeps related facts from different owners separate.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M02 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** A checked link refuses to point at a parent card that does not exist.

**New terms:**
- **Foreign key:** a database rule requiring a referenced parent record to exist.

**One action:** State which foreign key behavior should reject a child record whose parent record does not exist.

**Wait:** Stop and inspect the prediction before discussing schema files.

### Stage 2 — Schema location

**Mental model:** A numbered change log tells the database where its next structural step belongs.

**New terms:**
- **Migration:** a versioned artifact that changes database structure in a repeatable order.

**One action:** Identify the location for the next migration on the learner branch.

**Wait:** Stop and inspect the location before asking for a new artifact.

### Stage 3 — Migration

**Mental model:** An empty numbered form establishes one reviewable place for the next structural changes.

**New terms:** None.

**One action:** Create one new migration artifact at the reviewed location.

**Wait:** Stop and inspect the new migration diff before defining any record.

### Stage 4 — Account

**Mental model:** An account is an outer folder with its own stable label.

**New terms:**
- **Account:** the outer ownership record for the related synthetic data.
- **Primary key:** a stable identity for one record.

**One action:** Make one change in the migration that defines the account record with its primary key.

**Wait:** Stop and inspect the diff before defining the next child record.

### Stage 5 — Contact

**Mental model:** A contact card belongs inside one account folder, even when another folder uses the same local label.

**New terms:**
- **Contact:** an account-owned record for one synthetic person or endpoint.
- **Composite account scope:** an identity or relationship that includes its account boundary.

**One action:** Make one change that defines the contact record with composite account scope.

**Wait:** Stop and inspect the diff before defining the grouping record.

### Stage 6 — Conversation

**Mental model:** A conversation is a thread filed under both its contact and its account.

**New terms:**
- **Conversation:** an account-owned record grouping related messages.

**One action:** Make one change that defines the conversation record with its required foreign key and account scope.

**Wait:** Stop and inspect the diff before defining the received-event record.

### Stage 7 — Inbound message

**Mental model:** An inbound message is one received card attached to the correct conversation thread.

**New terms:**
- **Inbound message:** the persisted evidence of one received event.

**One action:** Make one change that defines the inbound message record with its required foreign key and account scope.

**Wait:** Stop and inspect the diff before discussing evidence preservation.

### Stage 8 — Immutable evidence

**Mental model:** A received evidence card may be referenced later but not rewritten as if different content arrived.

**New terms:**
- **Immutable inbound evidence:** received identity and content that the normal persistence path cannot replace after storage.

**One action:** Make one change that prevents normal persistence from replacing immutable inbound evidence.

**Wait:** Stop and inspect the diff before running the focused check.

### Stage 9 — Evidence

**Mental model:** A focused check is a receipt for the complete identity chain.

**New terms:** None.

**One action:** Run the M03 focused check.

**Wait:** Stop and inspect the result before advancing.

## Constraints

- Keep every example synthetic and local.
- Account, contact, conversation, and inbound message links must retain composite account scope.
- Preserve immutable inbound evidence: the normal persistence path must not replace its received content or identity after storage.
- Do not implement replay races, leases, or delivery behavior.

## Check

The M03 focused checkpoint verifies the migration, every required record, composite account scope, foreign-key relationships, and immutable inbound evidence.

## Explain

Explain the persistence flow, why a relationship uses a foreign key, and one failure that composite account scope prevents.

## Transfer

Given a second synthetic account with the same contact reference, explain how the account boundary keeps its conversation separate.
