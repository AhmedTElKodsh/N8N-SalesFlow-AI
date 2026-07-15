# Project Context — N8N SalesFlow AI

## Current truth

This is a greenfield planning repository. There is no implementation or validated production baseline. The executive DOCX is preserved as a source proposal; it is not implementation authority.

Canonical planning starts at [_bmad-output/planning-artifacts/README.md](../_bmad-output/planning-artifacts/README.md). The PRD remains `review-required` until its executive Open Questions are resolved.

## Binding product boundary

- MVP is a policy-bound WhatsApp sales assistant for opted-in inbound leads.
- The LLM drafts and classifies; deterministic Sales Policy and humans own commercial authority.
- `ready_for_handoff` is not `closed_won`.
- A Customer can request a human at any stage. Human-Owned blocks all automation except one fixed, approved, language-matched, non-commercial transfer acknowledgement precommitted atomically with the Handoff; opt-out still suppresses it.
- Follow-Ups recheck consent, opt-out, ownership, timing, frequency, and template eligibility immediately before send.
- PostgreSQL owns business state; n8n orchestrates; external side effects use unique persisted send intents.

## Delivery posture

Start with native n8n capabilities, one runtime, managed PostgreSQL, one WhatsApp number, one offer family, one provider/model, and one Handoff channel. No custom dashboard, vector database, Redis, multi-model routing, or HA topology until evidence or an approved SLO requires it.

Planning is technical-first. Resolve engineering choices from platform evidence and the architecture spine. Escalate only choices that change commercial authority, legal/privacy constraints, external-system ownership, or funded service levels.

## Agent-assisted implementation

Codex, Antigravity, and OpenCode may use suitable installed Skills, MCPs, and CLIs to build and verify the solution. They are development clients, not runtime dependencies. The repository is authoritative: exported n8n workflow JSON, PostgreSQL migrations, configuration contracts, tests, and release evidence must be reproducible without chat history. Production credentials stay in approved secret stores/n8n credentials and never in prompts, MCP arguments, workflow exports, or source control.

## Required before implementation

Resolve the PRD Open Questions, approve rollout gates, complete epics/stories, and pass implementation readiness. Legal/privacy/security statements are planning gates, not legal conclusions.
