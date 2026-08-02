- source_spec: `_bmad-output/implementation-artifacts/spec-local-self-hosted-n8n.md`
  summary: Make the Docker Compose project identity checkout-specific instead of relying on the existing folder-derived label.
  evidence: The inherited `n8n-salesflow-ai` label can collide with another checkout sharing the same directory basename; one local checkout is the current supported ceiling.

- source_spec: `_bmad-output/implementation-artifacts/spec-local-self-hosted-n8n.md`
  summary: Define immutable release-version rotation rules in addition to the existing content hash identity.
  evidence: The activation content hash is authoritative and verified, but the existing `release-v1` semantic label can cover refreshed synthetic-local harness content.

- source_spec: `_bmad-output/implementation-artifacts/spec-consolidate-production-worktree.md`
  summary: Repair visible Unicode substitutions and stale Sprint terminology in the production-delivery roadmap DOCX while preserving its format.
  evidence: The copied DOCX is structurally valid but contains visible question-mark substitutions and one retained Sprint 1 reference in a stage-based roadmap.
