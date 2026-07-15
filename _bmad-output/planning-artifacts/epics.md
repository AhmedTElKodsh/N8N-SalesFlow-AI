---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-N8N-SalesFlow-AI-2026-07-14/prd.md
  - _bmad-output/planning-artifacts/prds/prd-N8N-SalesFlow-AI-2026-07-14/addendum.md
  - _bmad-output/planning-artifacts/architecture/architecture-N8N-SalesFlow-AI-2026-07-14/ARCHITECTURE-SPINE.md
  - docs/project-context.md
---

# N8N SalesFlow AI - Epic Breakdown

## Overview

This document provides the complete requirement inventory for the N8N SalesFlow AI epic and story breakdown. The inventory is intentionally technical-first. Epic design and story decomposition remain pending until this extracted input is confirmed.

## Requirements Inventory

### Functional Requirements

- **FR-1 — Authenticate and normalize inbound events:** Accept only events for the configured WhatsApp account, validate authenticity where the integration exposes a signature, validate schema and size, and persist a normalized inbound record without side effects for rejected events.
- **FR-2 — Deduplicate and order message processing:** Enforce uniqueness on provider inbound message ID and serialize state changes per Conversation so retries, replays, and concurrency create at most one logical response action.
- **FR-3 — Record consent and opt-out state:** Store consent evidence when required, recognize configured opt-out signals, and immediately suppress pending outbound work; opt-out overrides every other objective or action.
- **FR-4 — Use approved Product Knowledge:** Answer only from the active approved Product Knowledge version, record factual source identifiers, and clarify or hand off when knowledge is missing or conflicting.
- **FR-5 — Capture Lead Facts with evidence:** Collect only approved qualification fields and link each stored fact to its source message; generated summaries cannot replace customer evidence.
- **FR-6 — Return a typed model draft:** Require a validated model structure containing response draft, intent candidates, Offer reference, confidence, source references, and escalation reason; invalid or unsafe output fails closed.
- **FR-7 — Enforce Sales Policy outside the model:** Deterministically validate product, price, currency, tax, discount, expiry, prohibited claims, and applicable policy version before creating a send intent.
- **FR-8 — Restrict commercial authority:** Permit the Assistant to present approved Offers only; prohibit custom terms, contracts, autonomous approval, and autonomous `closed_won` decisions.
- **FR-9 — Apply prohibited-content and escalation rules:** Block deceptive urgency, unsupported claims, discriminatory treatment, hidden-instruction disclosure, disallowed sensitive-topic handling, pressure, invented personalization, and unsafe language switching.
- **FR-10 — Offer direct human escalation:** Honor explicit human requests and escalate uncertainty, complaints, privacy/legal/safety topics, exceptions, unsupported requests, buying intent, and system failures with clear customer acknowledgement.
- **FR-11 — Create one evidence-backed Handoff:** Atomically set Human-Owned and create/reuse one Handoff with facts, unknowns, policy/Offer version, reason, transcript pointers, correlation ID, assignment target, and acknowledgement due time.
- **FR-12 — Enforce Human-Owned lockout:** Block every automated reply and Follow-Up while Human-Owned except one fixed precommitted transfer acknowledgement tied to the Handoff transition; only an authorized, audited release may restore AI-Owned.
- **FR-13 — Persist due Follow-Ups:** Create no more than the configured number of durable Follow-Ups with due time, generation, source Conversation version, and unique action key; invalidate stale work on relevant state changes.
- **FR-14 — Recheck eligibility immediately before send:** Claim a due Follow-Up exactly once and recheck consent, opt-out, ownership, last inbound time, frequency, quiet hours, campaign state, and WhatsApp service window; use only an approved eligible template outside the window.
- **FR-15 — Publish versioned configuration:** Allow authorized managers to draft typed Product Knowledge and Sales Policy and authorized approvers to publish immutable effective versions with rollback targets; reject arbitrary prompt/config input.
- **FR-16 — Ensure single logical side effects:** Persist a unique durable intent before every customer send or Handoff notification, and reuse that intent across workflow and provider retries.
- **FR-17 — Reconcile provider status:** Attach WhatsApp provider message IDs and idempotent delivery/read/failure callbacks to the existing outbound record while keeping unknown status visible for reconciliation.
- **FR-18 — Preserve decision provenance:** Record append-only evidence for inputs, state, policy, knowledge, prompt, model, template, workflow release, validation, intents, provider status, Handoff, approval, and actor.
- **FR-19 — Provide operational controls:** Let Operations globally stop outbound automation, disable a Conversation, inspect failed actions, and resume only after a recorded decision; outages fail closed.
- **FR-20 — Enforce data lifecycle:** Apply model-payload allowlists, role-based access, encryption, retention, deletion, backup rules, and Contact-scoped isolation across all documented stores and providers.

### Non-Functional Requirements

- **NFR-1 — Performance:** Proposed pilot targets are webhook acknowledgement p95 at or below 2 seconds and automation processing-to-send p95 at or below 10 seconds under approved pilot load, measured separately from external provider delivery.
- **NFR-2 — Reliability:** Duplicate logical send rate remains below 0.1% during the pilot; restart and retry tests lose no business data. Production RTO/RPO require explicit approval before any SLO claim.
- **NFR-3 — Security:** Use least-privilege credentials, isolated test/production channels, reviewed node inventory, authenticated transcript links, execution secret redaction, and a clean or explicitly accepted n8n security audit before launch.
- **NFR-4 — Privacy:** Data minimization, provider processing/retention terms, jurisdiction, retention, deletion, and access decisions are launch blockers; vague masking is not acceptance evidence.
- **NFR-5 — Observability:** Correlation IDs connect inbound event, turn, model decision, intent, provider status, Follow-Up, and Handoff. Alerts cover backlog, failures, unknown status, policy rejection, and kill-switch state.
- **NFR-6 — Implementation provenance:** Skills, MCPs, and CLIs may assist work, but every durable change must be a reviewable repository artifact and pass common test-environment checks; chat history is never required build knowledge.
- **NFR-7 — Secret handling:** Production credentials and customer data must not appear in prompts, logged MCP/CLI arguments, exported workflow JSON, fixtures, or source control.
- **NFR-8 — Accessibility and language:** Human escalation, disclosure, and opt-out instructions are clear and available in every approved language without relying on color or images.
- **NFR-9 — Availability:** The pilot uses a minimal single-runtime topology and claims no 99.9% end-to-end SLA; scaling or redundancy requires measured need or an approved funded SLO.
- **NFR-10 — Acceptance evidence:** Every launch-blocking NFR records test scope, environment, result, evidence owner, and approval; unresolved RTO/RPO and retention values remain explicit decision blockers.

### Additional Requirements

