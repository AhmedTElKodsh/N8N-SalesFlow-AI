# SalesFlow local test evidence

Date: 2026-07-15
Runtime: n8n 2.30.4 and PostgreSQL 17.10, both digest-pinned in `compose.yaml`
Command: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

## Result

The synthetic-local run completed with `PASS FULL PASS` and exit code 0 in 145.1 seconds. Independent post-run checks found no `.generated` directory and zero Docker volumes bearing the `n8n-salesflow-ai` Compose project label.

Verified evidence includes:

- migration idempotence and a least-privilege n8n database role;
- exact S01-S26 runtime assertions;
- concurrent replay and sequence races with native worker exit checks;
- immutable configuration, account disablement, service-window policy, retry/lease recovery, deletion minimization, and single-active release rotation bound to the complete activation manifest;
- seven workflow imports, activations, publications, and real connected endpoint paths;
- automatic ingress-to-orchestrator-to-dispatch and ingress-to-Handoff completion, concurrent callback collapse, actual UTC Schedule Trigger recovery of expired outbound/Handoff claims, final pre-adapter authorization checks, and account-bound operations terminals;
- source versus imported/exported canonical workflow identity;
- approved native-node inventory and generated export secret scans;
- generated plaintext credential and Docker-volume cleanup.

## Scope boundary

This evidence proves the disposable synthetic-local implementation only. It does not prove production Meta delivery, a production LLM, a CRM/Handoff acknowledgement, managed PostgreSQL security/backup controls, approved customer sales and knowledge content, legal/privacy wording, or production-owner approval. `release/release-manifest.json` therefore keeps `livePromotionAllowed` set to `false`.
