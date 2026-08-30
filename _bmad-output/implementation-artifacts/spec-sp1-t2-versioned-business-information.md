---
title: 'SP1-T2 Versioned Business Information Publication'
type: 'feature'
created: '2026-08-06'
status: 'done'
review_loop_iteration: 1
baseline_commit: '19be81d9b31f30ddcb73a83a14d4811dde174db5'
context:
  - '{project-root}/docs/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The database currently saves and activates configuration in one `publish_config` call. An authorized reviewer cannot inspect a permanently saved inactive version before approval, explicitly activate it later, safely roll back to an older version, or receive a clear stale result when another activation wins a race.

**Approach:** Split the existing PostgreSQL boundary into one command that validates and saves an immutable inactive version and one command that atomically activates a saved version. Treat activation as approval, record its actor and time in the append-only audit log, and implement rollback by activating an older saved version.

## Boundaries & Constraints

**Always:** Apply the lifecycle to the versioned configuration documents, including the five SP1-T1 business contracts; require an account-scoped `operator` token for saving and activation; validate only when saving and reject anything other than literal validation success; preserve every version, its original body, and `created_at`; keep exactly one active version per account and kind; require the caller's expected active version for a state-changing activation; serialize each account/kind with the existing PostgreSQL advisory-lock pattern; make already-active activation idempotent; audit each actual activation with kind, target version, previous version, actor, and database timestamp; keep `livePromotionAllowed: false`.

**Ask First:** Adding an operator-facing HTTP/UI surface, a separate approver role or two-person maker-checker rule, changing business contract fields, introducing scheduled effective times or safety revocation, granting publication functions to the runtime database role, or changing production promotion authority.

**Never:** Overwrite or delete a saved version, reactivate by resubmitting its body, create a separate rollback subsystem or history table, retain a save-and-activate bypass, let two competing activations both succeed, add a dependency, or claim local passing tests are production approval.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Save valid version | Valid document with a new version | Save one inactive dated row; active version is unchanged | Return `ok: true, created: true` |
| Repeat save | Same account/kind/version and identical body | No new row or mutation | Return `ok: true, created: false` |
| Conflicting or invalid save | Same version with different body, malformed document, wrong account, or invalid token | No row or active-state change | Return `version_immutable`, `invalid_config`, or `unauthorized` |
| Activate saved version | Target exists and current active equals the explicit expectation | Atomically switch active version and append approval audit | Return target and previous version |
| Retry activation | Target is already active | No state change and no duplicate audit | Return idempotent success |
| Roll back | Older saved target with current version as expectation | Older target becomes active; all rows and audit history remain | Same activation contract |
| Competing activation | Two different targets use the same expected active version | Exactly one activates | Loser returns `stale_active_version`; no database error |
| Missing/unauthorized activation | Target absent, wrong account, or invalid token | Active version remains unchanged | Return `not_found` or `unauthorized` |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- `config_docs`, strict validation, operator authentication, advisory locks, audit immutability, and the fused publication function to replace.
- `tests/runtime.sql` -- sequential database assertions for validation, authorization, immutable saving, activation, rollback, and audit evidence.
- `tests/run.ps1` -- fixture bootstrap, direct publication callers, concurrent-job helper, and canonical full-suite entry point.
- `docs/component-inventory.md` -- current reviewer-facing function inventory and configuration lifecycle wording.
- `release/release-manifest.json`, `config/release-set.json` -- changed-input hashes and reviewed activation digest; promotion must remain disabled.

## Tasks & Acceptance

**Execution:**
- [x] `database/001-initial.sql` -- replace `publish_config` with minimal `save_config` and `activate_config` commands; fail closed on null/cross-account input; make identical historical saves idempotent before applying current validation to new content; enforce body/key/date immutability while permitting activation-flag changes; drop the old bypass.
- [x] `tests/runtime.sql`, `tests/run.ps1` -- migrate fixture setup; assert every bootstrap save/activation result; prove valid/invalid save, authorization including null account, historical idempotency, key/body/date immutability, activation, rollback, audit evidence, and a two-target expected-version race with actual lock contention; seed the prior `release-v2` body to exercise an upgrade rather than only a fresh install.
- [x] `docs/component-inventory.md` -- explain save, approval/activation, audit evidence, rollback, and concurrency in plain language using the existing version fields.
- [x] `release/release-manifest.json`, `config/release-set.json` -- advance the immutable release-set and activation-manifest version to `release-v3`, refresh both input-hash copies and the canonical activation binding, and keep live promotion disabled.

