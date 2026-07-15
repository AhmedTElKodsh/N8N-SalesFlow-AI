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

## Provider status

Allowed statuses are `accepted`, `sent`, `delivered`, `read`, and `failed`. The callback must bind to an existing account/provider ID. Duplicate event IDs with a different payload are rejected, and older/lower-ranked events cannot regress the persisted status.

## Operations actions

| Action | Required fields | Result |
| --- | --- | --- |
| `evidence` | `action` | Counts audit evidence and returns retention/release references. |
| `delete` | `action`, `contact_id` | Creates target records, minimizes live customer data, and records completion. |
| `release` | `action`, `release_id`, `manifest`, `manifest_hash` | Activates an immutable release only when the reviewed manifest binding matches. |

## Internal workflow calls

The orchestrator calls workflow 03 or 06 with the authenticated token, `account_ref`, and `work_id`. The scheduler calls `salesflow.schedule_work` and routes each returned row by `workflow_id`. These internal calls do not create a second business-state path; all state changes still pass through PostgreSQL functions.

## Error model

Commands return typed JSON containing fields such as `ok`, `terminal`, `reason`, `work_id`, and claim/lease identifiers. Denials are normal terminal branches, not workflow exceptions. Representative reasons include `wrong_account`, `invalid`, `idempotency_conflict`, `consent_missing`, `global_stop`, `human_owned`, `stale_version`, `already_leased`, `claim_mismatch`, `retry_exhausted`, and `manifest_mismatch`.
