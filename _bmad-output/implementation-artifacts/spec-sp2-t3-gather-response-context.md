---
title: 'SP2-T3 Gather the right information before the AI responds'
type: 'feature'
created: '2026-08-18'
status: 'done'
review_loop_iteration: 0
baseline_commit: '781b09f'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp1-t2-versioned-business-information.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp2-t2-check-clean-store-incoming-messages.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `complete_turn` reads Product Knowledge and Sales Policy separately, does not check consent before drafting, and records no bounded history evidence. A response therefore cannot prove the complete, isolated context that produced it.

**Approach:** Assemble one account-, Contact-, Conversation-, and Turn-scoped context snapshot inside the existing PostgreSQL transaction. Gather the latest consent, both currently active immutable business documents, and a deterministic recent inbound-history slice; persist minimized references with the resulting intent so later business updates cannot rewrite historical provenance.

## Boundaries & Constraints

**Always:** Authenticate and lock the account-scoped Conversation before reading context. Serialize consent reads/writes for the same account and Contact. Require the latest consent event to be `granted` before AI drafting while retaining the existing fresh pre-send authorization check. Select the one active Sales Policy and Product Knowledge rows together in one locked SQL snapshot. Use only messages from the same account and Conversation with `seq` no greater than the current inbound message; select the newest ten within a 32 KiB UTF-8 budget, always include the current message, and present the selected slice in ascending database sequence. Persist consent timestamp/status, both business versions, ordered message IDs/sequences, history limits, current source ID, and Conversation version without copying raw history into immutable audit. Keep privacy deletion/minimization and `livePromotionAllowed=false`.

**Ask First:** Adding a cross-kind atomic publication or compatibility contract, making Release Set publication mandatory for ordinary business updates, adding stable consent-event UUIDs, building a two-sided transcript ledger, changing history limits, introducing Product Knowledge safety revocation, or connecting a real model/provider.

**Never:** Use provider timestamps for history order; read across accounts, Contacts, or Conversations; continue with missing/revoked consent or missing business context; fall back to inactive versions; copy raw conversation history into append-only audit; add vector search, infrastructure, or an administration UI.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Eligible turn | Granted consent, both active documents, ordered inbound history | Create one intent with exact context references | Existing dispatch authorization still rechecks consent and state |
| No consent | Missing or latest event revoked | No draft or intent | Suppress with typed minimized reason |
| Missing context | Either active business document absent | No partial context or intent | Fail closed with typed reason |
| Long history | More than ten messages or 32 KiB | Include current plus newest fitting predecessors, ordered by `seq` | Never include another Conversation |
| Mid-conversation update | Turn A sent under v1; active documents change before Turn B | Turn B records current versions; Turn A remains unchanged | Privacy deletion remains the only permitted minimization exception |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- consent serialization, context assembly, intent provenance, deletion behavior, and runtime grants.
- `tests/runtime.sql` -- focused consent, isolation, ordering/cap, provenance, and version-update assertions.
- `tests/run.ps1` -- fixture consent setup, concurrency proof, migration/regression harness, and release checks.
- `docs/api-contracts.md`, `docs/data-models.md`, `docs/architecture.md`, `docs/component-inventory.md` -- observed context and provenance contract.
- `config/release-set.json`, `release/release-manifest.json` -- release-v7 binding for changed deployable runtime/test inputs.
- `_bmad-output/implementation-artifacts/test-evidence.md` -- final focused and full-suite evidence.

## Tasks & Acceptance

**Execution:**
- [x] `database/001-initial.sql` -- assemble one ephemeral consent/business/history snapshot before drafting; persist references only; serialize consent and business activation races; guard intent evidence; preserve deletion minimization.
- [x] `tests/runtime.sql` -- prove missing/revoked consent denial, same-scope history, ascending sequence, count/byte gaps, oversized-current denial, intent immutability, and immutable v1/v2 provenance.
- [x] `tests/run.ps1` -- update eligible fixtures, add bounded consent/activation/busy concurrency checks with cleanup, and retain all prior SP2 regression proof.
- [x] `docs/*.md` -- document the proven inbound-history boundary, typed failures, consent distinction, and reconstructable minimized provenance.
- [x] `config/release-set.json`, `release/release-manifest.json`, `test-evidence.md` -- advance to release-v7, bind changed deployable runtime/test inputs, keep promotion blocked, and record verified results.

