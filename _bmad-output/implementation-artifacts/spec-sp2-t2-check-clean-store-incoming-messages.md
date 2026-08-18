---
title: 'SP2-T2 Check, clean, and safely store every incoming message'
type: 'feature'
created: '2026-08-18'
status: 'done'
review_loop_iteration: 0
baseline_commit: '71fbc828dbbcad374e4b01cf39ea92d93dccd34f'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp2-t1-test-whatsapp-intake.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-stable-customer-conversation-identity.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Inbound persistence validates, deduplicates, and orders original text, but stores no clean processing form and the model boundary reads the original body. Generic conflicts are not durably flagged, and the four SP2-T2 cases lack unified proof on the AI-driving path.

**Approach:** Preserve original text, derive a narrowly normalized processing form, retain exact account-scoped retry/conflict rules, and allow only newly committed messages into sequence-ordered processing. Keep SP2-T1 staging-only.

## Boundaries & Constraints

**Always:** Authenticate runtime actor/account before mutation. Preserve and hash the original body. Derive `processing_body` using Unicode NFC, CRLF/CR-to-LF conversion, and outer trimming only; preserve internal whitespace, line breaks, case, punctuation, and meaning. A retry matches account-scoped provider ID, original sender, and original body exactly. PostgreSQL assigns immutable Conversation order; provider time remains evidence. Commit one message and Turn before orchestration; only `accepted=true, created=true` proceeds. Audit authenticated rejection/conflict without sender or text. Keep `livePromotionAllowed=false`.

**Ask First:** Connecting SP2-T1 to orchestration; changing limits, identity, ordering, cleanup, public webhooks, or privacy deletion; adding real Meta/LLM integration.

**Never:** Merge different provider IDs because text matches; compare retries using cleaned text; overwrite conflict evidence; create sequence, Turn, or downstream work for retry/conflict; audit rejected content; add infrastructure.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Normal | Valid authenticated text with outer whitespace, CRLF, or decomposed Unicode | Store original/processing forms, one sequence and Turn; process after commit | Empty-after-cleaning is invalid |
| Duplicate retry | Same provider ID, sender, and original body; repeated/concurrent | Idempotent success; one row, sequence, and Turn | No downstream work |
| Conflicting resend | Same provider ID; different sender/body | Preserve first row; flag minimized conflict | Reject; no new work |
| Out of order | Decreasing/equal provider timestamps | Consume in database sequence | Keep timestamps unchanged |
| Invalid | Wrong account, malformed/unsupported/oversized/empty text | No business mutation | Typed result; minimized authenticated audit |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- migration, cleanup, ingest, immutability, deletion, processing order.
- `workflows/01-whatsapp-ingress.json` -- post-commit created-only gate and staging-only route; verify unchanged.
- `tests/runtime.sql`, `tests/run.ps1` -- focused cases, concurrency, commit visibility, full regression.
- `docs/api-contracts.md`, `docs/data-models.md`, `docs/architecture.md` -- observed contract/model.
- `config/release-set.json`, `release/release-manifest.json` -- release-v6 binding; promotion disabled.
- `_bmad-output/implementation-artifacts/test-evidence.md` -- final verified evidence.

## Tasks & Acceptance

**Execution:**
- [x] `database/001-initial.sql` -- add/backfill `processing_body`; exact replay checks, minimized flags, deletion-safe immutability, and processing-form consumption without changing sequence/staging.
- [x] `tests/runtime.sql` -- prove the matrix and database-owned order.
- [x] `tests/run.ps1` -- add named normal, concurrent duplicate, sender/body conflict, reverse-time, commit-visibility, and no-extra-work proof.
- [x] `docs/api-contracts.md`, `docs/data-models.md`, `docs/architecture.md` -- document proven behavior.
- [x] `config/release-set.json`, `release/release-manifest.json` -- advance/bind release-v6; keep promotion disabled.
- [x] `_bmad-output/implementation-artifacts/test-evidence.md` -- record successful final evidence.

**Acceptance Criteria:**
- Given an accepted message, when orchestration is eligible, then both forms, sequence, and one Turn are committed.
- Given retry/conflict delivery, when ingestion completes, then first evidence is unchanged and no extra sequence, Turn, intent, Handoff, or AI work exists.
- Given reverse provider time, when Turns process, then source messages follow database sequence and retain timestamps.
- Given clean/legacy schemas, when migration runs twice and the full harness runs, then all checks pass with exact release-v6 binding and promotion disabled.

## Spec Change Log

## Design Notes

`body` remains immutable evidence and alone decides content equality. `processing_body` supports downstream context; it is not a sanitizer or trust signal. Database-controlled deletion may replace both with `[deleted]`.

## Verification

**Commands:**
- Focused PostgreSQL assertions -- expected: normal, duplicate, conflict, cleanup, deletion, and reverse-time pass after database changes.
- PowerShell/JSON parsers and hash inventory -- expected: no syntax, parse, or stale-hash failures.
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: `PASS FULL PASS`, including named SP2-T2 proof, repeated migration, concurrency, release identity, and cleanup.
- `git diff --check` and `git status --short` -- expected: no whitespace defects or generated secrets/volumes; only intentional SP2-T2 files changed.

## Suggested Review Order

**Inbound safety boundary**

- Start with strict typed validation, raw limits, exact replay decisions, and atomic persistence.
  [`001-initial.sql:135`](../../database/001-initial.sql#L135)

- Narrow cleanup preserves meaning while producing deterministic model input.
  [`001-initial.sql:34`](../../database/001-initial.sql#L34)

- Database constraint prevents evidence and processing text from diverging.
  [`001-initial.sql:57`](../../database/001-initial.sql#L57)

- Immutable evidence permits only controlled privacy deletion.
  [`001-initial.sql:73`](../../database/001-initial.sql#L73)

**Ordered processing and privacy**

- Model-driving classification consumes the committed processing form.
  [`001-initial.sql:182`](../../database/001-initial.sql#L182)

- Deletion minimizes both text forms without changing event identity or order.
  [`001-initial.sql:229`](../../database/001-initial.sql#L229)

**Acceptance and adversarial evidence**

- Runtime cases prove strict types, Unicode preservation, conflicts, and processing input.
  [`runtime.sql:10`](../../tests/runtime.sql#L10)

- Decreasing and equal provider times still process by database sequence.
  [`runtime.sql:16`](../../tests/runtime.sql#L16)

- Transaction race proves message and Turn remain invisible before commit.
  [`run.ps1:102`](../../tests/run.ps1#L102)

- Concurrent retries and sender/body conflicts produce no extra downstream work.
  [`run.ps1:103`](../../tests/run.ps1#L103)

**Contract and release evidence**

- Public contract defines original evidence, processing text, and exact retry equality.
  [`api-contracts.md:19`](../../docs/api-contracts.md#L19)

- Release-v6 binds reviewed inputs while explicitly prohibiting live promotion.
  [`release-manifest.json:28`](../../release/release-manifest.json#L28)

- Final evidence records the full post-review `PASS FULL PASS` run.
  [`test-evidence.md:9`](test-evidence.md#L9)
