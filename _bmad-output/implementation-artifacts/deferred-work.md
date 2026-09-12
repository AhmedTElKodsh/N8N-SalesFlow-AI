- source_spec: `_bmad-output/implementation-artifacts/spec-local-self-hosted-n8n.md`
  summary: Make the Docker Compose project identity checkout-specific instead of relying on the existing folder-derived label.
  evidence: The inherited `n8n-salesflow-ai` label can collide with another checkout sharing the same directory basename; one local checkout is the current supported ceiling.

- source_spec: `_bmad-output/implementation-artifacts/spec-local-self-hosted-n8n.md`
  summary: Define immutable release-version rotation rules in addition to the existing content hash identity.
  evidence: The activation content hash is authoritative and verified, but the existing `release-v1` semantic label can cover refreshed synthetic-local harness content.

- source_spec: `_bmad-output/implementation-artifacts/spec-consolidate-production-worktree.md`
  summary: Repair visible Unicode substitutions and stale Sprint terminology in the production-delivery roadmap DOCX while preserving its format.
  evidence: The copied DOCX is structurally valid but contains visible question-mark substitutions and one retained Sprint 1 reference in a stage-based roadmap.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp2-t3-gather-response-context.md`
  summary: Prevent consent evidence from being written after Contact deletion and serialize deletion with consent changes.
  evidence: `set_consent` accepts any retained Contact UUID, while deletion keeps the Contact row and does not acquire the account/Contact consent advisory lock, so a runtime write can recreate plaintext evidence after minimization or race the deletion transaction.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp2-t3-gather-response-context.md`
  summary: Enforce intra-account Contact, Conversation, source-message, intent, Follow-Up, and Handoff tuple consistency in PostgreSQL.
  evidence: Composite account foreign keys prevent cross-account references, but current tables do not constrain all related IDs to describe the same Contact and Conversation, leaving owner/backfill code able to splice histories within one account.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp2-t3-gather-response-context.md`
  summary: Correct the architecture claim that source workflows contain no Code nodes.
  evidence: Workflow 01 contains two allowlisted synthetic-local Code nodes, so `docs/architecture.md` currently overstates the node-safety boundary even though the manifest and promotion gate identify the topology honestly.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp2-t3-gather-response-context.md`
  summary: Harden the consent command's typed input and storage limits.
  evidence: SQL NULL status can fall through to a constraint exception and authenticated callers can submit unbounded nonblank consent evidence; both behaviors pre-date SP2-T3 and need an approved evidence-size limit plus typed rejection tests.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp2-t3-gather-response-context.md`
  summary: Add durable source-state identity and sanitized output attestation for canonical full-suite runs.
  evidence: The evidence document records the command, result, runtime, and scope but retains no commit/worktree digest or hashed sanitized transcript proving that a reported run exercised the exact reviewed diff.

- source_spec: `_bmad-output/implementation-artifacts/spec-task-7-focused-learning-checkpoints.md`
  summary: Close the M02 typed accepted and eventId response evidence gap before publishing the completed reference.
  evidence: The hardened M02 checkpoint correctly fails because the current ingest contract returns inbound_id and has no executed typed eventId assertion.

- source_spec: `_bmad-output/implementation-artifacts/spec-task-7-focused-learning-checkpoints.md`
  summary: Enforce and observe immutable inbound evidence for M03 before publishing the completed reference.
  evidence: The existing schema has evidence columns but no ordinary update or delete rejection mechanism and no runtime proof of immutability.

- source_spec: `_bmad-output/implementation-artifacts/spec-task-7-focused-learning-checkpoints.md`
  summary: Add executed M08 service-window template-window quiet-hours and scheduler routing evidence.
  evidence: The strengthened checkpoint found no runtime assertions proving the declared time and human-ownership outcomes.

- source_spec: `_bmad-output/implementation-artifacts/spec-task-7-focused-learning-checkpoints.md`
  summary: Close M09 retention active-release rollback and actionable-alert runtime evidence gaps.
  evidence: The current completed implementation lacks executable observed retention enforcement and sufficient runtime proof for the remaining responsible-operations outcomes.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp3-t3-automatic-follow-up-system.md`
  summary: Make learning checkpoint SQL extraction resolve the effective final function definition regardless of CREATE versus CREATE OR REPLACE syntax.
  evidence: CheckpointSupport.ps1 currently ignores plain CREATE FUNCTION replacements, so M06-M08 can inspect stale earlier migration bodies instead of the deployed definitions.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp3-t3-automatic-follow-up-system.md`
  summary: Reconcile the M10 running-stack prerequisite with the disposable canonical harness precondition.
  evidence: M10 requires M01 to observe running services and then launches a harness that refuses an existing checkout environment or may collide on port 5678.

- source_spec: `_bmad-output/implementation-artifacts/spec-sp3-t3-automatic-follow-up-system.md`
  summary: Enforce curriculum prerequisite ordering when validating and starting learning milestones.
  evidence: Learning progress validation accepts a manually available later milestone without proving completion of its declared predecessors and understanding gates.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Resolve Follow-Up intent provenance from the active Sales Policy and Product Knowledge instead of the literal `source-1`/`offer-1`/`service-count` object.
  evidence: `schedule_followups` builds, and the IMMUTABLE `followup_child_evidence_valid` requires, that exact literal provenance. Replies now resolve it from configuration, so an account without `offer-1` gets every Follow-Up denied `offer_invalid`, and an account with `offer-1` but other source IDs sends Follow-Ups whose evidence cites a source it does not have. The fix needs the resolved offer/sources snapshotted on the `followups` row and bound into its request hash.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Return HTTP status codes from the Workflow 06 Conversation history route.
  evidence: Workflows 04 and 07 map typed reasons to 403/404/409/503, but the history route uses `responseMode: lastNode`, so unauthorized and malformed reads return HTTP 200 with a typed error body and are invisible to status-based monitoring. The fix needs `responseNode` Respond nodes on every Workflow 06 webhook path without affecting its Execute Workflow entry, plus harness updates at the three history assertions that currently rely on `Invoke-RestMethod` succeeding.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Decouple webhook acknowledgement and scheduler ticks from synchronous downstream work.
  evidence: Workflow 01 runs the orchestrator, and Workflow 05 runs every dispatch, with `waitForSubWorkflow: true`; the 15-second statement timeout covers only the claim query. Leases prevent duplicate sends, but a real provider latency will delay the Meta acknowledgement past its retry window and let one-minute scheduler executions overlap.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Reject signed test-intake messages older than an approved replay window.
  evidence: The validator rejects timestamps more than five minutes in the future but accepts any past timestamp; replays are contained only by provider-ID uniqueness. A new typed reason needs a harness case and an update to the exact rejection-reason set and count asserted at `tests/run.ps1:417`.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Replace source-text regex guards with behavioral or effective-definition checks.
  evidence: About 24 harness assertions match migration or compose text; `tests/run.ps1:58` requires `N8N_BLOCK_ENV_ACCESS_IN_NODE: "false"`, so hardening that setting fails the suite, and phrasing changes fail while semantic inversions can pass.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Exercise non-success adapter outcomes through the live workflows.
  evidence: The Workflow 03 and 06 synthetic adapters always emit `success`, so retry, backoff, ambiguous, and reconciliation paths are proven only by direct SQL fixtures, never through n8n.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Collapse superseded function definitions out of `database/001-initial.sql`.
  evidence: Seventeen functions are defined two or three times in the same migration; earlier bodies are dead on arrival but still parse, appear in search, and require the duplicate-signature boundary assertion in `tests/run.ps1`.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Remove the scheduler token from the Workflow 05 unknown-work terminal response.
  evidence: The no-work row is token-free by query design, but a returned row with an unrecognized `workflow_id` reaches the pass-through `Unknown Work Type` NoOp and echoes the scheduler token; the fix must keep `workflow_id` in the no-work response asserted at `tests/run.ps1:395`.

- source_spec: `_bmad-output/party-mode` Code Review Crew full-repository review, 2026-09-11
  summary: Declare or remove the undeclared ripgrep dependency in the canonical harness.
  evidence: `tests/run.ps1:71` shells out to `rg` for the function-signature scan, but the README lists only Docker Desktop and PowerShell as requirements; on a host without ripgrep on PATH the suite aborts with CommandNotFoundException after 273 passing assertions, before any Docker environment is created. Either document the dependency or use `Select-String`.
