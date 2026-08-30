# Sprint Change Proposal — Production Delivery Planning

**Date:** 2026-08-01
**Mode:** Batch
**Scope:** Moderate planning correction; no implementation authorization
**Approval status:** Approved for Story 1.1 local implementation on 2026-08-02

## 1. Issue Summary

The production-delivery DOCX is useful as a stage-gate roadmap, but it is not a committed sprint plan: it has no start/end dates, named accountable people, or available capacity, and its cover claims per-task dependencies that are not present. The first Meta ingress specification also conflicts with Story 1.1 by omitting the required PII-minimized rejection record and leaves security/response behavior underspecified.

Evidence:

- Story 1.1 requires a rejection record for invalid signature, wrong account, malformed schema, unsupported type, and oversized input while forbidding customer-facing, Handoff, notification, and Conversation side effects.
- The current native-node baseline is synthetic-local and historically verified; it is not current runtime or production-provider proof.
- `release/release-manifest.json` keeps `livePromotionAllowed=false`.
- Real Meta assets, managed PostgreSQL, LLM, Handoff, compliance, and named production ownership remain external gates.

## 2. Impact Analysis

### Epic and story impact

- Epic 1 remains achievable and does not need a new story.
- Story 1.1 is the first bounded production-integration slice. Stories 1.4 and 1.5 remain separate later slices; ingress does not implicitly authorize dispatch or status integration.
- Story 1.7 remains blocked until the Handoff adapter and acknowledgement contract are approved.
- Epics 2 and 3 remain ordered after Epic 1's shared safety contracts and do not need scope changes.

### Artifact impact

- **PRD:** no requirement change. The MVP and external gates remain valid.
- **Architecture:** no new architecture decision. The spec must implement AD-1, AD-5, AD-6, AD-13, AD-17 through AD-20, and AD-24. A minimal Code-node exception is allowed only for constant-time digest comparison and must be added to the reviewed node inventory/hardening evidence.
- **UX:** no custom UI impact.
- **Roadmap:** relabel as a gated roadmap, remove the false dependency claim, expose commitment status, split the Meta adapter item into Story 1.1/1.4/1.5 slices, and distinguish Handoff transport from later operator workflow.
- **Implementation spec:** tighten trust-boundary, audit, response, size, and evidence requirements before code begins.

## 3. Options Considered

| Option | Effort | Risk | Decision |
| --- | --- | --- | --- |
| Direct adjustment to the roadmap and Story 1.1 spec | Low | Low | **Selected** |
| Roll back the synthetic-local baseline | High | High | Rejected; no evidence it is invalid |
| Redefine or expand the MVP | High | High | Rejected; the existing bounded MVP remains viable |

The direct adjustment is the smallest change that restores traceability and security without duplicating stories, inventing staffing data, or broadening production scope.

## 4. Detailed Change Proposals

### Production roadmap

**Before:** `AI Engineer Sprint Plan`; `8 Sprints • 30 Tasks • Each with Description, Dependencies & Definition of Done`.

**After:** `AI Engineer Production Delivery Roadmap`; eight gated stages and 30 work items. No stage is committed until dates, named owners, and capacity are supplied. Stage 1 is the only commitment candidate; Stages 2–7 remain gated backlog and Stage 8 is a pilot gate.

**Sequencing corrections:**

- Stage 3 records unproven external API versions as `pending_external_proof`; Stage 4 pins only versions proven by credentialed checks.
- Stage 4 Meta work has three independently gated slices: Story 1.1 ingress, Story 1.4 dispatch, and Story 1.5 status. Only Story 1.1 is the first implementation candidate.
- Stage 4 Handoff work covers adapter transport and acknowledgement. Stage 6 covers representative claim, transcript access, and CRM-owned outcome on that approved adapter.

### Story 1.1 Meta ingress specification

**Before:** invalid/wrong/malformed/unsupported requests create no persistence; signature parsing and comparison are not exact; database failures have no explicit response; locally generated secrets are described as credentialed staging proof.

**After:**

- Strictly parse one `X-Hub-Signature-256` value as `sha256=<64 hex>` and compare fixed 32-byte digests in constant time.
- Enforce a 256 KiB text-only pilot payload limit before business JSON parsing and reject declared or measured oversize input.
- Validate the complete envelope and every entry/change identity before any accepted-message persistence; mixed identities are rejected atomically.
- Write one PII-minimized rejection Audit Event through a dedicated database command, with reason, correlation ID, and timestamp only; never store the raw rejected envelope.
- Return exactly one response per envelope: `200` for accepted/duplicate/unsupported signed deliveries, `400` malformed/oversize, `403` authentication/identity failure, and `5xx` when durable acceptance or rejection evidence cannot be committed.
- Preserve the synthetic route and stop Meta staging after durable ingest; no orchestrator, LLM, outbound, Follow-Up, or Handoff invocation.
- Separate generated-credential protocol proof from a real Meta test-asset smoke, which remains an external, approval-gated activity.

### Review records and planning index

Update stale conclusions so they reflect that the previously identified architecture/reconciliation gaps were converted into explicit rules, while implementation evidence and external approvals remain outstanding.

## 5. MVP Impact and Action Plan

The MVP scope is unchanged. Implementation is sequenced as follows:

1. Commit Stage 1 only after dates, named owner, and capacity are recorded; revalidate the local baseline.
2. Approve this proposal and the revised Story 1.1 specification.
3. Implement only the Story 1.1 local protocol slice in the `main` direct-implementation worktree; leave `codex/guided-learning` unchanged.
4. Run the complete existing harness plus the new ingress cases.
5. Request separate approval before using real Meta assets or changing any external subscription.

## 6. Handoff and Success Criteria

- **Product Owner / Executive Sponsor:** supply named owners, dates/capacity, and external contract approvals.
- **Architect / Security reviewer:** approve the minimal Code-node exception and ingress rejection-audit contract.
- **Developer:** after explicit approval, implement only Story 1.1 and its smallest runnable integration check.
- **Quality Advisor:** verify regression, security edge cases, traceability, and proof labels.
- **Release Owner:** keep `livePromotionAllowed=false` until every applicable production gate has evidence and approval.

Planning correction succeeds when the roadmap is honest about commitment, Story 1.1 has testable security/response semantics, stale review verdicts are reconciled, and no runtime artifact has changed. Implementation success is intentionally deferred pending explicit approval.

## 7. Checklist Status

- [x] Trigger, evidence, and problem category recorded.
- [x] Epic, story, PRD, architecture, UX, testing, deployment, and documentation impacts assessed.
- [x] Direct adjustment selected; rollback and MVP redefinition rejected.
- [x] Detailed artifact changes and handoff responsibilities defined.
- [N/A] `sprint-status.yaml` update — no such artifact exists and no epic/story IDs changed.
- [x] Explicit approval to implement — granted for Story 1.1 local protocol scope only on 2026-08-02.
