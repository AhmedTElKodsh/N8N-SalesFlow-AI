---
title: 'Restore cross-platform release verification'
type: 'bugfix'
created: '2026-08-18'
status: 'done'
review_loop_iteration: 0
baseline_commit: '35d53e1'
context:
  - '{project-root}/docs/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-sp2-t3-gather-response-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** After merging `codex/stable-customer-identity` into `main`, the canonical harness stops before runtime verification. Windows `core.autocrlf=true` changes release-input bytes at checkout, while the release-v7 manifest also retains pre-hardening hashes for the three SP2-T3 files changed last: the migration, harness, and runtime assertions.

**Approach:** Declare LF checkout semantics for every text input covered by the release manifest, refresh only the stale release-v7 digests and their Release Set binding from committed-form bytes, and rerun the canonical harness from the native Windows worktree.

## Boundaries & Constraints

**Always:** Preserve byte-exact release integrity rather than weakening checks through runtime normalization. Keep `release-v7`, the current workflow identities, pinned images, policy and knowledge versions, and `livePromotionAllowed=false`. Update both activation and outer copies of changed input hashes; recompute the PostgreSQL-jsonb activation digest, update the Release Set binding, and then update its outer input hash. Keep repository files free of credentials and generated runtime artifacts.

**Ask First:** Advancing the release version; changing deployable behavior, tests, workflow exports, database semantics, production promotion posture, or machine-wide Git configuration; discarding any user-owned work.

**Never:** Disable hash verification, hash CRLF-normalized content at test time, exclude changed release inputs, rewrite unrelated repository files, connect production services, or push/commit without a separate request.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Windows checkout | Global `core.autocrlf=true` and a fresh/renormalized checkout | Manifest-bound text inputs remain LF and byte hashes match | Harness names the exact mismatched path and exits nonzero |
| SP2-T3 final artifacts | Current `database/001-initial.sql`, `tests/run.ps1`, and `tests/runtime.sql` | Activation and outer hashes match the final Git content | Any stale copy or activation digest fails before runtime mutation |
| Release Set binding | Updated activation manifest | `config/release-set.json` binds its exact jsonb digest and its outer hash matches | Runtime release activation rejects any mismatch |
| Existing Windows worktree | Clean files already materialized as CRLF | Targeted release inputs are safely re-materialized as LF | Do not overwrite a dirty worktree |

</frozen-after-approval>

## Code Map

- `.gitattributes` -- repository-owned LF checkout contract for manifest-bound text inputs.
- `release/release-manifest.json` -- activation/outer input hashes, activation digest, and unchanged workflow/release metadata.
- `config/release-set.json` -- reviewed activation-manifest digest consumed by release activation.
- `tests/run.ps1` -- canonical preflight and full disposable Docker/PostgreSQL/n8n verification harness.

## Tasks & Acceptance

**Execution:**
- [x] `.gitattributes` -- add targeted `text eol=lf` rules for all manifest-bound text input paths so Git checkout bytes are stable across Windows and Unix.
- [x] `release/release-manifest.json` and `config/release-set.json` -- regenerate the three stale hashes, activation jsonb digest, Release Set binding, and outer Release Set hash in dependency order without changing release-v7 behavior.
- [x] Native worktree -- re-materialize only manifest-bound tracked inputs under the new attributes after proving the worktree is clean.
- [x] `_bmad-output/implementation-artifacts/spec-restore-release-verification.md` -- record final evidence and review outcome.

**Acceptance Criteria:**
- Given a clean Windows checkout with `core.autocrlf=true`, when release inputs are checked out and `tests/run.ps1` executes, then every manifest hash passes without normalization or disabled checks.
- Given final SP2-T3 artifacts, when activation binding is recomputed, then both manifest copies, the jsonb activation digest, and Release Set outer hash are internally exact.
- Given the canonical disposable harness, when verification completes, then it reports `PASS FULL PASS`, cleans generated credentials/volumes, and leaves only intentional source changes.

## Spec Change Log

