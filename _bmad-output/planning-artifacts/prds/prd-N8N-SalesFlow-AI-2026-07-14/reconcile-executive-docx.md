# Executive DOCX Input Reconciliation

**Source:** `../../../../PRD_ N8N Sales AI Agent.docx`  
**Compared with:** `prd.md` and `addendum.md`  
**Date:** 2026-07-14  
**Purpose:** Verify that every material executive-source item was preserved, deliberately changed, deliberately excluded/deferred, or identified as missing. This document does not approve the changes; it makes their disposition visible.

## Reconciliation verdict

The rewritten PRD preserves the executive initiative's channel, orchestration role, durable conversation context, policy-aware behavior, Follow-Up, Handoff, audit, and core outcome. It deliberately narrows autonomous persuasion/negotiation into a controlled sales-assistance pilot and adds safety, reliability, privacy, and operational requirements missing from the source.

Four source areas are not yet explicitly dispositioned: conversational/personalized tone, outbound document/interactive-message support, Follow-Up Revival Rate, and Average Handling Time through final closure. These are listed under **Silently disappeared or insufficiently reconciled**.

## Source items preserved

| Executive source item | Where it landed | Reconciliation note |
| --- | --- | --- |
| n8n is the central orchestration engine | PRD §§1, 5, 6; addendum Scaling Boundary | Preserved as orchestration, while PostgreSQL—not n8n execution memory—owns durable business state. |
| Bidirectional WhatsApp Business API integration | FR-1, FR-16, FR-17; UJ-1; Dependencies | Preserved for inbound events, outbound messages, and delivery/read/failure reconciliation. |
| Incoming message webhook flow | FR-1, FR-2 | Preserved and strengthened with authenticity, schema/size validation, normalization, persistence, deduplication, and ordering. |
| PostgreSQL user/profile and chat-history retrieval | Glossary; FR-2, FR-4, FR-5, FR-18, FR-20 | Preserved as Contact, Conversation, Lead Facts, evidence, bounded context, and audit records rather than a loosely defined profile/history blob. |
| Business targets constrain sales behavior | FR-7, FR-8, FR-15; UJ-3 | Preserved as typed, versioned, approved Sales Policy controlling products, prices, discounts, claims, and escalation. |
| LLM-powered natural-language response generation | FR-4, FR-6; UJ-1 | Preserved as a structured draft grounded in approved Product Knowledge. The model no longer directly authorizes or sends actions. |
| Conversation continuity across multiple days | Glossary; FR-5, FR-18, FR-20; addendum Product Knowledge Strategy | Preserved through durable Contact/Conversation records, evidence-linked facts, versioned context, and bounded history. |
| Intent detection/routing | FR-6, FR-10 | Preserved as typed intent candidates, confidence, evidence, and escalation reason; deterministic rules own state transitions. |
| Automated Follow-Up after inactivity | FR-13, FR-14; UJ-4 | Preserved with due time, generation, cancellation, atomic claim, final eligibility recheck, and WhatsApp template-window handling. |
| AI stops responding after Handoff | FR-11, FR-12; UJ-2 | Preserved and strengthened as an atomic Human-Owned transition that blocks all automated replies and Follow-Ups. |
| Sales-team Handoff contains negotiation/customer context | FR-11, FR-18; UJ-2 | Preserved as Lead Facts, unknowns, approved Offer and policy version, reason, transcript pointers, evidence, and correlation ID. |
| Delivery and read status handling | FR-17 | Explicitly preserved, with failed/unknown status also included for reconciliation. |
| Security and privacy for PII | FR-20; §§6, 8; G3, G4 | Preserved and strengthened from “mask where possible” into allowlisting, access control, encryption, retention, deletion, provider terms, and isolation tests. |
| Lead Conversion Rate / Ready-to-Sign outcome | SM-1, SM-5 | Preserved but reframed as accepted qualified Handoffs per eligible Conversation plus Handoff precision/recall, avoiding a false claim that the AI closes the deal. |

