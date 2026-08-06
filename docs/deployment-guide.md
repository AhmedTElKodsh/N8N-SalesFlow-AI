# Deployment Guide

## Implemented deployment

The repository implements a **disposable local verification environment**, not a production stack.

| Service | Image | Exposure | State |
| --- | --- | --- | --- |
| PostgreSQL | Digest-pinned PostgreSQL 17.10 | Internal Compose network | Named local volume, removed by the test harness |
| n8n | Digest-pinned n8n 2.30.4 | `127.0.0.1:5678` | Named local volume, removed by the test harness |

The repository is mounted read-only into n8n. Generated import/export material uses `.generated/`, which is ignored and deleted in `finally`. n8n success, error, and manual execution payload persistence is disabled.

This local topology deliberately permits workflow expressions and Code nodes to read environment variables because the disposable harness injects scheduler and Meta protocol-test secrets that way. That design is an explicit promotion blocker, even when secret scans and local tests pass. Do not expose this n8n instance to untrusted workflow editors.

## Local deployment

Prefer the canonical test harness:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

For a manual lifecycle, copy `.env.example` to ignored `.env`, fill every blank secret, start PostgreSQL, apply the migration with the owner role, then start n8n. See the root [README](../README.md) for exact commands.

## Meta-compatible local protocol proof

The `salesflow/meta` GET and POST routes are a generated-credential protocol check only. Set the blank `META_ACCOUNT_REF`, `META_WABA_ID`, `META_PHONE_NUMBER_ID`, `META_VERIFY_TOKEN`, and `META_RUNTIME_TOKEN` values in ignored environment input, and create the `SalesFlow Meta HMAC` n8n Crypto credential with the App Secret. The exported workflow contains credential references and environment expressions, never secret values.

Pinned n8n `2.30.4` rejects syntactically invalid `application/json` with `422` before Workflow 01 executes, so that platform rejection has no PostgreSQL audit. Signed JSON that reaches the workflow but fails schema validation returns `400` and writes the minimized rejection audit.

The POST route accepts text-only envelopes up to 256 KiB, verifies the original-byte HMAC, validates the whole envelope, and commits the batch atomically without invoking orchestration, outbound delivery, Follow-Up, or Handoff. Rejections retain only an allowlisted reason and opaque correlation value. n8n execution payload persistence remains disabled.

Passing the local harness does not prove a Meta connection. Public HTTPS, webhook subscription, customer-owned credentials/assets, permissions, supported Graph API version, callback identity, duplicate/out-of-order delivery, and test/production isolation remain approval-gated external evidence.

## Release evidence

`release/release-manifest.json` pins:

- both container digests;
- the exact workflow and config file sets;
- hashes for schema, scripts, tests, config, and workflow inputs;
- canonical imported/exported workflow identity;
- the approved native-node inventory;
- `livePromotionAllowed: false`.

The release manifest also binds the promotion block caused by environment-readable credentials. Promotion requires moving scheduler and Meta secrets into approved n8n credentials or an external secret store and removing runtime secret dependence on workflow-readable environment variables; flipping an n8n flag alone is not a credential redesign.

## Production gates

Do not promote this Compose topology or replace synthetic adapters until all applicable evidence exists:

1. Customer-owned Meta app/number, credentials, supported Graph API contract, templates, callback identity, and test/production isolation.
2. Approved LLM/provider selection, structured-output benchmark, privacy/retention/residency terms, and production credentials.
3. Real Handoff/CRM destination, assignment and acknowledgement contract, SLA, after-hours route, and retry/reconciliation behavior.
4. Managed PostgreSQL TLS, pooling, connection limits, backup/PITR, restore proof, monitoring, region, retention, and RTO/RPO approval.
5. Approved Product Knowledge, Sales Policy, offer, consent/opt-out wording, templates, language set, legal/privacy controls, and production owner.
6. Credentialed integration, adversarial, load, failure-recovery, and limited-pilot evidence.
7. Scheduler and Meta secrets removed from workflow-readable environment variables, migrated to approved credentials or an external secret store, and reverified with environment access blocked.

## Scaling boundary

Keep one n8n runtime until measured concurrency/backlog or an approved SLO requires queue mode, Redis, workers, or HA. The current local success does not prove 99.9% availability or campaign-scale concurrency.

## Rollback boundary

Business-information rollback is implemented by activating an older compatible immutable version through the operator endpoint. Release activation also retains immutable history through `release_pointers`, but full production workflow/config/schema rollback is not implemented by the local adapter set. A production runbook must define that order and post-rollback smoke/reconciliation checks before automation resumes.
