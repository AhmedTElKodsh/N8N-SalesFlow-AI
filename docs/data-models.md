# PostgreSQL Data Models

The `salesflow` schema contains 32 tables. Composite account keys are intentional: business records are scoped by `account_ref`, and runtime actors cannot cross that boundary.

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
| `intents` | Unique customer actions, authorization versions, minimized response-context provenance, lease/retry/provider state; historical acknowledgement kinds remain readable but cannot send while Human-Owned |
| `intent_transitions` | Append-only intent state changes |
| `provider_calls` | One durable call-start per logical intent, with stable provider/correlation identity and lease/attempt/release evidence |
| `provider_call_events` | Append-only call lifecycle evidence: started, accepted, failed, ambiguous, reconciliation-required, or reconciled |
| `provider_events` | Idempotent provider callback evidence |
| `followups` | Durable +12-hour jobs with immutable source/release/consent/campaign/template evidence, claims, retries, parent state, and one created intent reference |
| `followup_transitions` | Append-only parent state changes and exact cancellation/denial reasons |
| `followup_busy_events` | Parent-independent evidence that a scheduler candidate was skipped because its Conversation/authority or row was busy |
| `reconciliation_busy_events` | Append-only typed evidence that expired-call reconciliation skipped a busy authority or row |
| `scheduler_cursors` | Durable due, reconciliation, and all-work high-water/wrap progress across bounded scheduler invocations |
| `handoffs` | Human transfer work, evidence, queue/deadline, claims, retries, and the durable reason for terminal authority suppression |
| `handoff_summaries` | One immutable evidence-grounded snapshot per Handoff, with credential-free Conversation destination |
| `handoff_notification_attempts` | Append-only claim-bound attempt evidence; known starts prevent duplicate exposure, and legacy unknown start times require reconciliation |
| `handoff_notification_events` | Append-only adapter outcome, authority-change, retry, final-failure, and exhaustion evidence; contraction exhaustion has a null adapter outcome |

## Operations, privacy, and release

| Table | Purpose |
| --- | --- |
| `deletion_requests` | Contact deletion lifecycle |
| `deletion_targets` | Per-record deletion/minimization evidence |
| `releases` | Immutable manifest-backed release history; rows do not carry active authority |
| `release_pointers` | The single authoritative active-release reference per account |
| `audit_events` | Append-only operator/runtime decision evidence |
| `operational_failures` | Append-only, audit-retention-governed failure/retry projection with stable account-keyset page IDs, nullable known occurrence time, separate observation time, and manual-action status |
| `activity_backfill_markers` | Content-free migration markers that prevent retained-away legacy activity from being recreated on migration replay |
| `failure_backfill_markers` | Content-free migration markers that prevent retained-away legacy failure projections from being recreated on migration replay |

## Critical constraints

