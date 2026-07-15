---
title: N8N SalesFlow AI PRD
status: review-required
created: 2026-07-14
updated: 2026-07-14
source: ../../../../PRD_ N8N Sales AI Agent.docx
---

# PRD: N8N SalesFlow AI

## 0. Document Purpose

This PRD replaces the executive concept note as the proposed requirements authority for technical architecture, delivery, security, testing, and operations planning. Engineering decisions use safe platform-native defaults; executive input is reserved for choices that change commercial authority, compliance, cost/SLO, or an external-system contract. The approval requested now is permission to continue BMAD epic planning; it is not authorization to implement or launch. Stable IDs are used for downstream architecture and stories. Inline assumptions are indexed in §13.

## 1. Vision and Product Thesis

N8N SalesFlow AI shortens the path from an opted-in WhatsApp inquiry to a useful human sales conversation. It automates repeatable, policy-safe work: approved answers, qualification, pre-approved offers, eligible follow-up, and evidence-backed Handoff.

The thesis is not “an LLM can close deals.” The thesis is that a controlled assistant can improve response consistency and sales-team focus without delegating binding commercial authority. `[ASSUMPTION: current response delay, repetitive qualification effort, and inconsistent answers are material enough to justify a controlled pilot; the executive source provides no baseline evidence.]` The orchestration platform coordinates work, a durable operational store owns business state, an LLM produces an untrusted structured draft, and deterministic gates plus humans authorize side effects.

## 2. Target Users and Journeys

### 2.1 Jobs To Be Done

- A Customer gets a timely, accurate answer and can reach a human without fighting automation.
- A Sales Representative receives a qualified, traceable Handoff and knows what is confirmed versus unknown.
- A Sales Manager changes approved sales behavior without editing prompts or deploying workflows.
- An Operations Owner can stop automation, diagnose failure, and reconstruct any customer-facing action.

### 2.2 Non-Users for MVP

Cold prospects without consent; customers needing unsupported products or custom legal terms; voice-only users; teams requiring a new management dashboard; and multiple business tenants.

### 2.3 Key User Journeys

- **UJ-1. Mariam gets an approved answer and asks to buy.** Mariam, an opted-in prospect, messages the pilot WhatsApp number in an approved language. The Assistant answers from Product Knowledge, records Lead Facts, presents the approved offer, and detects buying intent. It creates a Handoff with transcript evidence and changes the Conversation to Human-Owned. Mariam sees that a representative will continue. If the answer is unsupported or uncertain, the same Handoff occurs without an invented answer.
- **UJ-2. Karim takes ownership without duplicate bot replies.** Karim, the assigned Sales Representative, receives one Handoff containing known Lead Facts, unknowns, policy version, proposed offer, and an authenticated transcript link. He acknowledges ownership. No automated reply or follow-up can send until an authorized user explicitly releases the Conversation.
- **UJ-3. Salma publishes a controlled policy change.** Salma, the Sales Manager, submits a typed Sales Policy change. The system validates required fields and rejects prompt-like or out-of-range values. An authorized approver publishes a version with an effective time. New turns snapshot it; old decisions remain reconstructable. `[ASSUMPTION: the MVP may use an existing internal editing/approval surface rather than a custom dashboard.]`
- **UJ-4. Omar receives one compliant follow-up.** Omar becomes silent after an eligible exchange. At due time, the system selects the Follow-Up exactly once, rechecks consent, opt-out, Conversation ownership, last inbound time, quiet hours, campaign status, and WhatsApp window. It sends either an approved template or nothing. A reply, opt-out, or Handoff cancels the job.

## 3. Glossary

