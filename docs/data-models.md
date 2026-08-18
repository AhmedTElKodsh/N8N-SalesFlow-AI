# PostgreSQL Data Models

The `salesflow` schema contains 20 tables. Composite account keys are intentional: business records are scoped by `account_ref`, and runtime actors cannot cross that boundary.

## Account and configuration

| Table | Purpose |
| --- | --- |
| `accounts` | Account identity and global enabled state |
| `config_docs` | Immutable versioned configuration with one active version per kind |
| `controls` | Account operational controls such as global stop |
| `auth_tokens` | Hashed role/account/actor bindings with expiry and revocation timestamps |

## Contact and Conversation

| Table | Purpose |
| --- | --- |
| `contacts` | Stable internal Customer record, named Contact in the canonical database vocabulary |
| `contact_identifiers` | UUID-backed channel/provider references linked to a Contact; retired references remain non-resolvable history |
| `consent_events` | Append-only granted/revoked evidence |
| `conversations` | Contact-owned lifecycle, automation owner, version, sequence, campaign state |
| `inbound_messages` | Immutable original inbound evidence, deterministic processing text, provider timestamp, and database-assigned monotonic sequence |
| `turns` | Claimable orchestration work for each inbound message |

## Outbound and external evidence

| Table | Purpose |
| --- | --- |
| `intents` | Unique customer/Handoff acknowledgement actions, authorization versions, lease/retry/provider state |
| `intent_transitions` | Append-only intent state changes |
| `provider_events` | Idempotent provider callback evidence |
| `followups` | Durable UTC due jobs, claims, retries, and created intent reference |
| `handoffs` | Human transfer work, evidence, queue/deadline, claims, retries |

## Operations, privacy, and release

| Table | Purpose |
| --- | --- |
| `deletion_requests` | Contact deletion lifecycle |
| `deletion_targets` | Per-record deletion/minimization evidence |
| `releases` | Immutable manifest-backed release history; rows do not carry active authority |
| `release_pointers` | The single authoritative active-release reference per account |
| `audit_events` | Append-only operator/runtime decision evidence |

## Critical constraints

- A retained SHA-256 identity fingerprint with unique `(account_ref, channel, provider, external_ref_hash)` prevents a current, retired, or plaintext-minimized Contact Identifier from ever mapping ambiguously to another Customer. This is pseudonymous retained identity evidence, not anonymization; its purpose is reuse rejection and ambiguity prevention after plaintext minimization.
- Unique `(account_ref, provider_id)` prevents duplicate inbound and outbound provider identities. Inbound retry equality additionally requires the exact original sender and original body; `processing_body` never controls deduplication.
- PostgreSQL assigns each inbound message a positive sequence while locking its Conversation; unique `(account_ref, conversation_id, seq)` and immutable order keys enforce canonical durable-intake order independently of provider timestamps.
- `inbound_messages.body` preserves the original text and `body_hash` hashes that exact evidence. `processing_body` applies only Unicode NFC, newline canonicalization, and outer trimming for the model-driving path, with a database check requiring it to equal `normalize_inbound_body(body)`. Both forms, provider time, identity, and order are immutable except that the database deletion command may replace both text forms and the sender with `[deleted]` while retaining event identity and order.
- Unique `(account_ref, conversation_id, source_id, kind)` enforces one logical outbound action.
- Unique `(account_ref, source_id)` enforces one Handoff for an inbound source.
- Composite foreign keys preserve account ownership across Contact, Conversation, intent, Follow-Up, Handoff, and evidence rows.
- Callback status is monotonic; claims/leases must match and remain unexpired at finish time.
- Conversation lifecycle and ownership are orthogonal. The constrained `ai|human` storage values mean AI-Owned and Human-Owned; turn, intent, provider, Follow-Up, Handoff, deletion, and target states use their own constrained vocabularies.
- Authentication succeeds only for an unrevoked token whose expiry is still in the future; token history can be retained while use is disabled.
- Configuration content and identity are immutable. Only the activation command may change `active`, and every save or effective activation records its actor and database time.
- `release_pointers`, not a flag on immutable release history, is the only source for the currently active release.
- Contact deletion tracks and minimizes active and retired Contact Identifiers as well as both inbound message forms and provider evidence. Audit and provider evidence remain append-only, with a narrow deletion-mode exception that minimizes identifiers without rewriting event identity/status/timestamp.

## Migration strategy

`database/001-initial.sql` creates roles, schema objects, triggers, functions, revocations, and runtime function grants in one transaction. The canonical harness substitutes disposable role passwords, proves legacy upgrade preservation and rollback on injected failure, and applies the migration twice before n8n starts.