- **AR-1 — Durable authority:** PostgreSQL is the business source of truth; n8n orchestrates work and its execution history is diagnostic only.
- **AR-2 — Untrusted model boundary:** The LLM is stateless from the workflow's perspective, sees only a minimal field allowlist, and returns schema-validated JSON; it receives no credentials, hidden operational data, direct send tool, arbitrary SQL, or unrestricted retrieval tool.
- **AR-3 — Orthogonal state:** `automation_owner` and Conversation `lifecycle` are separate state dimensions; terminal or suppressed lifecycle state cannot be reopened by an ownership change.
- **AR-4 — Versioned policy and knowledge:** Sales Policy and Product Knowledge use typed draft, validation, approval, publication, effective-time, rollback, and safety-revocation behavior outside prompts.
- **AR-5 — Stable idempotency:** Provider inbound IDs are unique; outbound action keys use Conversation, source event, action type, and a generation allocated once per new logical action.
- **AR-6 — Serialized mutation:** State-changing work uses one PostgreSQL transaction with row/advisory locking or compare-and-set versioning; separate n8n nodes do not constitute a transaction.
- **AR-7 — Transactional outbox:** State transition, unique outbox/Handoff record, and Audit Event commit atomically before external dispatch. Provider status events are immutable and derived status changes monotonically.
- **AR-8 — Durable scheduling:** Follow-Ups use a UTC due-job table, bounded scheduled batches, downtime catch-up, cancellation/version checks, final eligibility validation, and backlog age/size alerts—not per-lead Wait-node memory.
- **AR-9 — WhatsApp policy gate:** Window state derives from the last eligible customer message; outside the service window only an approved active template ID of the correct category/language may proceed.
- **AR-10 — Immutable provenance:** Every decision snapshots inbound source and Product Knowledge, Sales Policy, prompt, model, template, validator, evidence, and `workflow_release_id` composed from Git commit plus canonical export hash.
- **AR-11 — Scoped data lifecycle:** Internal Contact/Conversation IDs scope all queries; phone numbers are channel identifiers. One deletion request tracks live-store deletion, provider requests, execution purge, and deferred backup expiry.
- **AR-12 — Evidence-triggered scale:** Start with one pinned n8n runtime and managed PostgreSQL; Redis, queue mode, workers, webhook processors, multi-main, and load balancing require measured saturation/backlog or an approved SLO and load test.
- **AR-13 — Environment isolation:** Test and production use separate Meta apps/numbers, credentials, templates, subscriptions, and policy publication paths.
- **AR-14 — Final send authorization:** Immediately before every provider call, one deterministic gate evaluates global stop, scoped disablement, lifecycle, consent, opt-out, ownership, Conversation version, policy/knowledge validity, service window/template, quiet hours, frequency, and campaign eligibility in defined precedence order. The sole ownership exception is one fixed precommitted transfer acknowledgement tied atomically to its Handoff.
- **AR-15 — Release and recovery authority:** Operations controls secrets, migration-before-workflow rollout, activation, rollback, backup/restore drills, kill switch, monitoring, and incident recovery through a versioned release manifest.
- **AR-16 — Model failure handoff:** Invalid, unsafe, low-confidence, conflicting, timed-out, or unavailable model output atomically creates/reuses a Handoff and sets Human-Owned; only a separately approved fallback may pass the final send gate.
- **AR-17 — Hardened n8n boundary:** Production uses an allowlisted node inventory, excludes unneeded command/file/Code/HTTP and community/custom nodes, enables SSRF and egress protections, restricts editing, scopes credentials per workflow, and resolves n8n audit findings.
- **AR-18 — Immutable runtime versions:** A release pins the tested n8n package and official image digest, PostgreSQL deployment version, dependency inventory, supported WhatsApp Graph API version and retirement date, plus workflow release ID.
- **AR-19 — Shared database contracts:** One migration stream owns canonical aggregates, identifiers, state vocabularies, constraints, and versioned atomic commands; workflows may not invent incompatible JSON or mutation contracts.
- **AR-20 — Canonical ingestion order:** PostgreSQL assigns monotonic `ingested_seq` per Conversation. Provider timestamps are evidence only; newer committed inbound work invalidates older unsent drafts/intents through version guards.
- **AR-21 — Version-bound dispatch lease:** One transaction reruns final authorization and claims a short non-expired lease without holding a database lock during the network call; the provider-call start is the documented external linearization boundary.
- **AR-22 — Knowledge safety revocation:** A safety-revoked Product Knowledge version invalidates pending intents and routes the turn through the model-failure Handoff path; ordinary version replacement does not retroactively invalidate an in-flight turn.
- **AR-23 — Finite centralized retries:** One versioned Retry Policy defines action-specific attempt/age budgets and backoff/jitter; exhaustion marks reconciliation required, alerts Operations, and permits only audited replay with the original logical key.
- **AR-24 — Interchangeable build clients:** Codex, Antigravity, and OpenCode may use suitable Skills, MCPs, and CLIs, but canonical repository artifacts and common validation/import/export checks define the build. Each client uses its own verified configuration surface.
- **AR-25 — Structural workflow seed:** Plan separate exported workflows for WhatsApp ingress, Conversation orchestration, outbox dispatch, status callbacks, Follow-Up scheduling, Handoff dispatch, and error/operations handling, plus ordered SQL migrations and pilot scenario fixtures.
- **AR-26 — Native-first implementation:** Prefer supported n8n WhatsApp Trigger/Business, PostgreSQL, Schedule Trigger, and other native nodes; introduce HTTP/Code/custom/community nodes only after documented capability and security review demonstrates need.
- **AR-27 — No starter application template:** This is a workflow-and-database project, so no web application starter is selected. The minimal starting contract is canonical n8n exports, SQL migrations, fixtures, and documented import/validation commands.
- **AR-28 — Handoff adapter blocker:** Handoff dispatcher and acknowledgement-state stories cannot be finalized until executives name the CRM/channel, assignment owner, acknowledgement signal/SLA, timeout behavior, and permanent-failure escalation path.
- **AR-29 — Credentialed Meta proof:** Before production build/promotion, smoke tests must prove Graph API version, webhook subscription, permissions, template inventory, duplicate/out-of-order handling, and test/production isolation using approved credentials.
- **AR-30 — Managed PostgreSQL proof:** The selected service must prove PostgreSQL 17 compatibility, patched minor, TLS, connection/pooling limits, backup/PITR and restore behavior, maintenance, metrics, and approved region.
- **AR-31 — Deferred complexity triggers:** Vector retrieval, media/attachment understanding, multi-tenancy, multiple numbers, custom administration UI, model routing, and HA remain deferred until explicit evidence and a separate design justify them.
- **AR-32 — Agent tool safety:** MCPs and CLIs are operator interfaces, not hidden production services. Production secrets remain in approved secret stores/n8n credentials, and no customer data or secret may enter prompts, logged arguments, exports, fixtures, or source control.

### UX Design Requirements

No custom UI is planned for the MVP. Customer experience occurs in WhatsApp and is already constrained by FR-3, FR-9, FR-10, FR-12, FR-14, and NFR-8. Policy administration and operational control should use approved existing surfaces unless evidence establishes that a dedicated UI is necessary.

