# Component Inventory

## n8n workflows

| File | Workflow ID | Nodes | Trigger/role | Downstream behavior |
| --- | --- | ---: | --- | --- |
| `01-whatsapp-ingress.json` | `salesflow-wf-01` | 5 | POST `salesflow/inbound` | Atomic ingest; invokes workflow 02 only for accepted new work. |
| `02-conversation-orchestrator.json` | `salesflow-wf-02` | 7 | Execute Workflow | Completes one turn and invokes workflow 03 or 06. |
| `03-outbox-dispatcher.json` | `salesflow-wf-03` | 9 | Execute Workflow or POST `salesflow/dispatch` | Claim, authorize, recheck, synthetic send, finish. |
| `04-whatsapp-status.json` | `salesflow-wf-04` | 2 | POST `salesflow/status` | Account-bound, idempotent, monotonic provider status. |
| `05-follow-up-scheduler.json` | `salesflow-wf-05` | 8 | UTC Schedule or POST `salesflow/followups` | Finds due/retry work across enabled accounts and invokes workflow 03/06. |
| `06-handoff-dispatcher.json` | `salesflow-wf-06` | 9 | Execute Workflow or POST `salesflow/handoff` | Claim, recheck, synthetic Handoff, finish. |
| `07-error-and-operations.json` | `salesflow-wf-07` | 2 | POST `salesflow/operations` | Evidence, deletion, and release commands. |

Total: **7 workflows and 42 nodes**.

## Approved node inventory

- `executeWorkflow`
- `executeWorkflowTrigger`
- `if`
- `noOp`
- `postgres`
- `scheduleTrigger`
- `set`
- `webhook`

The manifest rejects extra node types. `Set` is used only for deterministic synthetic adapter outcomes.

## PostgreSQL command surface

| Area | Primary functions |
| --- | --- |
| Authentication/configuration | `actor_for`, `bootstrap`, `validate_config`, `publish_config`, `set_control` |
| Consent/ingress | `set_consent`, `ingest` |
| Turn processing | `complete_turn` |
| Outbox | `authorization_reason`, `claim_dispatch`, `recheck_dispatch`, `finish_dispatch` |
| Provider status | `callback` |
| Follow-Up/recovery | `schedule_followups`, `schedule_work` |
| Handoff | `claim_handoff`, `recheck_handoff`, `finish_handoff` |
| Operations | `operations` |

`database/001-initial.sql` is idempotent and contains later `CREATE OR REPLACE` definitions that supersede earlier versions inside the same migration.

## Configuration contracts

| File | Purpose |
| --- | --- |
| `account.json` | Synthetic account identity and enabled state |
| `consent-and-templates.json` | Service window, opt-out/human signals, approved template |
| `handoff.json` | Queue, deadline, claim, retry/backoff |
| `model.json` | Synthetic-local model selection and allowed claims |
| `product-knowledge.json` | Approved source and claim identifiers |
| `qualification.json` | Minimum and Handoff score thresholds |
| `release-set.json` | Reviewed activation manifest binding |
| `retention.json` | Audit/message retention inputs |
| `retry.json` | Shared attempt, backoff, lease, and claim durations |
| `sales-policy.json` | Offers, claims, confidence, campaign, frequency, quiet hours |

## Verification and release components

- `tests/run.ps1` — canonical lifecycle and assertion driver.
- `tests/runtime.sql` — database-level behavior evidence.
- `tests/pilot-scenarios.json` — exact S01-S26 inventory.
- `scripts/canonicalize-workflows.mjs` — stable stdlib-only workflow hashes.
- `release/release-manifest.json` — pinned images, inputs, workflow hashes, node types, and promotion flag.
