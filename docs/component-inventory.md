# Component Inventory

## n8n workflows

| File | Workflow ID | Nodes | Trigger/role | Downstream behavior |
| --- | --- | ---: | --- | --- |
| `01-whatsapp-ingress.json` | `salesflow-wf-01` | 15 | POST `salesflow/test/whatsapp-intake` and POST `salesflow/inbound` | Test-only WhatsApp-shaped protocol proof plus atomic staging ingest; valid text survives unsupported sibling events. |
| `02-conversation-orchestrator.json` | `salesflow-wf-02` | 7 | Execute Workflow | Completes one turn and invokes workflow 03 or 06. |
| `03-outbox-dispatcher.json` | `salesflow-wf-03` | 9 | Execute Workflow or POST `salesflow/dispatch` | Claim, atomic final authorization/call-start, synthetic send, finish; only a newly started call reaches the adapter. |
| `04-whatsapp-status.json` | `salesflow-wf-04` | 3 | POST `salesflow/status` | Account-bound, idempotent, monotonic provider status with explicit HTTP outcomes. |
| `05-follow-up-scheduler.json` | `salesflow-wf-05` | 8 | UTC Schedule or POST `salesflow/followups` | Runs the bounded all-account scheduler; PostgreSQL scans due jobs, records busy skips, reauthorizes, caps output at 50, and routes dispatch/Handoff work. |
| `06-handoff-dispatcher.json` | `salesflow-wf-06` | 11 | Execute Workflow or POST `salesflow/handoff` | Claim, recheck, expose the saved summary to the synthetic adapter, finish, or resolve same-account operator history. |
| `07-error-and-operations.json` | `salesflow-wf-07` | 3 | POST `salesflow/operations` | Account emergency stop, bounded activity/failure views, evidence, deletion, release, and audited configuration publication commands. |

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
| Outbox | `authorization_reason`, `claim_dispatch`, `begin_provider_call`, `recheck_dispatch`, `finish_dispatch` |
| Provider status | `callback` |
| Follow-Up/recovery | `create_followup_after_sent`, `followup_due_authorization_reason`, `followup_final_authorization_reason`, `try_claim_followup_candidate`, `schedule_followups`, `schedule_work`, `followup_metrics` |
| Handoff | `claim_handoff`, `recheck_handoff`, `finish_handoff` |
| Operations | `operations` |

`database/001-initial.sql` is idempotent and keeps one effective definition for each public function signature.

Outbound authority is split deliberately: `claim_dispatch` grants temporary ownership, while `begin_provider_call` reruns authorization and commits the unique call-start immediately before the adapter. `finish_dispatch` can only complete that matching call. `schedule_work` reclaims expired pre-start leases but converts expired post-start work to reconciliation, and `callback` can reconcile a matching provider identity without resending.

Automatic Follow-Up scheduling is database-owned. Sent completion creates one immutable +12-hour parent only when current scheduling authority still matches the reply. New inbound, consent/control/account/Conversation changes, identifier replacement, or a disabled campaign serialize through the same Conversation-first authority protocol. At due time and provider-call start, an active WhatsApp/Meta identifier and every current policy/template/frequency authority must still exist. Durable due, reconciliation, and projection cursors traverse fixed high-water cycles, wrap fairly, and checkpoint without aborting work when a cursor row is busy; each invocation retains the 50-success ceiling. The parent reaches `call_started` before its provider-call row becomes visible, advances monotonically from `sent` to `delivered` or `failed`, and reaches terminal denial/exhaustion before the child intent is suppressed. Pre-call exhaustion never claims an ambiguous provider call.

## Configuration contracts

The AI uses five separate business-information contracts. Every contract has the same three identity fields: `accountRef` identifies the account (`test-account` in these samples), `kind` is the exact contract name shown below, and `version` identifies the immutable business-information version. A saved version cannot later be changed or deleted.

Saving and activation are separate operator actions exposed through the existing `salesflow/operations` endpoint; the workflow role receives no table access or direct grant to the private publication functions. Saving strictly validates and permanently stores a new dated inactive version, then records the saving actor and database time. Retrying an identical saved body is harmless. Activation is the approval action: it rechecks compatibility, makes the saved target live, and records the kind, target version, previous version, approving actor, and database time in the append-only audit log. Rollback uses the same activation action with an older compatible saved version, so no history is lost.

Publication is serialized per account and kind with a bounded database lock. The caller supplies the active version it expects; if another approval wins first, the stale request is rejected, and lock contention returns a typed busy result instead of waiting indefinitely. `config_docs.active` may change only inside the activation command, so direct updates cannot bypass approval or audit.

