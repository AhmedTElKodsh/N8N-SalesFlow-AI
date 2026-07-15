# Deployment Guide

## Implemented deployment

The repository implements a **disposable local verification environment**, not a production stack.

| Service | Image | Exposure | State |
| --- | --- | --- | --- |
| PostgreSQL | Digest-pinned PostgreSQL 17.10 | Internal Compose network | Named local volume, removed by the test harness |
| n8n | Digest-pinned n8n 2.30.4 | `127.0.0.1:5678` | Named local volume, removed by the test harness |

The repository is mounted read-only into n8n. Generated import/export material uses `.generated/`, which is ignored and deleted in `finally`. n8n success, error, and manual execution payload persistence is disabled.

## Local deployment

Prefer the canonical test harness:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

For a manual lifecycle, copy `.env.example` to ignored `.env`, fill every blank secret, start PostgreSQL, apply the migration with the owner role, then start n8n. See the root [README](../README.md) for exact commands.

## Release evidence

`release/release-manifest.json` pins:

- both container digests;
- the exact workflow and config file sets;
- hashes for schema, scripts, tests, config, and workflow inputs;
- canonical imported/exported workflow identity;
- the approved native-node inventory;
- `livePromotionAllowed: false`.

## Production gates

Do not promote this Compose topology or replace synthetic adapters until all applicable evidence exists:

1. Customer-owned Meta app/number, credentials, supported Graph API contract, templates, callback identity, and test/production isolation.
2. Approved LLM/provider selection, structured-output benchmark, privacy/retention/residency terms, and production credentials.
3. Real Handoff/CRM destination, assignment and acknowledgement contract, SLA, after-hours route, and retry/reconciliation behavior.
4. Managed PostgreSQL TLS, pooling, connection limits, backup/PITR, restore proof, monitoring, region, retention, and RTO/RPO approval.
5. Approved Product Knowledge, Sales Policy, offer, consent/opt-out wording, templates, language set, legal/privacy controls, and production owner.
6. Credentialed integration, adversarial, load, failure-recovery, and limited-pilot evidence.

## Scaling boundary

Keep one n8n runtime until measured concurrency/backlog or an approved SLO requires queue mode, Redis, workers, or HA. The current local success does not prove 99.9% availability or campaign-scale concurrency.

## Rollback boundary

Release activation is manifest-backed and retains prior immutable records, but production rollback is not implemented by the local adapter set. A production runbook must define compatible workflow/config/schema rollback order and post-rollback smoke/reconciliation checks before automation resumes.