- A retained SHA-256 identity fingerprint with unique `(account_ref, channel, provider, external_ref_hash)` prevents a current, retired, or plaintext-minimized Contact Identifier from ever mapping ambiguously to another Customer. This is pseudonymous retained identity evidence, not anonymization; its purpose is reuse rejection and ambiguity prevention after plaintext minimization.
- Unique `(account_ref, provider_id)` prevents duplicate inbound and outbound provider identities. Inbound retry equality additionally requires the exact original sender and original body; `processing_body` never controls deduplication.
- PostgreSQL assigns each inbound message a positive sequence while locking its Conversation; unique `(account_ref, conversation_id, seq)` and immutable order keys enforce canonical durable-intake order independently of provider timestamps.
- `inbound_messages.body` preserves the original text and `body_hash` hashes that exact evidence. `processing_body` applies only Unicode NFC, newline canonicalization, and outer trimming for the model-driving path, with a database check requiring it to equal `normalize_inbound_body(body)`. Both forms, provider time, identity, and order are immutable except that the database deletion command may replace both text forms and the sender with `[deleted]` while retaining event identity and order.
- Unique `(account_ref, conversation_id, source_id, kind)` enforces one logical outbound action.
- Primary key `(account_ref, intent_id)` on `provider_calls` enforces at most one automatic provider-call start per logical intent. The final current-state authorization check and this insert occur in one transaction while holding the Contact/Conversation rows and matching consent/config/control locks; only the newly inserted call may reach the adapter.
- Frequency limits count durable provider-call starts, including in-flight and uncertain calls. The final gate serializes those reservations per Contact, so concurrent intents cannot consume the same remaining frequency slot.
- An expired lease is retryable only when no provider-call row exists. Once a call-start exists, missing or ambiguous completion moves the intent to `reconciliation_required`; a matching callback may resolve it without another send.
- Unique `(account_ref, source_id)` enforces one Handoff for an inbound source.
- Summary identity is unique by both account/Handoff and account/source message. New summaries are inserted in the same transaction that changes ownership and creates Handoff work; retries and config rotations cannot rewrite them. Controlled privacy deletion and authorized retention expiry may replace only retained excerpts with `[deleted]` while preserving evidence identifiers and operational fields.
- Conversation history is exposed only through a security-definer function that authenticates a current operator, derives account scope from its token, and refuses deleted or missing Conversations. The stored URL contains only the Conversation UUID, so raw account identifiers never require URL encoding. Returned messages use the database sequence, not provider time.
- Unique source-intent and action keys make sent-completion replay create at most one Follow-Up. A partial unique index permits at most one pre-call active Follow-Up per Conversation, while a newer sent reply can supersede only an older active job and can never overwrite a cancelled job.
- A Follow-Up request hash binds the source reply, action key, exact due time, expected and source Conversation versions, Release Set and business versions, consent timestamp/hash, template key/reference, correlation ID, generation, and campaign snapshot. The +12-hour due time is anchored to the durable database send transition rather than a provider-reported timestamp. The active synthetic template must match key/provider identity `followup-en`, category `marketing`, and language `en` at scheduling and due/final authorization. Due, claim, and provider-call start use current database time and re-evaluate current authority, including the current active WhatsApp/Meta identifier; provider-call `started_at` is written with `clock_timestamp()`, and rolling frequency is intentionally evaluated at due/start rather than frozen at scheduling.
- Follow-Up parent transitions occur before child suppression, provider-call exposure, or terminal completion in the same transaction. Terminal parents are append-only; `sent` may advance only to `delivered` or `failed`. A missing parent suppresses an orphan child, pre-call retry exhaustion suppresses without false reconciliation, and a provider call cannot coexist with a parent left at `intent_created`.
- Scheduler probes use `pg_try_advisory_xact_lock` in a rollbackable subtransaction and row `NOWAIT`; busy evidence has no parent foreign key so recording it never waits on the row it describes. Keyset traversal has no fixed candidate prefix, exits voluntarily after four seconds under a larger safety timeout, and caps the final work projection at 50. Pending Follow-Up intents are projected only while their parent is `intent_created`, preventing a retry child from bypassing parent scheduling.
- Composite foreign keys preserve account ownership across Contact, Conversation, intent, Follow-Up, Handoff, and evidence rows.
- Reply-intent provenance records the latest granted consent timestamp/status/evidence hash, the active Release Set version, the exact active Product Knowledge and Sales Policy versions named by that Release Set, source inbound ID, Conversation version, and bounded ordered inbound references. The history slice is restricted to the same account and Conversation, at or before the source sequence, with a ten-message and 32-KiB processing-text limit; non-fitting predecessors are skipped, and message text is used ephemerally but not duplicated into provenance. Intent identity, source, expected/business versions, body, and provenance cannot be updated or deleted ordinarily; controlled privacy deletion may replace only the body/provenance evidence with minimized values while operational delivery fields remain mutable.
- Consent publication and response-context assembly share an account/Contact advisory lock. This makes the context snapshot linearizable with a concurrent grant or revocation while the independent pre-send gate still evaluates the latest state.
- Callback events are immutable and derived status is monotonic. Provider completion must match the durable call-start lease; terminal replay is idempotent, while post-start retryable/uncertain outcomes cannot create a second call. Callback lookup uses a retained opaque alias derived only from the original provider ID; migration never derives aliases from `deleted-*` tombstones, direct tombstone lookup is rejected, and privacy deletion preserves the original payload fingerprint for exact replay.
- Conversation lifecycle and ownership are orthogonal. The constrained `ai|human` storage values mean AI-Owned and Human-Owned; turn, intent, provider, Follow-Up, Handoff, deletion, and target states use their own constrained vocabularies.
- Authentication succeeds only for an unrevoked token whose expiry is still in the future; token history can be retained while use is disabled.
- Configuration content and identity are immutable. Only the activation command may change `active`, and every save or effective activation records its actor and database time. Product Knowledge and Sales Policy can be activated independently, but AI context preparation fails closed until the active Release Set names the exact active pair.
- `release_pointers`, not a flag on immutable release history, is the only source for the currently active release.
- Contact deletion tracks and minimizes active and retired Contact Identifiers, both inbound message forms, intent bodies/provenance, and provider evidence. Audit and provider evidence remain append-only, with a narrow deletion-mode exception that minimizes customer data without rewriting event identity/status/timestamp.

## Migration strategy

`database/001-initial.sql` creates roles, schema objects, triggers, functions, revocations, and runtime function grants in one transaction. Follow-Up transition storage and duplicate/unverifiable cleanup precede all identity and active uniqueness indexes. Invalid or duplicate active jobs become `legacy_unverifiable` with immutable migration transitions; a legitimate terminal outcome is preserved while only its losing duplicate source/action identities are cleared so index creation cannot rewrite historical delivery truth. Existing send and Handoff-notification evidence is idempotently projected into activity during upgrade; a Handoff lacking historical transition time receives a clearly labeled current-state observation rather than an invented action time. The canonical harness substitutes disposable role passwords, proves that partial-upgrade fixture twice, proves rollback on injected failure, and applies the full migration twice before n8n starts. A narrowly granted account-management command authenticates an unexpired operator token even while its own account is disabled, allowing only the explicit enabled-state change; other disabled-account commands remain unavailable.