**Acceptance Criteria:**
- Given an eligible committed inbound Turn, when context is assembled, then one intent atomically records the latest granted consent, both active versions, and only bounded ordered references from that Conversation.
- Given revoked/missing consent, missing business context, or a wrong account/Conversation reference, when processing runs, then no AI intent exists and the result fails closed without exposing history.
- Given active business documents change between two turns, when the second response is created, then it uses the new active versions while the first sent response retains its original body and provenance except authorized privacy minimization.
- Given focused checks and the canonical harness run, when verification completes, then all SP1/SP2 and whole-application tests pass with release-v7 bound and live promotion disabled.

## Spec Change Log

- 2026-08-18 implementation: `complete_turn` now serializes granted-consent evidence, locks both independently active business documents in one read, and records an inbound-only context reference set bounded to ten messages and 32 KiB. Focused PostgreSQL checks and the canonical harness passed; release-v7 remains promotion-blocked.
- 2026-08-18 adversarial hardening: response assembly now shares deterministic bounded activation locks, builds and uses an ephemeral processing-text payload, safely restores busy Turns, skips byte-gap predecessors, rejects oversized current input, enforces strictly monotonic consent evidence, and prevents ordinary intent-evidence mutation or deletion.
- 2026-08-18 verification: disposable PostgreSQL migration/behavior checks passed, followed by the canonical whole-application harness with `PASS FULL PASS`; release-v7 hashes bind the final deployable runtime/test inputs and live promotion remains disabled.

## Design Notes

The MVP history slice is inbound-only because PostgreSQL currently owns a canonical sequence only for inbound messages. “Relevant” therefore means deterministic recency within explicit count and byte limits; semantic/vector retrieval and a unified outbound transcript require separate approval. Product Knowledge and Sales Policy remain independently publishable under SP1-T2; SP2-T3 prevents time-of-read mixing by acquiring their activation locks before selecting the active rows without redefining publication authority.

## Verification

**Commands:**
- Focused PostgreSQL migration/runtime assertions after each database and test change -- expected: the new SP2-T3 cases pass without running external adapters.
- PowerShell/JSON parsing and canonical hash checks after release changes -- expected: valid scripts/documents and exact release-v7 binding.
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: `PASS FULL PASS`, including migration idempotence, SP1/SP2 regression, n8n paths, release identity, and cleanup.
- `git diff --check` and `git status --short` -- expected: no whitespace defects or generated secrets/volumes; only intentional SP2-T3 changes.

## Suggested Review Order

**Response-context boundary**

- Start with the transactional entry point: consent, business locks, bounded history, and safe recovery.
  [`001-initial.sql:171`](../../database/001-initial.sql#L171)

- Consent writes share the context lock and produce strictly monotonic evidence order.
  [`001-initial.sql:131`](../../database/001-initial.sql#L131)

- Intent evidence is immutable while operational state and controlled deletion remain possible.
  [`001-initial.sql:74`](../../database/001-initial.sql#L74)

**Acceptance evidence**

- Sequential assertions cover isolation, missing context, byte boundaries, immutability, and version provenance.
  [`runtime.sql:76`](../../tests/runtime.sql#L76)

- Paused transactions prove consent and activation serialization plus bounded busy recovery.
  [`run.ps1:103`](../../tests/run.ps1#L103)

**Contracts and release**

- The API contract distinguishes pre-draft context checks from fresh pre-send authorization.
  [`api-contracts.md:29`](../../docs/api-contracts.md#L29)

- Release-v7 binds changed deployable inputs while live promotion remains disabled.
  [`release-manifest.json:28`](../../release/release-manifest.json#L28)

- Final evidence records focused checks, adversarial hardening, full pass, and cleanup.
  [`test-evidence.md:9`](test-evidence.md#L9)

**Whole-application follow-up**

- Pre-existing findings remain explicit without expanding SP2-T3's implementation boundary.
  [`deferred-work.md:13`](deferred-work.md#L13)
