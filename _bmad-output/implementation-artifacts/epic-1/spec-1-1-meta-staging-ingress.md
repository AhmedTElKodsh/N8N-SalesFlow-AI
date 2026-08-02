---
title: 'Add Meta-compatible staging ingress foundation'
type: 'feature'
created: '2026-07-30'
updated: '2026-08-01'
status: 'blocked'
review_loop_iteration: 1
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Workflow 01 accepts only the synthetic `x-salesflow-token` contract. A Meta test asset cannot yet verify its callback, authenticate signed POST deliveries over the original bytes, or persist supported WhatsApp inbound messages under Story 1.1's rejection-audit and response requirements.

**Approach:** Preserve the synthetic route and add separate Meta-compatible GET and POST paths. The POST path captures the raw body, enforces the text-only pilot size boundary, computes the HMAC using an encrypted n8n credential, performs strict header parsing and constant-time digest comparison, validates the whole envelope, records a PII-minimized accepted or rejected result in PostgreSQL, and stops without downstream sales automation.

**Proof label:** Generated local credentials prove the protocol and credential-handling contract only. A real Meta test-asset smoke remains an external, approval-gated activity and is not part of local acceptance.

## Boundaries & Constraints

**Always:** Work only in the `main` direct-implementation worktree; leave `codex/guided-learning` unchanged. Return the Meta challenge only for exact `hub.mode=subscribe` and constant-time verify-token match. For POST, require exactly one `X-Hub-Signature-256` header whose value matches `sha256=<64 hex>`. Compute the expected SHA-256 HMAC over the original request bytes using a secret-backed Crypto credential, decode both digests to fixed 32-byte values, and compare them with Node's standard-library `crypto.timingSafeEqual`. Validate the complete envelope and every entry/change identity before accepted-message persistence. PostgreSQL retains final deduplication and Conversation ordering. Keep secrets in ignored input or n8n credentials and keep `livePromotionAllowed=false`.

**Request limit:** The text-only pilot accepts at most 262,144 raw bytes (256 KiB). Reject a declared larger body before business parsing and verify the measured raw byte length before JSON parsing. Configure n8n's outer payload ceiling no higher than required by the deployment. `ponytail:` this conservative text-only ceiling may increase only after captured Meta test-asset evidence and a security review show a larger valid envelope is required.

**Rejection audit:** Invalid signature, wrong identity, malformed schema/JSON, oversized input, and unsupported event type create exactly one PII-minimized rejection Audit Event through a dedicated parameterized PostgreSQL command. Store only configured account reference, reason code, correlation ID, and timestamp; do not store the raw envelope, signature, phone number, message body, Contact, Conversation, or Inbound Message. Duplicate delivery may reuse the existing accepted/rejected result.

**Response contract:** Produce exactly one HTTP response per envelope. Return `200` for accepted, duplicate, or valid-signed unsupported deliveries after durable evidence is committed; `400` for malformed or oversized input after rejection evidence commits; `403` for signature or configured-identity failure after rejection evidence commits; `409` for a conflicting replay after reconciliation evidence commits; and `5xx` when the required accepted/rejection database write fails so the provider can retry. Never return `200` for a database failure.

**Ask First:** Use real Meta/customer credentials, change a Meta app or webhook subscription, expose a public HTTPS endpoint, enable downstream automation for Meta events, change commercial/consent/Human-Owned policy, or enable live promotion.

**Never:** Modify the guided-learning branch, hard-code credentials, persist a rejected raw envelope, partially accept a mixed-identity envelope, replace PostgreSQL idempotency with workflow checks, add a service or dependency, invoke the orchestrator/LLM/outbound/Follow-Up/Handoff path from Meta staging, or claim production readiness from local/generated-secret evidence.

## Node Decision

Use the generic Webhook node with raw-body capture, not the native WhatsApp Trigger, because rejected deliveries must reach the workflow's explicit rejection-audit and response contract. Use the existing Crypto node with an encrypted credential to compute the HMAC. Add one minimal Code node solely to parse the signature into a fixed 32-byte digest and call `crypto.timingSafeEqual`; allow only the Node standard-library `crypto` module. This exception must be added to the release node inventory, task-runner/node hardening review, and `n8n audit` evidence. No HTTP, command, file, community, custom, or new dependency is introduced.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Durable result | HTTP result |
| --- | --- | --- | --- |
| Verify callback | Exact subscribe mode, token, and challenge | None | `200`, exact challenge |
| Verify mismatch | Missing/mismatched mode or token | None; no token disclosure | `403` |
| Valid inbound | Correct raw-body HMAC, configured identities, supported text messages | Each unique provider ID persisted once with canonical order; one acceptance audit | `200` |
| Duplicate/concurrent retry | Same provider message ID and content | Existing logical record/result reused | `200` |
| Conflicting replay | Same provider ID with different content | No mutation of accepted message; PII-minimized rejection/reconciliation evidence | `409` |
| Missing/duplicate/malformed signature | Zero, multiple, or non-`sha256=<64 hex>` values | One PII-minimized rejection; no business record | `403` |
| Signature mismatch | Valid grammar, wrong digest | One PII-minimized rejection; no business record | `403` |
| Wrong or mixed identity | Wrong object/account/phone ID anywhere in envelope | Whole envelope rejected; no partial accepted-message persistence | `403` |
| Malformed payload | Invalid JSON/schema or missing required identifiers | One PII-minimized rejection; no business record | `400` |
| Oversized payload | Declared or measured raw body above 256 KiB | One PII-minimized rejection when the workflow can safely record it | `400` |
| Unsupported event | Valid signed and identity-bound non-message/non-text event | One PII-minimized rejection/ignored audit; no business record | `200` |
| Database failure | Accepted or rejection evidence cannot commit | No downstream action and no false success | `5xx` |