### FR Coverage Map

| Functional Requirement | Epic | Coverage summary |
| --- | --- | --- |
| FR-1 | Epic 1 | Trusted WhatsApp event authentication, validation, normalization, and persistence |
| FR-2 | Epic 1 | Inbound deduplication and per-Conversation ordering |
| FR-3 | Epic 1 | Consent evidence, opt-out recognition, and immediate suppression |
| FR-4 | Epic 2 | Grounded answers from approved Product Knowledge |
| FR-5 | Epic 2 | Evidence-linked Lead Facts |
| FR-6 | Epic 2 | Schema-validated model drafts and fail-closed behavior |
| FR-7 | Epic 2 | Deterministic Sales Policy enforcement outside the model |
| FR-8 | Epic 2 | Approved Offers only and no autonomous commercial closure |
| FR-9 | Epic 2 | Prohibited-content controls and safety escalation |
| FR-10 | Epic 1 | Direct customer access to human escalation |
| FR-11 | Epic 1 | Atomic, evidence-backed Handoff creation |
| FR-12 | Epic 1 | Human-Owned automation lockout and audited release |
| FR-13 | Epic 3 | Durable, unique, cancellable Follow-Up jobs |
| FR-14 | Epic 3 | Final Follow-Up eligibility and WhatsApp-window checks |
| FR-15 | Epic 2 | Typed, versioned Product Knowledge and Sales Policy publication |
| FR-16 | Epic 1 | Durable unique intents and single logical side effects |
| FR-17 | Epic 1 | Idempotent provider-status reconciliation |
| FR-18 | Epic 1 | Immutable decision and action provenance |
| FR-19 | Epic 1 | Kill switch, scoped disablement, inspection, and controlled recovery |
| FR-20 | Epic 1 | Contact-scoped security, retention, deletion, and backup lifecycle |

## Epic List

### Epic 1: Safe WhatsApp Conversation and Human Handoff

An opted-in customer can safely enter the WhatsApp flow, opt out, or request a representative. The system produces at most one traceable response or Handoff; human ownership stops automation, while Sales and Operations can reconcile delivery, reconstruct decisions, stop or resume processing, and manage customer data safely.

**FRs covered:** FR-1, FR-2, FR-3, FR-10, FR-11, FR-12, FR-16, FR-17, FR-18, FR-19, FR-20.

**Implementation notes:** This is the shared safety boundary: trusted ingress, Conversation state, consent and suppression, idempotent transactional outbox, provider status, Handoff, Human-Owned lockout, audit events, operational controls, and data lifecycle. It must deliver a deterministic non-LLM vertical slice. Live Handoff dispatch and acknowledgement stories remain blocked until executives select the destination, assignment owner, acknowledgement signal/SLA, timeout behavior, and permanent-failure escalation path.

### Epic 2: Governed and Grounded Sales Assistance

Authorized managers can publish controlled Product Knowledge and Sales Policy, and opted-in customers can receive grounded answers, evidence-backed qualification, approved Offers, and safe escalation without invented claims or autonomous negotiation.

**FRs covered:** FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-15.

**Implementation notes:** Build on Epic 1's Conversation, Handoff, audit, and outbox contracts. Keep the LLM behind a typed untrusted boundary; apply deterministic commercial and safety authorization before the shared send path. Product Knowledge and Sales Policy publication are part of this epic because assistance cannot be governed without them and separating them would churn the same contracts.

### Epic 3: Compliant Customer Re-engagement

An eligible silent customer receives at most the approved Follow-Up, while new inbound messages, opt-out, Human-Owned state, lifecycle changes, campaign stops, timing rules, and WhatsApp service-window restrictions suppress stale or prohibited messages.

**FRs covered:** FR-13, FR-14.

**Implementation notes:** Build on the prior Conversation, policy, authorization, and outbox paths. Persist UTC due jobs and process bounded catch-up batches; do not hold one Wait execution per lead and do not introduce a second customer-send path.

<!-- Epic and story sections are generated only after the requirements inventory is confirmed. -->

## Epic 1: Safe WhatsApp Conversation and Human Handoff

An opted-in customer can safely enter the WhatsApp flow, opt out, or request a representative. The system produces at most one traceable response or Handoff; human ownership stops automation, while Sales and Operations can reconcile delivery, reconstruct decisions, stop or resume processing, and manage customer data safely.

### Story 1.1: Accept and Record a Trusted WhatsApp Message

As an opted-in customer,
I want my WhatsApp message accepted exactly once and attached to the correct Conversation,
So that subsequent automation operates on trusted, ordered evidence.

**Requirements:** FR-1, FR-2, FR-18; NFR-1, NFR-2, NFR-3, NFR-5, NFR-7, NFR-10.

**Acceptance Criteria:**

**Given** a valid event for the configured test WhatsApp account
**When** the native WhatsApp ingress receives it
**Then** authenticity is validated where the integration exposes that evidence
**And** account identity, schema, payload size, event type, and required identifiers are validated before business processing
**And** only the Contact, Conversation, Inbound Message, and minimum Audit Event records required by this story are created
**And** PostgreSQL assigns a monotonic `ingested_seq` within the Conversation
**And** the provider timestamp is stored as evidence but does not determine processing order.

**Given** an invalid signature, wrong account, malformed schema, unsupported event type, or oversized payload
**When** ingress validation fails
**Then** no customer response, Handoff, notification, or Conversation mutation is created
**And** a PII-minimized rejection record is available to Operations.

**Given** the same provider message ID is delivered repeatedly or concurrently
**When** the events are persisted
**Then** a database uniqueness constraint retains one logical Inbound Message and one processing claim
**And** retries do not allocate another `ingested_seq` or downstream action.

**Given** two valid messages for the same Conversation arrive concurrently or out of provider timestamp order
**When** they are committed
**Then** PostgreSQL gives them a deterministic ingestion order
**And** downstream processing follows that order.

**Given** the workflow export, migration, and sanitized fixtures
**When** the repository's ingress check runs
**Then** valid, invalid, duplicate, concurrent, and wrong-account cases pass
**And** a restart after durable commit loses no accepted Inbound Message
**And** approved pilot-load evidence reports webhook acknowledgement p95 at or below 2 seconds
**And** no production credential or customer data is present in exports, fixtures, logs, or tool arguments.

### Story 1.2: Record Consent and Enforce Opt-Out State

As a customer,
I want my communication consent and opt-out choices enforced immediately,
So that automation contacts me only within the permission I provided.

**Requirements:** FR-3, FR-20; NFR-3, NFR-4, NFR-8, NFR-10.

**Acceptance Criteria:**

**Given** consent evidence is required for an approved communication category
**When** authorized consent is recorded
**Then** its source, scope, timestamp, channel, and actor are stored against the Contact
**And** it authorizes only the matching scope
**And** missing, expired, or out-of-scope consent makes the Conversation ineligible for automated outbound activity.

