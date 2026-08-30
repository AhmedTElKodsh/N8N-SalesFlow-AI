---
title: 'Persist stable Customer identity, Conversations, ownership, and ordered messages'
type: 'feature'
created: '2026-08-16'
status: 'complete'
review_loop_iteration: 1
baseline_commit: 'ef33eec0764deda625819bbda981cb4a3528ad57'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/planning-artifacts/architecture/architecture-N8N-SalesFlow-AI-2026-07-14/ARCHITECTURE-SPINE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `contacts` has a stable UUID but still embeds one `external_ref`, so a verified phone-number change creates a new Contact and disconnects the existing Conversation history. Message sequence allocation also lives inside `ingest_core` rather than at the table boundary, so direct database inserts are not guaranteed to receive canonical order.

**Approach:** Keep `contacts` as the canonical database Customer aggregate, move channel/provider references into separate UUID-backed Contact Identifier records, and provide an authorized atomic replacement command. Preserve the existing ingress contract while making PostgreSQL assign immutable, monotonically increasing sequence values to persisted inbound Conversation messages.

## Boundaries & Constraints

**Always:** Preserve composite account scoping, stable Contact and Conversation UUIDs, provider-message idempotency, lifecycle/ownership separation, and the `ai|human` storage vocabulary whose user-facing meanings are AI-Owned and Human-Owned. Keep legacy `contact_ref` ingress payloads compatible; resolve only active WhatsApp/Meta identifiers; retain retired identifiers as non-resolvable history; prevent one identifier from ever mapping ambiguously to different Contacts. Include identifiers in Contact deletion targeting and minimization. Keep `livePromotionAllowed=false`.

**Ask First:** Renaming the canonical Contact aggregate to Customer, allowing multiple lifetime Conversations per Contact, reassigning a retired identifier to another Contact, changing the public ingress payload, or introducing a unified inbound/outbound transcript ledger.

**Never:** Merge existing Contact records automatically; infer that two numbers belong to the same Customer without an authorized link/replace command; use provider timestamps for canonical order; weaken account foreign keys, uniqueness, ownership checks, deletion behavior, or runtime table-access restrictions; add UI, live Meta/CRM credentials, or AI-to-human routing behavior.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| First inbound identity | Unknown active WhatsApp/Meta reference | Create one Contact, one active identifier, and the existing Conversation; return their UUIDs | Reject malformed or conflicting input without partial rows |
| Verified number replacement | Existing Contact, active old reference, unused new reference | Atomically retire old reference, add new active identifier, and retain Contact/Conversation UUIDs and history | Reject wrong account, unknown Contact/old reference, or identifier owned by another Contact |
| Inbound through replacement | New active reference after replacement | Resolve the existing Contact and Conversation and append one message | Retired reference is non-resolvable and cannot expose prior history |
| Canonical ordering | Messages arrive with reversed/equal provider timestamps or a caller-supplied sequence | Database allocates the next positive sequence under Conversation serialization; reads by sequence reflect durable intake order | Duplicate provider ID creates no row and consumes no sequence |
| Ownership | Conversation starts `ai`, then an allowed transition stores `human` | Non-null constrained state remains independent of lifecycle | Any other value is rejected by PostgreSQL |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- canonical schema, idempotent backfill, identifier resolution/replacement, sequencing triggers, deletion, grants, and constraints.
- `tests/runtime.sql` -- database assertions for identity replacement, ownership, ordering, invalid states, and deletion minimization.
- `tests/run.ps1` -- clean/twice-applied migration harness, concurrent ordering checks, legacy lookup updates, and Release Set fixture progression.
- `docs/data-models.md` -- observed Contact Identifier model and critical constraints.
- `docs/architecture.md` -- observed table-count and data-architecture summary.
- `release/release-manifest.json` and `config/release-set.json` -- immutable release-v5 input hashes while live promotion remains disabled.

## Tasks & Acceptance

**Execution:**
- [x] `database/001-initial.sql` -- add `contact_identifiers` with internal UUID, account-scoped Contact FK, channel/provider/reference identity, active/retired state, all-history uniqueness, and idempotent legacy backfill/drop of `contacts.external_ref`; refactor `ingest_core` to resolve active identifiers and preserve its JSON contract.
- [x] `database/001-initial.sql` -- add an authorized atomic identifier-replacement command; move inbound sequence/version allocation into an insert trigger, reject sequence/key mutation, and extend deletion targets/minimization and least-privilege grants.
- [x] `tests/runtime.sql` and `tests/run.ps1` -- prove the matrix, retain duplicate/concurrent race coverage, replace direct `contacts.external_ref` lookups, and keep fresh plus repeated migration checks.
- [x] `docs/data-models.md` and `docs/architecture.md` -- document the 20-table model, Customer/Contact terminology, active versus retired identifiers, ownership labels, and database-owned ordering.
- [x] `release/release-manifest.json` and `config/release-set.json` -- advance the synthetic-local Release Set from v4 to v5 and refresh only canonical changed-input hashes/digests.

**Acceptance Criteria:**
- Given a clean database or the current legacy schema, when the canonical migration is applied twice, then it succeeds without errors and exposes the same constrained final schema.
- Given phone A created a Contact and Conversation, when an authorized replacement links phone B and retires phone A, then phone B resolves the same UUIDs and ordered history while phone A cannot expose that history.
- Given messages with provider timestamps opposite durable intake order, when history is read by database sequence, then every message has a unique positive sequence and appears in durable intake order.
- Given a duplicate provider message or a caller-supplied sequence, when insertion is attempted, then replay consumes no sequence and new messages receive the database-selected next sequence.
- Given an AI-Owned Conversation, when ownership becomes Human-Owned, then storage changes from `ai` to `human`, lifecycle remains unchanged, and any unsupported owner is rejected.
- Given Contact deletion, when minimization completes, then Contact Identifiers are tracked and minimized without weakening retained event identity or account isolation.
- Given the canonical full harness, when all database, workflow, release-identity, security, and cleanup checks run, then they pass and no credentials/customer fixtures are committed.

## Spec Change Log

- 2026-08-16 implementation: Retained a SHA-256 identity fingerprint when deletion minimizes plaintext references so all-history uniqueness and retired-reference rejection remain enforceable after deletion.

## Design Notes

`contacts` remains the internal Customer record to preserve AR-11 and downstream FKs. `inbound_messages` remains the persisted message/evidence table for this slice; outbound `intents` retain their existing outbox semantics. Identifier replacement must be explicit because a changed phone number alone provides no trustworthy proof that two channel identities belong to the same person.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: migration applies twice and the complete synthetic-local suite, race checks, release checks, and cleanup checks pass.
- `git diff --check` -- expected: no whitespace errors.
- `git status --short` -- expected: only intentional implementation, test, documentation, release, and spec artifacts are modified.
