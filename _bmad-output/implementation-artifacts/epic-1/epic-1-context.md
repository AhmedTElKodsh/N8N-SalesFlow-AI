# Epic 1 Context: Safe WhatsApp Conversation and Human Handoff

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Enable an opted-in customer to enter the WhatsApp flow safely, opt out, or request a representative while ensuring each inbound message leads to at most one traceable response or Handoff. This epic establishes the non-LLM safety boundary for trusted ingress, durable state, consent, Human-Owned lockout, provider reconciliation, recovery, and customer-data lifecycle management.

## Stories

- Story 1.1: Accept and Record a Trusted WhatsApp Message
- Story 1.2: Record Consent and Enforce Opt-Out State
- Story 1.3: Stop and Authorize Automated Outbound Intents
- Story 1.4: Dispatch an Authorized WhatsApp Intent Safely
- Story 1.5: Reconcile WhatsApp Delivery Status
- Story 1.6: Request a Human and Lock Automation
- Story 1.7: Deliver and Acknowledge the Handoff
- Story 1.8: Reconstruct and Recover an Automated Action
- Story 1.9: Delete Contact Data Across In-Scope Stores
- Story 1.10: Promote and Roll Back a Pinned Release

## Requirements & Constraints

- Authenticate events for the configured WhatsApp account, validate schema and size, normalize accepted messages, and persist them before downstream action. Rejected events create no customer response, Handoff, notification, or Conversation mutation; retain only a PII-minimized rejection record for Operations.
- Enforce unique provider inbound message IDs and serialize state changes per Conversation so retries, replays, duplicates, and concurrency yield at most one logical response.
- Record consent evidence where required, recognize approved opt-out signals, and suppress pending outbound work immediately. Opt-out overrides campaign, retry, policy, Follow-Up, and business objectives.
- Honor explicit human requests and escalate uncertainty, complaints, privacy/legal/safety topics, unsupported requests, commercial exceptions, buying intent, and system failures. Human takeover must atomically set Human-Owned and create or reuse one evidence-backed Handoff.
- Human-Owned blocks automated replies and Follow-Ups. The sole exception is one fixed, approved, language-matched transfer acknowledgement committed with the Handoff; only an authorized, audited release may restore AI-Owned for an active Conversation.
- Persist a unique durable intent before every customer send or Handoff notification, reuse it across retries, reconcile provider callbacks idempotently, and leave ambiguous or unknown delivery visible for Operations.
- Preserve immutable, correlation-linked evidence for inputs, state, validation, intents, provider events, Handoffs, releases, approvals, and actors so actions remain reconstructable after n8n execution data is pruned.
- Provide global stop, Conversation disablement, failure inspection, controlled resume or replay, and tracked Contact-scoped deletion across live stores, provider requests, execution purge, and deferred backup expiry.
- Pilot targets include webhook acknowledgement p95 at or below two seconds, duplicate logical sends below 0.1%, and no business-data loss in restart/retry checks. They are not production SLA claims; RTO/RPO require approval.
- Use least-privilege credentials, isolated test/production channels, PII-minimized logs, authenticated transcript links, encryption, retention controls, and secret redaction. Credentials and customer data must not enter prompts, logged arguments, exports, fixtures, or source control.

## Technical Decisions

- PostgreSQL is the business-state authority; n8n orchestrates persisted stages and its execution history is diagnostic only. One migration stream owns shared aggregates, identifiers, states, constraints, and atomic commands.
- `automation_owner` (`ai|human`) and lifecycle (`active|opted_out|closed`) are separate. Only `active+ai` is automation-eligible.
- PostgreSQL assigns a monotonic `ingested_seq` per Conversation. Provider timestamps remain evidence; newer committed inbound work invalidates older unsent work through Conversation-version guards.
- State-changing work serializes per Conversation and atomically commits state, unique Handoff/outbox intent, and Audit Event. External dispatch follows without holding database locks.
- Outbound keys use Conversation, source event, action type, and a generation allocated once per new action. Retries reuse the key; only explicit supersession advances generation.
- One deterministic gate runs before every provider call, checking stops, lifecycle, consent, opt-out, ownership, Conversation version, policy validity, WhatsApp window/template eligibility, quiet hours, frequency, and campaign state in defined order.
- Dispatch claims a short lease bound to the current Conversation version, verifies it immediately before the network call, and treats provider-call start as the external linearization boundary.
- Provider callbacks are immutable and derived delivery state advances monotonically. Central finite retry exhaustion requires reconciliation; audited replay preserves the original logical key.
- Internal UUIDs scope queries; phone numbers are channel identifiers. Use UTC `timestamptz`, parameterized SQL, lowercase states, PII-minimized logs, and correlation IDs.
- The pilot remains one pinned n8n runtime plus managed PostgreSQL. Queue mode, Redis, workers, multi-main, extra numbers, multi-tenancy, media, and custom UI remain deferred pending evidence and design.
- Releases pin runtime/image, PostgreSQL, Graph API, migrations, workflow hashes, node inventory, and applicable configuration. Migrations precede workflow activation; rollback does not assume destructive schema reversal.

## UX & Interaction Patterns

Interaction remains in WhatsApp; no custom UI is planned. Disclosure, opt-out, escalation, and transfer status must be clear in every approved language without relying on color or images. Customers may request a human at any stage, receive truthful after-hours behavior, and receive no automation after Human-Owned begins.

## Cross-Story Dependencies

- Trusted normalized intake and canonical ordering precede consent evaluation, outbound authorization, Handoff, audit reconstruction, and provider reconciliation.
- Consent, opt-out, lifecycle, ownership, Conversation version, and operational-stop state feed the single pre-send authorization gate used by every reactive, retry, fallback, and scheduled path.
- Live Handoff delivery and acknowledgement remain blocked until the CRM/channel, assignment owner, acknowledgement signal and SLA, after-hours/timeout behavior, and permanent-failure escalation path are approved.
- Credentialed Meta readiness must prove separate test/production assets, identity, permissions, webhook subscription, templates, supported Graph API version, callbacks, and duplicate/out-of-order behavior.
- Managed PostgreSQL readiness must prove PostgreSQL 17 compatibility, TLS, pooling limits, backup/PITR and restore, maintenance, metrics, and approved region.
- Promotion also needs approved consent/template rules, data map and retention/deletion obligations, privacy/legal/security review, named Operations ownership, kill-switch/recovery drills, and explicit unresolved RTO/RPO handling.
- Epics 2 and 3 consume this epic's Conversation, Handoff, audit, outbox, consent, ownership, and final-authorization contracts; neither may bypass them.
