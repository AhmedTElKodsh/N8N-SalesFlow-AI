---
title: 'SP3-T2 Build the message-sending system with duplicate protection'
type: 'feature'
created: '2026-08-25'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'b327e0c'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp3-t1-complete-context-snapshot.md'
  - '{project-root}/_bmad-output/planning-artifacts/architecture/architecture-N8N-SalesFlow-AI-2026-07-14/ARCHITECTURE-SPINE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The current dispatcher gives one worker a temporary lease but does not durably record when the provider call starts. A crash after the adapter runs but before completion is saved can therefore expire the lease and cause the same customer message to be sent again.

**Approach:** Add one durable, account-scoped provider-call record per logical Outbound Intent. Atomically combine the final current-state authorization check with creation of that record, make every retry consult it, and preserve accepted/delivered/failed/reconciliation evidence through the existing synthetic test channel and callback path.

## Boundaries & Constraints

**Always:** Reuse the existing unique Outbound Intent and logical action key. Immediately before the adapter call, recheck global/scoped stops, lifecycle, latest consent and opt-out, ownership, Conversation version, active policy/knowledge, WhatsApp window/template, quiet hours, frequency, and campaign state. In the same PostgreSQL transaction, create at most one durable call-start record with a stable provider ID, lease/attempt identity, correlation evidence, and start time. Permit automatic retry only when no call-start exists. Treat a started call without a conclusive result as `reconciliation_required`. Keep provider events append-only, status monotonic, account-bound, and queryable. Preserve all SP3-T1 behavior and keep `livePromotionAllowed=false`.

**Ask First:** Connecting live Meta, changing production idempotency-header behavior, allowing an audited operator replay after an ambiguous call, redefining callback terminal-status precedence, persisting unknown-provider callbacks, changing retry budgets, or altering consent/policy authority.

**Never:** Promise literal exactly-once delivery from an external network; infer that an expired lease means no provider request started; blindly resend an ambiguous call; create a second send path; use n8n execution history as durable authority; weaken final authorization; overwrite immutable provider evidence; include credentials or customer data in repository artifacts.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Eligible send | Pending authorized intent with no call-start | One lease, one atomic final gate/call-start, one stable provider ID, then sent/accepted | Typed denial before adapter if authorization changes |
| Duplicate workers | Same intent claimed or started concurrently/sequentially | Exactly one call-start and one synthetic provider message | Other workers return typed terminal/idempotent results and perform no adapter call |
| Safe retry | Worker fails or lease expires before call-start | Same intent may be reclaimed within retry policy | Preserve the logical key and record the pre-call failure |
| Ambiguous send | Call-start exists but completion is absent, timed out, or ambiguous | No automatic resend; intent becomes reconciliation-required | Alert/queryable reason and immutable attempt evidence |
| Status callbacks | Duplicate, concurrent, or out-of-order accepted/sent/delivered/failed events | One immutable event per event ID; derived status never regresses | Conflicting event-ID reuse is rejected; unknown provider remains typed denial |
| Twenty-message load | Twenty distinct eligible intents dispatched together, then retried | Exactly 20 unique call-starts/IDs and 20 delivered; retries add zero sends or deliveries | Any missing, duplicate, wrong association, or worker failure fails acceptance |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- outbound intent states, append-only dispatch-attempt/provider evidence, authorization, claim/start/finish, expired-lease recovery, callbacks, and grants.
- `workflows/03-outbox-dispatcher.json` -- claim, atomic final gate/call-start, synthetic adapter, and outcome persistence path.
- `workflows/04-whatsapp-status.json` -- authenticated callback path using the strengthened status contract.
- `tests/runtime.sql` -- focused state-machine, retry, ambiguity, immutability, callback-order, and migration assertions.
- `tests/run.ps1` -- real n8n path, crash boundaries, 20-message concurrency, retry replay, callback delivery, release identity, and cleanup.
- `docs/*.md`, `_bmad-output/implementation-artifacts/test-evidence.md` -- observed contract and synthetic-only evidence.
- `config/release-set.json`, `release/release-manifest.json` -- next release binding over the current SP3-T1 release-v8 baseline.

## Tasks & Acceptance

**Execution:**
- [x] `tests/runtime.sql` -- add red assertions for unique call-start, pre/post-start lease expiry, terminal replay, failed/reconciliation history, and callback monotonicity.
- [x] `database/001-initial.sql` -- add the migration-safe append-only call ledger and atomic final-gate/start command; harden claim, finish, scheduling, callback resolution, states, and grants.
- [x] `workflows/03-outbox-dispatcher.json` -- route only a newly started call to the synthetic adapter and pass its durable provider identity to completion.
- [x] `tests/run.ps1` -- prove concurrent duplicate collapse, both crash boundaries, exactly 20 distinct delivered messages, and zero additional effects when the same 20 are retried.
- [x] `docs/*.md`, `test-evidence.md`, `index.md` -- document only behavior proven by focused and full tests and retain the synthetic/live boundary.
- [x] `config/release-set.json`, `release/release-manifest.json` -- advance and recompute raw, canonical workflow, activation, and outer hashes without introducing a circular release-set hash.

