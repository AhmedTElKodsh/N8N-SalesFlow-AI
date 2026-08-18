# Component Inventory

## n8n workflows

| File | Workflow ID | Nodes | Trigger/role | Downstream behavior |
| --- | --- | ---: | --- | --- |
| `01-whatsapp-ingress.json` | `salesflow-wf-01` | 15 | POST `salesflow/test/whatsapp-intake` and POST `salesflow/inbound` | Test-only WhatsApp-shaped protocol proof plus atomic staging ingest; valid text survives unsupported sibling events. |
| `02-conversation-orchestrator.json` | `salesflow-wf-02` | 7 | Execute Workflow | Completes one turn and invokes workflow 03 or 06. |
| `03-outbox-dispatcher.json` | `salesflow-wf-03` | 9 | Execute Workflow or POST `salesflow/dispatch` | Claim, authorize, recheck, synthetic send, finish. |
| `04-whatsapp-status.json` | `salesflow-wf-04` | 3 | POST `salesflow/status` | Account-bound, idempotent, monotonic provider status with explicit HTTP outcomes. |
| `05-follow-up-scheduler.json` | `salesflow-wf-05` | 8 | UTC Schedule or POST `salesflow/followups` | Finds due/retry work across enabled accounts and invokes workflow 03/06. |
| `06-handoff-dispatcher.json` | `salesflow-wf-06` | 9 | Execute Workflow or POST `salesflow/handoff` | Claim, recheck, synthetic Handoff, finish. |
| `07-error-and-operations.json` | `salesflow-wf-07` | 3 | POST `salesflow/operations` | Evidence, deletion, release, and audited configuration publication commands. |

There are seven source workflows. Node counts are release-bound in `release/release-manifest.json`; this inventory describes responsibilities rather than duplicating that canonical value.

## Approved node inventory

- `executeWorkflow`
- `executeWorkflowTrigger`
- `code`
- `crypto`
- `if`
- `noOp`
- `postgres`
- `respondToWebhook`
- `scheduleTrigger`
- `set`
- `webhook`

The manifest rejects extra node types. `Set` is used only for deterministic synthetic adapter outcomes.

## PostgreSQL command surface

| Area | Primary functions |
| --- | --- |
| Authentication/configuration | `actor_for`, `bootstrap`, `validate_config`, `save_config`, `activate_config`, `set_control` |
| Consent/ingress | `set_consent`, `ingest` |
| Turn processing | `complete_turn` — claims ordered work; for AI replies, snapshots granted consent, both active business versions, and bounded inbound-history references before creating one intent |
| Outbox | `authorization_reason`, `claim_dispatch`, `recheck_dispatch`, `finish_dispatch` |
| Provider status | `callback` |
| Follow-Up/recovery | `schedule_followups`, `schedule_work` |
| Handoff | `claim_handoff`, `recheck_handoff`, `finish_handoff` |
| Operations | `operations` |

`database/001-initial.sql` is idempotent and keeps one effective definition for each public function signature.

## Configuration contracts

The AI uses five separate business-information contracts. Every contract has the same three identity fields: `accountRef` identifies the account (`test-account` in these samples), `kind` is the exact contract name shown below, and `version` identifies the immutable business-information version. A saved version cannot later be changed or deleted.

Saving and activation are separate operator actions exposed through the existing `salesflow/operations` endpoint; the workflow role receives no table access or direct grant to the private publication functions. Saving strictly validates and permanently stores a new dated inactive version, then records the saving actor and database time. Retrying an identical saved body is harmless. Activation is the approval action: it rechecks compatibility, makes the saved target live, and records the kind, target version, previous version, approving actor, and database time in the append-only audit log. Rollback uses the same activation action with an older compatible saved version, so no history is lost.

Publication is serialized per account and kind with a bounded database lock. The caller supplies the active version it expects; if another approval wins first, the stale request is rejected, and lock contention returns a typed busy result instead of waiting indefinitely. `config_docs.active` may change only inside the activation command, so direct updates cannot bypass approval or audit.

At response time, Product Knowledge and Sales Policy stay independently publishable. Response assembly takes their activation locks in deterministic order with a five-second bound, then selects the currently active rows together; contention restores the Turn and returns `busy`, and absence fails closed. The ephemeral drafting payload contains up to ten same-Conversation processing bodies within 32 KiB, skipping non-fitting predecessors while continuing to older candidates; an oversized current inbound is denied. The intent persists both versions and minimized references only. Its identity, source, versions, body, and provenance are immutable after creation except the controlled privacy-deletion body/provenance minimization.

