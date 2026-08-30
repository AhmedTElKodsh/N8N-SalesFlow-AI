---
title: 'SP2-T1 Build a test version of the WhatsApp message intake'
type: 'feature'
created: '2026-08-16'
status: 'done'
review_loop_iteration: 0
baseline_commit: '1b7c4c82ee85211a880c1de3dba447331602875d'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1/spec-1-1-meta-staging-ingress.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The repository has a robust synthetic staging ingress, but `/salesflow/meta` and `META_*` make it look like a live integration. Its evidence also lacks the requested one-second acknowledgement and one named five-case HTTP test.

**Approach:** Rebrand the signed terminal staging path as a loopback-only test WhatsApp intake. Retain the WhatsApp-shaped fixture, generated credentials, validation, atomic persistence, deduplication, arrival ordering, and no-downstream-work boundary; add timing and five-case proof.

## Boundaries & Constraints

**Always:** Expose only `POST /webhook/salesflow/test/whatsapp-intake` and generated `TEST_WHATSAPP_*` values. Preserve raw-byte HMAC, 262,144-byte envelope and 8,192-byte UTF-8 text limits, whole-envelope rejection, minimized audits, and `ingest_meta` staging. Store a valid new text before `200`; never invoke orchestration, LLM, outbound, Follow-Up, or Handoff. Identical provider-ID replay is success; conflicting reuse is `409`. Database sequence is arrival order; timestamps are evidence. Keep loopback binding and `livePromotionAllowed: false`.

**Ask First:** Real Meta, customer, or production credentials; public HTTPS, webhook subscription, a real WhatsApp number; any route from this intake to customer-facing automation; changing payload limits or allowing production promotion.

**Never:** Add a service, dependency, dashboard, real API call, customer fixture, hard-coded secret, or second ingress. Do not persist rejected raw bodies, signatures, phone references, or text, or weaken atomicity, HMAC, database authorization, release identity, or generic ingress.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Normal test text | Generated signature and configured test identity | `200` under one second; one terminal staged inbound record | No downstream work |
| Broken test message | Invalid JSON or schema-invalid JSON | Pinned n8n `422`; otherwise `400` with minimized audit | No mutation; next valid request succeeds |
| Oversized test message | Envelope over 262,144 bytes or text over 8,192 UTF-8 bytes | `400` and no persisted inbound record | Minimized rejection evidence where workflow executes |
| Duplicate | Same provider ID and identical sender/body | `200` idempotent acknowledgement; one inbound record and one sequence | Conflicting reuse returns `409` |
| Out of order | Two valid deliveries with decreasing timestamps | Both `200`; sequence follows delivery order and timestamps remain | No reorder or duplicate work |

</frozen-after-approval>

## Code Map

- `workflows/01-whatsapp-ingress.json` -- test-only route, configuration labels, signed validation, staging, and response.
- `compose.yaml`, `.env.example` -- loopback topology and blank generated `TEST_WHATSAPP_*` inputs.
- `tests/run.ps1`, `tests/runtime.sql` -- timing, five-case HTTP proof, and durable sequence evidence.
- `docs/api-contracts.md`, `docs/deployment-guide.md` -- local-only fixture contract and proof boundary.
- `config/release-set.json`, `release/release-manifest.json` -- refreshed canonical hashes with promotion disabled.

## Tasks & Acceptance

**Execution:**
- [x] `workflows/01-whatsapp-ingress.json`, `compose.yaml`, `.env.example` -- rename the staging endpoint/configuration to a synthetic test contract without changing safety behavior.
- [x] `tests/run.ps1` -- run the named five fixtures, time normal acknowledgement, and query rejection, duplicate, and arrival-order evidence.
- [x] `docs/api-contracts.md`, `docs/deployment-guide.md`, `config/release-set.json`, `release/release-manifest.json` -- document the boundary and refresh only required hashes.

### Review Findings

- [x] [Review][Patch] Replace count-only malformed-request comparison with a content fingerprint including Contact Identifiers [tests/run.ps1:174]
- [x] [Review][Patch] Scope SP2 provider-ID evidence queries explicitly to `test-account` [tests/run.ps1:166]
- [x] [Review][Patch] Compare complete business state before and after oversized-envelope rejection [tests/run.ps1:180]
- [x] [Review][Patch] Require the recovery message to own one terminal completed staging Turn [tests/run.ps1:180]

**Acceptance Criteria:**
- Given a warmed local runtime, when the normal fixture posts, then one terminal staged inbound record is acknowledged in less than one second with no customer-facing action.
- Given rejection, duplicate, and reverse-timestamp fixtures, when evidence is queried, then no partial state exists, replays create one row, and sequence follows receipt order without changing timestamps.
- Given the canonical harness, when all checks run, then it passes with no real customer or credential artifact committed and promotion disabled.

## Spec Change Log

## Design Notes

The payload remains WhatsApp-shaped, but is not a live callback: the container binds only to `127.0.0.1`, values are generated per run, and the endpoint includes `test`. The timing starts after n8n is healthy and ends at HTTP acknowledgement, excluding startup and downstream work.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: `PASS FULL PASS`, including the named five-case SP2-T1 proof and generated-artifact cleanup.
- `git diff --check` -- expected: no whitespace errors.
- `git status --short` -- expected: only reviewed SP2-T1 files before commit; no generated plaintext or volumes after the harness.

## Suggested Review Order

**Test-only boundary**

- The sole external entry point is visibly test-only and POST-only.
  [`01-whatsapp-ingress.json:106`](../../workflows/01-whatsapp-ingress.json#L106)

- Generated test configuration prevents use of real account settings.
  [`01-whatsapp-ingress.json:125`](../../workflows/01-whatsapp-ingress.json#L125)

**Safe staging behavior**

- Raw-byte HMAC and complete-envelope validation precede any durable action.
  [`01-whatsapp-ingress.json:205`](../../workflows/01-whatsapp-ingress.json#L205)

- Accepted messages use terminal staging ingestion, not customer-facing workflow execution.
  [`01-whatsapp-ingress.json:275`](../../workflows/01-whatsapp-ingress.json#L275)

**Contract and evidence**

- The local contract documents HMAC, staging-only behavior, and test-only scope.
  [`api-contracts.md:8`](../../docs/api-contracts.md#L8)

- The harness proves all five named cases, timing, timestamps, and downstream isolation.
  [`run.ps1:166`](../../tests/run.ps1#L166)

- Compose remains loopback-bound and exposes only generated test variables.
  [`compose.yaml:18`](../../compose.yaml#L18)
