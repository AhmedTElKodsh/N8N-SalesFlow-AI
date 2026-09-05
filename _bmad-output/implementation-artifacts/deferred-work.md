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
