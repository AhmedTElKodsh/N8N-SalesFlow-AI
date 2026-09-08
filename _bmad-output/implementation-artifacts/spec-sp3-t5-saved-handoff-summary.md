---
title: 'SP3-T5 Save an evidence-grounded hand-off summary'
type: 'feature'
created: '2026-09-08'
status: 'done'
execution_stage: 'complete'
baseline_commit: 'cbf90041a9f019252729f0cf466e9c11d0adac59'
review_loop_iteration: 4
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp3-t4-automatic-human-handoff.md'
---

<frozen-after-approval reason="User requested SP3-T5 implementation and authorized a synthetic-local, operator-authenticated conversation-history endpoint; UI and CRM integration remain later project-order work">

## Intent

**Problem:** Human ownership and durable Handoff work exist, but the test sales team receives no saved, evidence-grounded snapshot of what requires attention. Notification failure also lacks durable recovery evidence, and no authenticated local destination resolves a Conversation link.

**Approach:** Atomically create an immutable concise summary with each new Handoff, derived only from data available in the hand-off transaction. Expose its stable link through a synthetic-local operator-authenticated history endpoint, and retain summary/ownership/suppression plus typed notification recovery evidence when dispatch fails.

## Boundaries & Constraints

**Always:** PostgreSQL owns the summary snapshot, Human-Owned state, notification lifecycle, and authorization. Store the typed reason, deadline-derived urgency, exact referenced inbound message identifiers/sequences and bounded excerpts, remaining unknowns, relevant offer or literal `none`, active Sales Policy version or `unknown`, and a stable account-scoped Conversation URL. Later messages/config rotations cannot rewrite the snapshot. The endpoint requires a valid operator token for the same account and returns ordered persisted messages; malformed, missing, cross-account, deleted, or unauthorized requests fail closed without data disclosure. Retryable/final notification failures append durable typed evidence while leaving the summary saved, Conversation human-owned, and customer automation stopped.

**Ask First:** Any live CRM/inbox destination, browser session/authentication design, production summary generator/classifier, new lead-profile extraction, urgency categories beyond the existing deadline, or changed retry policy.

**Never:** Put an operator token or customer message body in the URL, invent unsupported lead facts or offer relevance, mutate a saved summary on retry, create a second notification path, enable live promotion, claim a UI/CRM exists, commit/push, or modify unrelated SP3-T4 work.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Three trigger reasons | Explicit request, qualification threshold, or grounding failure | One immutable summary containing the exact typed reason, deadline, source references/excerpts, unknowns, offer/`none`, active rule version/`unknown`, and URL | Missing evidence is `unknown`; no inferred fact |
| Conversation link | Same-account operator supplies token and URL identifiers | Ordered full persisted Conversation history is returned | Wrong/missing token/account/id, malformed input, or deleted Conversation is denied without content |
| Later change or replay | New message, policy rotation, duplicate/concurrent trigger, or notification retry | Original summary remains byte-identical and one logical Handoff remains | Busy/retry paths create no partial replacement |
| Notification failure | Synthetic adapter reports retryable, final, or exhausted failure | Summary and Human-Owned lockout remain; typed failure/retry evidence is durable | No automated customer work resumes |
| Brownfield migration | Existing SP3-T4 Handoff rows; migration applied twice | Legacy rows are preserved with conservative `unknown` fields and resolvable scoped links | No fabricated historical policy/offer claim |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- summary schema/migration, atomic snapshot builders, operator-authorized history read, notification transitions, and retry authority.
- `workflows/06-handoff-dispatcher.json` -- expose summary to the existing synthetic adapter and route the authenticated Conversation-history request without a new workflow.
- `tests/sp3-t5.sql`, `tests/Test-SP3T5.ps1` -- isolated acceptance, migration-twice, authorization, immutability, failure, retry, concurrency, and cleanup proofs.
- `tests/run.ps1` -- include focused SP3-T5 proof in canonical verification.
- `docs/api-contracts.md`, `docs/data-models.md`, `docs/component-inventory.md`, `docs/project-context.md` -- document only observed synthetic-local behavior and deferred UI/CRM boundary.
- `config/release-set.json`, `release/release-manifest.json` -- rebind release-hashed inputs after stabilization while preserving `livePromotionAllowed=false`.
- `_bmad-output/implementation-artifacts/test-evidence.md` -- append final focused/canonical and review evidence.