</frozen-after-approval>

## Code Map

- `workflows/01-whatsapp-ingress.json` — preserve the synthetic path; add isolated Meta GET/POST paths and one terminal response path per request.
- `database/001-initial.sql` — reuse `salesflow.ingest`; add the smallest dedicated runtime-authorized rejection-audit command rather than granting direct table writes.
- `.env.example` and `compose.yaml` — add blank Meta identity/verify inputs and the minimum Code-node standard-library allowance; no source secret.
- `tests/run.ps1` — extend the canonical disposable-credential/live-endpoint harness; do not create a second test runner.
- `release/release-manifest.json` and `config/release-set.json` — update hashes and exact node inventory while retaining `livePromotionAllowed=false`.
- `docs/deployment-guide.md` — document local protocol proof separately from the approval-gated Meta test-asset smoke and remaining external gates.

## Tasks & Acceptance

**Execution (only after explicit approval):**

- [ ] Add the dedicated PII-minimized rejection-audit database command and grant only its execution to the runtime role.
- [ ] Add Meta GET verification and raw-body POST validation/normalization paths to Workflow 01; keep the synthetic route unchanged and terminate Meta processing after ingest/audit.
- [ ] Add generated local Meta/HMAC inputs and the minimum `crypto` Code-node allowance without committing secrets.
- [ ] Extend `tests/run.ps1` with the matrix below while retaining S01–S26 and all existing race/identity/secret checks.
- [ ] Regenerate reviewed workflow/config hashes and node inventory with `livePromotionAllowed=false`.
- [ ] Update deployment documentation with proof labels and unresolved external gates.

**Local acceptance:**

- Given generated test credentials, the canonical harness passes existing S01–S26 plus GET verification, valid signed acceptance, batch/replay/concurrency, strict signature grammar, duplicate header, mismatch, wrong/mixed identity, malformed JSON/schema, exact/over-limit size, unsupported event, and database-failure cases.
- Each rejection case asserts no Contact, Conversation, Inbound Message, outbound intent, Handoff, Follow-Up, or raw envelope was created; exactly one PII-minimized Audit Event is queryable when its database write succeeds.
- Each envelope produces one HTTP response with the specified status. Database failure produces `5xx`, never `200`.
- An accepted Meta text event is persisted once with provider ID, configured account, Contact/Conversation references, body, provider timestamp, and monotonic sequence, with no downstream automation.
- Workflow export identity, approved node inventory, secret scans, cleanup, and `git diff --check` pass; no production credential/customer data is committed or exported.

**External acceptance (separate approval required):**

- With approved Meta test assets and public HTTPS, prove subscription verification, signed delivery, configured WABA/phone identity, supported Graph API version and retirement date, duplicate/out-of-order behavior, permissions, and test/production isolation.
- Record environment, owner, timestamp, redacted evidence, and result. This evidence is required before the roadmap may describe the slice as credentialed Meta staging.

## Spec Change Log

- 2026-08-01: Corrected Story 1.1 rejection persistence, strict signature/constant-time behavior, all-or-nothing identity validation, bounded payloads, single-response/5xx semantics, Code-node exception, harness matrix, and local-versus-credentialed proof labels.

## Verification

After implementation:

- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`
- `git diff --check`
- `git status --short`

Expected: full local suite passes; only reviewed production-delivery artifacts are changed; no generated plaintext remains; `livePromotionAllowed=false`.

## Auto Run Result

**Status:** Blocked before implementation on 2026-08-02.

**User authorization:** Story 1.1 implementation was explicitly approved from the production delivery proposal.

**Blocking condition:** The current `main` worktree is dirty after consolidation of the former production-delivery worktree. It contains the organized approved planning package, duplicate untracked pre-organization Story 1.1 context/spec files, a modified `deferred-work.md`, and the completed consolidation spec. `bmad-dev-auto` requires a clean, unambiguous branch before implementation.

**Runtime impact:** None. No workflow, database, configuration, release, test, Compose, or environment file was changed by this run.

**Required resolution:** Reconcile the duplicate drafts, review the intended documentation set, and commit or otherwise preserve it on the implementation branch; then resume this spec from `blocked` only after the worktree is clean.
