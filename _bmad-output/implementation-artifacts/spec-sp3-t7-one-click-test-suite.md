---
title: 'SP3-T7 Build a one-click test suite'
type: 'feature'
created: '2026-09-13'
status: 'done'
baseline_commit: '4dfdf90cb33ec138c9c401ff1b4be67745d06a00'
review_loop_iteration: 0
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp3-t6-durable-activity-stop-failure-visibility.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `tests/run.ps1` already rebuilds a disposable stack, runs S01-S26 plus the SP3 suites, and cleans up, but it only prints assertion lines and stops at the first error. Nobody can see which scenario failed, why, or what never ran, so it cannot serve as the go/no-go input for real integrations. It also fails before testing on machines without the undeclared `rg` tool.

**Approach:** Keep the existing runner as the single command and add a scenario-level report around it. The run stays fail-fast. Every catalog item is recorded as pass, fail, or not run, and a saved, secret-free report with a synthetic-local scope statement is written after cleanup.

## Boundaries & Constraints

**Always:** One command with no manual steps: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`. Keep fail-fast: the item in progress fails with its reason, and every later item is `not run`. Report items appear in one fixed order: prerequisites, SP3-T4/T5/T6 suites, release and source contracts, clean environment and migrations, S01-S26 individually, additional database regressions, concurrency races, workflow publication and live HTTP checks, cleanup. The verdict is `PASS` only when every item passes. Otherwise it is `FAIL` and the exit code is non-zero. The report appears on screen and is saved to `test-results/test-report-<UTC timestamp>.md`. It never contains generated passwords, tokens, or keys. Cleanup behavior is unchanged: the default run removes containers, volumes, and generated credentials on pass or fail, and `-KeepRunning` retains the stack only after a pass.

**Ask First:** Resetting or deleting the retained local stack in this checkout, adding to or relaxing any existing assertion, retrying individual checks, or adding CI.

**Never:** Change product behavior in `database/`, `workflows/`, or `config/` (except rebinding `release-set.json`). Never weaken or skip assertions, enable live promotion, call live providers, or commit/push.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Full pass | Docker running, no retained stack | Every item `pass`, verdict `PASS`, report saved, stack removed | N/A |
| Prerequisite missing | Docker engine, Compose, or git unavailable; existing stack; invalid switch | Prerequisites `fail` with an actionable reason; all later items `not run` | No environment is created |
| Scenario failure | Assertion fails inside `runtime.sql` before S26 | Earlier S-items executed before it `pass`; the failing S-item `fail` with the redacted database error; the rest `not run` | Cleanup still runs and is reported |
| Failure after S26 | A runtime regression or race assertion fails | S01-S26 `pass`; the owning item `fail`; later items `not run` | Same |
| Cleanup failure | Volumes or generated files remain | Cleanup `fail` and verdict `FAIL`, even if all tests passed | Existing recovery message preserved |
| Secret in error text | Failure message contains a generated secret | Value replaced with `[redacted]` in console and file | The report self-check fails the run if any secret remains |

</frozen-after-approval>

## Code Map

- `tests/run.ps1` -- canonical runner; single `try/catch/finally`; the only `rg` use is at `:71`; `runtime.sql` runs at `:179`; S-ID check at `:181`; cleanup at `:434`.
- `tests/runtime.sql` -- the first `DO` block holds the S01-S26 evidence inserts, in execution order rather than ID order; later blocks are regressions.
- `tests/pilot-scenarios.json` -- the S01-S26 inventory; its only reader is `run.ps1:93`.
- `release/release-manifest.json`, `config/release-set.json` -- hash-bind the harness inputs (both `inputHashes` maps, `activationManifestSha256`, `reviewedManifestHash`; the `release-v11` label stays, following precedent `58f38be`).
- `README.md`, `docs/development-guide.md`, `docs/component-inventory.md`, `docs/project-context.md` -- runner documentation.

## Tasks & Acceptance

**Execution:**
- [x] `tests/Test-TestReport.ps1` -- Docker-free RED proof of every matrix row against the report helper -- proves the reporting logic without a 20-minute stack run.
- [x] `tests/TestReport.ps1` -- new dot-sourced helper: ordered catalog, enter/fail item state, not-run marking, secret registry with redaction, Markdown rendering, and a file self-check -- keeps reporting out of the dense runner.
- [x] `tests/pilot-scenarios.json` -- add a plain-language `names` map for S01-S26, taken from each scenario's actual assertions; keep the `scenarios` array unchanged.
- [x] `tests/runtime.sql` -- add a temp-table trigger on `evidence` that raises `NOTICE SCENARIO_PASS <id>` -- notices survive the block rollback, so partial progress is attributable.
- [x] `tests/run.ps1` -- dot-source the helper; check prerequisites first; replace `rg` with an equivalent line-bounded .NET regex; mark item boundaries; register every generated secret and token; capture `runtime.sql` stderr for S-item attribution; write, print, and self-check the report in `finally` after cleanup.
- [x] `release/release-manifest.json`, `config/release-set.json` -- add `tests/TestReport.ps1` and `tests/Test-TestReport.ps1`, then rebind all changed hashes once the inputs stabilize.
- [x] Docs listed in the Code Map, plus `_bmad-output/implementation-artifacts/test-evidence.md` and `test-reports/sp3-t7-run-{1,2}.md` -- document the report and keep both verification reports.

**Acceptance Criteria:**
- Given a clean checkout with Docker running, when the one command runs twice back-to-back with no edits or reruns in between, then both runs exit 0 with verdict `PASS`, and no project volumes or `.generated` files remain.
- Given any saved report, when it is scanned for every secret the run registered, then no match is found, and the report states it covers the simulated local setup only, not live WhatsApp or AI providers.
- Given the unchanged scenario assertions, when the suite passes, then the S01-S26 exact-set check and the existing `PASS FULL PASS` line still hold.

## Spec Change Log

## Design Notes

This checkout retains a local stack (`.env`), which the runner correctly refuses to replace. Verification therefore runs in a disposable `git worktree` holding the candidate files: a different path gives a different compose project, so the retained stack stays untouched and each run starts clean.

S-item attribution: notices arrive in execution order. Execution order comes from the `INSERT INTO evidence` order in `runtime.sql`. On psql failure, the first S-item without a notice fails; if all 26 passed, the failure belongs to the regressions item.

## Verification

**Commands:**
- `pwsh -NoProfile -File tests/Test-TestReport.ps1` and the same under `powershell.exe` -- expected: all matrix rows pass on PowerShell 7 and Windows PowerShell 5.1.
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` in this checkout with its retained stack -- expected: exits non-zero; the report shows prerequisites `fail`, the other test checks `not run`, and the retained stack untouched.
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` twice back-to-back in the disposable worktree -- expected: `PASS FULL PASS`, verdict `PASS`, and exit 0 both times, with no leftover volumes, containers, or `.generated`.
- Manifest digest recomputed under both PowerShell versions, plus the CI-equivalent parse, JSON, `git diff --check`, and learning checks -- expected: identical digest, no failures.

## Suggested Review Order

**Report lifecycle in the one command**

- Entry point: the catalog loads and the report starts before the single `try`.
  [`run.ps1:42`](../../tests/run.ps1#L42)

- The report is written after cleanup, and a save failure cannot hide the real error.
  [`run.ps1:478`](../../tests/run.ps1#L478)

- The exit code must agree with the report verdict.
  [`run.ps1:482`](../../tests/run.ps1#L482)

- A failing cleanup step is captured instead of skipping the report.
  [`run.ps1:476`](../../tests/run.ps1#L476)

**Fail-fast attribution**

- Notices decide pass, fail, or not run, and setup failures stay on E01.
  [`TestReport.ps1:68`](../../tests/TestReport.ps1#L68)

- The check in progress fails; a failure between checks is labeled.
  [`TestReport.ps1:91`](../../tests/TestReport.ps1#L91)

- Stderr is captured as plain lines, so notices and errors attribute reliably on 5.1.
  [`run.ps1:194`](../../tests/run.ps1#L194)

- A temp-table trigger emits per-scenario passes, and a marker ends the preamble.
  [`runtime.sql:7`](../../tests/runtime.sql#L7)

- The execution order must match the catalog exactly, with no duplicates.
  [`run.ps1:104`](../../tests/run.ps1#L104)

**Secret safety**

- Registered secrets and base64 forms are redacted, plus secret-shaped hex.
  [`TestReport.ps1:50`](../../tests/TestReport.ps1#L50)

- The self-check refuses to save a report that still contains a secret, even split by whitespace.
  [`TestReport.ps1:131`](../../tests/TestReport.ps1#L131)

- Every generated password and token is registered as soon as it exists.
  [`run.ps1:122`](../../tests/run.ps1#L122)

**Prerequisites and portability**

- Required tools, Docker engine, Compose, and the report self-test are checked before anything starts.
  [`run.ps1:53`](../../tests/run.ps1#L53)

- A byte-order key sort makes the release digest identical on PowerShell 5.1 and 7.
  [`run.ps1:33`](../../tests/run.ps1#L33)

**Reliability gate finding**

- The starvation fixture reset now also resets the durable due cursor, which removes the busy=100 flake.
  [`run.ps1:215`](../../tests/run.ps1#L215)

**Peripherals**

- Plain-language scenario names that the report uses.
  [`pilot-scenarios.json:2`](../../tests/pilot-scenarios.json#L2)

- Docker-free proof of every report edge case.
  [`Test-TestReport.ps1:1`](../../tests/Test-TestReport.ps1#L1)

- Rebound harness inputs; `livePromotionAllowed` stays false.
  [`release-manifest.json:99`](../../release/release-manifest.json#L99)

- The user-facing description of the report and its guarantees.
  [`README.md:27`](../../README.md#L27)
