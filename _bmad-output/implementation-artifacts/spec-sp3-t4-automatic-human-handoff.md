---
title: 'SP3-T4 Build the automatic hand-off-to-human trigger'
type: 'feature'
created: '2026-09-06'
status: 'done'
execution_stage: 'complete'
baseline_commit: 'cbf9004'
review_loop_iteration: 3
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp3-t3-automatic-follow-up-system.md'
---

<frozen-after-approval reason="User approved the refined SP3-T4 task and requested implementation with the supplied verification template">

## Intent

**Problem:** The existing synthetic-local hand-off does not recognize the requested phrase "talk to a human", can create another hand-off for each repeated human request, and permits transfer acknowledgements after human ownership. Pending customer work must be durably stopped together with takeover.

**Approach:** Reuse PostgreSQL ingress, qualification, grounding checks, hand-off records, and the final send gate. Detect an explicit configured human request, the approved qualification threshold, or an ungrounded response; atomically mark the conversation Human-Handled (`owner='human'`), retain the reason, and stop automated customer messages.

## Boundaries & Constraints

**Always:** Human-Handled means the existing human ownership field, not a new lifecycle. Stop customer replies, follow-ups, retries, and transfer acknowledgements while human-owned. Preserve opt-out/deletion precedence and account authorization. Use existing conversation serialization and bounded waits. Cancel pre-call work while preserving immutable parent/child and provider-call evidence. A committed hand-off before call-start prevents a send; an already-started call can complete, with no later automatic call. Repeated requests during the same human-owned period create no additional hand-off. Retain existing authorized operator ownership controls.

**Always:** Detection proof is synthetic-local: normalized configured human signals including "talk to a human"; the existing exact `qualified` fixture reaching `qualification.handoffScore`; and the existing grounding failure when approved model/knowledge/policy cannot support the response. Near-miss messages must not trigger by substring. These fixtures do not prove natural-language classifier accuracy. Internal hand-off dispatch remains permitted because it is not a customer message.

**Ask First:** New production classifier/content, changed commercial thresholds, live provider connections, or altered retry budgets.

**Never:** Recall a started external message, claim external exactly-once delivery or real LLM accuracy, enable live promotion, commit, push, or modify unrelated learner work.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Explicit request | Configured normalized human signal | Human owner, one reasoned hand-off, no customer send | Opt-out/deletion and staging rules remain authoritative |
| Buying interest | Synthetic qualified score reaches current threshold | One qualification hand-off | Below-threshold ordinary message stays AI-owned |
| Uncertainty | Existing grounding check fails | One grounding-invalid hand-off, no draft sent | Missing hand-off configuration must not allow an automated send |
| Repetition | Duplicate event or later request while already human-owned | Existing ownership and no additional hand-off | Conflicting provider ID remains rejected |
| Pending work | Replies, retries, claimed or scheduled follow-ups exist | Pre-call work blocked with durable reason | Started work retains its actual outcome |
| Race | Takeover and call-start contend for conversation | Hand-off-first: zero calls; call-first: one retained call | Bounded busy result may be retried without duplicate effects |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- ingress, complete_turn, authorization_reason, ownership cancellation and durable transitions.
- `config/consent-and-templates.json` -- explicit signal list; preserve other approved values.
- `tests/sp3-t4.sql`, `tests/Test-SP3T4.ps1` -- isolated acceptance fixtures and real PostgreSQL concurrency proof.
- `tests/run.ps1` -- integrate focused acceptance into canonical verification.
- `config/release-set.json`, `release/release-manifest.json` -- dependent configuration and input hashes.
- `docs/project-context.md`, `docs/architecture.md` when applicable -- current no-ack ownership contract.

## Tasks & Acceptance

**Execution:**
- [x] `tests/sp3-t4.sql`, `tests/Test-SP3T4.ps1` -- prove gaps before production edits; map each case below to an executable assertion.
- [x] `database/001-initial.sql`, `config/consent-and-templates.json` -- smallest coherent detection, deduplication and ownership suppression delta.
- [x] `tests/run.ps1` -- execute scoped proofs in the canonical command without contaminating existing fixtures.
- [x] Current documentation and release files -- align the contract and recompute hashes after stabilization.
- [x] Targeted and canonical verification, cleanup, frozen snapshot, independent Blind and Edge reviews -- all passed.

**Acceptance Criteria / Traceability:**
- Given each positive and negative fixture, when ingress/complete_turn runs, then owner, reason, hand-off count and call count match the matrix. Authority: ingress/complete_turn; proof: focused trigger assertions.
- Given pending/retry replies and follow-ups, when ownership changes, then cancellation and ownership commit together, no pre-call intent remains sendable and transition evidence records the denial. Authority: ownership mutation and final authorization; proof: focused pending-work and acknowledgement assertions.
- Given repeated and concurrent requests, when retried, then there is one hand-off for the human-owned period and no duplicate customer call. Authority: conversation lock and ingress ownership check; proof: focused duplicate/concurrency assertions.
- Given both concurrent transaction orders, when hand-off and begin_provider_call contend, then zero or one existing call is retained respectively and future calls are blocked. Authority: shared conversation lock/final gate; proof: focused two-session race assertions.
- Given malformed, conflicting, cross-account, opted-out, deleted, staging, missing-config and retry states, when processed, then existing protection is preserved. Proof: focused boundary assertions plus canonical regression suite and migration twice.