- **Assistant** — The automated WhatsApp participant. It has no binding commercial authority.
- **Contact** — Internal identity linked to a WhatsApp channel identifier; the phone number alone is not identity authority.
- **Conversation** — A Contact's thread on the pilot WhatsApp number, including ownership and state.
- **AI-Owned** — Conversation state in which eligible automated replies may be sent.
- **Human-Owned** — Conversation state in which all automated replies and Follow-Ups are blocked.
- **Product Knowledge** — Approved, versioned facts and claims the Assistant may use.
- **Sales Policy** — Approved, typed commercial and behavioral constraints: products, prices, fixed offers, prohibited claims, escalation rules, and effective dates.
- **Lead Facts** — Structured customer-provided qualification data with evidence references.
- **Handoff** — Evidence-backed transfer request to a Sales Representative; it is not a closed deal.
- **Follow-Up** — A scheduled outbound attempt subject to consent, ownership, timing, template, and frequency rules.
- **Offer** — A price and terms combination explicitly present in the active Sales Policy.
- **Audit Event** — Append-only record of an input, state change, decision, approval, or side effect.
- **Approved Fallback** — Pre-approved customer text identified by Sales Policy for a specific failure category; it contains no generated commercial claim.
- **Eligible Conversation** — Conversation included in pilot measurement after applying the approved consent, market, offer, language, duplicate, test, and internal-contact exclusions.
- **Accepted Handoff** — Handoff acknowledged by the configured human queue as actionable under the approved qualification rule.
- **Release Set** — Versioned labeled scenarios and adversarial cases approved as the minimum launch evaluation corpus.
- **Critical Policy Violation** — Release Set outcome in the approved zero-tolerance categories, including unauthorized terms, opt-out failure, cross-Contact disclosure, deceptive claim, or post-Handoff automated send.

## 4. Features and Functional Requirements

### 4.1 Trusted WhatsApp Intake

**FR-1: Authenticate and normalize inbound events**  
The system shall accept only events for the configured WhatsApp account, validate authenticity before processing where the integration surface exposes the signature, validate the expected schema and size, and persist a normalized inbound record. Realizes UJ-1.

**Consequences:** Invalid, oversize, unsupported, or wrong-account events create no customer-facing or notification side effect; secrets and raw credentials never enter execution output.

**FR-2: Deduplicate and order message processing**  
The system shall enforce uniqueness on provider inbound message ID and serialize state changes per Conversation.

**Consequences:** Replay, retry, duplicate, and concurrent-message tests produce at most one logical response action per inbound message; late delivery-status callbacks do not generate replies.

**FR-3: Record consent and opt-out state**  
The system shall store consent source, scope, and timestamp when required, recognize configured opt-out signals, and suppress all pending outbound work immediately after opt-out.

**Consequences:** Opt-out overrides every OKR, Sales Policy, Follow-Up, retry, and campaign action.

### 4.2 Grounded Answering and Qualification

**FR-4: Use approved Product Knowledge**  
The Assistant shall answer only from the active Product Knowledge version and shall not present an unsupported fact as known. Realizes UJ-1.

**Consequences:** Each factual answer records source identifiers; missing or conflicting knowledge causes clarification or Handoff, not invention.

**FR-5: Capture Lead Facts with evidence**  
The Assistant shall collect only the approved qualification fields and link each stored Lead Fact to the source message.

**Consequences:** Unknown values remain unknown; generated summaries cannot overwrite customer evidence.

**FR-6: Return a typed model draft**  
The model step shall return a validated structure containing response draft, intent candidates, proposed Offer reference, confidence, source references, and escalation reason.

**Consequences:** Invalid structure, missing sources, low confidence, or unsupported action fails closed to Handoff or approved fallback.

### 4.3 Commercial and Safety Guardrails

**FR-7: Enforce Sales Policy outside the model**  
The system shall validate product, price, currency, tax treatment, discount, expiry, prohibited claims, and applicable policy version before creating a send intent.

**Consequences:** Customer text, Product Knowledge, management input, and model output cannot create a value absent from the published Sales Policy.

**FR-8: Restrict commercial authority**  
The Assistant may present only an approved Offer and shall not accept custom terms, generate a contract, or record a deal as closed.

**Consequences:** Every exception creates a Handoff; only a human/CRM may record approval or `closed_won`.

**FR-9: Apply prohibited-content and escalation rules**  
The system shall block deceptive urgency, unsupported claims, discriminatory treatment, disclosure of hidden instructions, and disallowed sensitive-topic handling. Customer-facing text shall be clear, concise, natural, respectful, non-aggressive, and personalized only from approved Lead Facts.

**Consequences:** Release red-team scenarios must produce no critical policy violation. The Release Set includes tone, repetition, pressure, unsupported-personalization, and language-switching cases; critical manipulation or invented personal detail is a failure.

### 4.4 Human Handoff and Ownership

**FR-10: Offer direct human escalation**  
The Assistant shall honor an explicit human request and shall escalate uncertainty, complaint, privacy/legal/safety topic, policy exception, unsupported request, buying intent, or system failure. Realizes UJ-1 and UJ-2.

