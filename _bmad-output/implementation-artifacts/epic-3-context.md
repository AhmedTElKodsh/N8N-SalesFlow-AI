# Epic 3 Context: Compliant Customer Re-engagement

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Enable compliant re-engagement of eligible customers who become silent by scheduling durable Follow-Up work and sending at most the approved message only after current consent, ownership, lifecycle, campaign, timing, frequency, and WhatsApp service-window rules are rechecked. Stale or prohibited outreach must end without a customer message, preserving customer choice while giving the pilot a measurable, auditable re-engagement path.

## Stories

- Story 3.1: Schedule and Cancel a Durable Follow-Up
- Story 3.2: Claim and Authorize Due Follow-Ups

## Requirements & Constraints

- For SP3-T3, schedule one Follow-Up for a silence episode exactly 12 hours after its approved automated reply first reaches durable sent state; a newer sent reply supersedes the pending reminder. Each job must carry a UTC due time, generation, unique logical action key, source sent intent and Conversation version, campaign, applicable policy, approved content or template reference, and correlation ID.
- Do not schedule when consent evidence is missing, the Contact is opted out, the Conversation is Human-Owned or terminal, or the campaign is stopped. Evaluate the rolling frequency limit at due time and immediately before the provider call; record any denial reason for audit.
- A new inbound message, opt-out, Human-Owned transition, closed or lost lifecycle, campaign stop, or superseding schedule must cancel or supersede stale pending work while retaining an immutable reason.
- Select due work exactly once, including overdue work after downtime, and recheck all current permissions immediately before creating a customer-send intent. Missing or ambiguous eligibility evidence fails closed.
- Recheck the global stop, scoped disablement, lifecycle, consent scope, opt-out, automation ownership, expected Conversation version, last eligible inbound time, policy and knowledge validity, frequency, quiet hours, campaign state, and WhatsApp customer-service window.
- Outside the customer-service window, only an active approved template with the correct category and language may proceed. Free-form or generated content must not send. Approved interactive templates are in scope; outbound documents and inbound media interpretation are not.
- Reliability evidence must cover retries, restarts, concurrent scheduling and claims, stale-version races, downtime catch-up, and duplicate suppression. The pilot target is fewer than 0.1% duplicate logical sends, with no business-data loss in restart and retry tests.
- Correlation IDs must connect Follow-Up scheduling and execution to the Conversation, outbound intent, provider status, and audit evidence. Expose backlog size and oldest-due-job age now; thresholded alerting remains blocked until pilot thresholds, destination, and Operations ownership are approved.

## Technical Decisions

- PostgreSQL owns Follow-Up and Conversation business state; n8n orchestrates. A published Schedule Trigger with explicit UTC configuration queries bounded batches where `due_at <= now()`. Do not use one n8n Wait execution per lead.
- Store time as UTC `timestamptz`. Apply the approved business timezone only when evaluating quiet hours and template eligibility so policy changes can be honored at execution time.
- Use a stable logical action key based on Conversation, source event, action type, and generation. Allocate a generation once for new logical work; retries and concurrent attempts reuse it, while only explicit supersession advances it.
- Serialize state-changing work with a PostgreSQL transaction and row/advisory locking or compare-and-set versioning. Scheduling, cancellation or supersession, and its Audit Event must commit atomically; separate n8n nodes do not form a transaction.
- Claim due jobs with a short lease and expected Conversation version. Concurrent schedulers must not create duplicate intents, and stale work must lose if Conversation state changes.
- Follow-Ups use the same deterministic authorization gate, Outbound Intent, version-bound dispatch lease, dispatcher, provider-status, and reconciliation path as every other customer send. No second send path is permitted.
- The final gate runs before every provider call, including retries, and applies suppression checks in the shared order. A failed check records a typed immutable outcome before any external call.
- Retry budgets, age limits, backoff, and jitter are finite and centralized. Pre-call exhaustion terminalizes the parent and suppresses the child while preserving the original logical key; post-call uncertainty enters reconciliation. Thresholded Operations alerts remain blocked until thresholds, destination, and ownership are approved.
- Keep the pilot topology to one pinned n8n runtime and managed PostgreSQL. Redis, queue mode, workers, and high-availability components require measured backlog or an approved service-level need.

## UX & Interaction Patterns

- The customer experiences at most one approved Follow-Up for the logical trigger, or no message when current eligibility fails. A reply, opt-out, or transfer to a representative suppresses stale automation.
- Customer-facing Follow-Up content must be clear, concise, respectful, non-aggressive, and available in the approved language. Consent, quiet-hour, frequency, complaint, and opt-out protections take precedence over revival or conversion metrics.

## Cross-Story Dependencies

- Story 3.1 establishes durable job identity, provenance, cancellation, and Conversation-version binding; Story 3.2 depends on those records to claim and authorize due work safely.
- Both stories depend on Epic 1's Contact and Conversation state, consent and opt-out controls, Human-Owned lockout, transactional outbox, final authorization, dispatch lease, provider-status reconciliation, audit trail, kill switch, and operational recovery paths.
- Execution depends on Epic 2's immutable Sales Policy and Product Knowledge versions, approved Follow-Up limits and delays, quiet hours, frequency caps, campaign state, and approved template or content references.
- Production activation requires approved consent evidence, opt-out wording, WhatsApp templates and service-window rules, operating timezone and hours, frequency caps, campaign controls, managed PostgreSQL, separate test and production Meta assets, and named Operations ownership. Technical foundation work may proceed with synthetic fixtures, but unresolved production contracts remain launch blockers.
