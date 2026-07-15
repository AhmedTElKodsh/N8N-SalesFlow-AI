---
title: Executive PRD Review — N8N Sales AI Agent
status: complete
created: 2026-07-14
source: ../../../PRD_ N8N Sales AI Agent.docx
---

# Executive PRD Review — N8N Sales AI Agent

## Verdict

The executive document is a useful concept note, but it is not implementation-ready. It defines an aspirational autonomous negotiator and a technology sketch before defining commercial authority, WhatsApp policy constraints, consent, human escalation, data governance, failure behavior, or testable acceptance criteria.

The safe, testable MVP is a **policy-bound WhatsApp sales assistant**. It may answer approved questions, qualify an inbound lead, present a pre-approved offer, follow up when eligible, and prepare a human handoff. It may not invent or change price, discount, scope, SLA, warranty, or contract terms; declare a deal closed; or continue after human takeover.

## Party-mode challenge

| Severity | Finding | Why the executive plan fails | Modification |
| --- | --- | --- | --- |
| Critical | LLM is given commercial authority | Prompt text such as “do not offer more than 10%” is not an enforceable control and is vulnerable to prompt injection, stale policy, and hallucination. | Treat model output as an untrusted draft. Validate every offer against a versioned policy record; require a human for exceptions and contracts. |
| Critical | “Deal Closed” is inferred from text | Customer language may be ambiguous, sarcastic, conditional, or incomplete. An intent label cannot establish a binding agreement. | Replace with `ready_for_handoff`; only a human or CRM records `closed_won`. |
| Critical | Human access exists only at the end | Customers need a direct human path for requests, complaints, uncertainty, sensitive topics, and failures. | Allow human takeover at every stage and block automation until explicitly released. |
| Critical | Follow-up ignores channel rules | A generated free-form message after 24 hours can violate WhatsApp requirements. Consent, opt-out, templates, frequency, quiet hours, and cancellation are absent. | Recheck eligibility before every send. Outside the customer-service window, send only an approved template. |
| Critical | PII handling is optional language | “Where possible, masked” does not define fields, purpose, retention, deletion, provider terms, or tenant isolation. | Define an approved LLM payload, minimize identifiers, isolate each conversation, and approve provider retention/residency terms before production. |
| Critical | Webhook-to-action path is untrusted | No signature verification, replay protection, idempotency, ordering, or attachment limits are defined. | Authenticate, normalize, deduplicate, persist, and serialize before any model call or side effect. |
| High | OKRs and policies are conflated | OKRs measure or prioritize outcomes; they are not executable pricing or compliance rules. | Separate strategic objectives from versioned Sales Policy. |
| High | Phone number is the memory key | Numbers can be shared or reassigned and do not identify tenant or CRM customer safely. | Use internal Contact and Conversation IDs; treat the phone number as a channel identifier. |
| High | Wait-based follow-ups can become stale | A paused execution can wake after reply, opt-out, handoff, close, or campaign cancellation. | Use a due-job scheduler with an atomic claim and final pre-send eligibility check. |
| High | NFRs are unsupported promises | “3–5 seconds” has no percentile or load boundary; “99.9%” has no funded topology, RTO/RPO, or provider exclusions. | Use proposed pilot SLOs, measure them, and add queue/HA infrastructure only when evidence requires it. |
| High | Metrics reward unsafe behavior | Minimizing Human Intervention Rate can suppress correct escalations; handling time can punish necessary discovery. | Measure accepted handoffs, missed escalation, unauthorized offers, opt-outs, complaints, duplicates, and grounded-answer quality. |
| Medium | Diagram is not an architecture contract | It duplicates logical and physical flows, sends model output directly, loops scheduled follow-up into the inbound trigger, and includes undefined “Flow Module” and “Opennation.” | Replace it with the architecture spine and one deterministic event flow. |

## What remains valuable

- WhatsApp is the primary customer channel.
- n8n is the orchestration platform.
- PostgreSQL is appropriate for durable operational state.
- Managers need controlled business policy input.
- Conversation context, follow-up, and structured handoff are real product capabilities.
- Conversion, response time, revival, and human effort are useful measures once baselines and safeguards are defined.

## Corrected MVP

1. Limit the pilot to one WhatsApp number, one approved offer family, one launch market, an approved language set, and an explicit volume cap.
2. Accept opted-in inbound leads; record consent evidence and honor opt-out immediately.
3. Answer only from approved Product Knowledge and collect a short, structured qualification record.
4. Present list price or a pre-approved fixed offer; reject or hand off every exception.
5. Escalate on customer request, buying intent, uncertainty, complaint, sensitive topic, policy exception, or system failure.
6. Schedule at most the approved number of follow-ups; recheck consent, ownership, last inbound time, template eligibility, and campaign state immediately before send.
7. Create one evidence-backed Handoff containing known Lead Facts, the applicable Sales Policy version, transcript link, and unresolved items.
8. Keep PostgreSQL as the business-state authority and record every inbound event, decision, send intent, provider status, policy version, and human ownership transition.
9. Run a labeled Arabic/English evaluation and adversarial test set before a limited live pilot.
10. Expand autonomy, products, languages, volume, or infrastructure only after a gate explicitly approves it.

## Executive decisions with technical impact

Engineering defaults are already selected in the PRD and architecture. Executive input is limited to contracts engineering cannot safely invent:

1. WhatsApp app/number assets, approved languages, operating timezone/hours, and maximum pilot concurrency.
2. Commercial authority boundary: qualification only or pre-approved fixed Offers.
3. Authoritative Product Knowledge, pricing/Sales Policy, and pipeline systems plus their owners/approvers.
4. CRM/Handoff adapter, receiving queue, acknowledgement signal/SLA, and after-hours escalation.
5. Consent evidence, opt-out wording, approved templates, quiet hours, and frequency caps.
6. LLM provider data terms/region, retention/deletion obligations, and any jurisdictional constraints.
7. Whether a funded production SLO requires HA/queue infrastructure; if so, service boundary and RTO/RPO.
8. Who may release a Human-Owned Conversation back to automation.

## Primary platform evidence

- [n8n WhatsApp Trigger](https://docs.n8n.io/integrations/builtin/trigger-nodes/n8n-nodes-base.whatsapptrigger/)
- [n8n WhatsApp Business Cloud node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.whatsapp/)
- [n8n Wait node behavior](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.wait/)
- [n8n queue-mode architecture](https://docs.n8n.io/hosting/scaling/queue-mode/)
- [WhatsApp Business Messaging Policy](https://business.whatsapp.com/policy)
- [Meta official WhatsApp message-window reference](https://www.postman.com/meta/whatsapp-business-platform/folder/fuaee8l/statuses-object)