**Consequences:** The customer receives a clear transfer acknowledgement; after-hours behavior is configured and disclosed.

**FR-11: Create one evidence-backed Handoff**  
The system shall atomically change the Conversation to Human-Owned and create one Handoff containing Lead Facts, unknowns, Offer/policy version, reason, transcript pointers, correlation ID, configured assignment target, and acknowledgement due time.

**Consequences:** Retries reuse the existing Handoff; notification failure does not revert ownership and follows the approved after-hours/escalation path.

**FR-12: Enforce Human-Owned lockout**  
The system shall block all automated replies and Follow-Ups while a Conversation is Human-Owned, except one precommitted approved non-commercial transfer acknowledgement tied to the atomic Handoff transition.

**Consequences:** The transfer acknowledgement uses fixed approved text for the applicable approved language and configured after-hours behavior, is created in the same transaction as the Handoff, and cannot be recreated as a new logical action. Only an authorized explicit release may return the Conversation to AI-Owned, and that transition is audited.

### 4.5 Compliant Follow-Up

**FR-13: Persist due Follow-Ups**  
The system shall create at most the configured number of Follow-Ups with due time, generation, source Conversation version, and unique action key. Realizes UJ-4.

**Consequences:** A new inbound message, opt-out, Human-Owned transition, closed/lost status, campaign stop, or superseding job cancels stale work.

**FR-14: Recheck eligibility immediately before send**  
The system shall select a due Follow-Up exactly once and recheck consent, opt-out, ownership, last inbound time, frequency, quiet hours, campaign state, and WhatsApp customer-service window.

**Consequences:** Outside the window only an approved eligible template ID may send; an ineligible job ends without a free-form message.

**MVP media boundary:** Interactive approved WhatsApp templates are supported when required by FR-14. Outbound documents and all inbound voice/image/document interpretation are deferred; a representative sends documents after Handoff.

### 4.6 Policy Administration, Audit, and Operations

**FR-15: Publish versioned configuration**  
Authorized managers shall create typed Product Knowledge and Sales Policy drafts; an authorized approver publishes versions with effective time and rollback target. Realizes UJ-3.

**Consequences:** Runtime never consumes live spreadsheet cells or arbitrary prompt text; malformed or hostile configuration is rejected.

**FR-16: Ensure single logical side effects**  
Customer sends and Handoff notifications shall be represented by a unique durable intent before dispatch; retries shall reuse the same intent.

**Consequences:** Partial failure or workflow retry cannot create a second logical action.

**FR-17: Reconcile provider status**  
The system shall attach WhatsApp provider message IDs and delivery/read/failure callbacks to the existing outbound record.

**Consequences:** Unknown status remains visible for operator reconciliation; callback retries are idempotent.

**FR-18: Preserve decision provenance**  
The system shall record Audit Events for inbound references, consent/opt-out, Conversation state, Sales Policy/Product Knowledge/prompt/model/template/workflow versions, validation result, send intent/status, Handoff, approval, and actor.

**Consequences:** An authorized reviewer can reconstruct why any Offer or message was sent without consulting mutable current configuration.

**FR-19: Provide operational controls**  
An Operations Owner shall be able to stop automated outbound globally, disable a Conversation, inspect failed actions, and resume only after a recorded decision.

**Consequences:** The kill switch is exercised before pilot launch; provider or model outage fails closed to approved fallback or Handoff.

**FR-20: Enforce data lifecycle**  
The system shall apply an approved field allowlist for model payloads, role-based access, encryption in transit/at rest, retention, deletion, and backup rules.

**Consequences:** Cross-Contact tests cannot retrieve another Conversation; deletion propagates through operational stores and documented provider paths.

## 5. Non-Goals

- Autonomous discount, scope, SLA, warranty, or contract negotiation.
- Legal determination of agreement or deal closure.
- Cold outbound prospecting or contact without required consent.
- Custom management dashboard or customer web application.
- Voice, image, attachment, or document understanding.
- Multiple tenants, products, markets, WhatsApp numbers, unrestricted languages, or LLM routing.
- Vector retrieval for a pilot knowledge set that fits controlled structured storage.
- Queue mode, Redis, multi-main, or 99.9% high availability before load and budget justify them.

## 6. Cross-Cutting Non-Functional Requirements