## Source items changed, with reason

| Executive source proposal | Replacement in PRD/addendum | Reason recorded by the rewritten plan |
| --- | --- | --- |
| “Fully automated” persuasion and negotiation through customer agreement | Approved answers, qualification, pre-approved Offers, objection escalation, and evidence-backed Handoff | The source gives the LLM binding commercial influence without a deterministic policy, evidence, approval, or legal boundary. FR-7 through FR-10 keep customer-facing commercial actions controlled. |
| Human Sales Representative steps in exclusively at the final signing stage | Human escalation is available for explicit request, uncertainty, complaint, unsupported topic, policy exception, buying intent, or failure | Restricting humans to the end conflicts with safe handling, customer choice, and the source's own Human Intervention metric. |
| Managers inject OKRs/KPIs directly into the system prompt | Strategic metrics remain metrics; enforceable behavior comes from typed, validated, approved, versioned Sales Policy/Product Knowledge | KPIs measure outcomes and arbitrary prompt text cannot reliably enforce discounts, prices, claims, or terms. |
| Memory keyed by phone number | Internal Contact and Conversation IDs; phone is a channel identifier | Phone numbers may be shared or reassigned and are unsafe as sole identity/context authority. |
| LLM identifies “Deal Closed” and triggers the final path | `ready_for_handoff`; only a human/CRM records approval or `closed_won` | An LLM intent label is not agreement or contract evidence and contradicts the executive statement that a human signs. |
| LLM output is sent directly through WhatsApp | Schema validation, deterministic commercial/safety gate, durable idempotent outbox, then dispatch | Prevents hallucinated offers, prohibited claims, duplicate sends, and side effects without committed state. |
| Wait node or Cron timer per inactive conversation | Schedule Trigger plus durable Follow-Up due-job table | Wait alone cannot provide authoritative cancellation, ownership, opt-out, generation, claim, and retry semantics. |
| At roughly 24 hours, generate a free-form context-aware Follow-Up | Recheck the rolling customer-service window; outside it, only an approved eligible template may send | WhatsApp channel rules constrain what can be sent outside the service window. |
| HTTP Request nodes send WhatsApp content | Native n8n WhatsApp nodes for supported operations; custom HTTP only if a required operation is unsupported | Reduces workflow code and credential surface while retaining the official API boundary. |
| Fixed model examples: Gemma 4, Qwen 2.7, Gemini 1.5 Pro | Provider/model selection gate based on evaluated quality, structured output, latency, language, privacy, availability, and cost | Named examples can be inaccurate or stale and are implementation choices, not product requirements. |
| Response latency “within 3–5 seconds” | Proposed webhook acknowledgment p95 ≤2 seconds and processing-to-send p95 ≤10 seconds, measured separately | The source does not define load, percentile, external-provider boundary, or fallback behavior. The replacement is explicitly an assumption pending pilot approval. |
| n8n must provide 99.9% uptime and campaign concurrency | Single-runtime pilot with no 99.9% claim; scaling/HA requires approved service boundary, load, budget, RTO/RPO, and tests | The source claims availability without topology, service boundary, budget, measurement window, or recovery objective. |
| Human Intervention Rate should be minimized | Track missed escalation and interventions caused by Assistant error; do not minimize appropriate human involvement | Low intervention can indicate unsafe automation. Correct escalation is a safety outcome, not product failure. |
| Notify Sales via WhatsApp, email, CRM/dashboard | One Handoff adapter is selected after executives name the system of record, acknowledgement SLA, and after-hours route | The outcome is preserved; committing multiple channels before ownership and SLA are known would create duplicate notification paths. |

## Intentionally excluded or deferred

