---
title: 'SP3-T1 Build the complete context snapshot for each AI response'
type: 'feature'
created: '2026-08-24'
status: 'review'
review_loop_iteration: 0
baseline_commit: 'b327e0c'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp1-t2-versioned-business-information.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp2-t3-gather-response-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The SP2-T3 response-context foundation locks independently active Product Knowledge and Sales Policy rows, but it does not prove that the selected pair belongs to one approved Release Set. It also records consent status and time without an explicit minimized reference to the selected consent evidence. A response can therefore retain substantial provenance while still leaving release-pair and consent-evidence ambiguity.

**Approach:** Extend the existing account-, Contact-, Conversation-, and Turn-scoped PostgreSQL snapshot. Select the active Release Set together with its exact active Product Knowledge and Sales Policy versions, fail closed when the three records are missing or inconsistent, and persist minimized Release Set and consent-evidence references with the existing ordered bounded message references.

## Boundaries & Constraints

**Always:** Authenticate and lock the account-scoped Conversation before context reads. Keep the latest-consent and same-account/Contact checks. Treat the active Release Set as the approved pair authority and require both referenced immutable documents to be active for the same account. Keep the existing ten-message and 32 KiB UTF-8 history limits, current-message inclusion, ascending stored sequence, and reference-only persisted history. Record the Release Set version, consent status/time/evidence hash, both business versions, ordered message IDs/sequences, source ID, and Conversation version. Keep `livePromotionAllowed=false`.

**Ask First:** Changing the history limits, storing raw consent evidence in intent provenance, adding stable consent-event UUIDs, expanding history beyond canonical inbound messages, changing release publication authority, connecting a real model/provider, or adding infrastructure.

**Never:** Select an active Product Knowledge/Sales Policy pair that conflicts with the active Release Set; use provider timestamps for history order; read across accounts, Contacts, or Conversations; continue with missing/revoked consent or missing/conflicting business context; copy raw conversation history or raw consent evidence into immutable intent provenance.

## Acceptance Criteria

- Given an eligible committed inbound Turn, when context is assembled, then one intent records the latest granted consent reference, one active Release Set, the exact active Product Knowledge and Sales Policy versions named by that Release Set, and only bounded ordered references from the same Conversation.
- Given missing/revoked consent, missing active Release Set, a Release Set/document mismatch, missing business information, or a wrong account/Conversation reference, when processing runs, then no AI intent exists and processing fails closed without exposing history.
- Given more than ten messages or more than 32 KiB of eligible processing text, when context is assembled, then the current message is present, fitting predecessors are selected deterministically, and persisted sequences remain ascending.
- Given Product Knowledge or Sales Policy changes during an ongoing Conversation, when the matching Release Set is activated and the next response is created, then the response uses the newly approved pair while the earlier sent response retains its original body and provenance except authorized privacy minimization.
- Given focused checks and the canonical harness run, when verification completes, then all existing regression tests and SP3-T1 tests pass with the release artifact bound and live promotion disabled.

</frozen-after-approval>

## Implementation Plan

### Task 1: Prove the missing release-pair and consent-evidence contracts

**Files:**
- Modify: `tests/runtime.sql`

**Interfaces:**
- Consumes: `salesflow.complete_turn(text,text,uuid)`, active `config_docs`, immutable `intents.provenance`.
- Produces: failing behavior checks for active Release Set absence/mismatch and exact minimized consent evidence provenance.

- [x] Add sequential SQL assertions whose production break is accepting a cross-release business pair or omitting the selected consent-evidence reference.
- [x] Run the focused disposable PostgreSQL checks and confirm the new assertions fail for the expected missing behavior.

### Task 2: Bind context assembly to one active Release Set

**Files:**
- Modify: `database/001-initial.sql`
- Test: `tests/runtime.sql`

**Interfaces:**
- Consumes: active `release_set`, active Product Knowledge and Sales Policy rows, latest account/Contact consent event.
- Produces: `complete_turn` intent provenance containing `releaseSetVersion` and `consentEvidenceHash`; typed `missing_business_context` or `inconsistent_business_context` suppression.

- [x] Select and lock the active Release Set with its referenced active business documents in the existing transaction.
- [x] Persist only minimized release and consent-evidence references alongside existing context provenance.
- [x] Run focused checks and confirm all SP3-T1 and prior runtime assertions pass.

### Task 3: Prove publication races and immutable mid-conversation provenance

**Files:**
- Modify: `tests/runtime.sql`
- Modify: `tests/run.ps1`

**Interfaces:**
- Consumes: bounded activation locks, `activate_config`, `complete_turn`, intent evidence immutability.
- Produces: sequential and paused-transaction proof that context never uses a mixed release pair and that old sent intents remain unchanged.

