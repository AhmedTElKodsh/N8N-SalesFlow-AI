# Project Context — N8N SalesFlow AI

## Current truth

The repository contains a complete **synthetic-local implementation** of the seven-workflow SalesFlow design. SP3-T4 established automatic Human-Owned takeover for three synthetic triggers. SP3-T5 adds an atomic evidence-grounded Handoff summary, durable notification-failure recovery evidence, and an operator-authenticated local Conversation-history API destination. SP3-T6 exposes an account-wide emergency stop plus bounded, account-isolated activity and failure/retry views through the Operations workflow. Conversation UI and CRM integration remain later work. This evidence covers the synthetic-local boundary; production promotion remains disabled.

This is not a production approval. The adapters are deterministic local substitutes, and `release/release-manifest.json` keeps `livePromotionAllowed` set to `false`. Real Meta delivery, a selected production LLM, the CRM/Handoff contract, managed PostgreSQL controls, approved sales and knowledge content, legal/privacy approval, and a named production owner remain external gates.

The original executive DOCX remains the source proposal. Because it was open in Word and locked during this update, [PRD_ N8N Sales AI Agent - Updated 2026-07-15.docx](../PRD_%20N8N%20Sales%20AI%20Agent%20-%20Updated%202026-07-15.docx) is the dated copy containing the implementation-status addendum. Product authority starts at the [planning artifacts index](../_bmad-output/planning-artifacts/index.md); story specifications and evidence start at the [implementation artifacts index](../_bmad-output/implementation-artifacts/index.md); observed implementation documentation starts at [index.md](./index.md).

## Binding product boundary

The September 5 corrections add durable pending-turn discovery to Workflow 05 and route it through Workflow 02 with scheduler authorization. Accepted duplicates retain their Conversation identity for safe retry. Consent signal configuration must use lowercase, trimmed, normalized whitespace; inbound provider identifiers are limited to 1024 UTF-8 bytes. Workflow 07 resolves account-management scope from the operator token, including re-enabling a disabled account.

Learning checkpoint failures now invalidate earlier behavior passes and retain their classified diagnostics. Native Windows entrypoints resolve an omitted repository root after initialization, and lineage is checked before initial progress writes. M10 copies reviewed harness inputs into a separate disposable checkout so its Compose resources and cleanup cannot replace the retained learner stack. Fresh provider-free verification is available; Docker-backed verification of these corrections is still required.

- The MVP is a policy-bound WhatsApp sales assistant for opted-in inbound leads.
- The LLM drafts and classifies; deterministic Sales Policy and humans own commercial authority.
- `ready_for_handoff` is not `closed_won`.
- A customer can request a human at any stage. The approved SP3-T4 contract makes Human-Owned block every automated customer message, including transfer acknowledgements, superseding the earlier acknowledgement exception. Internal Handoff dispatch remains separate; opt-out and deletion still take precedence.
- Every new Handoff freezes its trigger reason, response deadline, referenced source excerpt, explicit unknowns, durably supported offer or `none`, active Sales Policy version, and credential-free Conversation URL. The current classifier has no durable offer-relevance evidence, so summaries conservatively store `none`. Notification retry/failure and post-recheck authority-change evidence is append-only and never releases Human-Owned lockout; privacy retention minimizes copied excerpts with source messages. The local history URL contains only the Conversation UUID, derives account scope from a separate operator token, and is not a production CRM or UI.
- Follow-Ups recheck consent, opt-out, ownership, timing, frequency, and template eligibility immediately before send.
- PostgreSQL owns business state; n8n orchestrates; external side effects originate from unique persisted intents.

## Implemented local baseline

- Seven n8n workflows cover ingress, orchestration, dispatch, provider status, UTC scheduling, Handoff dispatch, and operations. Workflow 01 alone uses two allowlisted Code nodes for raw test-body capture and HMAC/envelope validation; no workflow uses command, community, or arbitrary HTTP nodes.
- PostgreSQL provides account-scoped state, immutable configuration versions, idempotency, ordering, authorization, leases/claims, retries, audit evidence, deletion minimization, and release activation.
- Ten JSON contracts define the synthetic account, consent/templates, Handoff, model, Product Knowledge, qualification, Release Set, retention, retry, and Sales Policy inputs.
- `tests/run.ps1` provisions disposable credentials, applies the migration twice, publishes configuration and workflows, executes S01-S26 and race checks, verifies canonical workflow identity and secrets hygiene, and cleans plaintext/volumes in `finally`.

## Delivery posture

Keep the local baseline deliberately small: one n8n runtime, PostgreSQL, native nodes, one account fixture, one offer, one model fixture, and one Handoff queue. Do not add a custom dashboard, vector database, Redis, multi-model routing, or HA topology until evidence or an approved SLO requires it.

## Agent-assisted implementation

Codex, Antigravity, and OpenCode are development clients, not runtime dependencies. Exported workflow JSON, PostgreSQL migrations, configuration contracts, tests, and release evidence must remain reproducible without chat history. Production credentials stay in approved secret stores/n8n credentials and never enter prompts, workflow exports, fixtures, or source control.

## Required before production

Resolve the PRD executive decisions, approve commercial and compliance boundaries, connect customer-owned Meta/LLM/Handoff assets, prove managed-infrastructure controls, run credentialed integration and pilot tests, and obtain production-owner approval. Local success is evidence for the repository baseline only.
