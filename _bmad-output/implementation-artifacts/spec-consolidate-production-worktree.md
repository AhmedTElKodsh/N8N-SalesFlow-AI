---
title: 'Consolidate the redundant production-delivery worktree into main'
type: 'chore'
created: '2026-08-02'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'e443459b3f46b4aa0d211a202e3c363c6eb86bb0'
context:
  - '{project-root}/docs/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `N8N-SalesFlow-AI-production-delivery` is a third linked worktree whose branch points at the same commit as `main`, but it contains twelve uncommitted production-planning changes. Keeping it creates folder and branch ambiguity; deleting it directly would lose those changes.

**Approach:** Copy only the production worktree's six modified and six untracked files into the same relative paths under `N8N-SalesFlow-AI`, verify every copied file by SHA-256, then remove the redundant worktree and its fully merged local branch. Keep the guided-learning worktree untouched.

## Boundaries & Constraints

**Always:** Preserve all pre-existing dirty files in `main`; copy source files byte-for-byte; verify source and destination hashes before removing anything; retain `main` as direct implementation and `codex/guided-learning` as the isolated learning branch; stop if the source inventory changes or a destination collision appears.

**Ask First:** Any overwrite outside the six currently modified tracked paths; any source/destination hash mismatch; any source commit that no longer equals `main`; any ignored file discovered in the production worktree.

**Never:** Commit, stage, push, reset, or clean user changes; copy linked-worktree `.git` metadata; modify or remove `N8N-SalesFlow-AI-guided-learning`; change production gates such as `livePromotionAllowed=false`; force-delete the production folder before verification succeeds.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Expected consolidation | Same HEAD, twelve known dirty paths, no ignored files | All twelve files exist under `main` with matching SHA-256; source worktree and local branch are removed | N/A |
| Main already has unrelated changes | Existing memlog, DOCX, and root-level Epic 1 drafts | Existing files remain byte-identical unless they are one of the six clean tracked destinations | Stop on unexpected collision |
| Source changes during transfer | Dirty-path list or file hash differs from the captured inventory | Source worktree remains registered and present | Report mismatch; do not delete |
| Worktree removal fails | Files copied and verified but Git rejects removal | Destination remains intact; source folder remains for retry | Report Git error; do not delete branch |

</frozen-after-approval>

## Code Map

- `D:/AI Projects/Gentech/N8N-SalesFlow-AI-production-delivery` — source linked worktree containing the production-only uncommitted artifacts.
- `D:/AI Projects/Gentech/N8N-SalesFlow-AI` — destination `main` worktree; remains the direct-implementation project folder.
- `_bmad-output/planning-artifacts/**`, `_bmad-output/implementation-artifacts/**`, `docs/**` — the twelve source changes to preserve at identical relative paths.
- `D:/AI Projects/Gentech/N8N-SalesFlow-AI-guided-learning` — protected linked worktree; verification target only.

## Tasks & Acceptance

**Execution:**

- [x] Capture the source status, ignored-file check, branch pointers, and SHA-256 inventory; confirm the production branch and `main` still share one HEAD.
- [x] Copy the twelve reported source files to identical relative paths in `main`, creating only required parent directories and preserving unrelated destination changes.
- [x] Recompute SHA-256 for every source/destination pair and require a complete match before deletion.
- [x] Resolve and validate the exact production worktree path, remove it through `git worktree remove --force`, then delete `codex/production-delivery-meta-ingress` with the non-forcing merged-branch check.
- [x] Verify only two worktrees remain and report the final dirty state of `main` without staging or committing it.

**Acceptance Criteria:**

- Given the captured twelve-file source inventory, when consolidation completes, then all twelve destination hashes equal their source hashes.
- Given verified destination copies, when cleanup completes, then the production-delivery folder and local production branch no longer exist.
- Given the final Git worktree list, when inspected, then only `main` and `codex/guided-learning` remain in their two sibling folders.
- Given the pre-existing `main` and guided-learning states, when compared after cleanup, then their unrelated content and branch assignments are unchanged.

## Spec Change Log

- 2026-08-02: After explicit user approval, removed the three superseded root copies and refreshed the canonical nested Epic 1 context before committing the planning package.

## Design Notes

No Git merge was required because both production pointers resolved to `e443459`. The only divergent state was uncommitted filesystem content, so native file copy plus hash verification was the smallest loss-safe operation. The initial preservation pass retained root-level duplicates; a later user-approved cleanup removed them after the organized nested artifacts were verified.

## Execution Evidence