- [x] Extend the version-update scenario to activate a matching Release Set and assert the recorded pair/release provenance.
- [x] Add a bounded mismatch/race check that proves no intent is created from a partially activated pair.
- [x] Run focused database checks and PowerShell syntax/static validation.

### Task 4: Update observed contracts and release evidence

**Files:**
- Modify: `docs/api-contracts.md`
- Modify: `docs/architecture.md`
- Modify: `docs/component-inventory.md`
- Modify: `docs/data-models.md`
- Modify: `_bmad-output/implementation-artifacts/test-evidence.md`
- Modify: `config/release-set.json`
- Modify: `release/release-manifest.json`

**Interfaces:**
- Consumes: verified runtime behavior and canonical release hashing.
- Produces: accurate observed documentation, a new reviewed release binding, and reproducible evidence while keeping promotion blocked.

- [x] Document active Release Set pair selection, typed mismatch handling, minimized consent evidence, and immutable historical provenance.
- [x] Advance and regenerate the release binding using the repository's canonical harness.
- [x] Run the complete regression harness and require `PASS FULL PASS`.

## Dev Agent Record

### Implementation Plan

- Preserve SP2-T3's transaction, account isolation, consent serialization, and bounded-history algorithm.
- Add only the Release Set consistency and consent-evidence provenance behavior needed by SP3-T1.
- Use red-green-refactor for each production behavior and retain synthetic-local boundaries.

### Debug Log

- 2026-08-24: Current-state audit found that SP2-T3 already satisfies account/Contact/Conversation isolation, latest consent gating, stored-sequence ordering, explicit history limits, message references, and immutable version-update provenance.
- 2026-08-24: Gap identified: independently active Product Knowledge and Sales Policy can form a transient cross-release pair; consent provenance does not explicitly identify the selected evidence value.
- 2026-08-24: Implemented deterministic Release Set/Product Knowledge/Sales Policy locking and pair validation, minimized consent-evidence hashing, typed mismatch suppression, sequential and paused-transaction acceptance checks, observed-contract updates, and release-v8 static binding.
- 2026-08-24: Independent review found and corrected a stale release-upgrade expectation and an overclaim that pairing provenance represented deployment-manifest publication. The second review reported no remaining actionable findings.
- 2026-08-24: PowerShell parsing, JSON parsing, Git whitespace checks, and byte-for-byte release/activation hash recomputation pass. Executable PostgreSQL and full n8n verification remain unavailable because this Windows environment has no Docker client/server or local PostgreSQL runtime.
- 2026-08-24 continuation: Live verification now shows WSL 2.7.12.0, WSL default version 2, and the Windows hypervisor are healthy. Docker Desktop remains uninstalled, so the canonical disposable PostgreSQL/n8n harness still cannot start.
- 2026-08-24 continuation: Docker Desktop 4.88.0 became available with Docker Engine 29.7.2. Both digest-pinned images were verified locally, disposable Compose state was cleaned, and the unchanged canonical harness completed with `PASS FULL PASS`, exit code 0, plaintext credential cleanup, and volume cleanup.

### Completion Notes

- Implemented one transactionally consistent context snapshot bound to the account's active Release Set, active Product Knowledge, active Sales Policy, latest granted consent, and bounded ordered Conversation references.
- Added minimized consent-evidence hashing and immutable Release Set/version/message provenance without retaining raw consent evidence or copied conversation content in the intent.
- Added sequential and real paused-transaction tests for missing or mixed releases, typed lock contention, version rotation during an ongoing Conversation, and preservation of previously sent content and provenance.
- Independent adversarial review completed with no remaining actionable findings after corrections.
- Canonical verification completed on 2026-08-24 with `PASS FULL PASS` and exit code 0; generated plaintext credentials and Docker volumes were removed.

## File List

- `_bmad-output/implementation-artifacts/spec-sp3-t1-complete-context-snapshot.md` (new)
- `_bmad-output/implementation-artifacts/index.md` (modified)
- `config/release-set.json` (modified)
- `database/001-initial.sql` (modified)
- `docs/api-contracts.md` (modified)
- `docs/architecture.md` (modified)
- `docs/component-inventory.md` (modified)
- `docs/data-models.md` (modified)
- `release/release-manifest.json` (modified)
- `tests/run.ps1` (modified)
- `tests/runtime.sql` (modified)

## Change Log

- 2026-08-24: Created the approved SP3-T1 implementation specification and marked work in progress.
- 2026-08-24: Added Release Set-bound context selection, minimized consent provenance, safe mismatch handling, acceptance/race coverage, observed documentation, and release-v8 static binding; runtime verification remains pending.
- 2026-08-24: Verified the complete disposable PostgreSQL/n8n regression harness with `PASS FULL PASS` and moved SP3-T1 to review.

## Status

review