- 2026-08-18 implementation: Added explicit LF checkout rules for all 24 manifest inputs, re-materialized the eight inputs that contained CRLF only after confirming no tracked changes, and refreshed the release-v7 integrity chain. Focused byte checks and the canonical harness passed; independent adversarial review remains the next workflow gate.
- 2026-08-18 adversarial review: Anchored the two root-file patterns, added a durable preflight assertion for every manifest path's `text eol=lf` contract, and recomputed the activation jsonb digest before runtime mutation. The final harness passed after the dependent release hashes were regenerated. Review notes about old CRLF clones were rejected because the approved boundary is fresh/explicitly re-materialized checkouts; Git's temporary stat-only status for those intentional LF rewrites is documented below.

## Design Notes

The activation digest is SHA-256 over PostgreSQL `jsonb` textual form, whose object-key order is length-then-bytewise with spaces after separators. `config/release-set.json` is intentionally excluded from the activation input set to avoid a digest cycle, but its finalized bytes remain covered by the outer manifest.

The final SP2-T3 input hashes are `49574c11920e0d81e3faebf3dc07eb96a8c5a27c9ed5d72da9823d6538f14926` for the migration, `3a2fbdcf5dd1e52970b4e34e5df300982a6d62692ce1d355ae2da6feb26ce7b9` for the hardened harness, and `1f567463dfb9d8beb514f7aca38ecbbfe09319751a69296ac82126e1d5589c25` for the runtime assertions. Their activation jsonb digest is `ccaf082243a200c3f9f273ad5abca1ef9ad356a903a176c77da2cf3fa1413358`; the finalized Release Set file hash is `2535259c68b0749a59cf0944760cd6557a0fb6936a8c90a2cf18c7c96d91020c`.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: `PASS FULL PASS` and exit code 0 from the native Windows worktree.
- `git diff --check` -- expected: no whitespace errors.
- `git status --short` and `git diff --name-only` -- expected: only the attribute contract, release binding, implementation spec, and intentional LF re-materialization appear; the semantic tracked diff remains limited to the release binding and hardened harness, with no generated secrets or runtime artifacts.

**Results (2026-08-18):**
- Focused integrity audit passed all 24 raw input hashes, both copies of the 23 activation hashes, the PostgreSQL-jsonb activation digest, the Release Set binding, exact root-only attributes, all 24 durable LF preflight checks, and absence of CR bytes.
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` exited `0` with `PASS FULL PASS`, `PASS plaintext generated credentials removed`, and `PASS container volumes removed`.
- Blind and edge-case adversarial review produced three actionable patch findings, all resolved before the final full pass; no high-severity or deferred finding remained.
- `git diff --check` passed. No `.env`, `.generated`, or Docker-volume artifacts remained. Until `.gitattributes` enters the index, Git may list the eight intentional LF re-materializations as stat-only modifications even though their raw hashes equal the index blobs and they have no semantic diff.

## Suggested Review Order

**Cross-platform integrity preflight**

- Start with the jsonb-compatible serializer that catches a stale activation digest early.
  [`run.ps1:11`](../../tests/run.ps1#L11)

- Then inspect the pre-mutation digest, LF-attribute, and byte-hash enforcement.
  [`run.ps1:47`](../../tests/run.ps1#L47)

- Confirm every manifest-bound path has an exact checkout policy.
  [`.gitattributes:1`](../../.gitattributes#L1)

**Release binding**

- Verify the activation digest reflects the final hardened harness.
  [`release-manifest.json:91`](../../release/release-manifest.json#L91)

- Verify the outer manifest binds the finalized Release Set bytes.
  [`release-manifest.json:124`](../../release/release-manifest.json#L124)

- Confirm Release Set review authority points to the activation digest.
  [`release-set.json:1`](../../config/release-set.json#L1)

**Acceptance evidence**

- Finish with full-suite, cleanup, and adversarial-review evidence.
  [`spec-restore-release-verification.md:78`](spec-restore-release-verification.md#L78)
