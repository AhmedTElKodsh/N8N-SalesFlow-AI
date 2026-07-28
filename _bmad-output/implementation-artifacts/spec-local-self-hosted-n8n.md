---
title: 'Keep the verified N8N stack running locally'
type: 'chore'
created: '2026-07-28'
status: 'done'
route: 'one-shot'
baseline_commit: '2ebb6b6'
---

# Keep the verified N8N stack running locally

## Intent

**Problem:** The canonical harness proved the SalesFlow workflows but always removed N8N, PostgreSQL, volumes, and generated credentials, leaving no local runtime for implementation.

**Approach:** Extend the existing harness with an explicit persistent mode that retains a verified localhost-only stack, refuses accidental data replacement, preserves recoverability on cleanup failures, and keeps secrets outside Git.

## Suggested Review Order

**Safe local lifecycle**

- Start with the two explicit lifecycle switches and shared harness entry point.
  [`run.ps1:1`](../../tests/run.ps1#L1)

- Fail closed on concurrent runs, Docker errors, and existing local state.
  [`run.ps1:18`](../../tests/run.ps1#L18)

- Tear down old state with its original credentials before generating replacements.
  [`run.ps1:39`](../../tests/run.ps1#L39)

- Preserve only successful healthy stacks; retain recovery credentials when cleanup fails.
  [`run.ps1:119`](../../tests/run.ps1#L119)

**Release integrity**

- Bind the changed harness into the reviewed activation manifest.
  [`release-manifest.json:27`](../../release/release-manifest.json#L27)

- Require the synthetic Release Set to match the PostgreSQL-canonical manifest hash.
  [`release-set.json:1`](../../config/release-set.json#L1)

**Operator guidance**

- Document start, resume, destructive reset, and plaintext local-secret boundaries.
  [`README.md:27`](../../README.md#L27)
