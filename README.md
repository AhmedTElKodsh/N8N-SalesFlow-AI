# N8N SalesFlow AI

This repository contains a reproducible synthetic-local implementation of the seven-workflow SalesFlow design. PostgreSQL owns business state, authorization, retries, leases, and audit evidence; n8n provides native-node orchestration.

## Verified local workflow set

1. WhatsApp ingress
2. Conversation orchestrator
3. Outbox dispatcher
4. WhatsApp status callback
5. UTC follow-up scheduler
6. Handoff dispatcher
7. Error and operations endpoint

The local adapters are deterministic synthetic providers. They prove workflow wiring and state transitions without claiming Meta, LLM, CRM, legal, privacy, or managed-infrastructure approval.

## Run the complete test

Requirements: Docker Desktop with Compose and Windows PowerShell 5.1 or PowerShell 7.

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

The command starts a clean digest-pinned PostgreSQL/n8n environment, applies the migration twice, creates random local credentials, publishes both account configurations, executes S01-S26 and concurrency checks, imports and publishes all workflows, calls every live endpoint, re-exports and hashes the imported workflows, scans exports for credentials, and removes generated plaintext and Docker volumes in `finally`.

## Keep a free local development stack

Run the same verified path and retain the healthy containers, volumes, and ignored `.env`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 -KeepRunning
```

Open <http://127.0.0.1:5678>. Resume a stopped stack with `docker compose --env-file .env up -d`. The command refuses to overwrite an existing local environment; use `-KeepRunning -ResetLocal` only when you intend to delete and rebuild its data.

The retained `.env` contains local database and encryption secrets in plaintext. It is Git-ignored, but use this mode only on a trusted development account and never copy that file to chat, source control, or a shared machine.

## Manual lifecycle

The automated harness is the canonical path because it generates disposable secrets, provisions the least-privilege roles, and imports/publishes the workflows. For a manual clean start, fill every blank secret in an ignored `.env`, start PostgreSQL alone, apply the owner migration, and only then start n8n:

```powershell
Copy-Item .env.example .env
# Edit .env and set every blank password, N8N_ENCRYPTION_KEY, and SCHEDULER_TOKEN.
$envMap = @{}; Get-Content .env | Where-Object { $_ -match '^[^#=]+=' } | ForEach-Object { $key, $value = $_ -split '=', 2; $envMap[$key] = $value }
docker compose --env-file .env up -d postgres --wait
$migration = (Get-Content database/001-initial.sql -Raw).Replace('__MIGRATION_PASSWORD__', $envMap.MIGRATION_PASSWORD).Replace('__WORKFLOW_DB_PASSWORD__', $envMap.WORKFLOW_DB_PASSWORD).Replace('__N8N_DB_PASSWORD__', $envMap.N8N_DB_PASSWORD)
$migration | docker compose --env-file .env exec -T postgres psql -U $envMap.POSTGRES_SUPERUSER -d $envMap.POSTGRES_DB -v ON_ERROR_STOP=1
if ($LASTEXITCODE) { throw 'Migration failed; n8n was not started.' }
docker compose --env-file .env up -d n8n
```

Workflow credential import and publication are intentionally left to `tests/run.ps1`; the repository does not contain deployable credentials.

Workflow JSON is canonicalized inside the pinned n8n container by `scripts/canonicalize-workflows.mjs`. Expected image, workflow, and input hashes are recorded in `release/release-manifest.json`.

## Production gates

Live promotion remains disabled. Production proof still requires customer-owned Meta assets and credentials, an approved LLM/provider selection, the real Handoff/CRM acknowledgement contract, managed PostgreSQL controls, approved sales/knowledge/legal/privacy content, and named production-owner approval. None of those external gates is represented as passed by the local suite.
