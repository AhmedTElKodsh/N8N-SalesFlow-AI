# Development Guide

## Prerequisites

- Docker Desktop with Compose
- Windows PowerShell 5.1 or PowerShell 7
- Docker can allocate a free loopback port; resolve n8n with `docker compose port n8n 5678`

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

## Tutoring maintenance

Treat the curriculum, milestone contracts, learner state, CLI, and focused checkpoints as one versioned interface. Before changing them, read `learning/tutor-contract.md`, identify the single milestone outcome being changed, and keep the learner-facing lesson limited to that milestone and its immediate prerequisite.

`learning/curriculum.yaml` and every `checkpoint.yaml` use JSON-compatible YAML: the files must remain valid JSON so Windows PowerShell can parse them with `ConvertFrom-Json` without another runtime dependency. When adding or changing a milestone, update its curriculum entry, `lesson.md`, `hints.md`, checkpoint contract, and focused script together. Keep every `testScript` inside `tests/learning/checkpoints`; checkpoints must validate observable milestone outcomes rather than compare learner work with a completed solution.

Run the focused maintenance checks from the repository root:

```powershell
# Tutor contract and curriculum structure
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-TutorContract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-Curriculum.ps1

# Durable state, CLI, and checkpoint runner behavior
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-LearningState.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-LearningCli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-CheckpointSuite.ps1

# Milestone documents, release hashes, and complete tutoring journey
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-MilestoneDocuments.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-ManifestHashing.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\learning\Test-TutoringAcceptance.ps1
```

Before merging a tutoring change, run every learning test:

```powershell
Get-ChildItem .\tests\learning\Test-*.ps1 | Sort-Object Name | ForEach-Object {
  powershell -NoProfile -ExecutionPolicy Bypass -File $_.FullName
  if ($LASTEXITCODE -ne 0) { throw "$($_.Name) failed" }
}
```

The reference code is unavailable to ordinary tutoring. Learner-facing lessons and hints may point to the active learner branch, milestone contract, relevant documentation, and focused evidence, but they may not contain completed code or commands that extract completed files from the reference ref. Curriculum maintainers may inspect the reference only within the read-only boundary allowed by the tutor contract.

Update `starter/salesflow-guided-v1` and `reference/salesflow-complete-v1` deliberately. Review the exact source commits, rerun the learning and release checks appropriate to each ref, update any recorded revisions or hashes, and verify the published refs resolve to those reviewed commits. Never move either ref as an incidental consequence of a curriculum edit.