- **Performance:** `[ASSUMPTION]` webhook acknowledgement p95 ≤2 seconds and automation processing-to-send p95 ≤10 seconds under the approved pilot load; measure separately and exclude external provider delivery time from the latter.
- **Reliability:** Duplicate logical send rate <0.1% in pilot; no data loss in restart and retry tests; RTO/RPO require executive approval before a production SLO is claimed.
- **Security:** Least-privilege credentials, separate test/production WhatsApp apps or numbers, no community/custom nodes without review, protected internal transcript links, secrets redacted from executions, and n8n security audit before launch.
- **Privacy:** Data minimization and provider terms are launch blockers; “mask where possible” is not acceptance.
- **Observability:** Correlation IDs join inbound event, Conversation turn, model decision, send intent, provider status, Follow-Up, and Handoff. Alerts cover backlog, failure rate, unknown delivery status, policy rejection, and kill-switch state.
- **Implementation provenance:** Agent clients may use installed Skills, MCPs, and CLIs, but every change must land as reviewable repository artifacts and pass the same test-environment checks. No required build knowledge may exist only in a Codex, Antigravity, or OpenCode session.
- **Secret handling:** Production credentials and customer data must not appear in prompts, MCP/CLI arguments that are logged, exported workflow JSON, fixtures, or source control.
- **Accessibility and language:** Human escalation must be available in every approved language; bot disclosure and opt-out instructions use clear language and do not rely on color or images.
- **Availability:** `[ASSUMPTION]` the pilot uses a minimal single-runtime topology and claims no 99.9% end-to-end SLA. Scale topology is a measured follow-on architecture decision.
- **Acceptance evidence:** Every launch-blocking NFR shall name its test scope, environment, result, evidence owner, and approval. Production RTO/RPO and retention values remain blocked until their owners decide them.

## 7. Success Metrics and Counter-Metrics

All numeric targets below are proposed gates, not source facts.

### Primary

- **SM-1:** Accepted qualified Handoffs per eligible Conversation improves against the approved baseline/control. Validates FR-4, FR-5, FR-10, FR-11.
- **SM-2:** `[ASSUMPTION]` zero unauthorized commercial or prohibited claims in the release set. Validates FR-7 through FR-9.
- **SM-3:** `[ASSUMPTION]` 100% opt-out and explicit human-transfer recall in the release set. Validates FR-3 and FR-10.

### Secondary

- **SM-4:** `[ASSUMPTION]` at least 90% grounded, policy-compliant answer rate. Validates FR-4 and FR-6.
- **SM-5:** `[ASSUMPTION]` Handoff recall ≥95% and precision ≥85%. Validates FR-10 and FR-11.
- **SM-6:** `[ASSUMPTION]` duplicate logical send rate <0.1%. Validates FR-2, FR-13, FR-16, FR-17.
- **SM-7:** Median and p95 time from eligible inbound message to reply or Handoff, segmented by provider and outcome.
- **SM-8:** Follow-Up revival rate — percentage of eligible sent Follow-Ups that receive a customer response within the approved observation window; informational during the pilot and never allowed to override consent/frequency counter-metrics.
- **SM-9:** Inquiry-to-Accepted-Handoff time — technical product cycle time. Inquiry-to-final-close remains a CRM-owned business metric outside the automation acceptance gate.

### Counter-Metrics

- **SM-C1:** Opt-out, block, and complaint rate must not worsen against the human-led baseline.
- **SM-C2:** Missed-escalation rate and interventions caused by Assistant error; do not minimize appropriate human involvement.
- **SM-C3:** Human correction rate for Lead Facts and summaries.
- **SM-C4:** Cost per eligible Conversation and per accepted Handoff; do not optimize conversion while ignoring provider cost.

## 8. Data Governance and Safety

Production requires an approved data map, Contact/Conversation scope, model-payload allowlist, provider DPA/retention/no-training/region decision, retention/deletion policy, access roles, incident path, and launch-jurisdiction review. Customer content must never be able to reveal Sales Policy internals, prompts, credentials, or another Contact's data.

## 9. Rollout and Go/No-Go Gates