**Given** a valid inbound message contains a configured opt-out signal
**When** the message is processed
**Then** one PostgreSQL transaction records the evidence, changes the lifecycle to `opted_out`, increments the Conversation version, and records an Audit Event
**And** the current turn cannot authorize an automated response
**And** opt-out takes precedence over objectives, policy, ownership, campaign, retry, and Follow-Up eligibility.

**Given** the same opt-out event is retried or processed concurrently
**When** the state transition executes
**Then** it remains one idempotent lifecycle transition and one logical Audit Event.

**Given** a Contact is already opted out
**When** another inbound message arrives or ownership changes
**Then** neither event automatically restores consent or an active lifecycle
**And** automated eligibility remains denied
**And** automated re-subscription is excluded until an approved consent policy defines it.

**Given** ownership and lifecycle are stored independently
**When** `automation_owner` changes between `ai` and `human`
**Then** an `opted_out` or `closed` lifecycle remains unchanged.

**Given** sanitized consent, missing-consent, duplicate opt-out, concurrent opt-out, later-inbound, and ownership-change fixtures
**When** the repository's consent-state check runs
**Then** every suppression case passes without production credentials or customer data.

### Story 1.3: Stop and Authorize Automated Outbound Intents

As an Operations Owner,
I want one enforceable control point for every automated outbound action,
So that unsafe, stale, or unauthorized messages cannot reach customers.

**Requirements:** FR-3, FR-12, FR-16, FR-19; NFR-2, NFR-3, NFR-5, NFR-10.

**Acceptance Criteria:**

**Given** an authorized Operations Owner
**When** they enable the global stop or disable a Contact or Conversation
**Then** the change records actor, reason, time, expected prior state, and an Audit Event
**And** unauthorized control changes are rejected without changing state.

**Given** a workflow proposes an automated customer action
**When** the atomic PostgreSQL command creates its Outbound Intent
**Then** it assigns a unique logical action key and one generation
**And** snapshots the expected Conversation version and source event
**And** evaluates global stop, scoped disablement, lifecycle, applicable consent, opt-out, automation ownership, Conversation version, and WhatsApp service-window eligibility in deterministic precedence order
**And** missing required evidence fails closed
**And** the result and denial reason are persisted with the intent and Audit Event.

**Given** an Outbound Intent is pending
**When** opt-out, global stop, scoped disablement, Human-Owned state, terminal lifecycle, or a newer committed inbound message invalidates it
**Then** PostgreSQL atomically marks it suppressed or cancelled before dispatch
**And** the reason is immutable and queryable.

**Given** the same logical action is proposed repeatedly or concurrently
**When** the intent command executes
**Then** the unique action key returns the existing intent
**And** no retry allocates another generation.

**Given** a denied or cancelled intent
**When** any workflow attempts to advance it
**Then** the state transition is rejected by the shared database contract.

**Given** this story's scope
**When** the authorization command completes
**Then** no provider network call occurs inside the transaction
**And** commercial-policy and Follow-Up-specific checks will extend this command in later stories rather than create another authorization path.

**Given** sanitized fixtures for every suppression condition, precedence collision, duplicate proposal, stale Conversation version, and unauthorized operator
**When** the repository's authorization check runs
**Then** no prohibited intent becomes dispatchable
**And** no production credentials or customer data are used.

### Story 1.4: Dispatch an Authorized WhatsApp Intent Safely

As a customer,
I want an authorized WhatsApp response delivered without duplicate automatic sends,
So that retries and concurrent workers do not create repeated messages.

**Requirements:** FR-16, FR-19; NFR-1, NFR-2, NFR-5, NFR-7, NFR-10.

**Acceptance Criteria:**

**Given** a dispatchable WhatsApp Outbound Intent
**When** a dispatcher claims it
**Then** one PostgreSQL transaction reruns the final authorization checks
**And** creates a short lease bound to the current Conversation version and worker token
**And** changes the intent to `dispatching`
**And** releases all database locks before the provider call.

**Given** two dispatchers claim the same intent concurrently
**When** their claim transactions execute
**Then** only one receives the active lease
**And** the other performs no provider call.

**Given** a dispatcher holds an active lease
**When** it is ready to call WhatsApp
**Then** it immediately rechecks lease ownership, expiry, suppression state, and Conversation version
**And** uses the native n8n WhatsApp Business operation with an approved n8n credential
**And** the production credential is absent from the exported workflow.

**Given** WhatsApp acknowledges the request
**When** the provider response returns
**Then** its provider message ID is attached to the existing Outbound Intent
**And** the intent records the attempt, workflow release, timestamps, and correlation ID
**And** another automatic provider call for that logical intent is rejected.

**Given** a failure occurs before any provider request can have started
**When** the Retry Policy classifies it as retryable
**Then** the same intent may retry within its configured attempt and age budget
**And** it retains the same logical action key.

**Given** a timeout or connection failure occurs after the provider request may have started
**When** the outcome cannot be proven
**Then** the intent becomes `reconciliation_required`
**And** Operations is alerted
**And** the system does not blindly resend it.

**Given** a `dispatching` lease expires after a worker crash
**When** the system cannot prove that no provider call started
**Then** the intent becomes `reconciliation_required`
**And** it never returns automatically to `pending`
**And** only an audited operator decision may resolve or replay it.

**Given** suppression or a newer inbound message commits before the provider call starts
**When** the dispatcher performs its final recheck
**Then** the intent is cancelled without a provider call.

**Given** suppression commits after the provider call starts
**When** the result is recorded
**Then** the system records that the in-flight request could not be recalled
**And** blocks every later automated action for that Conversation.

**Given** duplicate workers, expired leases, pre-call failure, ambiguous timeout, stale version, and suppression-race fixtures
**When** the repository's dispatch check runs
**Then** each logical intent produces no more than one automatic provider-call start
**And** restart and retry scenarios lose no durable intent or provider response already recorded
**And** the duplicate logical send rate remains below 0.1% under approved pilot load
**And** automation processing-to-send p95 is at or below 10 seconds excluding external provider delivery
**And** ambiguous outcomes require reconciliation instead of automatic replay.

### Story 1.5: Reconcile WhatsApp Delivery Status

As an Operations Owner,
I want WhatsApp delivery callbacks reconciled to the original Outbound Intent,
So that message status remains trustworthy despite callback retries and reordering.

**Requirements:** FR-17, FR-18; NFR-2, NFR-3, NFR-5, NFR-10.

**Acceptance Criteria:**

**Given** a valid callback for the configured WhatsApp account
**When** the status workflow receives it
**Then** authenticity, account identity, schema, size, provider message ID, status, and provider timestamp are validated
**And** an immutable Provider Status Event is appended to the matching Outbound Intent
**And** no callback generates a customer reply or new outbound action.