**Acceptance Criteria:**
- Given a valid new document, when an operator saves it, then a dated inactive immutable row is created and the current active version is unchanged.
- Given a saved target and matching expected active version, when an operator activates it, then exactly that target is active and one append-only audit event identifies who approved it and when.
- Given an older saved target, when it is activated, then future reads use it while newer and older rows remain reconstructable.
- Given two simultaneous different targets with the same expectation, when activation completes, then exactly one succeeds and the other returns `stale_active_version` without partial state or native database failure.
- Given the canonical local harness runs, when it completes, then all existing scenarios plus the SP1-T2 lifecycle and race checks pass and release evidence remains promotion-blocked.

## Spec Change Log

- 2026-08-06 review loop 1: Adversarial review found that changing the Release Set body while retaining `release-v2` would be rejected on an existing SP1-T1 database. The execution plan now requires `release-v3`, an existing-`release-v2` upgrade fixture, checked bootstrap results, fail-closed null authorization, historical idempotency, fuller immutability checks, and deliberate lock contention. Avoid the known-bad fresh-install-only proof and silent JSON failures. KEEP the separate save/activate API, immutable rows, activation audit, rollback by reactivation, one-winner compare-and-set, existing runtime reader shape, and promotion-disabled release posture.

## Design Notes

Keep `config_docs.active` and its unique partial index because every runtime reader already consumes that shape. `activate_config` checks an already-active target before its null-safe compare-and-set, so retries are harmless; `NULL` explicitly means the caller expects no active version. `save_config` checks an existing identical immutable row before current validation so an old-version retry remains idempotent, while new rows still validate fail-closed. Activation does not revalidate an immutable saved body, which keeps historical rollback possible if validation rules later evolve. Release evidence is configuration too: whenever its body changes, both `config/release-set.json.version` and `activationManifest.version` must advance together.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: canonical manifest checks, all runtime assertions, direct activation race proof, cleanup, and `FULL PASS`.
- `git diff --check` -- expected: no whitespace errors.
- `rg -n "publish_config\(" database tests workflows` -- expected: no executable caller or retained bypass.

## Suggested Review Order

**Publication boundary**

- Save validates new content while preserving historical retry idempotency.
  [`001-initial.sql:63`](../../database/001-initial.sql#L63)

- Activation provides authorization, compare-and-set, audit, and rollback semantics.
  [`001-initial.sql:64`](../../database/001-initial.sql#L64)

- The row guard preserves version identity, content, and creation time.
  [`001-initial.sql:38`](../../database/001-initial.sql#L38)

**Upgrade and release binding**

- Checked JSON responses prevent silent fixture publication failures.
  [`run.ps1:65`](../../tests/run.ps1#L65)

- Existing release-v2 state proves the immutable release-v3 upgrade.
  [`run.ps1:66`](../../tests/run.ps1#L66)

- The activation manifest advances and remains canonically hash-bound.
  [`release-manifest.json:28`](../../release/release-manifest.json#L28)

- Release Set pins the same reviewed release-v3 digest.
  [`release-set.json:1`](../../config/release-set.json#L1)

**Concurrency and regression evidence**

- Exact-key lock contention proves one winner, one stale result, and rollback.
  [`run.ps1:82`](../../tests/run.ps1#L82)

- Database assertions cover authorization, history, immutability, audit, and rollback.
  [`runtime.sql:47`](../../tests/runtime.sql#L47)

- Plain-language documentation explains the operator lifecycle and conflict behavior.
  [`component-inventory.md:49`](../../docs/component-inventory.md#L49)