At response time, Product Knowledge and Sales Policy stay independently publishable, but the active Release Set is the authority for which pair may be used together. Response assembly takes all three activation locks in deterministic order with a five-second bound, then selects the active rows in one transaction. Contention restores the Turn and returns `busy`; absence returns `missing_business_context`; and a document pair that conflicts with the active Release Set returns `inconsistent_business_context`. The ephemeral drafting payload contains up to ten same-Conversation processing bodies within 32 KiB, skipping non-fitting predecessors while continuing to older candidates; an oversized current inbound is denied. The intent persists Release Set, business-version, consent-evidence, and message references only. Its identity, source, versions, body, and provenance are immutable after creation except the controlled privacy-deletion body/provenance minimization.

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
| `templates` | A list of provider-owned template references and provider metadata; it does not store message wording. | `[{"key":"followup-en","approved":true,"windowHours":24,"providerTemplateId":"followup-en","category":"marketing","language":"en"}]` |
| `templates[].key` | Non-empty provider template identifier. | `followup-en` |
| `templates[].approved` | `true` or `false`; only approved references are eligible for sending. | `true` |
| `templates[].windowHours` | Template eligibility window from `1` through `168` hours. | `24` |
| `templates[].providerTemplateId` | Non-empty provider-managed identity. The approved synthetic Follow-Up contract requires `followup-en`. | `followup-en` |
| `templates[].category` | Provider category. Allowed structural values are `marketing`, `utility`, or `authentication`; the approved synthetic Follow-Up contract requires `marketing`. | `marketing` |
| `templates[].language` | Non-empty provider language code. The approved synthetic Follow-Up contract requires `en`. | `en` |

### Handoff Dispatch Settings (`handoff.json`, kind `handoff`)

| Field | Meaning and allowed value | Example |
| --- | --- | --- |
| `queue` | Non-empty destination queue identifier. | `synthetic-sales` |
| `deadlineSeconds` | Time allowed for Handoff, from `1` through `86400` seconds. | `300` |
| `maxAttempts` | Maximum dispatch attempts, from `1` through `10`. | `3` |
| `backoffSeconds` | Wait before retry, from `1` through `3600` seconds. | `2` |
| `claimSeconds` | Worker claim duration, from `1` through `300` seconds. | `10` |

Handoff triggers do not live in this dispatch contract: Qualification scores, explicit human signals, and Sales Policy own those decisions. Structural validation rejects missing fields, undocumented fields, wrong JSON types, fractional values in integer fields, blank or duplicate identifiers, out-of-range values, and invalid relationships. Human reviewers still own whether the business meaning and provider-managed wording are approved. The word `qualified` is an exact synthetic-local test signal, not natural-language qualification logic.

SP3-T4 requires normalized whole-message human signals (including `talk to a human`), the existing qualification threshold fixture, and grounding failure to transfer ownership without further automated customer messages. Repeated requests while Human-Owned must not create another Handoff. A provider call already started may finish; takeover before call-start prevents it. These checks do not establish production classifier accuracy, and the Meta staging intake continues to store messages without downstream actions.

SP3-T5 saves one concise PostgreSQL-owned summary for those three triggers. Known details are bounded source-message excerpts with immutable IDs/sequences; absent structured lead data is explicit, and offer relevance is `none` because the current classifier persists no durable offer-relevance evidence even when policy permits several offers. The active Sales Policy version is frozen. Workflow 06 resolves a Conversation-UUID-only URL by deriving account scope from the separately supplied operator token and returns persisted inbound plus sent outbound messages. Privacy deletion and authorized retention expiry minimize copied excerpts without removing their evidence identifiers. Single-use, claim-bound adapter-start evidence prevents duplicate exposure and blind resend after an expired post-recheck notification lease while accepting the exact late outcome after real authority transitions; migrated claims are conservatively marked. Only the deliberately global scheduler may be unscoped, and all terminal suppression clears retry scheduling. This is synthetic-local API proof only; Conversation UI and CRM integration remain deferred.

SP3-T6 makes the existing account stop an Operations command and exposes durable activity plus failure/retry pages through Workflow 07. Stop acceptance and provider-call start share one account lock; a typed `busy` response leaves control state unchanged. Audit entries identify actor or `system`, database time, entity, action/outcome, and before/after state without message bodies or credentials. Failure projections retain attempt, latest reason, nullable known occurrence time, separate observation time, next retry, and manual-action status, use indexed stable account-keyset pagination, remain account isolated, and expire under the approved audit-retention window.

Operational configuration stays separate from the five business contracts: `account.json` controls the synthetic account, `model.json` the local model, `retry.json` shared retries and claims, `retention.json` data retention, and `release-set.json` the reviewed activation-manifest binding.

## Verification and release components

- `tests/run.ps1` — canonical lifecycle and assertion driver.
- `tests/runtime.sql` — database-level behavior evidence.
- `tests/pilot-scenarios.json` — exact S01-S26 inventory.
- `scripts/canonicalize-workflows.mjs` — stable stdlib-only workflow hashes.
- `release/release-manifest.json` — pinned images, inputs, workflow hashes, node types, and promotion flag.