**Given** the same callback is delivered repeatedly or concurrently
**When** it is persisted
**Then** a database uniqueness constraint retains one logical Provider Status Event
**And** the derived Outbound Intent status changes at most once.

**Given** valid callbacks arrive out of order
**When** the derived status is recalculated
**Then** the versioned provider-status transition rules prevent an older event from downgrading a later confirmed state
**And** every raw callback remains available as immutable evidence.

**Given** two callbacks report conflicting terminal outcomes
**When** neither can be safely discarded
**Then** the Outbound Intent becomes `reconciliation_required`
**And** Operations receives an alert instead of one callback silently overwriting the other.

**Given** a valid callback references an unknown provider message ID
**When** it cannot be matched
**Then** it is stored as an unresolved reconciliation item
**And** it does not create a fabricated Outbound Intent or Conversation association.

**Given** an invalid signature, wrong account, malformed payload, or unsupported status
**When** validation fails
**Then** no business record is mutated
**And** a PII-minimized rejection is available to Operations.

**Given** unresolved or unknown statuses exceed the configured age threshold
**When** the monitoring check runs
**Then** Operations is alerted with correlation-safe references.

**Given** duplicate, concurrent, out-of-order, conflicting, unknown-ID, and invalid callback fixtures
**When** the repository's status-reconciliation check runs
**Then** status history remains immutable and derived state remains deterministic.

### Story 1.6: Request a Human and Lock Automation

As a customer,
I want a request for a representative honored immediately,
So that automation stops and a human receives the evidence needed to continue.

**Requirements:** FR-10, FR-11, FR-12, FR-18; NFR-2, NFR-5, NFR-8, NFR-10.

**Acceptance Criteria:**

**Given** an explicit human request or a configured mandatory-escalation reason
**When** the Conversation transition executes
**Then** one transaction locks the Conversation, sets `automation_owner` to `human`, increments its version, creates or reuses one Handoff, cancels incompatible pending automated intents, and records Audit Events
**And** lifecycle state remains independent and unchanged.

**Given** the Handoff is created
**When** its evidence is stored
**Then** it contains available Lead Facts, explicit unknowns, source-message and transcript pointers, reason, correlation ID, applicable Offer and policy references, a configured assignment-route reference when available, and acknowledgement due time
**And** absent future Epic 2 facts remain unknown rather than invented.

**Given** a clear customer transfer notice is required
**When** the Handoff transaction commits
**Then** it creates at most one fixed, approved, language-matched, non-commercial `handoff_acknowledgement` intent tied to that Handoff and Conversation version and configured after-hours behavior
**And** the intent passes the shared authorization path
**And** no other automated message or Follow-Up is permitted while Human-Owned.

**Given** opt-out is committed before the transfer notice starts its provider call
**When** final authorization runs
**Then** the acknowledgement is suppressed because opt-out has higher precedence.

**Given** the same escalation source is retried or processed concurrently
**When** the Handoff command executes
**Then** it returns the existing Handoff and acknowledgement intent
**And** does not create another ownership transition or notification action.

**Given** a Conversation is Human-Owned
**When** an unauthorized release or automated action is attempted
**Then** it is rejected
**And** only an authorized explicit release with actor, reason, and expected version may restore AI-Owned.

**Given** direct request, mandatory escalation, duplicate request, concurrent request, opt-out race, blocked automation, and authorized-release fixtures
**When** the repository's Handoff-state check runs
**Then** ownership and acknowledgement behavior are deterministic and auditable.

### Story 1.7: Deliver and Acknowledge the Handoff

As a Sales Representative,
I want one actionable Handoff delivered through the selected internal channel,
So that I can acknowledge ownership and continue the customer conversation.

**Requirements:** FR-11, FR-16, FR-17; NFR-2, NFR-3, NFR-5, NFR-8, NFR-10.

**Blocked decision:** Executives must select the CRM or Handoff channel, assignment owner, acknowledgement signal and SLA, timeout behavior, and permanent-failure escalation path before this story can be finalized for implementation.

**Acceptance Criteria:**

**Given** an approved Handoff adapter contract and a newly committed Handoff
**When** the Handoff dispatcher runs
**Then** it creates or reuses one unique notification intent
**And** sends the minimum required evidence and an authenticated least-privilege transcript link to the configured assignment target
**And** no customer data appears in unauthenticated links or broad notification logs.

**Given** the selected channel returns the approved acknowledgement signal
**When** it is authenticated and correlated
**Then** the Handoff changes from `requested` to `acknowledged` once
**And** Conversation ownership remains Human-Owned.

**Given** acknowledgement is not received before its configured due time
**When** the timeout check runs
**Then** the selected after-hours or escalation path executes once
**And** the customer-facing transfer state remains truthful.

**Given** a pre-call notification failure
**When** the centralized Retry Policy permits another attempt
**Then** the original notification intent retries within its attempt and age budget.

**Given** notification delivery is ambiguous or permanently fails
**When** retry or reconciliation limits are reached
**Then** Operations is alerted through the approved escalation path
**And** Human-Owned state is not reverted.

**Given** duplicate dispatcher, acknowledgement replay, timeout, after-hours, ambiguous delivery, and permanent-failure fixtures for the selected adapter
**When** its contract check runs
**Then** one logical Handoff and one acknowledgement transition are preserved.

### Story 1.8: Reconstruct and Recover an Automated Action

As an Operations Owner,
I want to reconstruct and safely recover any failed automated action,
So that incidents can be resolved without hidden state or duplicate side effects.

**Requirements:** FR-18, FR-19; NFR-2, NFR-3, NFR-5, NFR-9, NFR-10.

**Acceptance Criteria:**

**Given** a correlation ID, provider message ID, Handoff ID, or Contact-scoped reference
**When** an authorized operator requests the audit view
**Then** it returns the ordered inbound evidence, consent and ownership state, policy/configuration/workflow references, validation results, intent transitions, provider events, Handoff events, actors, and timestamps needed to explain the action
**And** access is least-privilege and audited.

**Given** mutable configuration or pruned n8n execution data
**When** a historical action is reconstructed
**Then** immutable business provenance remains sufficient without consulting current configuration or chat history.

**Given** an action is `reconciliation_required` or terminally failed
**When** an authorized operator records a recovery decision
**Then** resume, cancel, or audited replay uses the original logical key where required
**And** no new generation is created unless the decision explicitly supersedes the original action.

**Given** the global stop is active
**When** an operator attempts recovery
**Then** no customer-facing replay is dispatchable until an authorized recorded release occurs.

**Given** the release readiness drill
**When** Operations exercises global stop, failure inspection, reconciliation, controlled resume, and backup restore evidence
**Then** results, owner, environment, and approval are recorded
**And** any unresolved RTO/RPO remains an explicit executive blocker rather than an asserted SLO.

**Given** reconstruction, unauthorized access, pruned execution, replay, supersession, active-stop, and recovery-drill fixtures
**When** the repository's operations check runs
**Then** every action remains explainable and recovery cannot bypass authorization.

