---
title: 'Task 7 focused SalesFlow learning checkpoints'
type: 'feature'
created: '2026-08-19'
status: 'done'
review_loop_iteration: 0
baseline_commit: '439c5965c81e6fafe7904bb68c698b1a1a8043e8'
context:
  - '{project-root}/learning/tutor-contract.md'
  - '{project-root}/docs/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** M00-M10 milestone contracts exist, but there are no focused validators proving that learner work satisfies each behavioral boundary. The tutoring CLI therefore cannot provide deterministic milestone evidence before the capstone suite.

**Approach:** Add one native-PowerShell validator per milestone plus a meta-test that enforces the shared interface, failure protocol, anti-reference boundary, and non-stub behavior. Parse JSON structurally and validate n8n connections as dataflow; use narrow SQL construct plus test-evidence assertions without copying or hashing a complete solution.

## Boundaries & Constraints

**Always:** Accept `-RepositoryRoot`; on success emit exactly one `LEARNING_EVIDENCE=<json-array>` line after every assertion; on failure emit no evidence, write a classified invariant/location diagnostic to stderr, and exit nonzero. Keep checks deterministic and dependency-free except for M01's read-only Docker/Compose reachability checks and M10's explicitly deferred release harness. Preserve unrelated working-tree dirt.

**Ask First:** Any destructive Docker action, production/external integration, product implementation change needed only to satisfy a checkpoint, or change to the approved milestone evidence contract.

**Never:** Read or reveal `reference/salesflow-complete-v1`; compare complete source text or hashes; rely on regex alone when JSON graph or field structure is available; mutate Docker state in M01; invoke M10 or the full suite more than the one authorized final run before Task 8.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Valid milestone | Current completed learner-branch artifacts | Exit 0 and exactly one JSON-array evidence line | N/A |
| Missing or malformed artifact | Missing file, invalid JSON, disconnected workflow, absent SQL/test invariant | No evidence | Classified diagnostic names invariant, observed value, and location; nonzero exit |
| M01 unavailable environment | Docker command/daemon/Compose unavailable | No state mutation and no evidence | `Environment or tooling failure` diagnostic; nonzero exit |
| M10 before Task 8 | Meta-test inspects preflight/full-suite structure only | Full suite is not launched | Direct M10 execution remains deferred |

</frozen-after-approval>

## Code Map

- `tests/learning/TestSupport.ps1` -- existing learning meta-test assertions.
- `tests/learning/checkpoints/CheckpointSupport.ps1` -- native structural readers, workflow graph traversal, and invariant diagnostics shared by focused validators.
- `database/001-initial.sql` -- durable state, account scoping, idempotency, authorization, retry, privacy, and release constructs.
- `workflows/*.json` -- n8n nodes and connection graphs parsed with `ConvertFrom-Json`.
- `config/*.json` and `release/release-manifest.json` -- typed configuration and release-binding contracts.
- `tests/runtime.sql` and `tests/run.ps1` -- behavioral evidence markers, concurrency assertions, capstone output, and cleanup proof.

## Tasks & Acceptance

**Execution:**
- [x] `tests/learning/Test-CheckpointSuite.ps1` -- add the meta-test first and capture RED for eleven missing scripts.
- [x] `tests/learning/checkpoints/CheckpointSupport.ps1` -- add quiet native helpers for paths, JSON, SQL constructs, and workflow reachability.
- [x] `tests/learning/checkpoints/Test-M00.ps1` through `Test-M09.ps1` -- implement the exact focused evidence contracts.
- [x] `tests/learning/checkpoints/Test-M10.ps1` -- preflight M00-M09, announce cost, invoke `tests/run.ps1`, and require full-pass plus cleanup evidence; do not execute it in Task 7.
- [x] `.superpowers/sdd/2026-08-16-ai-guided-salesflow-tutoring-implementation/task-7-report.md` -- record RED, verification, Task 8 resolution, commits, and preserved state.

**Acceptance Criteria:**
- Given the checkpoint scripts are absent, when the meta-test runs first, then it fails for exactly eleven missing validators.
- Given the current completed implementation, when M00-M09 run independently, then each exits 0 with one structurally valid evidence array and no other success output.
- Given an invalid repository root, when any M00-M09 validator runs, then it emits no evidence and returns a classified stderr diagnostic with nonzero exit.
- Given all scripts exist, when the meta-test runs, then syntax, interface, anti-reference, failure protocol, evidence protocol, and milestone-specific non-stub assertions pass without launching M10.
- Given final verification, when learning tests and the full suite run once, then learning tests pass and the pre-Task-8 manifest hashing failure is reported precisely without treating M10 as executed.

## Spec Change Log

## Design Notes

Workflow checks identify semantically relevant nodes from node type and SQL function/workflow target fields, then prove ordered reachability through the parsed `connections` graph. SQL checks extract table/function constructs and pair them with focused runtime/race assertions so a keyword-only stub cannot pass.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-CheckpointSuite.ps1` -- first RED, then all meta assertions green.
- `0..9 | ForEach-Object { powershell -ExecutionPolicy Bypass -File ".\tests\learning\checkpoints\Test-M$('{0:d2}' -f $_).ps1" -RepositoryRoot (Get-Location) }` -- each checkpoint emits one evidence line and exits 0.
- Run all `tests/learning/Test-*.ps1` files -- learning suite green.
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- run once; record the known Task 8 hashing failure if still present.

**Final result:** All top-level tutoring tests pass. The disposable release harness reports `PASS FULL PASS`, `PASS plaintext generated credentials removed`, and `PASS container volumes removed`. M02, M03, M08, and M09 now prove their declared runtime outcomes; M00 remains learner-branch/ref specific and M01 remains live-environment specific by design.

## Suggested Review Order

**Checkpoint protocol and evidence alignment**

- Start with repository isolation, classified failures, and shared structural readers.
  [`CheckpointSupport.ps1:27`](../../tests/learning/checkpoints/CheckpointSupport.ps1#L27)

- Exact milestone evidence arrays prevent implementation-detail labels from masquerading as outcomes.
  [`Test-CheckpointSuite.ps1:108`](../../tests/learning/Test-CheckpointSuite.ps1#L108)

**Runtime outcome closure**

- Typed ingress preserves legacy identifiers while adding the milestone's event contract.
  [`001-initial.sql:72`](../../database/001-initial.sql#L72)

- Scoped retention minimizes expired messages and returns observable account-bound evidence.
  [`001-initial.sql:134`](../../database/001-initial.sql#L134)

- Runtime assertions independently prove accepted and eventId JSON types.
  [`runtime.sql:10`](../../tests/runtime.sql#L10)

**Cross-platform and journey acceptance**

- Raw hashes now verify the actual LF materialized bytes on Windows.
  [`Test-ManifestHashing.ps1:21`](../../tests/learning/Test-ManifestHashing.ps1#L21)

- Fresh-process resume proves progress survives without chat history.
  [`Test-TutoringAcceptance.ps1:109`](../../tests/learning/Test-TutoringAcceptance.ps1#L109)
