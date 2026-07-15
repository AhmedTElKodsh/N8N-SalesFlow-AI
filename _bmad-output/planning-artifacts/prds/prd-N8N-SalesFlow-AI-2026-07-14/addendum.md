---
title: N8N SalesFlow AI PRD Addendum
status: supporting
created: 2026-07-14
updated: 2026-07-14
---

# PRD Addendum

## Executive Source Reconciliation

| Executive source proposal | Disposition | Reason |
| --- | --- | --- |
| Fully automated persuasion and negotiation | Restricted to grounded answers, qualification, and approved Offers | Binding autonomy has no enforceable commercial policy, evidence, or approval. |
| Managers inject OKRs/KPIs into the system prompt | Replaced by separate strategic metrics and typed, versioned Sales Policy | Metrics do not enforce prices, claims, or terms; arbitrary prompt injection is unsafe. |
| Memory per phone number | Replaced by Contact + Conversation IDs with bounded history | Phone numbers are channel identifiers and can be shared/reassigned. |
| Wait node or Cron after 24 hours | Use a durable due-job scheduler with a final eligibility check | Cancellation, ownership, opt-out, retries, and template-window decisions need one persistent record. |
| “Deal Closed” intent triggers notification | Renamed `ready_for_handoff`; human/CRM closes | An LLM label is not agreement evidence. |
| LLM response goes directly to WhatsApp | Insert deterministic validation and idempotent outbox | Prevent unauthorized offers and duplicate side effects. |
| HTTP Request nodes for WhatsApp | Use native n8n WhatsApp nodes for supported operations | Smaller workflow and credential surface. |
| Gemma 4, Qwen 2.7, or Gemini 1.5 Pro | Provider/model deferred to evaluation | Product requirements should define selection criteria, not stale examples. |
| 3–5 second latency and 99.9% uptime | Replace with proposed percentile pilot SLOs and an explicit HA decision | The source supplies no load, boundary, budget, RTO/RPO, or topology. |

## Model Selection Gate

Benchmark candidate provider/model configurations on the approved scenario set. Score grounded-answer quality, Arabic/English performance if required, policy violations, escalation recall/precision, structured-output validity, latency percentiles, retention/residency terms, availability, and cost. Pin one provider/model/prompt version for the pilot; do not route across models until evidence requires it.

## Product Knowledge Strategy

Start with controlled structured records and a bounded context. Do not add a vector database for a pilot corpus that fits in approved tables or documents. Add retrieval infrastructure only when corpus size or evaluation shows bounded context fails.

## Follow-Up Options Considered

- **One n8n Wait per lead:** native and simple, and paused data is stored in the database. Rejected for this pilot because stale cancellation, deduplication, ownership, and policy recheck still require a durable business record.
- **Schedule Trigger + due-job table:** adopted. One record exposes due time, cancellation, generation, claim, sent state, and retry behavior.

## Scaling Boundary

Start with one n8n runtime and managed PostgreSQL. Add Redis queue mode, workers, webhook processors, load balancing, and redundant n8n instances only after measured concurrency, backlog, or an approved availability SLO requires them. n8n documents queue mode as Redis + workers and notes webhook latency overhead; it is not free reliability.

## Reconciled Executive Details

- Conversation style is a testable bounded requirement: clear, natural, respectful, non-aggressive, and personalized only from approved Lead Facts. Brand-specific voice is optional and not a technical blocker.
- Approved interactive templates remain in MVP. Outbound documents are deferred to the human representative after Handoff; inbound media understanding is out of scope.
- Follow-Up Revival Rate is retained as an informational secondary metric with consent/complaint counter-metrics.
- Automation handling time ends at Accepted Handoff. Final-close cycle time belongs to the CRM/business funnel.
- Internal transcript/contact links must be authenticated and least-privilege; short-lived links are preferred when the selected adapter supports them.

## Agent-Assisted Delivery Boundary

Codex, Antigravity, and OpenCode may select suitable installed Skills, MCP servers, or CLIs for authoring, importing/exporting, querying, and verification. The same repository contract applies to every client. An MCP is an operator interface, not a hidden service dependency: workflow exports, migrations, schemas, test vectors, commands, and evidence must remain reproducible through documented repository procedures. Client-specific configuration is handled separately for each client; no shared-config assumption is made.