### Story 1.9: Delete Contact Data Across In-Scope Stores

As an authorized privacy operator,
I want one tracked deletion process for a Contact,
So that customer data is removed consistently without falsely claiming that deferred backups are already erased.

**Requirements:** FR-20; NFR-3, NFR-4, NFR-10.

**Acceptance Criteria:**

**Given** an authenticated, authorized deletion request for one Contact
**When** the request is accepted
**Then** one Deletion Request records scope, requester, legal basis or approved reason, targets, correlation ID, and timestamps
**And** every query and mutation remains scoped by internal Contact and Conversation IDs rather than phone number alone.

**Given** the deletion runs
**When** each immediate target is processed
**Then** operational records are deleted or irreversibly minimized according to the approved field policy
**And** pending outbound work is suppressed
**And** documented provider deletion and n8n execution-purge actions are requested and tracked.

**Given** backups cannot be selectively edited safely
**When** live-store deletion completes
**Then** backup copies remain access-restricted
**And** their scheduled expiry is recorded as a deferred obligation
**And** the request is not represented as fully complete until every immediate target and deferred obligation has an explicit state.

**Given** one Contact deletion is processed
**When** isolation checks run
**Then** no other Contact or Conversation is read, changed, or deleted.

**Given** an unauthorized, malformed, duplicate, or phone-only deletion request
**When** validation runs
**Then** it is rejected or safely correlated without deleting data
**And** the attempt is audited.

**Given** sanitized live-store, provider-request, execution-purge, backup-expiry, duplicate-request, and cross-Contact fixtures
**When** the repository's deletion check runs
**Then** completion state is accurate and isolation is preserved.

### Story 1.10: Promote and Roll Back a Pinned Release

As an Operations Owner,
I want one reproducible promotion and rollback procedure,
So that reviewed database and n8n artifacts reach the correct environment without configuration drift or hidden client state.

**Requirements:** FR-18, FR-19, FR-20; NFR-2, NFR-3, NFR-5, NFR-6, NFR-7, NFR-9, NFR-10.

**Acceptance Criteria:**

**Given** a release candidate
**When** its manifest is generated
**Then** it pins the n8n package and official image digest, PostgreSQL deployment version, supported WhatsApp Graph API version and retirement date, ordered migration set, canonical workflow export hashes, node inventory, every policy, knowledge, prompt, schema, and model version applicable to that release, and test-evidence references
**And** components not yet present in the incremental release are recorded as `not_applicable` rather than treated as future dependencies
**And** no mutable image tag, production credential, or customer data appears in repository artifacts.

**Given** Codex, Antigravity, or OpenCode performs release preparation
**When** the documented repository validation procedure runs
**Then** every client produces the same canonical workflow hashes and validation result through its own verified configuration surface
**And** no chat history or MCP session state is required to reproduce the release.

**Given** a test-environment promotion
**When** release validation runs
**Then** ordered migrations apply before compatible workflows activate
**And** canonical exports import successfully
**And** the production node allowlist, SSRF and egress controls, least-privilege credential map, restricted editor access, and `n8n audit` have no unapproved finding.

**Given** credentialed Meta test assets
**When** the release smoke test runs
**Then** it proves webhook subscription, account identity, permissions, template inventory, callback handling, supported Graph API version, and test/production isolation without exposing credentials.

**Given** the selected managed PostgreSQL service
**When** infrastructure readiness runs
**Then** PostgreSQL 17 compatibility, patched minor, TLS, pooling and connection limits, backup/PITR, restore evidence, maintenance behavior, metrics, and approved region are recorded
**And** unresolved retention or RTO/RPO values remain explicit approval blockers.

**Given** any migration, import, audit, smoke, or readiness check fails
**When** promotion is evaluated
**Then** production activation is blocked
**And** the failure and evidence owner are recorded.

**Given** an activated release must be reversed
**When** an authorized rollback decision is recorded
**Then** the manifest's compatible applicable workflow, schema, policy, prompt, and model rollback procedure executes in safe order
**And** destructive schema reversal is not assumed
**And** post-rollback smoke and reconciliation checks must pass before automation resumes.

## Epic 2: Governed and Grounded Sales Assistance

Authorized managers can publish controlled Product Knowledge and Sales Policy, and opted-in customers can receive grounded answers, evidence-backed qualification, approved Offers, and safe escalation without invented claims or autonomous negotiation.

### Story 2.1: Publish Versioned Product Knowledge

As an authorized Sales Manager,
I want approved product facts published as immutable versions,
So that customer answers use controlled and traceable knowledge.

**Requirements:** FR-4, FR-15, FR-18; NFR-3, NFR-4, NFR-5, NFR-10.

**Acceptance Criteria:**

**Given** an authorized manager uses the approved existing administration surface or repository import
**When** a Product Knowledge draft is submitted
**Then** required identifiers, language, source references, content limits, ownership, and effective dates are validated
**And** the draft is stored separately from the active version
**And** prompt-like instructions cannot grant tools, alter system policy, or bypass validation.

**Given** a valid draft and an authorized approver
**When** publication occurs
**Then** an immutable Product Knowledge version and effective time are recorded
**And** new turns can select it deterministically
**And** prior turns retain their original version references.

**Given** a published version must be replaced
**When** an authorized rollback or successor is published
**Then** the previous version remains immutable and reconstructable
**And** future turns use the selected effective version.

**Given** a factual claim becomes unsafe
**When** an authorized approver safety-revokes its version
**Then** pending intents using that version fail final authorization
**And** affected turns are cancelled and handed off
**And** ordinary replacement does not retroactively invalidate an already authorized in-flight turn.

**Given** malformed, unauthorized, oversized, prompt-injection, publish, rollback, effective-time, and safety-revocation fixtures
**When** the repository's Product Knowledge check runs
**Then** only approved immutable versions become active and historical provenance remains intact.

### Story 2.2: Publish Versioned Sales Policy

As an authorized Sales Manager,
I want commercial and behavioral rules published as typed policy,
So that prices, Offers, claims, and escalation behavior cannot be changed through prompts.

**Requirements:** FR-7, FR-9, FR-15; NFR-3, NFR-5, NFR-10.

**Acceptance Criteria:**

**Given** an authorized manager submits a Sales Policy draft
**When** validation runs
**Then** products, Offer IDs, prices, currencies, tax treatment, fixed discounts, expiry, approved claims, prohibited claims, escalation reasons, language rules, Follow-Up enablement, maximum attempts, delay, business timezone, quiet hours, frequency cap, campaign state, approved template references, and effective dates use typed fields and approved ranges
**And** arbitrary prompt text, OKRs, and conversion targets cannot create commercial authority.

**Given** malformed currency, out-of-range discount, missing approval evidence, conflicting effective dates, or unsupported product terms
**When** validation runs
**Then** publication is rejected with a typed operator-visible reason
**And** active runtime policy is unchanged.

