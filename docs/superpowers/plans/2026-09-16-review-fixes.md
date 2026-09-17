# September project review fixes implementation plan

> For agentic workers: use superpowers:subagent-driven-development to implement and review the bounded tasks below.

**Goal:** Address all twelve concerns from the September 16 project review and finish a follow-up review with explicit verification limits.

**Architecture:** PostgreSQL remains the authority for account isolation, evidence, and recovery. Native n8n nodes handle bounded orchestration and typed responses; PowerShell manages reproducible local tests and credential renewal. Production promotion stays disabled.

**Tech stack:** PostgreSQL, n8n, PowerShell, Docker; no new runtime dependency.

**Spec:** September 16 review at `C:/Users/hp/AppData/Local/Temp/salesflow-project-review-2026-09-16.md`; user authorized all fixes and refinements.

## Constraints and execution decisions

- Direct-solution assistance explicitly requested for this corrective task. No learner milestone is active or completed. Reconstruction, explanation, and transfer evidence remain required before crediting a learning milestone.
- Use only PowerShell and Docker for executable scripts. No reference-branch access or secret output. No retained-stack reset.
- Work on `codex/september-review-fixes` in the existing checkout; unrelated untracked client directories remain untouched.
- Docker is currently unavailable. Write executable database and workflow regressions, attempt prerequisites, and distinguish authored checks from executed checks. Do not substitute text matching for runtime proof.
- Keep changes in the established migration and native workflow topology. Review effective final SQL definitions.

## Task 1: Database authority, evidence, and recovery

Files: `database/001-initial.sql`, new `tests/review-fixes.sql` and focused runner if needed.

- [ ] Add executable regressions for expired-started Handoff recovery, cross-account scoped scheduler calls, replay after retention/deletion, non-fixture Follow-Up provenance, and same-account tuple mismatches.
- [ ] Persist Handoff reconciliation failure evidence once; remove it from automatic retry selection without releasing Human-Owned lockout.
- [ ] Enforce token account scope at scheduler discovery and every outbound lifecycle boundary while retaining deliberately global scheduler support.
- [ ] Preserve privacy-compatible replay identity through minimization, including changed-body/sender conflict detection.
- [ ] Snapshot approved Follow-Up provenance, bind it into request identity, and validate children against their parent snapshot.
- [ ] Enforce related Contact/Conversation/source tuples for owner/backfill writes without breaking minimization or rerunnable migration.
- [ ] Review schema changes, function grants, migration idempotence, and authored regression coverage.

## Task 2: Workflow contracts and deterministic integration tests

Files: workflows 01/03/05/06, `tests/run.ps1`, workflow regression helpers as needed.

- [ ] Change history webhook paths to explicit response nodes with typed HTTP failures, preserving Execute Workflow behavior.
- [ ] Replace unknown scheduler work pass-through with a token-free typed terminal.
- [ ] Decouple persisted-ingress acknowledgement and scheduler dispatch from child completion; adapt tests to bounded observation of durable state.
- [ ] Exercise retryable, permanent, and ambiguous adapter outcomes through synthetic live workflow fixtures whose activation is restricted to the test environment.
- [ ] Replace the starvation fixture's ten-second lifetime with an explicit observation/release handshake plus bounded cleanup.
- [ ] Wire the database corrective regression suite into canonical verification and report it in the existing database-regression stage.

## Task 3: Secret-safe report handling

Files: `tests/TestReport.ps1`, `tests/Test-TestReport.ps1`.

- [ ] Add a regression using a registered synthetic secret straddling the detail cap; observe it fail.
- [ ] Redact before truncating while preserving deduplication and bounded messages.
- [ ] Test raw/base64/hex secrets through printable and saved report paths; run all reporter checks.

## Task 4: Retained-stack credential lifecycle and release evidence

Files: new `scripts/Renew-LocalTokens.ps1`, corresponding focused tests, README/operator docs, release manifest and release-set binding.

- [ ] Provide explicit local owner-authorized renewal of existing non-revoked tokens, scoped to the validated checkout Compose project; do not print or return secrets, extend production tokens, or reset data.
- [ ] Cover renewal SQL/authorization in executable database tests and test command validation in PowerShell.
- [ ] Document expiry, safe renewal, and the retained local stack boundary.
- [ ] Recompute workflow canonical identity and all manifest input/activation hashes using repository-compatible serialization. Keep `livePromotionAllowed=false`.
- [ ] Update deferred-work entries and review disposition/evidence with verified current outcomes.

## Task 5: Combined verification and final review

- [ ] Run focused PowerShell checks, parse all changed scripts/JSON, check manifest hashes, and run `git diff --check`.
- [ ] Attempt Docker availability and run focused SQL plus canonical suite when available. State cost before any container build/full suite.
- [ ] Independent review of database and workflow contracts plus verification coverage; resolve confirmed findings.
- [ ] Record what passed, what could not run, and any remaining uncertainty; do not declare full integration success without execution evidence.

## Task interfaces and ownership

