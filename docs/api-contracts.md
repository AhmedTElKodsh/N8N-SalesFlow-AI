# Local Webhook Contracts

These are **synthetic-local/test interfaces**, not production Meta or CRM contracts. Each uses the active n8n webhook base plus the path below and an `x-salesflow-token` header unless invoked internally by Execute Workflow.

| Method | n8n path | Purpose | Minimum body |
| --- | --- | --- | --- |
| POST | `salesflow/inbound` | Normalize and persist inbound customer text | `account_ref`, `provider_id`, `contact_ref`, `body`; optional `received_at` |
| POST | `salesflow/dispatch` | Test entry to outbox claim/dispatch | `work_id`; optional `account_ref` |
| POST | `salesflow/status` | Reconcile provider status | `account_ref`, `event_id`, `provider_id`, `status`, `provider_time` |
| POST | `salesflow/followups` | Authenticated test trigger for scheduler logic | No business body required |
| POST | `salesflow/handoff` | Test entry to Handoff claim/dispatch | `work_id`; optional `account_ref` |
| POST | `salesflow/operations` | Account-bound operator command | Action-specific object |

The source workflow set also contains the ingress path above, so there are six distinct webhook paths; the seventh runtime entry is the UTC Schedule Trigger.

## Inbound behavior

`salesflow.ingest` authenticates the runtime actor, enforces account scope, validates required strings/timestamps/size, normalizes configured signals, deduplicates by provider ID and payload hash, allocates a monotonic Conversation sequence, and returns a typed result. Only a newly created accepted event starts the orchestrator.

For the signed Meta protocol route, supported text messages are processed independently of unsupported sibling changes in the same envelope. A mixed envelope therefore retains every valid text message, while an envelope containing no supported text is acknowledged without creating business work.

A delivery addressed to a retired Contact Identifier is terminal: it creates no message or downstream work, records minimized rejection evidence, and returns HTTP `410` so the provider is not instructed to retry a permanently non-resolvable reference.

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

Commands return typed JSON containing fields such as `ok`, `terminal`, `reason`, `work_id`, and claim/lease identifiers. Expected validation, authorization, idempotency, conflict, and policy denials are normal terminal branches. Unexpected database failures remain workflow failures rather than being relabeled `invalid_input`. Representative reasons include `wrong_account`, `invalid`, `idempotency_conflict`, `consent_missing`, `global_stop`, `human_owned`, `stale_version`, `stale_active_version`, `busy`, `already_leased`, `claim_mismatch`, `retry_exhausted`, and `manifest_mismatch`.