Final-state verification timestamp: `2026-08-02T08:58:42.1013835+03:00`. Immediately before deletion, the source ignored-file audit returned no entries and all twelve source/destination SHA-256 pairs matched. These are the byte-for-byte transfer hashes before post-consolidation review patches:

```text
3acae08f0178fe663478b6a22d569a9a9ed0ec9debbda604ad1e1aee7f866bd5  _bmad-output/planning-artifacts/README.md
328de57b5f97b88b9b02e51665b1ece486089fcadb972f1fc30065d79822d2f5  _bmad-output/planning-artifacts/architecture/architecture-N8N-SalesFlow-AI-2026-07-14/reviews/review-divergence.md
351ee076d369a75d5cb8038a2579b4d99613a989f4ce76a85f721f703a481623  _bmad-output/planning-artifacts/architecture/architecture-N8N-SalesFlow-AI-2026-07-14/reviews/review-reality.md
9648f092fe2273d056988d9f4795749e1c3c034bce451b9077b82b167a876689  _bmad-output/planning-artifacts/prds/prd-N8N-SalesFlow-AI-2026-07-14/reconcile-executive-docx.md
a4bec4cae4d89888baf206f63c1aa56838e5c13dddc5104ebbcd68072569a029  docs/index.md
78f7ba49199190014b8c9f7f6ebd74f0bc85f9bcc7e987fc6b389113920cab4e  docs/project-context.md
9115ea30cb4ed9cfbc065fb3690318d01a178b4ef495f718cc741f7c45afa964  _bmad-output/implementation-artifacts/epic-1/epic-1-context.md
ff4dc9becca7064a8d6254d4165b56b42aebd1e52c876161cbebf0d78fcfd108  _bmad-output/implementation-artifacts/epic-1/spec-1-1-meta-staging-ingress.md
5d481d54373d3728e08d99aa8fba6112f592e59147eb6da296653fff7ebc02f9  _bmad-output/implementation-artifacts/index.md
92e2d360170067fd6bd4849f938d57476508f0b99d68f2ce7e5388a0110ac2f9  _bmad-output/planning-artifacts/index.md
9f2a35b0ae2668798fa18fcea892429577218f00cc4d10c5c401f4c0fc82679d  _bmad-output/planning-artifacts/production-delivery/production-delivery-roadmap.docx
c1d4f5911195d6b49a0931f7016ecef7bc2ab400b623343f7846d0047142e942  _bmad-output/planning-artifacts/production-delivery/sprint-change-proposal-2026-08-01.md
```

Final checks found two registered worktrees only, no production branch ref, no production-delivery folder, no staged changes, and a clean guided-learning worktree.

## Verification

**Commands:**

- `git status --short --branch --untracked-files=all` in both source and destination — expected: captured inventory before removal and preserved consolidated inventory afterward.
- `Get-FileHash -Algorithm SHA256` for each source/destination pair — expected: twelve matches.
- `git worktree list --porcelain` — expected: only `N8N-SalesFlow-AI` on `main` and `N8N-SalesFlow-AI-guided-learning` on `codex/guided-learning`.
- `git show-ref --verify refs/heads/codex/production-delivery-meta-ingress` — expected: missing after cleanup.
- `Test-Path 'D:/AI Projects/Gentech/N8N-SalesFlow-AI-production-delivery'` — expected: `False`.

## Suggested Review Order

**Consolidation contract**

- Start with the approved two-worktree intent and preservation boundaries.
  [`spec-consolidate-production-worktree.md:14`](spec-consolidate-production-worktree.md#L14)

- Confirm the retained twelve-file transfer ledger and final cleanup proof.
  [`spec-consolidate-production-worktree.md:69`](spec-consolidate-production-worktree.md#L69)

**Direct-implementation routing**

- Verify the active Story 1.1 spec now targets `main` only.
  [`spec-1-1-meta-staging-ingress.md:25`](epic-1/spec-1-1-meta-staging-ingress.md#L25)

- Verify the production action plan uses the same branch boundary.
  [`sprint-change-proposal-2026-08-01.md:84`](../planning-artifacts/production-delivery/sprint-change-proposal-2026-08-01.md#L84)

**Artifact navigation**

- Confirm the implementation index labels Story 1.1 as review-required.
  [`index.md:8`](index.md#L8)

- Review the new planning entry point before opening supporting artifacts.
  [`planning-artifacts/index.md:1`](../planning-artifacts/index.md#L1)

- Confirm project context routes readers through both consolidated indexes.
  [`project-context.md:9`](../../docs/project-context.md#L9)

**Deferred document cleanup**

- Review the remaining roadmap Unicode/terminology correction deferred from this cleanup.
  [`deferred-work.md:10`](deferred-work.md#L10)
