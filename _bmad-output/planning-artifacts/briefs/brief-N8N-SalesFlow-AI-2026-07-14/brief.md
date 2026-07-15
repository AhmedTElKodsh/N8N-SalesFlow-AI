---
title: N8N SalesFlow AI Product Brief
status: review-required
created: 2026-07-14
updated: 2026-07-14
source: ../../../../PRD_ N8N Sales AI Agent.docx
---

# Product Brief: N8N SalesFlow AI

## Executive Summary

N8N SalesFlow AI is a policy-bound WhatsApp sales assistant for opted-in inbound leads. It reduces the delay and repetitive effort between a customer's first message and a useful human sales conversation by answering approved questions, collecting qualification facts, presenting only approved offers, and preparing a structured handoff.

The product does not make binding commercial decisions. The LLM drafts language and classifies intent; deterministic Sales Policy and human approval control prices, discounts, commitments, and contracts. This boundary turns the executive concept into a pilot that can be audited, evaluated, and stopped safely.

## The Problem

Prospects expect prompt WhatsApp replies, while human representatives repeatedly answer product questions, collect the same lead facts, chase silent leads, and reconstruct context before taking over. The executive source asserts this cost but provides no baseline for lead volume, response delay, conversion, or rep effort. `[ASSUMPTION: the pilot targets an existing inbound WhatsApp sales flow with a human sales team.]`

## The Solution

The assistant receives a WhatsApp message, verifies and records the event, loads the Conversation and active Sales Policy, drafts a grounded response, validates the proposed action, and either sends an eligible response or transfers ownership to a human. A scheduler handles eligible follow-ups. Every decision is linked to the inbound message, policy version, model/prompt version, and resulting provider status.

## Who This Serves

- **Customer:** gets prompt, consistent answers and can request a human at any time.
- **Sales Representative:** receives a concise, evidence-linked Handoff instead of rereading an unstructured thread.
- **Sales Manager:** publishes controlled Sales Policy and evaluates quality and funnel outcomes without editing raw prompts.
- **Operations owner:** can pause automation, trace sends, recover failures, and prove why an offer was made.

## MVP Scope

### In

- One WhatsApp Business number and one approved offer family.
- Opted-in inbound text conversations in an approved language set.
- Approved FAQ/Product Knowledge answers and structured Lead Facts.
- List price or pre-approved fixed offer only.
- Human escalation at any stage and bot lockout after takeover.
- One configured Handoff destination.
- Approved-template follow-up with consent and eligibility recheck.
- Durable conversation state, idempotency, audit events, kill switch, and pilot evaluation.

### Out

- Autonomous discounts, custom terms, or contract negotiation.
- Declaring a deal legally closed.
- Cold outbound prospecting.
- Voice-note, image, or document interpretation.
- Multiple products, markets, unrestricted languages, or model routing.
- Custom management dashboard, bespoke middleware, vector database, Redis, or high-availability topology.

## Success Criteria

The executive source contains no baselines. These are proposed pilot gates and remain assumptions until approved:

- `[ASSUMPTION]` Zero unauthorized price, discount, contractual, or prohibited claims in the release evaluation set.
- `[ASSUMPTION]` 100% of explicit opt-outs and human-transfer requests honored.
- `[ASSUMPTION]` Zero automated sends after Human-Owned state begins.
- `[ASSUMPTION]` At least 90% grounded, policy-compliant answers on the approved scenario suite.
- `[ASSUMPTION]` Handoff recall at least 95% and precision at least 85% on labeled scenarios.
- `[ASSUMPTION]` Duplicate-send rate below 0.1%.
- `[ASSUMPTION]` p95 processing-to-send at most 10 seconds, measured separately from webhook acknowledgement.
- Business result: accepted qualified Handoffs per eligible Conversation improves against the current human-led baseline without worsening opt-out, block, or complaint rate.

## Principal Risks

Unauthorized commitments, policy-invalid outreach, prompt injection, PII leakage, cross-customer memory, stale follow-ups, duplicate sends, missed human escalation, and untraceable configuration changes. Each is a release gate in the PRD.

## Executive Decisions Before Build

Confirm the pilot offer/market/languages/volume; autonomy boundary; Sales Policy and Product Knowledge owners; CRM and handoff SLA; consent/templates; LLM provider and data terms; retention; baseline and success threshold; availability budget; and Human-Owned release authority.

## Longer-Term Vision

If the bounded pilot proves safe and useful, expand one controlled dimension at a time: additional offers, languages, CRM actions, or higher volume. Autonomous commercial negotiation remains a separate product phase requiring explicit commercial rules, legal approval, adversarial evaluation, and a reversible limited rollout.

