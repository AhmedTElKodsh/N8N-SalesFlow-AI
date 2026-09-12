---
title: 'SP3-T6 Build durable activity logs, emergency stop, and failure visibility'
type: 'feature'
created: '2026-09-09'
status: 'done'
baseline_commit: 'b0a9c6df58c637bbc3fb35fa50c19596ee3a2395'
review_loop_iteration: 0
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp3-t5-saved-handoff-summary.md'
---

<frozen-after-approval reason="User requested direct SP3-T6 implementation with targeted proof, canonical verification, and two fresh independent reviews; live activation and publication remain excluded">

## Intent

**Problem:** Operations cannot use the existing stop authority through Workflow 07, inspect individual failed/retried sends, or retrieve one attributable record of important rule, send, hand-off, ownership, and stop changes.

**Approach:** Extend the account-scoped Operations boundary and PostgreSQL evidence model with an emergency-stop command, bounded activity feed, and bounded failure view. A successful stop becomes the exact boundary after which no new automated customer provider call may begin.

## Boundaries & Constraints

**Always:** PostgreSQL owns state, authorization, ordering, and evidence; n8n routes authenticated Operations requests. Each material action records account, actor or `system`, database time, entity, outcome, and relevant before/after values. Evidence is append-only in ordinary operation and changes only through approved retention/deletion controls. A successful stop covers all automated customer messages for the operator's account, serializes with provider-call start, preserves queued records, and leaves already-started calls visible for completion or reconciliation. Views are newest-first, stable, account-isolated, default to 50 items, cap at 100, and expose no tokens or message bodies.

**Ask First:** A multi-account deployment switch, dashboard, alert threshold/destination, retention exemption, new role, live provider/CRM integration, retry-policy change, or replay when stop clears.

**Never:** Treat `busy` as stopped, recall or erase started calls, add another send path, rewrite evidence, invent legacy facts, leak cross-account data, enable live promotion, invoke live providers, commit/push, or alter unrelated files.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Stop/resume | Same-account operator sends `emergency_stop` with boolean `enabled` | Return accepted state; audit actor/time and previous/new value; clearing affects future eligible work only | Invalid input is typed; `busy` leaves state unchanged |
| Stop/send race | Claimed work races stop in either commit order | Stop-first creates no call; call-first preserves exactly one started call and blocks later starts | Started work remains reconcilable |
| Activity | Valid limit and optional stable cursor | Return only that account's material events with actor/time/entity/outcome/change | Invalid bounds are typed; empty page is an empty list |
| Failures | Retry, exhaustion, failure, ambiguity, or hand-off notification failure | Return work/attempt/state, latest reason/time, next retry, and manual-action status | Unauthorized access fails closed without counts |
| Upgrade/retention | Legacy evidence; repeated migration; later retention | Preserve state, use `unknown` where necessary, avoid duplicates, honor retention | Injected migration failure rolls back |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- stop command, attributable evidence, failure projections, migration, retention, and grants.
- `workflows/07-error-and-operations.json` -- route actions and map typed HTTP outcomes.
- `tests/sp3-t6.sql`, `tests/Test-SP3T6.ps1` -- isolated acceptance, migration, authorization, and cleanup proof.
- `tests/run.ps1` -- focused integration, concurrent race ordering, and Workflow 07 HTTP proof.
- `docs/api-contracts.md`, `docs/architecture.md`, `docs/component-inventory.md`, `docs/data-models.md`, `docs/project-context.md` -- observed behavior and limits.
- `config/release-set.json`, `release/release-manifest.json` -- bind stable inputs while keeping `livePromotionAllowed=false`.
- `_bmad-output/implementation-artifacts/test-evidence.md` -- focused, canonical, snapshot, and review evidence.

## Tasks & Acceptance

**Execution:**
- [x] `tests/sp3-t6.sql`, `tests/Test-SP3T6.ps1`, `tests/run.ps1` -- add RED proofs for the matrix, both race orders, replay/concurrency, account isolation, malformed/NULL input, retry boundaries, repeated/rollback migration, retention, and cleanup.
- [x] `database/001-initial.sql`, `workflows/07-error-and-operations.json` -- implement the smallest PostgreSQL-owned delta through the existing Operations and send paths.
- [x] `docs/*.md`, `config/release-set.json`, `release/release-manifest.json`, `_bmad-output/implementation-artifacts/test-evidence.md` -- align documentation, bind stabilized inputs once, and record synthetic-local evidence.
- [x] Focused verification, canonical `PASS FULL PASS`, frozen snapshot, fresh Blind Hunter, and fresh Edge Case Hunter -- clear every gate on one unchanged candidate.

**Acceptance Criteria:**
- Given a successful account stop, when pending or claimed work reaches provider-call start, then no new call begins, queued evidence remains, and any earlier call stays exactly-once and reconcilable.
- Given each required material action, when it commits, then Operations can retrieve an immutable, attributable, privacy-minimized record of what changed.
- Given retryable, exhausted, failed, ambiguous, callback-failed, and hand-off failure states, when Operations queries failures, then the bounded response identifies attempts, latest reason, next retry, and required action without cross-account disclosure.
- Given replay, concurrency, migration twice/rollback, retention, malformed input, invalid authorization, and release rotation, when exercised, then behavior is atomic, idempotent, bounded, isolated, and fail-closed.

## Spec Change Log

## Design Notes

The stop is account-wide because operator authority is account-bound. Success—not button press or `busy`—is the linearization point. Clearing the stop never automatically replays suppressed work.

## Verification

**Commands:**
- `powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SP3T6.ps1` -- exact focused pass with disposable cleanup.
- `$env:PYTHONUTF8='1'; .\tests\run.ps1 -ResetLocal -KeepRunning` -- exact `PASS FULL PASS`, migration twice, concurrency, hashes, credential cleanup, retained healthy stack, and `livePromotionAllowed=false`.
- Fresh read-only Blind Hunter and Edge Case Hunter reviews -- both `CLEAR` for the same unchanged snapshot hash.

## Suggested Review Order

**Durable operations boundary**

- Start with PostgreSQL-owned stop semantics and operator attribution.
  [`001-initial.sql:303`](../../database/001-initial.sql#L303)

- Review bounded, account-isolated activity and failure reads.
  [`001-initial.sql:305`](../../database/001-initial.sql#L305)

- Confirm Workflow 07 exposes only the existing operations command surface.
  [`07-error-and-operations.json:1`](../../workflows/07-error-and-operations.json#L1)

**Migration and retention finality**

- Inspect content-free marker storage for replay-safe failure projection.
  [`001-initial.sql:68`](../../database/001-initial.sql#L68)

- Trace cutoff-aware, idempotent activity and failure backfills.
  [`001-initial.sql:700`](../../database/001-initial.sql#L700)

- Verify the Handoff migration-to-retention-to-migration regression.
  [`Test-SP3T6.ps1:35`](../../tests/Test-SP3T6.ps1#L35)

**Contracts and release evidence**

- Check the documented stop linearization and privacy-minimized response contract.
  [`api-contracts.md:65`](../../docs/api-contracts.md#L65)

- Confirm the corrected candidate remains cryptographically release-bound and promotion-disabled.
  [`release-manifest.json:97`](../../release/release-manifest.json#L97)

- Read the focused, canonical, snapshot, and independent-review evidence trail.
  [`test-evidence.md:23`](./test-evidence.md#L23)