**Given** a valid draft and authorized approver
**When** it is published
**Then** an immutable Sales Policy version and effective time are recorded
**And** new turns snapshot that version
**And** prior decisions remain reconstructable.

**Given** a policy or Offer is revoked or rolled back
**When** final send authorization runs
**Then** pending intents referencing an invalid version are suppressed
**And** the customer turn is handed off when no approved alternative exists.

**Given** unauthorized, malformed, hostile-input, publish, rollback, overlap, and revocation fixtures
**When** the repository's Sales Policy check runs
**Then** runtime can consume only one deterministic approved version for a turn.

### Story 2.3: Benchmark and Pin the Pilot Model Configuration

As a Release Owner,
I want candidate model configurations evaluated against an approved Release Set,
So that the pilot promotes one evidence-backed configuration instead of an assumed model choice.

**Requirements:** FR-6, FR-9, FR-19; NFR-1, NFR-4, NFR-6, NFR-7, NFR-8, NFR-10.

**Acceptance Criteria:**

**Given** approved candidate providers and models whose privacy, retention, residency, availability, and cost constraints are documented
**When** the benchmark runs in the test environment
**Then** it uses sanitized scenarios only
**And** evaluates every approved language, grounded-answer case, Offer case, escalation case, invalid-schema case, prompt-injection case, tone case, and latency/cost measure.

**Given** a benchmark result
**When** it is scored
**Then** grounded-answer quality, critical policy violations, escalation recall and precision, structured-output validity, latency percentiles, and estimated cost are reported separately
**And** missing evidence is not converted into a passing assumption.

**Given** no candidate meets every approved launch threshold
**When** promotion is evaluated
**Then** no model configuration is released
**And** failed dimensions and required decisions are recorded.

**Given** one candidate meets the gates
**When** it is promoted
**Then** provider, model, prompt, schema, evaluation corpus, result hash, and release owner are pinned in the release manifest
**And** runtime routing across untested models remains disabled.

**Given** a repeat benchmark against unchanged inputs
**When** it executes
**Then** its configuration and evidence are reproducible from repository artifacts without chat history or production customer data.

### Story 2.4: Produce a Grounded Typed Model Draft

As an opted-in customer,
I want answers based on approved product facts,
So that the assistant does not present unsupported information as known.

**Requirements:** FR-4, FR-6, FR-9, FR-10; NFR-1, NFR-3, NFR-4, NFR-7, NFR-8, NFR-10.

**Acceptance Criteria:**

**Given** an AI-Owned eligible Conversation and pinned model release
**When** the orchestrator builds the model request
**Then** it includes only the approved field allowlist, bounded Conversation evidence, active Product Knowledge, applicable Sales Policy references, and separate system instructions
**And** excludes credentials, direct identifiers unless explicitly approved, hidden operational data, arbitrary SQL, unrestricted retrieval, and direct send tools.

**Given** customer text contains instructions to ignore policy, reveal prompts, access another Contact, or call an unauthorized tool
**When** the model request is processed
**Then** customer content remains untrusted data
**And** no instruction changes the tool boundary or system policy.

**Given** the model responds
**When** output validation runs
**Then** it must match the pinned schema for response draft, intent candidates, proposed Offer reference, confidence, Product Knowledge source references, and escalation reason
**And** every cited source resolves to the active approved Product Knowledge version.

**Given** the output is invalid, missing sources, contradictory, below the approved confidence threshold, timed out, or unavailable
**When** validation fails
**Then** no customer Outbound Intent is created from the generated draft
**And** the existing Handoff path is invoked with the typed failure reason.

**Given** a valid draft
**When** it is persisted
**Then** model, prompt, schema, policy, knowledge, workflow release, source inbound, correlation ID, and validator result are recorded
**And** the draft remains untrusted until later deterministic authorization.

**Given** valid, unsupported, injection, cross-Contact, invalid-schema, timeout, and low-confidence fixtures
**When** the repository's model-boundary check runs
**Then** only typed grounded drafts advance and none can send directly.

### Story 2.5: Capture Evidence-Linked Lead Facts

As a Sales Representative,
I want qualification facts linked to the customer's own messages,
So that I can distinguish confirmed information from unknown or generated summaries.

**Requirements:** FR-5, FR-18; NFR-3, NFR-4, NFR-5, NFR-10.

**Acceptance Criteria:**

**Given** a valid typed model draft proposes qualification data
**When** Lead Facts are validated
**Then** only fields in the active approved qualification schema are accepted
**And** every value includes its source inbound message and extraction provenance
**And** absent values remain explicitly unknown.

**Given** a generated summary conflicts with customer evidence
**When** persistence runs
**Then** the customer evidence remains authoritative
**And** the conflicting proposal is rejected or flagged for Handoff.

**Given** the customer later corrects a fact
**When** the correction is processed
**Then** a new evidenced fact version supersedes the prior value without erasing historical provenance.

**Given** a workflow queries Lead Facts
**When** Contact and Conversation scope do not match
**Then** no data is returned or changed
**And** the denied access is audited.

**Given** approved-field, unknown, conflict, correction, duplicate, and cross-Contact fixtures
**When** the repository's Lead Fact check runs
**Then** every active fact is traceable to customer evidence and generated text cannot overwrite it.

### Story 2.6: Authorize Grounded Answers and Approved Offers

As a customer,
I want every answer and Offer checked against current approved rules,
So that the assistant cannot invent terms or present withdrawn claims.

**Requirements:** FR-4, FR-7, FR-8, FR-9, FR-16, FR-18; NFR-1, NFR-2, NFR-3, NFR-5, NFR-8, NFR-10.

**Acceptance Criteria:**

**Given** a valid model draft
**When** deterministic commercial validation runs
**Then** each factual source resolves to the snapshotted Product Knowledge version
**And** product, Offer ID, price, currency, tax treatment, discount, expiry, and claims exactly match the snapshotted Sales Policy
**And** prohibited content and hidden-instruction disclosure checks pass.

**Given** a custom term, unsupported claim, missing source, mismatched value, expired or revoked Offer, or safety-revoked knowledge version
**When** validation runs
**Then** the draft is rejected with a typed reason
**And** no customer Outbound Intent is created from it
**And** the existing Handoff path is invoked when clarification cannot safely resolve it.

**Given** a draft passes validation
**When** the customer Outbound Intent is created
**Then** it snapshots the model, prompt, Product Knowledge, Sales Policy, Offer, template if applicable, validator, source inbound, and expected Conversation version
**And** customer text uses the approved language, clear non-aggressive wording, and no image- or color-only instruction
**And** the first automated interaction includes approved bot disclosure, opt-out instructions, and a direct human-escalation path
**And** it enters the shared final authorization and dispatch path from Epic 1.

