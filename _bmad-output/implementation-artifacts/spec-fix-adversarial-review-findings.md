---
title: 'Remediate Adversarial Implementation Review'
type: 'bugfix'
created: '2026-08-06'
status: 'done'
review_loop_iteration: 0
baseline_commit: '9dedc8b104b5421f982156bc00a316f090d95832'
context:
  - '{project-root}/docs/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The current synthetic-local baseline passes its harness but still accepts ambiguous configuration values, permits publication and state-integrity bypasses, loses valid messages in mixed Meta envelopes, hides transport/database failures, and carries misleading or incomplete security and provenance contracts.

**Approach:** Close every reviewed gap at the shared PostgreSQL and n8n boundaries, expose publication through the existing operator endpoint, delete superseded code, and add focused database plus live HTTP regressions while preserving the deliberately small synthetic-local topology.

## Boundaries & Constraints

**Always:** Keep PostgreSQL authoritative; use native constraints and existing stored commands; preserve immutable version history and one-active-version semantics; make publication locks bounded; return meaningful HTTP failures; keep valid text from mixed Meta envelopes; record saver and activator identity; keep `livePromotionAllowed: false`; update every release/hash binding; leave one runnable regression for each fixed behavior.

**Ask First:** Destructive migration of unknown production data, a custom administration UI, production credentials, a new dependency, or changing the approved business fields and state vocabulary.

**Never:** Grant table access to workflow roles, restore direct activation updates, swallow unexpected database failures, expose secrets in exports, claim synthetic tests prove production readiness, or replace exact validation with heuristic parsing.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Configuration save | Strict valid document through operator endpoint | One inactive immutable version plus saver audit | Invalid, duplicate-ambiguous, blank, fractional-integer, cross-account, or incompatible input is rejected without mutation |
| Activation or rollback | Saved compatible target and expected current version | One active target plus approver audit | Stale, busy, bypassed, missing, or incompatible target leaves state unchanged |
| Meta mixed envelope | Valid text plus unsupported sibling event | Persist valid text once and acknowledge | Unsupported-only remains acknowledged and audited |
| Status callback | Valid, malformed, unauthorized, missing-provider, or conflicting event | Success/duplicate is 200 | Return explicit 400/403/404/409; unexpected failures propagate as 5xx |
| Runtime state/token | Valid and invalid states; active, expired, or revoked tokens | Valid transitions and active tokens work | Database rejects invalid states; expired/revoked tokens are unauthorized |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- configuration validation/publication, state constraints, token lifecycle, runtime commands, release pointer, and duplicated definitions.
- `workflows/01-whatsapp-ingress.json`, `workflows/04-whatsapp-status.json`, `workflows/07-error-and-operations.json` -- mixed-envelope handling and explicit operator/callback HTTP contracts.
- `tests/runtime.sql`, `tests/run.ps1` -- database invariants, live endpoints, concurrency, and authoritative `FULL PASS` harness.
- `docs/component-inventory.md`, `docs/data-models.md`, `docs/api-contracts.md`, `docs/deployment-guide.md` -- reviewer-facing contracts and retained synthetic-local security boundary.
- `release/release-manifest.json`, `config/release-set.json` -- release-v4 input, workflow, activation, and promotion-blocking bindings.

## Tasks & Acceptance

**Execution:**
- [x] `database/001-initial.sql` -- enforce exact integers, nonblank unique set identifiers, compatible audited save/activation, activation-only state changes, bounded locks, state checks, expiring/revocable tokens, exact synthetic qualification signal, pointer-only release authority, and propagated internal errors; delete superseded function bodies.
- [x] `workflows/01-whatsapp-ingress.json`, `workflows/04-whatsapp-status.json`, `workflows/07-error-and-operations.json` -- retain valid mixed-envelope texts; add native response-node status mapping; expose save/activate/rollback through existing operator operations without granting private functions.
- [x] `tests/runtime.sql`, `tests/run.ps1` -- cover every reviewed failure, exact lock contention/timeout, operator HTTP lifecycle, callback statuses, state/token constraints, no duplicate signatures, and unexpected 5xx propagation.
- [x] `compose.yaml`, documentation -- prevent this env-readable local topology from being promoted and document the credential redesign gate instead of breaking local workflows with a false flag-only fix.
- [x] Release artifacts and completed SP1 documentation -- advance to release-v4, refresh all raw/canonical/combined/activation hashes, and record only observed test evidence.

**Acceptance Criteria:**
- Given malformed or ambiguous business information, when validation or activation runs, then no version becomes active and a typed reason is returned.
- Given direct activation, invalid aggregate state, or expired/revoked credentials, when mutation is attempted, then PostgreSQL rejects or denies it without losing history.
- Given concurrent publication, mixed Meta input, callback rejection, or an internal database fault, when the live workflow runs, then outcomes are bounded, lossless, and represented by the correct HTTP class.
- Given the canonical harness runs, when it completes, then all prior scenarios and new regressions pass, hashes match release-v4, and promotion remains disabled.

## Spec Change Log

## Design Notes

`release_pointers` remains the only active-release authority. The exact word `qualified` remains a marked synthetic-local signal rather than pretending to implement NLP. Environment access is not made safe by flipping one compose flag: the local topology remains technically blocked from promotion until scheduler and Meta secrets move to approved n8n credentials or an external secret store.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: all database/live regressions, cleanup, and `FULL PASS`.
- `git diff --check` -- expected: no whitespace errors.
- `rg -n "CREATE OR REPLACE FUNCTION" database/001-initial.sql` plus harness signature assertion -- expected: one effective definition per public signature.

## Suggested Review Order

### Publication and authority

- [Strict contract validation](../../database/001-initial.sql#L65) -- Start with the shared trust boundary.
- [Immutable version saving](../../database/001-initial.sql#L80) -- Check authorization, audit, and version creation.
- [Bounded activation](../../database/001-initial.sql#L92) -- Review concurrency, compatibility, and pointer authority.
- [Operator commands](../../database/001-initial.sql#L190) -- Trace save, activate, and rollback exposure.

### Ingress and transport

- [Mixed Meta envelopes](../../workflows/01-whatsapp-ingress.json#L266) -- Confirm valid text survives unsupported siblings.
- [Callback command](../../database/001-initial.sql#L177) -- Check missing identity and timestamp rejection.
- [Callback HTTP mapping](../../workflows/04-whatsapp-status.json#L23) -- Verify explicit response ownership.
- [Operations HTTP mapping](../../workflows/07-error-and-operations.json#L23) -- Verify database failures propagate as 5xx.

### State and credential integrity

- [Token lifecycle](../../database/001-initial.sql#L19) -- Review expiry, revocation, and safe renewal.
- [State mutation guard](../../database/001-initial.sql#L54) -- Confirm activation-only active-state changes.
- [Exact qualification marker](../../database/001-initial.sql#L154) -- Confirm synthetic matching cannot overreach.

### Proof and release binding

- [Runtime database checks](../../tests/runtime.sql#L57) -- Inspect credential, state, and qualification regressions.
- [Live boundary checks](../../tests/run.ps1#L115) -- Follow callback, ingress, and 5xx endpoint proof.
- [Release-v4 binding](../../release/release-manifest.json#L28) -- Confirm reviewed inputs and activation hash.
- [Observed evidence](test-evidence.md#L16) -- Finish with the authoritative full-pass record.