## Tasks & Acceptance

**Execution:**
- [x] `tests/sp3-t5.sql`, `tests/Test-SP3T5.ps1` -- establish RED proofs for every matrix row before production edits, including both notification retry boundaries and account isolation.
- [x] `database/001-initial.sql`, `workflows/06-handoff-dispatcher.json` -- implement the smallest durable summary, authenticated history, and notification-evidence delta using the existing Handoff path.
- [x] `tests/run.ps1`, docs, evidence, and release files -- integrate regression proof, describe verified limits, and bind the stable candidate once.
- [x] Focused verification, canonical `PASS FULL PASS`, frozen snapshot, fresh Blind Hunter, and fresh Edge Case Hunter -- clear all completion gates on one unchanged snapshot.

**Acceptance Criteria:**
- Given each approved trigger, when ownership hands off, then its saved summary is complete, bounded, evidence-referenced, non-invented, and reflects the active transactional snapshot.
- Given the stored Conversation URL, when a same-account operator resolves it, then all and only that Conversation's ordered persisted messages are returned without placing credentials in the URL.
- Given retryable, final, or exhausted notification failure, when dispatch finishes, then durable recovery evidence records the exact attempt/outcome while summary and Human-Owned automation suppression remain unchanged.
- Given migration twice, duplicates/concurrency, config rotation, malformed inputs, deletion, and cross-account access, when exercised, then behavior is idempotent, isolated, bounded, and fail-closed.

## Spec Change Log

- 2026-09-08 review patch loop 4: Invalidated snapshot `8f58630afc1294830006f70347ba141e458de12b077b992f8a24f65b196f1b99` after exact-snapshot reviews found loss of an in-flight notification outcome following disable/suppress/re-enable, and omission of sent Follow-Ups from history. Added failing regressions, preserved terminal suppression while recording the exact original outcome once, and retained all sent outbound history through optional source lookups with explicit unknown metadata. Approved frozen intent remains unchanged.