**Acceptance Criteria:**
- Given any eligible logical intent, when workers and retries race, then at most one automatic provider-call start exists and every later attempt performs no second adapter call.
- Given authorization changes before call-start, when the atomic start command runs, then no provider call is recorded or made and the typed denial is durable.
- Given failure before versus after call-start, when recovery runs, then only the proven pre-call case is retryable and every uncertain post-start case requires reconciliation.
- Given 20 distinct approved messages and concurrent dispatch/status work, when all callbacks complete and the same work IDs are retried, then exactly 20 unique messages remain delivered with none missing and no additional call-start, provider ID, event, or delivery.
- Given focused checks and the canonical harness, when verification completes, then all prior SP1/SP2/SP3-T1 behavior passes, release identity is exact, cleanup succeeds, and live promotion remains disabled.

## Spec Change Log

- 2026-08-25: Implemented and verified the durable provider-call boundary, conservative retry/reconciliation state machine, callback reconciliation, 20-message concurrent send/delivery/retry proof, and promotion-blocked release-v9 binding.
- 2026-08-25 adversarial review: Fixed active-call false reconciliation and terminal replay routing; serialized the final gate with consent/config/control/deletion and durable per-Contact frequency reservations; made conclusive provider failure terminal without changing existing callback-origin precedence; bounded HTTP race cleanup; renamed call evidence to the accurate Release Set reference; and added same-intent plus final-frequency-slot contention proofs. KEEP the one-call ledger, conservative post-start reconciliation, immutable evidence, 20-message zero-delta proof, and synthetic-only boundary.

## Design Notes

The durable call-start record is intentionally conservative: committing it immediately before the adapter means a crash in the tiny gap before the network operation may create a false reconciliation case, but it cannot create a duplicate automatic send. This is safer than treating lease expiry as proof that no external effect occurred. The synthetic ledger proves local behavior only; a live adapter will still require the provider's supported idempotency mechanism and credentialed integration evidence.

Implementation keeps the existing `recheck_dispatch` function for compatibility, but Workflow 03's authoritative final boundary is `begin_provider_call`. A provider callback can resolve a started or reconciliation-required intent; the original call-start and every callback remain queryable.

## Verification

**Commands:**
- Focused disposable PostgreSQL migration/runtime checks after each database/test patch -- expected: new SP3-T2 assertions and all prior SQL assertions pass.
- PowerShell parse plus JSON/canonical-workflow/hash checks after workflow and release changes -- expected: valid artifacts and exact next-release binding.
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: `PASS FULL PASS`, exact 20-message proof, retry zero-delta proof, imported/exported workflow identity, and cleanup.
- `git diff --check` and `git status --short` -- expected: no whitespace defects, secrets, generated volumes, or changes outside the combined SP3-T1/SP3-T2 scope.

**Observed:** Focused disposable PostgreSQL migration/runtime checks passed after the initial missing-function red failure. After adversarial corrections, the canonical isolated harness again completed with `PASS FULL PASS`; six same-intent workers collapsed to one sent call, two same-Contact intents reserved one remaining frequency slot, the 20-message snapshot was `20:20:20:20:20:20:20:20`, retry evidence remained `20:40:40`, imported/exported workflow identity matched release-v9, and generated credentials/volumes were removed.

## Suggested Review Order

**Final authorization and call boundary**

- Serializes every mutable authority, then atomically reserves the unique provider call.
  [`001-initial.sql:174`](../../database/001-initial.sql#L174)

- Counts durable call-starts so concurrent intents cannot share one frequency slot.
  [`001-initial.sql:170`](../../database/001-initial.sql#L170)

- Routes only a newly started call into the synthetic adapter.
  [`03-outbox-dispatcher.json:1`](../../workflows/03-outbox-dispatcher.json#L1)

**Durable state and recovery**

- Establishes unique immutable call identity and append-only lifecycle evidence.
  [`001-initial.sql:42`](../../database/001-initial.sql#L42)

- Distinguishes live calls, terminal replay, safe reclaim, and uncertain outcomes.
  [`001-initial.sql:172`](../../database/001-initial.sql#L172)

- Persists accepted, failed, ambiguous, and idempotent terminal completion.
  [`001-initial.sql:175`](../../database/001-initial.sql#L175)

- Reclaims only pre-start work and reconciles expired post-start work.
  [`001-initial.sql:219`](../../database/001-initial.sql#L219)

- Retains contradictory callbacks while preserving conclusive failure and monotonic status.
  [`001-initial.sql:221`](../../database/001-initial.sql#L221)

**Concurrency and acceptance evidence**

- Proves six workers racing one intent produce one call and send.
  [`run.ps1:193`](../../tests/run.ps1#L193)

- Proves two intents reserve exactly one remaining per-Contact frequency slot.
  [`run.ps1:202`](../../tests/run.ps1#L202)

- Proves 20 concurrent deliveries and retry replay with zero additional effects.
  [`run.ps1:207`](../../tests/run.ps1#L207)

- Exercises active-call, crash, terminal, callback-order, and conclusive-failure branches.
  [`runtime.sql:92`](../../tests/runtime.sql#L92)

**Release and reviewer context**

- Binds database, workflow, and test bytes to promotion-blocked release-v9.
  [`release-manifest.json:28`](../../release/release-manifest.json#L28)

- Records the observed synthetic-only contract and explicit production boundary.
  [`test-evidence.md:1`](test-evidence.md#L1)