### Product Knowledge (`product-knowledge.json`, kind `product_knowledge`)

| Field | Meaning and allowed value | Example |
| --- | --- | --- |
| `sources` | A non-empty list of approved source objects. Each object may contain only `id` and `claims`. | `[{"id":"source-1","claims":["service-count"]}]` |
| `sources[].id` | A non-empty source identifier used in evidence. | `source-1` |
| `sources[].claims` | A list containing only claim-identifier strings. | `["service-count"]` |

### Sales Policy (`sales-policy.json`, kind `sales_policy`)

| Field | Meaning and allowed value | Example |
| --- | --- | --- |
| `campaignEnabled` | `true` or `false`; whether campaign sending is enabled. | `true` |
| `allowedOffers` | A non-empty list containing only approved offer-identifier strings. | `["offer-1"]` |
| `allowedClaims` | A non-empty list containing only approved claim-identifier strings. | `["service-count"]` |
| `minimumConfidence` | Draft-confidence threshold from `0` through `1`. | `0.8` |
| `frequencyCap24h` | Maximum sends in 24 hours, from `1` through `100`. | `3` |
| `quietHoursUtc` | An object containing only `start` and `end`. | `{"start":0,"end":0}` |
| `quietHoursUtc.start`, `quietHoursUtc.end` | UTC hour numbers from `0` through `23`; equal values mean no quiet-hours interval. | `0`, `0` |

### Qualification (`qualification.json`, kind `qualification`)

| Field | Meaning and allowed value | Example |
| --- | --- | --- |
| `minimumScore` | Minimum qualifying score from `0` through `100`. | `1` |
| `handoffScore` | Score that requires human Handoff, from `0` through `100`; it must be at least `minimumScore`. | `5` |

### Consent and Template References (`consent-and-templates.json`, kind `consent_templates`)

| Field | Meaning and allowed value | Example |
| --- | --- | --- |
| `serviceWindowHours` | Contact window after inbound consent, from `1` through `168` hours. | `24` |
| `optOutSignals` | A non-empty list of text signals that stop automation. | `["stop","unsubscribe"]` |
| `humanSignals` | A non-empty list of text signals that request a human. It cannot overlap `optOutSignals`, ignoring letter case. | `["human","agent"]` |
| `templates` | A list of provider-owned template references; it does not store message wording. | `[{"key":"followup-en","approved":true,"windowHours":24}]` |
| `templates[].key` | Non-empty provider template identifier. | `followup-en` |
| `templates[].approved` | `true` or `false`; only approved references are eligible for sending. | `true` |
| `templates[].windowHours` | Template eligibility window from `1` through `168` hours. | `24` |

### Handoff Dispatch Settings (`handoff.json`, kind `handoff`)

| Field | Meaning and allowed value | Example |
| --- | --- | --- |
| `queue` | Non-empty destination queue identifier. | `synthetic-sales` |
| `deadlineSeconds` | Time allowed for Handoff, from `1` through `86400` seconds. | `300` |
| `maxAttempts` | Maximum dispatch attempts, from `1` through `10`. | `3` |
| `backoffSeconds` | Wait before retry, from `1` through `3600` seconds. | `2` |
| `claimSeconds` | Worker claim duration, from `1` through `300` seconds. | `10` |

Handoff triggers do not live in this dispatch contract: Qualification scores, explicit human signals, and Sales Policy own those decisions. Structural validation rejects missing fields, undocumented fields, wrong JSON types, fractional values in integer fields, blank or duplicate identifiers, out-of-range values, and invalid relationships. Human reviewers still own whether the business meaning and provider-managed wording are approved. The word `qualified` is an exact synthetic-local test signal, not natural-language qualification logic.

Operational configuration stays separate from the five business contracts: `account.json` controls the synthetic account, `model.json` the local model, `retry.json` shared retries and claims, `retention.json` data retention, and `release-set.json` the reviewed activation-manifest binding.

## Verification and release components

- `tests/run.ps1` — canonical lifecycle and assertion driver.
- `tests/runtime.sql` — database-level behavior evidence.
- `tests/pilot-scenarios.json` — exact S01-S26 inventory.
- `scripts/canonicalize-workflows.mjs` — stable stdlib-only workflow hashes.
- `release/release-manifest.json` — pinned images, inputs, workflow hashes, node types, and promotion flag.
