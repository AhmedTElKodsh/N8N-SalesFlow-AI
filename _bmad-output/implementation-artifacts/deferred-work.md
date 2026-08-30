- source_spec: `_bmad-output/implementation-artifacts/spec-local-self-hosted-n8n.md`
  summary: Make the Docker Compose project identity checkout-specific instead of relying on the existing folder-derived label.
  evidence: The inherited `n8n-salesflow-ai` label can collide with another checkout sharing the same directory basename; one local checkout is the current supported ceiling.

- source_spec: `_bmad-output/implementation-artifacts/spec-local-self-hosted-n8n.md`
  summary: Define immutable release-version rotation rules in addition to the existing content hash identity.
  evidence: The activation content hash is authoritative and verified, but the existing `release-v1` semantic label can cover refreshed synthetic-local harness content.

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
