# N8N SalesFlow AI — Planning Index

Status: **Synthetic-local implementation complete and verified; executive review and production promotion remain open**
Source reviewed: `PRD_ N8N Sales AI Agent.docx`  
Review date: 2026-07-14
Implementation evidence date: 2026-07-15

## Planning authority

| Order | Artifact | Purpose | Status |
| --- | --- | --- | --- |
| 1 | [Executive PRD review](executive-prd-review.md) | Critique and source reconciliation | Complete |
| 2 | [Product brief](briefs/brief-N8N-SalesFlow-AI-2026-07-14/brief.md) | Corrected product thesis and MVP boundary | Review required |
| 3 | [PRD](prds/prd-N8N-SalesFlow-AI-2026-07-14/prd.md) | Canonical requirements and release gates | Review required |
| 4 | [PRD addendum](prds/prd-N8N-SalesFlow-AI-2026-07-14/addendum.md) | Source reconciliation and technical options | Supporting |
| 5 | [Architecture spine](architecture/architecture-N8N-SalesFlow-AI-2026-07-14/ARCHITECTURE-SPINE.md) | Build invariants and structural seed | Review required |
| 6 | [Epics and stories](epics.md) | Delivery decomposition | Complete |
| 7 | [Implementation specification](../implementation-artifacts/spec-finish-and-test-n8n-workflow.md) | Synthetic-local delivery contract | Done |
| 8 | [Local test evidence](../implementation-artifacts/test-evidence.md) | Runtime, concurrency, identity, secret, and cleanup proof | PASS (local only) |
| 9 | `implementation-readiness-report-2026-07-14.md` | Cross-artifact readiness verdict | Not generated; not retroactively claimed |

The executive DOCX remains an input rather than canonical implementation authority. `PRD_ N8N Sales AI Agent - Updated 2026-07-15.docx` is the dated copy that records the delivered synthetic-local baseline, corrected product authority boundary, local evidence, and unresolved production decisions. This pack is technical-first: engineering defaults are decided here; executive input is requested only when it changes commercial authority, compliance, cost/SLO, or an external-system contract.

## Current implementation status

- Seven canonical n8n workflows, the PostgreSQL command/state model, ten configuration contracts, release manifest, and one-command test harness are present.
- The 2026-07-15 run completed with `PASS FULL PASS`, including S01-S26, race checks, live n8n endpoint paths, import/export identity, secret scans, and cleanup.
- Evidence is synthetic-local only. `release/release-manifest.json` keeps `livePromotionAllowed` set to `false`.
- Review-required/draft labels on the Product Brief, PRD, and Architecture Spine have not been silently converted into executive approval.

## Deliberately not created

- UX specification: the MVP uses WhatsApp plus existing internal tools; no custom user interface is approved.
- Separate roadmap, risk register, or decision log: epics, PRD gates, and BMAD memlogs already cover them.
- A retroactive implementation-readiness report: implementation evidence exists, but a missing planning gate is not fabricated after the fact.