- 2026-09-08: Approved direct-solution implementation started from `cbf90041a9f019252729f0cf466e9c11d0adac59` while preserving the uncommitted completed SP3-T4 baseline. Focused RED failed at the absent summary authority; the implemented focused suite then reached `PASS SP3-T5 FULL PASS` for all three reasons, snapshot immutability, operator/account boundaries, failure recovery, migration three times, deletion minimization, and concurrent replay.
- 2026-09-08: The first HTTP-expanded canonical candidate exposed an unsafe malformed Conversation UUID boundary in Workflow 06. Added `read_conversation_history_request` to validate text before UUID conversion and a focused regression assertion. Rebound the release after compacting Workflow 06 to the repository convention. Final activation manifest `c233a45d64a6691a53b2a1fbb2ff24a259be086ca405511f062a4616de619f07`; focused `PASS SP3-T5 FULL PASS` and canonical `PASS FULL PASS`; plaintext credentials removed, local stack retained at `http://127.0.0.1:32771`, and `livePromotionAllowed=false`. Candidate is frozen pending both mandatory reviews.
- 2026-09-08 review patch loop: Frozen snapshot `2b26fbfc9b9c21f3bc7ae405ed406773431dfa25e4b2c57fed1db5e3e95d293d` was invalidated after fresh reviews found reproducible gaps: unsupported first-allowed-offer inference, retention not minimizing copied excerpts, raw account identifiers breaking URLs, post-recheck authority changes losing actual notification outcomes, configuration-contraction exhaustion lacking evidence, and terminal notification rows retaining stale retry timestamps. Add focused RED proofs before the smallest corrections; KEEP atomic summary creation, three trigger reasons, operator header authentication, account isolation, immutable snapshots, Human-Owned lockout, migration idempotency, malformed UUID denial, release binding, and the synthetic-local boundary.
- 2026-09-08 review patch loop implementation: Focused RED first reproduced the raw-account Conversation URL failure, with tests added for every accepted finding. The corrected candidate stores `none` without durable offer relevance, minimizes copied excerpts under retention, derives account scope from the operator token, records exact post-recheck adapter outcomes under changed authority, records contraction exhaustion without fabricating an adapter attempt, and clears terminal retry timestamps. Focused `PASS SP3-T5 FULL PASS` and canonical `PASS FULL PASS` both exited 0; activation manifest `f086d6656e315dad545ef0b5b3ed11466f196d06a73ca5c287fe8ccaccf0d1fe`, local stack retained at `http://127.0.0.1:32773`, `livePromotionAllowed=false`. Fresh unchanged-snapshot reviews remain open.
- 2026-09-08 review patch loop 2: Frozen snapshot `9531021221b6eb33aed9f306ad63862b986ddd58a7fbdc4fd924209eb35f6b61` was invalidated after fresh reviews found terminal suppression paths retaining retry timestamps, scoped scheduler/runtime account mismatches exposing foreign Handoff work, disabled-account recheck leaving a live claim, and expired notification claims losing adapter outcomes while permitting blind retry. Add focused RED proofs before the smallest corrections. KEEP the frozen intent, all first-loop offer/retention/link/outcome/exhaustion fixes, malformed UUID denial, atomic summary creation, three trigger reasons, operator-header authentication, account isolation, Human-Owned lockout, migration idempotency, release binding, and the synthetic-local boundary.
- 2026-09-08 review patch loop 2 implementation: Focused RED first reproduced retry-to-opt-out retaining `next_attempt`; the expanded cases cover every accepted finding. The corrected candidate clears terminal claim/retry state, rejects foreign scoped runtime and scheduler claims without summary disclosure, terminalizes disabled-account rechecks, and writes claim-bound adapter-start evidence so an expired post-recheck attempt cannot be blindly reclaimed but its exact late outcome can be recorded once. Focused `PASS SP3-T5 FULL PASS`, manifest hashing, and canonical `PASS FULL PASS` exited 0; activation manifest `aa0b03d69af84fa1237e36b786429fc02900a920dc7629c143e21c4095626e7a`, local stack `http://127.0.0.1:32777`, and `livePromotionAllowed=false`. Fresh unchanged-snapshot reviews remain open.
- 2026-09-08 review patch loop 3: Frozen snapshot `ed4590311bd3461479365b1f5c0ac6346d0a9799dacfdf92eb79ff79cf186efa` was invalidated after fresh review reproduced duplicate adapter exposure from repeated recheck, null-scoped runtime cross-account access, lost outcomes after real in-flight opt-out/deletion, unsafe migration of already-claimed legacy Handoffs, and incomplete history that omitted persisted outbound messages. Add focused RED proofs before corrections. KEEP all prior summary grounding, privacy, scope, notification evidence, terminal cleanup, malformed-input, migration-idempotency, release-binding, and synthetic-local boundaries.

## Design Notes

Completion: both fresh independent reviewers cleared snapshot `93dfde01f013251defe21b2bc711d9a047aac6a0d914abfbd40089afb304831a`, which the primary agent reverified unchanged after review. Blind Hunter returned `CLEAR`; Edge Case Hunter confirmed `CLEAR` and returned `[]`. All approved completion gates are satisfied. Subsequent changes only record completion and update this review navigation; implementation, tests, workflows, configuration, and release bindings remain as reviewed. No commit or push was performed.

