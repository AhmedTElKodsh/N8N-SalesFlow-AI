# PostgreSQL Data Models

The `salesflow` schema contains 19 tables. Composite account keys are intentional: business records are scoped by `account_ref`, and runtime actors cannot cross that boundary.

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
| `contacts` | Internal Contact ID and channel reference |
| `consent_events` | Append-only granted/revoked evidence |
| `conversations` | Contact-owned lifecycle, automation owner, version, sequence, campaign state |
| `inbound_messages` | Provider-deduplicated inbound evidence and monotonic sequence |
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

- Unique `(account_ref, provider_id)` prevents duplicate inbound and outbound provider identities.
- Unique `(account_ref, conversation_id, seq)` enforces Conversation ordering.
- Unique `(account_ref, conversation_id, source_id, kind)` enforces one logical outbound action.
- Unique `(account_ref, source_id)` enforces one Handoff for an inbound source.
- Composite foreign keys preserve account ownership across Contact, Conversation, intent, Follow-Up, Handoff, and evidence rows.
- Callback status is monotonic; claims/leases must match and remain unexpired at finish time.
- Conversation lifecycle/owner and turn, intent, provider, Follow-Up, Handoff, deletion, and target states are constrained to the documented vocabulary at the database boundary.
- Authentication succeeds only for an unrevoked token whose expiry is still in the future; token history can be retained while use is disabled.
- Configuration content and identity are immutable. Only the activation command may change `active`, and every save or effective activation records its actor and database time.
- `release_pointers`, not a flag on immutable release history, is the only source for the currently active release.
- Audit and provider evidence are append-only, with a narrow deletion-mode exception that minimizes identifiers without rewriting the event identity/status/timestamp.

## Migration strategy

`database/001-initial.sql` creates roles, schema objects, triggers, functions, revocations, and runtime function grants. The canonical harness substitutes disposable role passwords and applies the migration twice to prove idempotence before n8n starts.
