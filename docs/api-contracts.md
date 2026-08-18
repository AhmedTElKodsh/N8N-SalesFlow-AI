# Local Webhook Contracts

These are **synthetic-local/test interfaces**, not production Meta or CRM contracts. Each uses the active n8n webhook base plus the path below and an `x-salesflow-token` header unless invoked internally by Execute Workflow.

| Method | n8n path | Purpose | Minimum body |
| --- | --- | --- | --- |
| POST | `salesflow/inbound` | Normalize and persist inbound customer text | `account_ref`, `provider_id`, `contact_ref`, `body`; optional `received_at` |
| POST | `salesflow/test/whatsapp-intake` | Local-only WhatsApp-shaped staging intake; `x-hub-signature-256` HMAC required | WhatsApp-shaped text envelope; generated test identities only |
| POST | `salesflow/dispatch` | Test entry to outbox claim/dispatch | `work_id`; optional `account_ref` |
| POST | `salesflow/status` | Reconcile provider status | `account_ref`, `event_id`, `provider_id`, `status`, `provider_time` |
| POST | `salesflow/followups` | Authenticated test trigger for scheduler logic | No business body required |
| POST | `salesflow/handoff` | Test entry to Handoff claim/dispatch | `work_id`; optional `account_ref` |
| POST | `salesflow/operations` | Account-bound operator command | Action-specific object |

There are seven distinct local webhook paths; the eighth runtime entry is the UTC Schedule Trigger.

## Inbound behavior

`salesflow.ingest` authenticates the runtime actor, enforces account scope, requires an object with string `account_ref`, `provider_id`, `contact_ref`, and `body` fields plus a string `received_at` when supplied, and rejects whitespace-only provider/sender identities. The raw 8,192-byte body limit is enforced before normalization. The original `body` and its SHA-256 hash are then stored as immutable evidence. `processing_body` is derived deterministically by Unicode NFC normalization, CRLF/CR-to-LF conversion, and outer-whitespace trimming only. Internal whitespace, line breaks, case, punctuation, and meaning are otherwise preserved; a message that is empty after this processing is rejected. Signal matching uses a separate lowercase, whitespace-collapsed comparison value and does not alter either stored form.

Provider IDs are unique within an account. A replay is accepted as an idempotent retry only when its original sender and original body exactly match the first delivery; cleaned text is never used for equality. Reusing the provider ID with a different sender or body returns `idempotency_conflict`, preserves the first message, and appends minimized conflict evidence without sender or message text. PostgreSQL atomically creates one database-assigned Conversation sequence and one Turn with each new message. Only a committed result with `accepted=true` and `created=true` may start sequence-ordered orchestration; retries and conflicts create no Turn or downstream work.

The signed test WhatsApp intake is localhost-only and uses generated test credentials; it has no live Meta/WhatsApp account or public registration. It verifies raw-byte HMAC, stages supported text messages without starting orchestration or other downstream work, and atomically rejects malformed, oversized, or identity-invalid envelopes. Supported text messages are processed independently of unsupported sibling changes in a valid envelope; an envelope containing no supported text is acknowledged without creating business work.

A delivery addressed to a retired Contact Identifier is terminal: it creates no message or downstream work, records minimized rejection evidence, and returns HTTP `410` so the provider is not instructed to retry a permanently non-resolvable reference. Other authenticated validation rejections are also audited without sender or text.

## Response-context behavior

Before the synthetic AI path can create a reply intent, `salesflow.complete_turn` locks the account-scoped Conversation and serializes with consent changes for that Contact. The latest consent event must be `granted`; missing consent returns `consent_missing`, while a later revocation returns `consent_revoked`. Both suppress the Turn without creating a draft or intent. Handoff-only processing remains separate from AI drafting, and every eventual customer send still performs the existing fresh authorization check.

Product Knowledge and Sales Policy activation and response-context assembly use the same account/kind advisory locks in deterministic order. Context assembly waits at most five seconds; contention returns `busy` and restores the Turn to an unclaimed pending state, while a successful wait reads the post-commit active rows. A missing row returns `missing_business_context` without falling back to an inactive version. Eligible reply intents retain their policy and knowledge versions plus a minimized `provenance.context` object containing the granted consent timestamp/status, source inbound ID, Conversation version, and ordered inbound message IDs/sequences. The bounded ephemeral drafting payload contains processing text, but persisted provenance contains references only.

History is scoped to the same account and Conversation and never reads beyond the current inbound sequence. The current inbound message is always present; up to nine newest predecessors are added while the processing-text total remains at or below 32 KiB, then the selected references are presented in ascending database sequence. Provider timestamps do not control this order.

## Provider status

Allowed statuses are `accepted`, `sent`, `delivered`, `read`, and `failed`. The callback must bind to an existing account/provider ID. Duplicate event IDs with a different payload are rejected, and older/lower-ranked events cannot regress the persisted status.

The live webhook maps accepted and idempotent callbacks to HTTP `200`, malformed input to `400`, invalid credentials or account scope to `403`, an unknown provider identity to `404`, and conflicting duplicate evidence to `409`. Unexpected database or workflow failures are not converted into typed input errors; they propagate as `5xx` so monitoring and retry behavior remain available.

## Operations actions

| Action | Required fields | Result |
| --- | --- | --- |
| `evidence` | `action` | Counts audit evidence and returns retention/release references. |
| `delete` | `action`, `contact_id` | Creates target records, minimizes live customer data, and records completion. |
| `contact_identifier_replace` | `action`, `contact_id`, `channel`, `provider`, `old_ref`, `new_ref` | Atomically retires the active old reference and links the unused new reference to the same Contact; ownership conflicts return HTTP `409`. |
| `release` | `action`, `release_id`, `manifest`, `manifest_hash` | Activates an immutable release only when the reviewed manifest binding matches. |
| `config_save` | `action`, `document` | Strictly validates and saves one immutable inactive version, recording the saving actor. |
| `config_activate` | `action`, `kind`, `version`, `expected_active_version` | Activates or rolls back to one compatible saved version and records the approving actor. |
| `config_rollback` | `action`, `kind`, `version`, `expected_active_version` | Explicit alias for the same compatible activation contract when selecting an older version. |

`config_activate` is also the rollback command: supply the older saved `version` and the currently active version as `expected_active_version`. Publication conflicts return typed `stale_active_version` or `busy` results without changing the active document. The operations workflow is the authorized public boundary; its database role does not receive direct access to the underlying publication functions or tables.

## Internal workflow calls

The orchestrator calls workflow 03 or 06 with the authenticated token, `account_ref`, and `work_id`. The scheduler calls `salesflow.schedule_work` and routes each returned row by `workflow_id`. These internal calls do not create a second business-state path; all state changes still pass through PostgreSQL functions.

## Error model

Commands return typed JSON containing fields such as `ok`, `terminal`, `reason`, `work_id`, and claim/lease identifiers. Expected validation, authorization, idempotency, conflict, and policy denials are normal terminal branches. Unexpected database failures remain workflow failures rather than being relabeled `invalid_input`. Representative reasons include `wrong_account`, `invalid`, `idempotency_conflict`, `consent_missing`, `consent_revoked`, `missing_business_context`, `context_too_large`, `global_stop`, `human_owned`, `stale_version`, `stale_active_version`, `busy`, `already_leased`, `claim_mismatch`, `retry_exhausted`, and `manifest_mismatch`.