| Tasks | Shared interface | Decision |
| --- | --- | --- |
| 1 and 2 | tests/review-fixes.sql, existing SQL workflow entrypoints | Database worker owns SQL; workflow worker wires tests after file is ready. |
| 1 and 4 | auth_tokens table | Renewal uses owner-only local database access and existing non-revoked rows; no changes to runtime token lifetime defaults. |
| 2 and 3 | TestReport functions invoked by run.ps1 | Public reporter function signatures remain unchanged. |
| 1–4 and 5 | manifest/harness inputs | Parent refreshes release identity only after workers finish. |

Each task's checks correspond to its observable contract. Docker-dependent checks remain pending until the environment supports execution; this limitation does not authorize weakening assertions.

### Review Findings

Code review of the uncommitted implementation (2026-09-16), diff vs HEAD `327d261`.

- [x] [Review][Patch] Concurrent-insert race path returns `idempotency_conflict` instead of `replay_identity_unavailable` when the fingerprint match is unavailable [database/001-initial.sql:244]
- [x] [Review][Patch] Handoff claim/finish denial reasons outside the status map fall through to HTTP 200, and only the conversation-history sub-route has a status-code test [workflows/06-handoff-dispatcher.json:1]
- [x] [Review][Patch] Unguarded `JSON.parse($env.SALESFLOW_SYNTHETIC_OUTCOMES)` throws instead of falling back to `success` on malformed input [workflows/03-outbox-dispatcher.json:1, workflows/06-handoff-dispatcher.json:1]
- [x] [Review][Patch] `Test-ReviewFixes.ps1`'s cleanup `throw` in `finally` can mask the real test failure that triggered it [tests/Test-ReviewFixes.ps1:33]
- [x] [Review][Patch] `review-fixes-2026-09-16.md`'s disposition table doesn't flag which rows are "authored, not run" as clearly as the prose below it [_bmad-output/implementation-artifacts/review-fixes-2026-09-16.md:9]
- [x] [Review][Patch] Async-ingest docs don't name a caller-facing mechanism for observing the eventual dispatch outcome [docs/api-contracts.md:20]
- [x] [Review][Patch] `.env.example` doesn't declare `SALESFLOW_SYNTHETIC_TEST_MODE`/`SALESFLOW_SYNTHETIC_OUTCOMES`, which `compose.yaml` and the deployment guide now reference [.env.example:1]

#### Rejected

- `false` — `followup_child_evidence_valid`'s `f.provenance_snapshot||...` producing NULL on a legacy NULL snapshot does not vacuously pass: `intents.provenance` is `NOT NULL`, so `i.provenance IS NOT DISTINCT FROM NULL` is always false, and the row is correctly rejected. [database/001-initial.sql:532]
- `false` — `LocalTokenRenewal.psm1`'s strict `.env` line parser is deliberate fail-closed design consistent with its own surrounding allowlist checks (exact `POSTGRES_DB`/`POSTGRES_SUPERUSER`/`TEST_WHATSAPP_ACCOUNT_REF` match, hex-64 token checks); the harness never emits a non-matching line, and the doc string explicitly restricts renewal to a harness-created file. [scripts/LocalTokenRenewal.psm1:11]
- `false` — the `SALESFLOW_SYNTHETIC_TEST_MODE`/`SALESFLOW_SYNTHETIC_OUTCOMES` wiring is not an externally reachable "kill switch": both env vars default to empty in `compose.yaml`, are read only via `$env.*` (container-environment-controlled, never from request/webhook data), and the project has no live WhatsApp/AI provider yet for this to subvert. Reaching it requires the same container-environment access that already implies full compromise. [workflows/03-outbox-dispatcher.json:1]
- `false` — `Test-WorkflowReview.ps1` having no `param()` block and relying on ambient caller variables matches this codebase's established dot-sourcing convention (`TestReport.ps1` and `WorkflowReviewHelpers.ps1` do the same), not a regression introduced by this diff. [tests/Test-WorkflowReview.ps1:1]
- `low`, rejected — the unbatched single-transaction `inbound_replay_identities` backfill is a real future-production concern, but the project has no production data yet (`livePromotionAllowed=false`), so it's unlikely to be hit in current everyday use, and a proper fix (batched/throttled backfill with progress tracking) is more than a direct correction. [database/001-initial.sql:225]
- `low`, rejected — reordering `release/release-manifest.json`'s `inputHashes` keys into full alphabetical order (from the prior semi-grouped order) makes diffs noisier, but the file's key order has no functional effect (the verifier compares by key, not position) and preserving insertion order while inserting new keys would require generator changes beyond a direct correction. [release/release-manifest.json:74]
- `false` — `f.provenance_snapshot` NULL handling for `followup_evidence_valid` was not separately checked; see the `followup_child_evidence_valid` rejection above, which covers the same `NOT NULL`-on-`intents.provenance` guarantee.
- Not raised as a formal finding — the diff's own artifacts (`review-fixes-2026-09-16.md`, `README.md`, `deferred-work.md`) already and prominently disclose that Docker was unavailable and none of the new SQL/workflow behavior was runtime-verified in this diff. This is accurately self-reported, not a hidden gap, so it isn't actionable as a code-review finding on its own.