**Given** a newer inbound message, opt-out, ownership change, policy revocation, or knowledge safety revocation occurs before provider-call start
**When** final authorization reruns
**Then** the older intent is suppressed or cancelled.

**Given** valid answer, approved Offer, custom terms, mismatched price, expired Offer, unsupported claim, revoked knowledge, stale version, and injection-output fixtures
**When** the repository's deterministic sales check runs
**Then** only grounded policy-exact content becomes dispatchable.

### Story 2.7: Escalate Uncertainty, Safety Risks, and Buying Intent

As a customer,
I want uncertain or sensitive situations transferred safely to a representative,
So that automation does not bluff, pressure me, or make binding decisions.

**Requirements:** FR-6, FR-9, FR-10, FR-11, FR-12; NFR-2, NFR-5, NFR-8, NFR-10.

**Acceptance Criteria:**

**Given** an explicit human request, buying intent, complaint, privacy/legal/safety topic, unsupported request, policy exception, invalid model result, low confidence, conflicting sources, or system failure
**When** the turn is classified
**Then** the existing atomic Handoff command creates or reuses one Handoff and sets Human-Owned
**And** no model-declared intent records `closed_won` or binding approval.

**Given** a failure category has a fixed Approved Fallback
**When** the Handoff transition occurs
**Then** only the approved non-commercial acknowledgement may enter the shared authorization path
**And** it cannot restore AI-Owned state or introduce a commercial claim.

**Given** no Approved Fallback exists
**When** escalation occurs
**Then** the system fails silently on generated customer content while still creating and dispatching the internal Handoff.

**Given** the approved multilingual Release Set
**When** runtime behavior is evaluated
**Then** explicit human request and opt-out recall meet the approved threshold
**And** zero critical cases contain unauthorized terms, deceptive urgency, unsupported personalization, hidden-instruction disclosure, cross-Contact data, or post-Handoff automation
**And** tone, repetition, pressure, and language-switching results are reported.

**Given** a failed or unavailable model provider
**When** retries exhaust their finite policy
**Then** Operations is alerted
**And** Human-Owned state and the original logical action evidence are preserved.

**Given** every escalation category, duplicate trigger, multilingual case, provider outage, fallback-present, and fallback-absent fixture
**When** the repository's escalation check runs
**Then** authority consistently transfers to a human without autonomous deal closure.

## Epic 3: Compliant Customer Re-engagement

An eligible silent customer receives at most the approved Follow-Up, while new inbound messages, opt-out, Human-Owned state, lifecycle changes, campaign stops, timing rules, and WhatsApp service-window restrictions suppress stale or prohibited messages.

### Story 3.1: Schedule and Cancel a Durable Follow-Up

As an eligible customer,
I want Follow-Up work scheduled and cancelled according to my latest Conversation state,
So that stale automation does not contact me after I reply, opt out, or move to a representative.

**Requirements:** FR-13; NFR-2, NFR-5, NFR-10.

**Acceptance Criteria:**

**Given** an eligible AI-Owned Conversation reaches an approved Follow-Up trigger
**When** the scheduling command runs
**Then** it creates at most the configured number of Follow-Up records
**And** each stores UTC due time, generation, unique action key, source Conversation version, campaign, policy, template or approved-content reference, and correlation ID
**And** no n8n Wait execution is created per lead.

**Given** required consent is missing, the Contact is opted out, the Conversation is Human-Owned or terminal, the campaign is stopped, or the configured frequency limit is reached
**When** scheduling is attempted
**Then** no pending Follow-Up is created
**And** the denial reason is audited.

**Given** the same scheduling trigger is retried or processed concurrently
**When** the command executes
**Then** the unique action key returns the existing Follow-Up
**And** no additional generation is allocated.

**Given** a pending Follow-Up
**When** a new inbound message, opt-out, Human-Owned transition, closed or lost lifecycle, campaign stop, or explicit superseding schedule commits
**Then** stale Follow-Ups are cancelled or superseded in the same state-changing transaction
**And** their immutable reason and source Conversation version remain queryable.

**Given** business timezone and quiet-hour rules
**When** the due time is persisted
**Then** storage uses UTC `timestamptz`
**And** timezone conversion is deferred to final eligibility rather than baked into an unchangeable Wait execution.

**Given** eligible, ineligible, duplicate, concurrent, reply, opt-out, Human-Owned, terminal, campaign-stop, supersession, and timezone-boundary fixtures
**When** the repository's Follow-Up scheduling check runs
**Then** each eligible trigger has at most one active logical job and every stale job is visibly cancelled.

### Story 3.2: Claim and Authorize Due Follow-Ups

As an eligible silent customer,
I want a Follow-Up sent only when every current permission and timing rule still allows it,
So that delayed jobs cannot bypass consent, ownership, or WhatsApp messaging restrictions.

**Requirements:** FR-3, FR-12, FR-13, FR-14, FR-16, FR-17; NFR-1, NFR-2, NFR-5, NFR-8, NFR-10.

**Acceptance Criteria:**

**Given** the published n8n Schedule Trigger uses explicit UTC configuration
**When** it runs after normal operation or downtime
**Then** it queries a bounded batch where `due_at <= now()`
**And** includes overdue catch-up work
**And** claims each job with a short lease so concurrent schedulers cannot create duplicate intents.

**Given** a claimed due Follow-Up
**When** final eligibility runs immediately before intent creation
**Then** it rechecks global stop, scoped disablement, lifecycle, consent scope, opt-out, automation ownership, expected Conversation version, last eligible inbound time, Sales Policy and Product Knowledge validity, frequency, quiet hours, campaign state, and WhatsApp service window
**And** missing evidence fails closed.

**Given** the customer-service window is closed
**When** final eligibility runs
**Then** only an active approved template ID with the correct category and language may proceed
**And** generated or free-form text is rejected.

**Given** the window is open
**When** approved Follow-Up content is selected
**Then** it still matches the snapshotted Sales Policy and approved content reference
**And** it enters the same Outbound Intent, final authorization, lease, dispatcher, provider-status, and reconciliation paths delivered by Epic 1.

**Given** any eligibility check fails
**When** the claim is finalized
**Then** the Follow-Up becomes suppressed, cancelled, or expired with a typed immutable reason
**And** no customer Outbound Intent or provider call is created.

**Given** two schedulers claim the same job or a Conversation change races with a claim
**When** their transactions execute
**Then** at most one authorized Outbound Intent is created
**And** the expected Conversation version causes stale work to lose.

**Given** backlog size or oldest due-job age exceeds configured pilot thresholds
**When** monitoring runs
**Then** Operations is alerted with PII-minimized correlation references.

**Given** eligible-window, approved-template, closed-window free-form, quiet-hour, frequency, campaign-stop, opt-out, Human-Owned, stale-version, concurrent-claim, and downtime-catch-up fixtures
**When** the repository's Follow-Up execution check runs
**Then** only one currently eligible logical Follow-Up becomes dispatchable and every prohibited case remains unsent.