| Source item | Disposition | Boundary/revisit condition |
| --- | --- | --- |
| Autonomous custom discount, scope, SLA, warranty, contract, or complex-term negotiation | **Excluded from MVP** | Revisit only with explicit commercial/legal authority, deterministic policy coverage, human approvals, and evaluated safety evidence. |
| AI records a contract as agreed/closed | **Excluded** | Human/CRM remains authoritative. |
| AI handles every complex objection | **Restricted** | It may answer only from approved knowledge and Offers; unsupported or uncertain objections create Handoff. |
| Custom management dashboard | **Excluded from MVP** | Existing controlled editing/approval surfaces may be used; add a UI only if they cannot safely support publication. |
| Specific LLM/provider | **Deferred** | Select after the approved scenario benchmark and provider privacy/region/retention review. |
| Queue mode, Redis, workers, load balancer, redundant n8n instances | **Deferred** | Add after measured concurrency/backlog or an approved availability SLO requires them. |
| Multiple simultaneous WhatsApp/email/CRM/dashboard notifications | **Deferred** | Choose the minimum adapter after system-of-record and acknowledgement requirements are confirmed. |

## Silently disappeared or insufficiently reconciled

These source details are neither preserved as testable requirements nor explicitly rejected/deferred in the current PRD/addendum.

### Gap 1 — Personalized, natural, persuasive, and non-aggressive communication quality

The executive source repeatedly asks for personalized, natural conversation and a polite Follow-Up that is not overly aggressive. The rewritten PRD requires grounded, clear, policy-safe language, but it defines no approved brand voice, personalization boundary, tone scenarios, or quality measure. “Persuasive” may be intentionally narrowed for safety, but “natural,” “personalized,” and “not overly aggressive” should be either adopted as evaluated conversation-quality requirements or explicitly excluded.

### Gap 2 — Outbound documents and interactive WhatsApp messages

The source explicitly requires sending text, documents, and interactive templates. The rewritten PRD supports messages and approved templates, but no FR specifies outbound documents or interactive message behavior. The Non-Goals exclude attachment/document **understanding**, not clearly outbound document delivery. Decide whether these are MVP capabilities, deferred media work, or intentionally excluded.

### Gap 3 — Follow-Up Revival Rate

The source names the percentage of unresponsive Conversations re-engaged by Follow-Up as a success metric. The rewritten PRD rigorously measures Follow-Up compliance and duplicate sends, but it has no revival/response effectiveness metric. Add it as a segmented secondary metric if Follow-Up value is part of the pilot thesis, or explicitly reject it if safe delivery—not revival—is the only MVP objective.

### Gap 4 — Average Handling Time through successful closure

The source measures elapsed time from initial interaction to successful deal closure. SM-7 stops at reply or Handoff. Narrowing the Assistant's authority justifies separating these measures, but the original funnel-cycle metric has not been dispositioned. Either retain end-to-end inquiry-to-human-closure time as a CRM-owned business metric, replace it explicitly with inquiry-to-accepted-Handoff time, or state why post-Handoff cycle time is outside product evaluation.

### Gap 5 — Direct customer contact link in the Handoff alert

The executive source asks for a direct link to customer contact details. The rewritten Handoff includes transcript pointers and a protected authenticated transcript link requirement, but not an explicit customer/contact action link. Confirm whether the selected CRM/Handoff adapter must provide an authorized contact link, or intentionally omit it for privacy/security.

## Source-content disappearance check

No whole executive section disappeared. Target users, core features, architecture sequence, NFRs, and success metrics all have successors. The five gaps above are the only material source details found without an explicit preserved/changed/excluded disposition.

## Resolution after review

The PRD/addendum now disposition all five gaps: bounded natural/non-aggressive tone is part of FR-9 and the Release Set; interactive templates remain in MVP while outbound documents are deferred to the representative; Follow-Up Revival Rate is informational SM-8; technical handling time ends at Accepted Handoff while final close remains CRM-owned; and internal contact/transcript links must be authenticated and least-privilege.

## Reconciliation conclusion

The rewrite is traceable and intentionally more conservative than the executive source. Before calling input reconciliation complete, the product owner should disposition Gaps 1–5. Gaps 2–4 affect MVP scope and measurement; Gaps 1 and 5 can be resolved as bounded quality and adapter requirements without restoring autonomous negotiation.
