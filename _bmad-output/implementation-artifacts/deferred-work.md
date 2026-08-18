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
