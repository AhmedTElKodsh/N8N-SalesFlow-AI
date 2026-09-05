---
title: 'Fix Whole-Repository Review Findings'
type: 'bugfix'
created: '2026-09-03'
status: 'in-progress'
review_loop_iteration: 0
baseline_commit: '0ac5bbbd0b406303744427a0c7da6b2af047f33a'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/learning/tutor-contract.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The whole-repository review found privacy, relational-integrity, authorization-race, trusted-time, migration, test-bounding, learner-protocol, documentation, evidence, isolation, and CI gaps despite the current synthetic-local release passing its canonical harness.

**Approach:** Correct all verified findings as one hardened repository bundle, preserving PostgreSQL authority, legacy evidence, learner ownership, reproducible Windows/PowerShell operation, release-v10 compatibility where safe, and the promotion-disabled boundary.

## Boundaries & Constraints

**Always:** Preserve existing staged and unstaged work; fail closed with typed outcomes; serialize authority-sensitive operations in Conversation-first order; use trusted database time; preserve malformed legacy evidence in terminal form; keep migrations idempotent; use UTF-8 byte limits; update tests and release hashes with executable changes; finish with focused checks, one canonical harness, and independent frozen reviews.

**Ask First:** Any real Meta, LLM, Handoff-provider, managed-infrastructure, credential, deployment, production activation, branch rewrite, commit, push, destructive reset, or project-volume deletion.

**Never:** Inspect or expose `reference/salesflow-complete-v1`; add runtime dependencies; weaken privacy, idempotency, authorization, evidence, or cleanup gates; store secrets; claim external-provider proof; set `livePromotionAllowed` true.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Consent | deleted Contact, NULL status, or oversized evidence | no plaintext write; 8192-byte maximum accepted | typed `deleted` or `invalid_input` |
| Relationships | mismatched Contact/Conversation/source tuple | new write rejected; legacy terminal evidence retained | constraint/typed failure without partial state |
| Handoff | concurrent authority change or forged time | ordered locks and post-lock trusted-time authorization | typed busy/denial; no stale side effect |
| Retention | malformed, non-string, or future `at` | no data mutation | typed `invalid_input` |
| Migration | special-character passwords, existing roles, alternate database | safe rotation and current-database grants | atomic rollback on failure |
| Learning | stale SQL definition, skipped prerequisite, wrong lineage, direct help, hung child | effective definition, ordered gates, starter ancestry, extra transfer proof, bounded termination | classified failure without progress mutation |
| Local stack | parallel checkout or occupied default port | unique Compose identity and dynamically assigned loopback port | fail with actionable diagnostic |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` -- durable schema, authority, migration, consent, Handoff, retention, and configuration enforcement.
- `tests/runtime.sql`, `tests/run.ps1` -- focused SQL/race/migration evidence and canonical lifecycle.
- `scripts/LearningState.psm1`, `scripts/learn.ps1`, `scripts/Invoke-LearningCheckpoint.ps1` -- learner state, lineage, transfer, and timeout enforcement.
- `tests/learning/**` -- provider-free regression and curriculum acceptance proof.
- `compose.yaml`, `README.md`, `.github/workflows/provider-free.yml` -- isolated local operation and CI.
- `docs/**`, `_bmad-output/implementation-artifacts/test-evidence.md` -- observed-state and snapshot evidence.
- `release/release-manifest.json`, `config/release-set.json` -- exact promotion-disabled release binding.

## Tasks & Acceptance

**Execution:**
- [x] `database/001-initial.sql`, `tests/runtime.sql`, `tests/run.ps1` -- reject post-deletion/NULL/oversized consent, enforce tuple consistency, guard inbound deletion, bound configuration, serialize Handoff with trusted time, validate retention time, and add proof for every boundary including both race orders.
- [x] `database/001-initial.sql`, `README.md`, `tests/run.ps1` -- use safe encoded password transport, rotate existing roles, and grant the current database; add special-character rotation and legacy migration-idempotence proof.
- [x] `tests/learning/checkpoints/CheckpointSupport.ps1`, `scripts/LearningState.psm1`, `scripts/learn.ps1`, `scripts/Invoke-LearningCheckpoint.ps1`, `tests/learning/**` -- resolve effective SQL definitions, enforce prerequisites/lineage/direct-help transfer, reconcile M10 lifecycle, and bound child/jobs without mutating failed progress.
- [x] `compose.yaml`, `tests/run.ps1`, `tests/learning/checkpoints/Test-M01.ps1`, `README.md`, `docs/*.md` -- isolate checkout identity and dynamic loopback port while correcting architecture/current-state documentation.
- [x] `.github/workflows/provider-free.yml` -- run non-secret parsing, manifest, Compose-config, and learning checks on supported runners.
- [x] `_bmad-output/implementation-artifacts/test-evidence.md`, `release/release-manifest.json`, `config/release-set.json` -- record reproducible snapshot/transcript identity, recompute bindings in dependency order, and retain `livePromotionAllowed=false`.

**Acceptance Criteria:**
- Given every reviewed invalid, concurrent, malformed, legacy, or timeout state, when its public path executes, then it returns bounded fail-closed evidence with no unauthorized, cross-history, plaintext, premature-retention, or leaked-lock outcome.
- Given valid existing behavior, when focused and canonical suites execute, then prior scenarios remain green, migrations apply twice, special-character credential rotation works, seven workflows remain release-bound, cleanup succeeds, and no external-provider claim is added.
- Given any learning command, when progress or Git lineage violates the curriculum, then it fails without mutation; valid learner branches and legacy progress remain usable, with an additional transfer gate after direct help.
- Given two same-named checkouts, when local stacks or checks run, then Compose resources and ports do not collide.

## Spec Change Log

- 2026-09-03: Implemented all six execution slices. Fresh provider-free/static checks pass; Docker-backed canonical verification and the final frozen runtime review remain pending because the Docker Desktop Linux engine is unavailable.

## Verification

**Commands:**
- Provider-free PowerShell, JSON, JavaScript, Compose-config, and learning suites -- expected: all pass with no secrets or live calls.
- Focused PostgreSQL migration/runtime/race checks -- expected: new boundaries pass and legacy evidence survives.
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: `PASS FULL PASS`, snapshot evidence, credential cleanup, volume cleanup, exact hashes, and `livePromotionAllowed=false`.
- Fresh read-only adversarial and Edge Case Hunter passes on the frozen post-harness snapshot -- expected: no unresolved correctness finding.

**Current evidence:** Provider-free learning suites, JSON parsing, PowerShell parsing, manifest hashing, Compose configuration, and diff integrity pass. Docker-backed commands remain unexecuted on this snapshot because the Docker Desktop Linux-engine named pipe is unavailable.
