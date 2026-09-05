---
title: 'Fix the eight September 5 repository review findings'
type: 'bugfix'
created: '2026-09-05'
status: 'done'
baseline_commit: '0ac5bbbd0b406303744427a0c7da6b2af047f33a'
review_loop_iteration: 0
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/learning/tutor-contract.md'
---

<frozen-after-approval reason="User explicitly requested implementation of all eight reviewed fixes">

## Intent

**Problem:** The current repository loses pending turn recovery, accepts ineffective consent signals, cannot manage account enablement through its webhook, and fails untyped on oversized identifiers. Learning commands also lose failed-check state, fail default Windows invocation, write before lineage validation, and collide with retained learner stacks at capstone.

**Approach:** Correct all eight caller-traced findings with focused regression coverage, preserving existing changes and synthetic-local boundaries.

## Boundaries & Constraints

**Always:** PostgreSQL owns durable state and authorization. Preserve account isolation, conversation ordering, bounded scheduler work, remote idempotency, immutable configuration, and existing learner state. Verify actual failing input paths. Keep release bindings synchronized after executable changes. All local disposable resources must have validated ownership and isolation.

**Ask First:** Production/provider activation, live messages, destructive changes to retained user environments, commit or push.

**Never:** Read secrets into output, use reference learner code, silently reset learner volumes, modify actual learner progress, add runtime dependencies, or enable live promotion.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Turn recovery | Ingest committed; orchestrator stopped or busy | Scheduler revisits unfinished conversations; retries do not duplicate side effects | Bounded work and existing authorization |
| Consent signals | Uppercase/padded/noncanonical configured signal | Reject configuration or match using identical normalization | Typed invalid configuration |
| Check failure | Prior pass then real failure without evidence | Previous pass invalidated; classified diagnostic retained | Nonzero exit and failed result |
| Account management | Webhook NULL account; valid operator | Resolve authorized account including disabled-account recovery | Reject wrong/revoked token |
| CLI defaults | Native Windows powershell.exe -File without root | Resolve own repository inside initialized script scope | Normal command errors |
| Capstone | Existing learner .env/volumes | Isolated disposable harness; retained stack unchanged | No implicit reset |
| First use | Invalid Git lineage and missing progress | Failure without progress creation | Validate before writes |
| Inbound ID | Oversized incompressible provider ID | Reject before indexed insertion | Typed invalid input |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql`, `workflows/01-whatsapp-ingress.json`, `workflows/02-conversation-orchestrator.json`, `workflows/05-follow-up-scheduler.json` -- turn recovery, validation, and account-management enforcement.
- `scripts/learn.ps1`, `scripts/Invoke-LearningCheckpoint.ps1`, `scripts/LearningState.psm1` -- learner CLI initialization and failed behavior evidence.
- `tests/learning/checkpoints/Test-M10.ps1`, `tests/run.ps1` -- capstone isolation and runtime lifecycle.
- `tests/learning/Test-*.ps1`, `tests/runtime.sql` -- regression evidence.
- `release/release-manifest.json`, `config/release-set.json` -- executable release identity.

## Tasks & Acceptance

**Execution:**
- [x] Fix learner CLI defaults, initialization ordering, and real checkpoint failure recording; add regressions for each.
- [x] Isolate M10 disposable harness from retained learner stack; add provider-free isolation regression.
- [x] Recover durable pending turns through existing scheduler/workflow architecture; test interrupted ingest and repeated recovery.
- [x] Correct signal validation, NULL-account management, and provider-ID byte limits; add SQL and applicable workflow regression cases.
- [x] Update release bindings and documentation; run focused checks and available canonical verification.
- [x] Independently review the final frozen changes and resolve concrete remaining findings.

**Acceptance Criteria:**
- Given an accepted message with interrupted orchestration, when scheduled recovery runs repeatedly, then the turn eventually completes without duplicate outbound work and respects account/conversation authority.
- Given each invalid configuration, identifier, account token, or learner state, when its public entrypoint executes, then it returns the intended failure and preserves unrelated state.
- Given a valid learner stack, when M10 runs, then its disposable lifecycle cannot replace or delete the retained stack.
- Given a previously passing milestone followed by a real failing check, when completion is attempted, then stale evidence cannot authorize completion.
- Given the final snapshot, when provider-free verification runs, then all checks pass; Docker unavailability must be recorded separately from runtime proof.

## Spec Change Log

- 2026-09-05: User authorized all eight findings together after the whole-repository review; no additional scope approval required.

## Verification

- Run all provider-free learning test files, PowerShell/JSON parsing, diff integrity, workflow canonicalization, and manifest hashing.
- Run the synthetic Docker harness only in a disposable environment if the engine is available; retain exact cleanup and full-pass evidence.
- Run independent adversarial and edge-case reviews after implementation stabilizes. Do not claim runtime clearance from older evidence.

## Final Verification — 2026-09-05

All eight fixes are implemented and verified in a fresh disposable checkout. After recovering stale Docker Desktop socket directories without deleting project volumes, the canonical synthetic-local harness completed with `PASS FULL PASS`. This proves the local PostgreSQL/n8n test boundary; it does not authorize or prove production/provider operation.

- All eight provider-free learning suites passed after the main implementation.
- The final timeout correction passed the complete focused CLI suite, including pass → hang → failed gate → denied completion and locked successor.
- The capstone helper copied every actual manifest input with identical hashes into a disposable checkout and cleaned it successfully. Its provider-free regression proved retained environment, stack artifacts, and progress are excluded and preserved.
- JSON and PowerShell parsing, Node syntax, Compose configuration, manifest hashing, and diff integrity passed. Manifest hashing and parsing were repeated after the final executable corrections.
- Actual workflow JavaScript passed ASCII and multibyte provider-ID boundary checks, duplicate retry routing, and both runtime/scheduler input bindings.
- SQL and HTTP regressions passed for durable recovery, repeated recovery without duplicate calls, account enable/disable through the NULL-account webhook, canonical consent signals, and provider-ID byte limits.
- The harness also passed migration idempotence and rollback, runtime S01-S26 assertions, concurrency races, workflow import/activation/publication/export identity, native UTC scheduling, endpoint paths, manifest binding, generated-secret scans, plaintext credential cleanup, and Docker-volume cleanup.
- Workflow readiness now refreshes the dynamically assigned n8n port after restart, and the final no-work assertion drains bounded recoverable work before requiring `authenticated_no_work`.
- Independent adversarial and edge reviews found a residual timeout path and an existing misencoded SQL boundary fixture. Both were corrected and independently rechecked; the final edge result was `[]`, and the adversarial reviewer reported no concrete regression in the corrections.
- The disposable checkout contained no retained `.env`, `.generated`, or `.learning` state. Its runtime credential file was absent after harness cleanup, and the validated snapshot directory was removed without traversing a reparse point.
- No commit, push, real provider call, actual learner progress mutation, or retained-stack reset was performed.
- Final review closure: the independent adversarial recheck returned `[]`. The earlier independent edge review cleared the implementation; its final repeat failed to run because the reviewer workspace exhausted credits. The primary agent reviewed the subsequent port-refresh and recovery-drain changes locally and found no additional actionable regression.

## Suggested Review Order

- Durable pending conversations share the bounded work cursor and existing orchestrator.
  [001-initial.sql:453](../../database/001-initial.sql#L453)
- The scheduler routes pending conversation work to Workflow 02.
  [05-follow-up-scheduler.json:1](../../workflows/05-follow-up-scheduler.json#L1)
- Failed execution and timeout results invalidate earlier learner behavior evidence.
  [Invoke-LearningCheckpoint.ps1:139](../../scripts/Invoke-LearningCheckpoint.ps1#L139)
- Capstone isolation copies reviewed inputs and preserves retained learner resources.
  [CheckpointSupport.ps1:3](../../tests/learning/checkpoints/CheckpointSupport.ps1#L3)
- Regression scenarios exercise account management, validation, and durable recovery.
  [runtime.sql:222](../../tests/runtime.sql#L222)
