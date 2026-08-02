---
title: 'Add Meta-compatible staging ingress foundation'
type: 'feature'
created: '2026-07-30'
updated: '2026-08-02'
status: 'done'
baseline_commit: 'e648be25b67bc7013bd261df246951ed6cb6f2f6'
review_loop_iteration: 2
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Workflow 01 accepts only the synthetic token contract. It cannot safely verify a Meta callback or signed raw-body delivery, and its current ingest path can trigger sales automation that is forbidden for this staging slice.

**Approach:** Preserve the synthetic route and add isolated Meta GET/POST paths. Validate the entire signed envelope before one atomic PostgreSQL call, persist accepted text messages or one minimized rejection record, return one explicit response, and stop without orchestration.

## Boundaries & Constraints

**Always:** Require exact subscribe/token verification for GET. For POST, enforce one `X-Hub-Signature-256: sha256=<64 hex>` value, HMAC-SHA256 over original bytes, fixed-length constant-time comparison, declared and measured raw size at most 262,144 bytes, and whole-envelope object/WABA/phone/schema validation before persistence. PostgreSQL owns batch atomicity, deduplication, sequencing, and audit after the request reaches Workflow 01. Pinned n8n `2.30.4` rejects syntactically invalid `application/json` with `422` before workflow execution, so that platform rejection has no workflow audit; schema-invalid JSON still receives `400` and a minimized audit. Workflow rejections store only account, allowlisted reason, timestamp, and `sha256("salesflow:meta-rejection:v1:" + reason + ":" + expectedHmacHex)` as an opaque deterministic correlation value; never store the raw-body hash, supplied signature, or expected HMAC. Generated credentials prove local protocol behavior only. Keep `livePromotionAllowed=false`.

**Ask First:** Real Meta/customer credentials, public HTTPS or subscription changes, downstream Meta automation, policy changes, or live promotion.

**Never:** Modify guided learning; store rejected raw bodies, signatures, phone numbers, or message text; partially persist mixed/failed batches; hard-code secrets; add a service/dependency; invoke the orchestrator, LLM, outbound, Follow-Up, or Handoff path from Meta staging.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
| --- | --- | --- | --- |
| GET verification | Exact mode/token/challenge | Exact challenge | Mismatch `403` |
| Accepted POST | Valid signature/identity and text messages | Atomic ordered persistence, no downstream work | New/duplicate `200`; conflict `409` |
| Authentication | Missing, duplicate, malformed, or mismatched signature | One minimized rejection, no business mutation | `403` |
| Envelope validation | Wrong/mixed identity, syntactically invalid JSON, schema-invalid JSON, or >256 KiB | Whole envelope rejected | `403` identity; pinned n8n `422` for invalid JSON; otherwise `400` |
| Unsupported event | Valid signed and identity-bound non-text event | Minimized ignored/rejection audit only | `200` |
| Database failure | Required ingest/audit write fails | No false success or downstream action | `5xx` for provider retry |

</frozen-after-approval>

## Code Map

- `workflows/01-whatsapp-ingress.json` — retain synthetic topology; add raw Meta GET/POST, a raw-byte bridge, Crypto, validation Code, database, and explicit response paths.
- `database/001-initial.sql` — add atomic Meta-envelope ingest and idempotent minimized rejection commands; keep synthetic `ingest(text,jsonb)` behavior.
- `.env.example`, `compose.yaml` — pass blank Meta identity/runtime inputs and allow only Node stdlib `crypto`; App Secret remains an encrypted n8n credential.
- `tests/run.ps1` — extend the existing disposable live-endpoint harness with the complete matrix and regression assertions.
- `release/release-manifest.json`, `config/release-set.json` — refresh hashes/node inventory while preserving the promotion prohibition.
- `docs/deployment-guide.md` — separate local protocol proof from approval-gated Meta test-asset proof.

## Tasks & Acceptance

**Execution:**

- [x] Implement `record_ingress_rejection(text,text,text)` and atomic staging-ingest commands, including batch rollback and no signal/Handoff side effects.
- [x] Add isolated Meta GET/POST workflow paths using raw body, encrypted HMAC credential, strict/timing-safe validation, and one response per envelope.
- [x] Add generated local inputs and the minimum `crypto` Code-node allowance without source secrets.
- [x] Extend `tests/run.ps1`; retain S01–S26, concurrency, identity, export, and secret checks.
- [x] Refresh release evidence and deployment guidance.

**Acceptance Criteria:**

- Given generated credentials, when the canonical harness runs, then GET verification plus valid, batch, duplicate/concurrent, conflicting replay, signature grammar/mismatch, wrong/mixed identity, malformed, declared/measured exact and over-limit, unsupported, and database-failure cases return the specified statuses.
- Given a workflow rejection or batch failure, when PostgreSQL is inspected, then no Contact, Conversation, inbound message, intent, Handoff, or Follow-Up is partially created and exactly one allowlisted minimized audit exists when its write succeeds; n8n's pre-workflow invalid-JSON rejection creates no workflow audit.
- Given accepted Meta text containing configured human/opt-out signals, when it commits, then messages receive canonical sequence values but create no downstream/suppression/Handoff work.
- Given final artifacts, when the full harness and identity/security checks pass, then no secret/customer data is committed and `livePromotionAllowed` remains false.