Loop 4 final verification: targeted SP3-T5 tests and canonical `$env:PYTHONUTF8='1'; .\tests\run.ps1 -ResetLocal -KeepRunning` passed with exact `PASS FULL PASS`, scheduler `1:1:1`, the deterministic lock fixture, matching hashes, and credential cleanup. Activation manifest: `8eea2e0395b3ba75028f8056c1a6e4ff118e1a5d2835fc2bde8754cee29358fb`; retained synthetic stack: `http://127.0.0.1:32781`; `livePromotionAllowed=false`. Fresh reviews of this candidate remain pending. All preceding review/pending statements describe superseded snapshots.

Canonical harness correction during loop 4: two runs failed the pre-existing six-second lock-holder fixture. A focused Compose reproduction with a 1.5-second contender launch delay showed the lock releasing before the five-second timeout, allowing dispatch. `tests/run.ps1` now holds that lock until an explicit release in `finally`, with a 30-second fail-safe and bounded cleanup. The same delayed contender then returned `busy` before holder release. The runtime timeout and recovery assertions are unchanged; this corrects test synchronization rather than runtime behavior.

Review loop 3 verification: focused `PASS SP3-T5 FULL PASS` covers concurrent recheck authorization, null-scoped runtime denial, global scheduler access, late and replayed outcomes after real opt-out/deletion, conservative legacy unknown-start reconciliation, and inbound/sent-outbound history excluding drafts. The canonical command with `-ResetLocal -KeepRunning` exited 0 with exact `PASS FULL PASS`, scheduler `1:1:1`, matching activation manifest `4c8f6a9a9c98c9f67bff5cbbb246eab264eaaf13468099adc56089781b2e09bb`, and plaintext credential cleanup. Local stack: `http://127.0.0.1:32779`; `livePromotionAllowed=false`. Both fresh reviews remain required.

Urgency is expressed as the existing Handoff response deadline, avoiding an invented priority taxonomy. Because the current system has no approved structured lead extractor, `knownLeadDetails` consists of bounded verbatim message excerpts paired with immutable message IDs/sequences; `remainingUnknowns` conservatively identifies the absent structured lead profile. An offer is named only when durable hand-off evidence supports relevance; otherwise it is literal `none`. Legacy summaries use `unknown` for values that cannot be reconstructed historically.

The Conversation URL is credential-free and contains only the Conversation UUID. Workflow 06 derives account scope from the separately supplied operator token; this is an API proof for synthetic-local testing, not a browser UI or CRM integration.

## Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SP3T5.ps1` -- focused summary/history/failure/migration/race proof passes with disposable cleanup.
- `$env:PYTHONUTF8='1'; .\tests\run.ps1 -ResetLocal -KeepRunning` -- exact `PASS FULL PASS`, migration twice, release hashes, credential cleanup, and `livePromotionAllowed=false`.
- Freeze tracked and relevant untracked files plus evidence into one combined SHA-256; both fresh read-only reviews must return `CLEAR` for that exact snapshot.

## Suggested Review Order

- Follow the existing dispatcher through authenticated history and notification authorization.
  [06-handoff-dispatcher.json:1](../../workflows/06-handoff-dispatcher.json#L1)
- Inspect the immutable summary and notification evidence schema.
  [001-initial.sql:54](../../database/001-initial.sql#L54)
- Trace evidence-backed summary creation and both directions of conversation history.
  [001-initial.sql:170](../../database/001-initial.sql#L170)
- Review claim scope, single adapter authorization, and late outcome handling.
  [001-initial.sql:640](../../database/001-initial.sql#L640)
- Check all three handoff reasons and failure-ordering regression assertions.
  [sp3-t5.sql:1](../../tests/sp3-t5.sql#L1)
- Verify isolated migration, concurrency, and cleanup proofs.
  [Test-SP3T5.ps1:1](../../tests/Test-SP3T5.ps1#L1)
- Inspect the final release input bindings and disabled live promotion.
  [release-manifest.json:1](../../release/release-manifest.json#L1)