## Spec Change Log

- 2026-09-06: Recorded the approved conversation task as the implementation specification. No additional approval required; the user's implementation template governs final verification. Initial tree clean at cbf9004; Docker client/server 29.7.2 and pinned images verified.
- 2026-09-06: Focused RED reproduced the missing explicit request. The final focused suite and canonical harness passed; activation manifest `7847fd34d08275ddb551a61e2fff4277d76d99b4b2189593aa9ac5f3064fc766`, `livePromotionAllowed=false`. Candidate frozen for independent review.
- 2026-09-06 review loop 1: Edge review found combined operator `opted_out` plus Human-Owned changes skipped pre-call intent suppression because lifecycle reason precedence selected the follow-up-only branch. Added the missing executable operator case and changed the helper to retain the lifecycle reason while suppressing all pre-call automation. KEEP the three trigger paths, no-ack rule, repeated-request reuse, shared conversation lock, started-call preservation, focused isolation, and synthetic-local boundary.
- 2026-09-06 corrected candidate: Focused `PASS SP3-T4 FULL PASS` and canonical `PASS FULL PASS` obtained after the operator-precedence correction. Activation manifest `9090f9d524695b2c24059a8a4c539a96db35ec9d46170a10bd21e38b8fef18e3`; generated credentials removed; requested local stack retained; `livePromotionAllowed=false`. Candidate re-frozen for both mandatory reviews.
- 2026-09-06 review loop 2: Both fresh reviews found that pre-SP3-T4 Human-Owned database rows were not backfilled; Edge review also found no direct proof for every active Follow-Up parent state. Added an idempotent migration backfill with lifecycle reason precedence, seeded pre-upgrade pending/leased/retry/acknowledgement and Follow-Up work, applied the migration twice over it, and directly proved due/claimed/retry/intent-created parent cancellation plus child suppression. KEEP all prior trigger, final-gate, race, cleanup, and synthetic-local boundaries.
- 2026-09-06 final backfill candidate: Focused `PASS SP3-T4 FULL PASS` and canonical `PASS FULL PASS`; activation manifest `aee82dd28371e977b539751c5b7864dd8f20cdd58961576deed9adbd049b7957`; exact scheduler recovery `1:1:1`; credentials removed; local stack retained; `livePromotionAllowed=false`. Re-frozen for both mandatory reviews.
- 2026-09-06 review loop 3: Blind review cleared the corrected backfill candidate. Edge review found that the fixture named `retry` was actually in `pending`, and that Human-Owned takeover did not directly prove preservation of `reconciliation_required` work. Seeded literal retry rows in takeover and migration-upgrade paths, asserted exact `retry -> suppressed` evidence and migration idempotency, and added an ambiguous-call takeover case that preserves reconciliation with one durable provider call and blocks another claim/call creation. KEEP the implementation; this correction expands executable coverage only.
- 2026-09-06 final coverage candidate: Focused `PASS SP3-T4 FULL PASS` and canonical `PASS FULL PASS`; activation manifest `768fe97033953c7c0441562ccd453dff384770eee99903176f75b26bd8cd9adb`; exact scheduler recovery `1:1:1`; credentials removed; local stack retained at `http://127.0.0.1:32777`; `livePromotionAllowed=false`. Re-frozen for both mandatory reviews.
- 2026-09-06 completion: Frozen implementation snapshot `b02503d5bd5148514ee8137f09862b0b967817c091e6abbb2171bc42d318924d` was reverified unchanged and received `CLEAR` from both the independent Blind Hunter and Edge Case Hunter. Task marked done; no commit, push, or live promotion performed.

## Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SP3T4.ps1` -- isolated targeted SQL and concurrent transaction proofs; disposable container cleanup.
- `$env:PYTHONUTF8='1'; .\tests\run.ps1 -ResetLocal -KeepRunning` -- exact `PASS FULL PASS`, migration twice, hash binding, generated plaintext credential cleanup, explicitly retained local stack.
- Freeze scoped tracked/untracked inputs and evidence; record combined SHA-256. Both fresh read-only reviews must clear that identical snapshot. `livePromotionAllowed=false` throughout.

## Suggested Review Order

1. [Human takeover and send authority](../../database/001-initial.sql#L389)
2. [Focused trigger and state coverage](../../tests/sp3-t4.sql#L30)
3. [Isolated migration and race harness](../../tests/Test-SP3T4.ps1#L12)
4. [Canonical verification entrypoint](../../tests/run.ps1#L48)
5. [Release binding](../../release/release-manifest.json#L27)