## Spec Change Log

- 2026-08-01: Added rejection persistence, strict signature comparison, envelope identity, bounded payload, explicit response/database-failure behavior, and proof labels.
- 2026-08-02: Investigation found existing ingest signal side effects and partial-batch risk; added an atomic staging-only database boundary and retained the synthetic API unchanged.
- 2026-08-02: Party review made staging mode server-authoritative, restored declared-size enforcement, required database-side whole-array validation, and defined a non-PII rejection correlation value.
- 2026-08-02: Human approved the pinned-platform exception: syntactically invalid JSON returns n8n `422` before Workflow 01 and therefore has no workflow audit; valid JSON with invalid schema retains `400` and minimized auditing.

## Design Notes

Use Webhook raw-body capture plus a minimal Code bridge that materializes the pinned task runner's buffer for Crypto v2 with an encrypted credential. The validation Code node performs strict header parsing, byte-size/identity/schema normalization, `crypto.timingSafeEqual`, and the domain-separated correlation digest; neither Code node has network or secret-store access. Refactor existing persistence into an ungranted `ingest_core(text,jsonb,boolean)` helper: public `ingest(text,jsonb)` always passes `false`, while `ingest_meta(text,jsonb)` validates the complete normalized message array before any write and always passes `true`. Request data cannot select the mode. The Meta wrapper raises inside a PostgreSQL subtransaction on any message conflict so all earlier writes roll back, returns the typed conflict only after rollback, and lets unexpected database errors propagate to an explicit `5xx` response. Retain existing runtime grants, add only `ingest_meta(text,jsonb)` and allowlist-validating `record_ingress_rejection(text,text,text)`, and never grant `ingest_core`; synthetic behavior remains unchanged.

## Verification

- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` — existing S01–S26 plus Story 1.1 matrix pass.
- `git diff --check` — no whitespace errors.
- `git status --short` — only reviewed Story 1.1 artifacts; no generated plaintext.
- 2026-08-02 canonical isolated run — `FULL PASS`; generated credentials, containers, and checkout-scoped volumes removed.
- 2026-08-02 post-review canonical isolated run — `FULL PASS`; verified terminal staging turns, UTF-8 text and clock-skew boundaries, empty identity/field rejection, measured chunked limit enforcement, exact minimized audits, and the `release-v1` to active `release-v2` upgrade; generated credentials, containers, and checkout-scoped volumes removed.

## Review Resolution

- Adversarial and edge-case review findings were resolved in the shared validation/database boundaries and covered by the canonical harness.
- No specification defect, intent gap, deferred finding, or accepted security exception remains beyond the human-approved pinned-n8n `422` behavior documented above.

## Suggested Review Order

**Ingress trust boundary**

- Start with strict raw-byte authentication, identity, schema, size, and timestamp validation.
  [`01-whatsapp-ingress.json:101`](../../../workflows/01-whatsapp-ingress.json#L101)

- Raw-body delivery preserves the exact bytes required for Meta HMAC verification.
  [`01-whatsapp-ingress.json:64`](../../../workflows/01-whatsapp-ingress.json#L64)

- The minimal bridge exposes the pinned runner buffer without adding a service.
  [`01-whatsapp-ingress.json:81`](../../../workflows/01-whatsapp-ingress.json#L81)

**Atomic staging persistence**

- Server-owned staging mode makes accepted turns terminal and suppresses downstream automation.
  [`001-initial.sql:63`](../../../database/001-initial.sql#L63)

- Whole-envelope validation and transaction rollback prevent partial mixed-batch persistence.
  [`001-initial.sql:82`](../../../database/001-initial.sql#L82)

- Allowlisted, idempotent rejection audits retain only opaque correlation metadata.
  [`001-initial.sql:79`](../../../database/001-initial.sql#L79)

**Runtime proof**

- Live endpoint checks begin with exact GET verification and staging isolation.
  [`run.ps1:122`](../../../tests/run.ps1#L122)

- UTF-8, clock-skew, declared, and measured size boundaries exercise trust-edge failures.
  [`run.ps1:135`](../../../tests/run.ps1#L135)

- Exact rejection counts and minimized shapes prevent false-positive audit coverage.
  [`run.ps1:140`](../../../tests/run.ps1#L140)

- A prepublished v1 fixture proves the release-v2 upgrade path.
  [`run.ps1:67`](../../../tests/run.ps1#L67)

**Release and deployment boundary**

- Immutable release-v2 evidence remains explicitly prohibited from live promotion.
  [`release-manifest.json:28`](../../../release/release-manifest.json#L28)

- Runtime enables only Node crypto and blank, environment-supplied Meta identity values.
  [`compose.yaml:35`](../../../compose.yaml#L35)

- Source configuration declares blank Meta inputs rather than credentials.
  [`.env.example:12`](../../../.env.example#L12)

- Deployment guidance separates local protocol proof from approval-gated Meta evidence.
  [`deployment-guide.md:24`](../../../docs/deployment-guide.md#L24)