1. **G0 Product/legal:** offer eligibility, launch jurisdiction, bot disclosure, and ownership approved.
2. **G1 Messaging:** consent, opt-out, templates, 24-hour boundary, quiet hours, and frequency tests pass.
3. **G2 Commercial:** deterministic Offer enforcement and human approval boundaries pass adversarial tests.
4. **G3 Security:** authenticity, replay, duplicate, ordering, malformed payload, egress, and secret-redaction tests pass.
5. **G4 Privacy:** minimization, tenant/contact isolation, provider settings, retention, and deletion test pass.
6. **G5 Handoff:** direct human request, escalation recall, Human-Owned lockout, notification retry, and after-hours path pass.
7. **G6 AI quality:** approved multilingual scenario and prompt-injection evaluation meets SM-2 through SM-5.
8. **G7 Operations:** provider/model/database outage, retry, restart, kill switch, backup, and restore drill pass approved RTO/RPO.
9. **G8 Audit:** an independent reviewer reconstructs sampled sends and Offers from immutable evidence.
10. **G9 Pilot:** volume cap, monitoring owner, complaint/block thresholds, rollback criteria, and daily review approved.

Any failed critical gate blocks autonomous customer messaging for the affected path.

## 10. Dependencies and Approvals

WhatsApp Business account/number and templates; Product Knowledge and Sales Policy owners; selected Handoff/CRM destination; approved LLM provider and credentials; managed PostgreSQL; test/prod environments; labeled evaluation dataset; privacy/legal/security/operations approvers; named pilot owner and human sales coverage.

## 11. Story-Readiness Prerequisites

Technical foundation stories may proceed using synthetic fixtures and the architecture defaults. A production integration story is not ready until its owning contract is approved and versioned. The minimum production contracts are: Product Knowledge manifest; Sales Policy schema with Offer catalogue, prohibited claims, escalation taxonomy, confidence/fallback mapping, opt-out signals, Follow-Up limits, quiet hours, and release roles; Handoff adapter/acknowledgement contract; consent/template register; model/data-processing decision; retention/deletion schedule; and Release Set.

## 12. Open Questions and Owners

| # | Decision | Proposed owner | Blocks |
| --- | --- | --- | --- |
| 1 | WhatsApp number/app assets, approved languages, operating timezone/hours, and maximum pilot concurrency | Executive sponsor + Sales Operations | G0, production integration and load test |
| 2 | Whether the Assistant may present a pre-approved fixed Offer or only qualify | Commercial owner | G2, FR-7..FR-9 |
| 3 | System of record for products, prices, tax, discounts, terms, and pipeline state | Sales Operations + Finance | G2, architecture adapter |
| 4 | Product Knowledge and Sales Policy authors, approvers, publishers, and rollback authority | Sales Operations | G2, FR-4, FR-15 |
| 5 | CRM/Handoff channel, representative queue, acknowledgement SLA, notification escalation, and after-hours behavior | Sales Operations | G5, FR-10..FR-12 |
| 6 | Consent evidence, opt-out wording, templates, quiet hours, and frequency caps | Legal/Privacy + Marketing Operations | G0, G1 |
| 7 | LLM provider, region, retention/no-training terms, and monthly budget | Security/Privacy + Product | G4, G6 |
| 8 | Retention/deletion, launch-jurisdiction, incident, and customer-rights obligations | Legal/Privacy | G0, G4, G7 |
| 9 | Eligible Conversation, Accepted Handoff, baseline/control, minimum meaningful improvement, observation window, and sample rule | Product + Sales Analytics | G9 business evaluation only |
| 10 | Whether 99.9% is funded; service boundary, measurement window, RTO/RPO, and provider exclusions | Executive sponsor + Operations | Production architecture only |
| 11 | Authority and permitted lifecycle states for releasing Human-Owned back to AI-Owned | Sales Operations | G5, FR-12 |
| 12 | Approved bot disclosure and “AI cannot bind the company” wording | Legal/Brand | G0, G6 |

All decisions except #9 and #10 are launch-blocking for the affected production path. They do not block technical foundation stories that use synthetic fixtures. #9 determines business continuation, while #10 determines whether the post-pilot HA/scale architecture is funded. Owners and decision dates are not invented here.

## 13. Assumptions Index

- §2.3 — Existing internal editing/approval surface can be used; no custom dashboard is needed for MVP.
- §1 — Current response delay, repetitive qualification effort, and inconsistent answers justify a pilot; baseline evidence is missing.
- §6 Performance — Proposed p95 acknowledgement and processing targets pending pilot-volume approval.
- §6 Availability — Single n8n runtime plus managed PostgreSQL is adequate for a limited pilot; no 99.9% claim.
- §7 SM-2 through SM-6 — Proposed release thresholds pending baseline and evaluation-set approval.
