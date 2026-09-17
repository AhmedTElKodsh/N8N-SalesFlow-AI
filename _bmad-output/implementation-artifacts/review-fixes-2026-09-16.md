# September 16 corrective work and review disposition

Base: `327d261`; working branch: `codex/september-review-fixes`.

The user explicitly requested implementation of all September 16 review findings and completion of the follow-up review. Direct-solution assistance is recorded for this corrective task. No learner milestone was opened, advanced, or completed; reconstruction, explanation, and transfer evidence remain necessary before granting learning credit.

## Finding disposition

**Read the "Verification boundary" column literally.** "Authored" or "inspected" means the check exists in source but was **not run** in this change (Docker was unavailable — see Follow-up review below). Only "passed" means it actually executed. Most rows below are authored, not passed.

| Concern | Implemented change | Verification boundary |
| --- | --- | --- |
| Expired started Handoff | Persist reconciliation state and a separate operational failure; preserve the exact claim for late completion and remove automatic rediscovery | SQL recovery, failure visibility, foreign-claim rejection, and late completion assertions authored; SP3-T5 late-result contract retained |
| Scheduler account scope | Scope discovery, reconciliation, cursor namespaces, and outbound lifecycle calls; retain explicitly global schedulers | Cross-account non-disclosure/non-mutation and global recovery assertions authored |
| Replay after minimization | Private keyed fingerprints preserve duplicate/conflict decisions after retention/deletion | Original/body-change/sender-change assertions and runtime privilege checks authored; historical missing identity fails explicitly |
| Retained token expiry | Local owner command renews only the two credentials saved in the harness environment, without reset or secret output | PowerShell settings/hash/transport checks passed; real-migration database renewal tests authored |
| Follow-Up provenance | Snapshot approved offer/source/claim evidence, bind it into request identity, require matching child provenance | Non-fixture business IDs, tampering, and materialized child assertions authored |
| History HTTP failures | Typed HTTP failures with explicit response nodes; internal calls keep typed results | Unauthorized, malformed, and out-of-account HTTP checks authored |
| Adapter failure coverage | Environment-controlled persisted-work UUID map exercises retryable pre-call, failed, ambiguous, and Handoff retry/failure paths | Live n8n assertions authored; fixture config restored in finally; no public outcome selector |
| Unknown scheduler output | Token-free typed fallback and queued-work terminals | Live unknown-work fixture and secret-absence assertions authored |
| Starvation timing | Explicit release signal after measurement with bounded timeout/cleanup | Existing busy-count assertion retained; handshake inspected but not executed |
| Aggregate relationships | Composite Contact/Conversation/source constraints and polymorphic intent-source validation | Owner/backfill mismatch assertions authored; NOT VALID preserves historical rows while enforcing new writes |
| Downstream waits | Ingress/scheduler dispatch asynchronously; responses describe persistence or dispatch | Bounded durable-state observation replaces synchronous-result assumptions; consent-denial assertions retained |
| Report secret fragment | Redact complete values before truncation | Original failure reproduced; raw/base64/hex cases pass through details, console, and saved reports |

The original edge-case findings independently corroborated the Handoff, scheduler scope, and replay concerns above.

## Executed verification

- `tests/Test-TestReport.ps1`: passed, including red/green evidence for the new boundary regression.
- `tests/Test-LocalTokenRenewal.ps1`: passed, including wrong project/account/database, malformed credentials, and remote/ambiguous transports.
- `tests/learning/Test-ManifestHashing.ps1`: passed after release rebinding.
- PowerShell parsing: 37 scripts/modules. JSON parsing: 18 config/workflow/manifest files.
- `git diff --check`: passed.
- PowerShell canonical serialization matched all three unchanged workflow hashes before deriving changed hashes. Activation/input hashes were rebound and `livePromotionAllowed=false` remains enforced. Source identity does not prove imported/exported runtime identity.

## Follow-up review

Local review covered final SQL definitions, scheduler credentials, privacy replay, migration ordering, relationships, response branches, test invocation, Windows PowerShell compatibility, and the existing late-Handoff-outcome contract. It corrected a duplicated fixture invocation, a PowerShell-7-only HTTP option, an incorrect suppressed-turn expectation, a missing Turn relationship constraint, and a recovery change that would have blocked a valid late outcome.

The reporting worker completed its red/green checks. The database, workflow, and local-security reviewer workers stopped because the workspace reported exhausted credits. Their partial work was inspected and finished locally; independent final approval is not claimed.

Docker is unavailable on PATH and at the standard Docker Desktop path. `tests/Test-ReviewFixes.ps1` was attempted and stopped at its explicit Docker prerequisite. Migration execution, SQL assertions, live n8n paths, the concurrency handshake, and the canonical suite are **not verified on this change**. Prior Docker results do not certify this tree.

Next verification on a Docker-capable host: run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-ReviewFixes.ps1`, then `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run.ps1`. The focused run creates a disposable PostgreSQL container; the complete suite rebuilds its disposable stack and recreates n8n twice for adapter fixtures. No retained-stack reset is implied.

## Migration and scope limits

Historical already-minimized inbound rows cannot acquire reconstructed replay identity and return `replay_identity_unavailable`. Existing Follow-Ups without provenance snapshots remain fail-closed rather than receiving invented evidence. NOT VALID constraints do not certify historical rows. These limits matter for retained stacks.

No commits, merges, pushes, live-provider calls, promotion, or retained-volume resets were performed. Unrelated untracked client directories were left untouched.
