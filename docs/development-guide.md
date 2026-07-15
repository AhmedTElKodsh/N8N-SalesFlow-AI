# Development Guide

## Prerequisites

- Docker Desktop with Compose
- Windows PowerShell 5.1 or PowerShell 7
- Free local ports required by Docker; n8n binds to `127.0.0.1:5678`

No npm, Python, or application dependency installation is required for the canonical path.

## Canonical verification

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

The harness creates disposable credentials, starts PostgreSQL, applies the migration twice, publishes account configuration, imports/publishes all workflows, executes database scenarios and concurrency races, calls every live endpoint, verifies canonical exports and secret hygiene, and removes generated plaintext and volumes in `finally`.

## Change workflow

1. Read [project-context.md](./project-context.md) and the relevant canonical PRD/architecture section.
2. Trace the affected n8n workflow into its PostgreSQL function. State behavior belongs in the shared SQL command, not duplicated across callers.
3. Keep source workflows on the approved native-node list unless the architecture and release manifest deliberately change.
4. Add the smallest assertion to `tests/runtime.sql` or `tests/run.ps1` that fails if the new behavior regresses.
5. Export/canonicalize the workflow in the pinned n8n environment and update the manifest only after the artifact set is reviewed.
6. Run the complete harness and update `test-evidence.md` only from an actual passing run.

## Manual local lifecycle

Use the commands in the root [README](../README.md) when inspecting the environment manually. Start PostgreSQL and apply the owner migration before starting n8n. Workflow credentials/import/publication are intentionally automated in `tests/run.ps1` to avoid storing deployable credentials.

## Important conventions

- PostgreSQL owns business state and atomic transitions.
- Tokens/credentials never enter source exports, fixtures, logs, or documentation.
- Missing config/control fails closed.
- All identifiers and joins remain account/Contact scoped.
- Customer sends and Handoffs use persisted logical work with bounded claims/leases.
- Synthetic fixtures must never be described as approved production policy or content.

## Common checks

```powershell
# Confirm repository changes
git status --short

# Validate JSON source files
Get-ChildItem config,workflows,release,tests -Filter *.json -Recurse |
  ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json | Out-Null }

# Run the complete executable contract
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```
