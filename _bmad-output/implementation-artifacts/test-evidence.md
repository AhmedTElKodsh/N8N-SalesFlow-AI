# SalesFlow local test evidence

Date: 2026-09-02
Runtime: n8n 2.30.4 and PostgreSQL 17.10, both digest-pinned in `compose.yaml`
Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run.ps1`

## Result

The final SP3-T3 correction bundle is cryptographically bound as activation manifest `746ae15d6ec243bd26aa907150ae8889fe4f24761fc540dce08c10613f6f7c16`. On Docker server `29.7.2`, the canonical command completed with `PASS FULL PASS`, removed generated plaintext credentials, and removed its disposable containers and volumes. The native UTC schedule recovered the exact three branches as `1:1:1`: expired pre-call outbound work was safely sent, expired post-call work moved to `reconciliation_required` with one provider call and no blind resend, and the expired Handoff claim was acknowledged.

The final harness closes the diagnostic loopholes that previously obscured this result. The SP2-T3 partial-release test now restores the shipped `policy-v1` required by `release-v10` instead of leaving `policy-v2` active; the scheduled-recovery fixture asserts its typed `dispatch` results and exact pre-call/post-call/Handoff states atomically before cron can race them; PostgreSQL assertion errors remain visible; and branch-specific polling/diagnostics replace aggregate counts. The bundle also preserves malformed post-call legacy parents for reconciliation, detects duplicate SQL function definitions across both CREATE forms, and uses a deterministic lock window for commit-order races. Production behavior remains synthetic-local and `livePromotionAllowed=false` is unchanged.

Verified evidence includes:

- clean and legacy migration idempotence, deterministic `processing_body` backfill, and a least-privilege n8n database role;
- partial-upgrade duplicate non-null Follow-Up source/action identities cleaned before uniqueness indexes, with invalid active jobs terminalized through immutable typed transitions while legitimate terminal delivery outcomes remain unchanged;
- durable database send time rather than provider time anchoring +12 hours, `clock_timestamp()` provider-call starts, exact provider template identity/category/language at schedule and due/final gates, and null-safe child evidence checks;
- finite contention behavior across Follow-Up writers, voluntary four-second scheduler exit beneath a larger safety timeout, retry children blocked while their parent remains `retry`, disabled-account restoration through only the narrow granted command, and exact non-negative `followupBacklog`, `oldestFollowupDueAgeSeconds`, `followupRetry`, and `followupExhausted` metrics;
- migration and runtime orphan-parent terminalization, both reply-first and provider-call-first commit orders, concurrent scheduler single-child/single-transition behavior, newer-sent supersession with linked-child suppression and both source identities, exact due-time missing-control/business-context/template/quiet-hour/frequency reasons, and controlled numeric backlog/retry/exhaustion/age metrics;
- exact S01-S26 runtime assertions;
- SP2-T2 strict JSON/string and whitespace-identity validation, raw pre-normalization size enforcement, decomposed-Unicode NFC plus internal formatting preservation, the database processing-form invariant, empty-after-cleaning rejection, signal-only whitespace collapse, processing-form model consumption, exact duplicate and sender/body conflict decisions, decreasing/equal provider-time processing in database sequence, and deletion-safe message immutability;
- commit visibility, concurrent duplicate/conflict, no-extra-Turn/work, and sequence races with native worker exit checks and minimized durable conflict audits;
- SP2-T3 missing and revoked consent denial before AI drafting, wrong-token/account/Conversation denial, same-account/Contact/Conversation isolation, symmetric missing-policy/knowledge failure, ascending database-sequence history, ten-message and 32-KiB limits, byte-gap continuation, oversized-current denial, mandatory current-message inclusion, and minimized reconstructable intent provenance;
- deliberately paused transactions proving actual consent advisory waiting and post-commit Sales Policy activation visibility, bounded `busy` recovery that safely returns the Turn to pending without an intent, and a mid-conversation Product Knowledge and Sales Policy update proving the next response uses v2 while the already-sent v1 body and provenance remain unchanged;
- SP3-T1 active Release Set selection with the exact active Product Knowledge and Sales Policy pair, minimized SHA-256 consent-evidence provenance, typed denial for missing or inconsistent business context, and ordered bounded message references tied to one account, Contact, Conversation, and source;
- a real paused policy-activation transaction proving context waits for publication and then rejects a post-commit mixed pair until its matching Release Set is active, plus a held Release Set lock proving bounded typed `busy` handling without an intent;
- an ongoing-Conversation release rotation proving the next response records the newly active Release Set and business versions while the previously sent response body and provenance remain unchanged;
- SP3-T2 one-row-per-intent provider-call starts, atomic final authorization immediately before the synthetic adapter, stable provider/correlation identity, idempotent terminal replay, and append-only started/accepted/failed/ambiguous/reconciliation evidence;
- six concurrent HTTP workers targeting the same nonterminal intent producing one call-start, one accepted event, and one sent intent, with every contender returning a bounded typed result;
- two distinct intents for one Contact racing for its final frequency slot, with exactly one call-start and one durable `frequency_cap` suppression;
- final-gate serialization with Contact/Conversation, consent, active authorization configuration, stop-control, deletion, and durable frequency authorities, plus conclusive failed completion remaining failed when a contradictory later callback is retained as evidence;
- expired pre-start work safely reclaimed by the UTC scheduler, while an expired post-start call moved to `reconciliation_required` with one recorded call and no blind resend;
- 20 distinct approved messages dispatched concurrently through n8n with exactly 20 unique provider calls and 20 delivered statuses, followed by concurrent retries of the same 20 work IDs that added zero calls, provider events, or call events;
- strictly monotonic per-Contact consent timestamps and intent-evidence guards rejecting ordinary identity/source/version/body/provenance mutation and deletion while permitting only controlled privacy minimization;
- strict integer/set configuration validation, audited immutable save/activation/rollback, bounded activation locking, incompatible-version rejection, account disablement, service-window policy, pre-call retry/lease recovery, deletion minimization of inbound, intent, and provider identity evidence, and single-active release rotation;
- seven workflow imports, activations, publications, and real connected endpoint paths;
- automatic ingress-to-orchestrator-to-dispatch and ingress-to-Handoff completion, mixed Meta-envelope text preservation, explicit callback/operations HTTP error classes, operator publication through Workflow 07, propagated database failures, concurrent callback collapse, actual UTC Schedule Trigger recovery of expired outbound/Handoff claims, final pre-adapter authorization checks, and account-bound operations terminals;
- source versus imported/exported canonical workflow identity;
- approved native-node inventory and generated export secret scans;
- generated plaintext credential and Docker-volume cleanup.

## SP3-T3 loop-5 focused and canonical evidence

Date: 2026-08-27

- The preserved loop-5 contract assertions first failed with: `SP3-T3 loop-5 RED missing contracts: bounded nonblocking candidate discovery; actual row or authority busy evidence; Conversation serialization key; parent-first linked intent transition; exact final Follow-Up authorization; campaign snapshot provenance; shared Follow-Up correlation; real Follow-Up retry metric; privacy-safe callback alias; trusted time refreshed after locks`.
- The current migration applied twice in the disposable `salesflow-loop5-focus` PostgreSQL database after each production slice.
- A first durable reply `sent` transition produced `1:due:true:true`: exactly one Follow-Up, a +12-hour due identity, and the source provider-call correlation ID.
- One valid due job produced `intent_created:<uuid>:0`: one intent-created parent with no false busy evidence.
- Post-deletion callback reconciliation produced `sent:delivered:deleted-<intent-id>:true`, proving delivered truth through a retained 64-hex callback alias while the stored provider identity remained minimized.
- Callback ordering was reproduced red as `status: accepted`, fixed, then passed as `FOCUSED CALLBACK ORDER PASS` after two migrations.
- The corrected cross-account fixture produced `2:2:intent_created`, and the isolated stale-window fixture passed both service and approved-template denial as `FOCUSED WINDOW GATES PASS`.
- The loop-5 concurrency harness processed exactly 50 of 61 equal-due unlocked jobs in its first batch, left 11 due, and recorded zero false busy events for the limit-excluded rows. A genuinely authority-busy oldest job did not stall a later processable job and produced one deduplicated busy event.
- Forced inbound, consent, account-disable, global-stop, campaign-disable, sent/config/scheduler, cancellation-versus-claim/begin/finish/callback/reconciliation, and cancellation-versus-supersession races all completed within their bounds without deadlock and retained coherent parent/intent/call evidence. A trusted-time boundary change denied the job as `template_window_closed` before intent creation.
- Reducing `retry.maxAttempts` after claim blocked provider-call start with `retry_exhausted` and zero provider calls. The runtime proof also moved a real linked pre-call retry into and out of `followupRetry`, retained one correlation ID and campaign snapshot across job, intent, and provider call, and reconciled accepted/failed/delivered post-deletion callbacks through a 64-hex non-PII alias.
- The corrected SP3-T2 final-frequency race produced `3:1:1:1`: one remaining slot admitted exactly one valid reply contender, suppressed exactly one with `frequency_cap`, and recorded one started event. The existing 20-message test still produced exactly 20 unique calls and 20 delivered statuses; retrying all 20 work IDs added no calls, provider events, or call events.
- The published Workflow 05 path scheduled and dispatched a fully evidenced due Follow-Up. All seven workflows imported, activated, published, exported, and matched their source identities.
- `& .\tests\run.ps1 -ResetLocal -KeepRunning` exited successfully with `PASS FULL PASS`, removed generated plaintext credentials, retained the intentionally running local stack and ignored `.env`, and kept `livePromotionAllowed=false` in promotion-disabled `release-v10`.

## SP3-T3 loop-6 canonical evidence

Date: 2026-08-28
Command: `& .\tests\run.ps1 -ResetLocal -KeepRunning`
Result: `PASS FULL PASS` with exit code 0

- The migration applied twice on fresh, legacy-upgrade, and injected-failure databases; no partial schema survived the forced failure.
- A sent reply created one immutable Follow-Up due exactly +12 hours, replay created no duplicate, a committed customer reply cancelled it as `customer_replied`, and a newer inbound between call-start and sent completion prevented stale scheduling with exact `stale_version` evidence.
- Due processing rechecked the durable parent and current authority, created one child intent, transitioned the parent to `call_started` before provider exposure, and completed with one provider call and one sent parent.
- With the oldest 200 Follow-Ups holding real Conversation locks, the scheduler recorded 200 actual busy observations, scanned beyond them, and materialized the 201st processable job. The synthetic backlog was then cancelled through the production parent/child transition path before n8n resumed.
- The forced deletion-versus-late-ingress race completed without deadlock after existing identities adopted Conversation-first revalidation; deletion waited for ingress and minimized both messages while recording the late message as a deletion target.
- Pre-deletion callback replay remained idempotent after deletion through the retained opaque alias and original payload fingerprint; a direct predictable `deleted-<intent-id>` callback was rejected.
- Native UTC Workflow 05 recovered expired pre-call work, reconciled one post-start unknown outcome without resending, scheduled and dispatched the automatic Follow-Up, and preserved the total 50-work bound.
- Two valid same-Conversation reply intents raced for one remaining Contact frequency slot: exactly one provider call started and exactly one contender was durably suppressed as `frequency_cap`.
- Twenty distinct approved messages sent concurrently through n8n produced exactly 20 unique provider calls and 20 delivered outcomes. Concurrent retries of all 20 work IDs added zero provider calls, provider events, or call events.
- Source/imported workflow identity, release-v10 manifest hashes, generated secret scans, plaintext credential cleanup, ignored local `.env`, and `livePromotionAllowed=false` all passed. The local stack intentionally remains running because `-KeepRunning` was requested.

## Scope boundary

This evidence proves the disposable synthetic-local implementation only. It does not prove production Meta delivery, a production LLM, a CRM/Handoff acknowledgement, managed PostgreSQL security/backup controls, approved customer sales and knowledge content, legal/privacy wording, or production-owner approval. `release/release-manifest.json` therefore keeps `livePromotionAllowed` set to `false`.
## SP3-T3 review loop 7 â€” 2026-08-28

- Canonical command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run.ps1 -ResetLocal -KeepRunning`.
- Result: `PASS FULL PASS` with migration applied twice, atomic rollback intact, duplicate legacy active Follow-Ups terminalized as `legacy_unverifiable`, and all S01-S26 runtime assertions passing.
- Focused loop-7 proof: nullable evidence returned strict false; malformed consent time returned `consent_changed`; NULL finish outcome returned `invalid_outcome`; pre-call Follow-Up exhaustion produced parent `exhausted` plus child `suppressed` with no provider call; callback-created `provider_failed` remained terminal against a later accepted callback; a sent parent advanced to delivered; direct parent deletion was rejected.
- Concurrency proof: both account and stop-control writers returned typed `busy` under a held Conversation lock, made no partial changes, and released cleanly; 200 busy oldest Follow-Ups did not starve the 201st processable job.
- Existing reliability proof remained green: exactly 20 distinct messages produced 20 unique provider calls and 20 deliveries, while duplicate retries added zero calls, statuses, or call events. Generated plaintext credentials were removed, the local stack was retained, release-v10 hashes matched, and `livePromotionAllowed=false`.

## Whole-repository review fix bundle â€” 2026-09-03

Baseline HEAD: `0ac5bbbd0b406303744427a0c7da6b2af047f33a`

This entry records the current dirty working-tree snapshot after the approved committed-plus-uncommitted review fixes. It does not supersede the historical Docker evidence above and does not claim that the modified database/runtime bundle has executed successfully.

- All eight provider-free learning suites passed together in fresh, separate PowerShell processes: `Test-CheckpointSuite`, `Test-Curriculum`, `Test-LearningCli`, `Test-LearningState`, `Test-ManifestHashing`, `Test-MilestoneDocuments`, `Test-TutorContract`, and `Test-TutoringAcceptance`.
- All 19 JSON files under the tested config/release/workflow/learning roots parsed; all 25 PowerShell files under scripts/tests parsed; `docker compose config` passed with an explicit checkout-safe project name; and `git diff --check` passed with line-ending warnings only.
- The effective database input is bound as SHA-256 `8eb4a1e50a3b508cf960923c27d8891b05d298e10076f734ccd2d2468c7ce72b`; the activation manifest is bound as `d37e1281a94f71ab96c7c701813e8d1a0d06b037fb4c0c68501143652939d1d9`; the release-set document is bound as `2d633ba88839c01e9ab38f4889964fc8c0db8542a815aafc90b90fb1586eb943`; and `livePromotionAllowed=false` remains enforced.
- The sanitized transcript is `_bmad-output/implementation-artifacts/test-transcript-sanitized.txt`, SHA-256 `04fd3d931f633d070cf75862310818b59436388536da159ef6b207ff7bd63b36`.
- The deterministic working-file manifest covers 31 changed or untracked paths and hashes each path plus its current SHA-256, sorted by path. Its aggregate SHA-256 is `ee3d28791586220008c7066bd57182d5ddbb99a0eb307f0c77edd5fc5c17cc27`. To avoid self-reference, it excludes this evidence file, the sanitized transcript, and `spec-fix-whole-repository-review-findings.md`; it also excludes the prohibited `reference/**` namespace.
- Docker Desktop was launched and polled, but `docker info` still failed because the Docker Desktop Linux-engine named pipe did not exist. Therefore the modified migration, runtime SQL, n8n import/export, concurrency races, special-character password rotation, cleanup checks, and canonical `PASS FULL PASS` remain pending rather than silently inferred from earlier evidence.
- No Meta, production LLM, CRM/Handoff-provider, managed-infrastructure, deployment, activation, commit, or push action was performed.


## September 5 review-fix verification

The eight findings from the whole-repository review are implemented in `spec-fix-september-5-review.md`. All eight provider-free learning suites passed; the final timeout correction additionally passed the full focused CLI suite. Final parsing, manifest hashing, workflow-expression boundary probes, Compose model validation, and diff checks passed. Independent adversarial and edge reviews cleared their reported corrections; final edge output was `[]`.

Executable snapshot SHA-256: `f1bc0001e0c5cc04190b90d743ef1e30a5db73032b47cc963701feef8308e356`. This hashes sorted `path:sha256(raw bytes)` rows, joined by LF with no trailing LF, for `.sql`, `.json`, `.ps1`, `.psm1`, and `.mjs` files recursively under database, workflows, config, release, scripts, and tests. Activation manifest SHA-256: `2836a4e044117da898eeca6ab87ea5960633ec47fc4eba764458334a2ca69972`. `livePromotionAllowed=false` remains unchanged.

PostgreSQL migration/runtime/race and n8n HTTP/scheduler tests remain unexecuted on this snapshot because Docker Desktop's Linux engine is unavailable. Added SQL/HTTP regressions are not represented as executed evidence. Earlier Docker passes remain historical. No retained learner environment, progress, or volume was reset.

### September 5 final verification correction

The preceding unavailable-engine note records an intermediate state and is superseded for the final review-fix snapshot. Docker Desktop recovered after its stale local socket directories were moved aside; no project Docker volume was deleted during that recovery. The canonical harness then ran in disposable checkout `salesflow-capstone-da3aa23e7711488eb2f2e623f1019102` and exited 0 with `PASS FULL PASS`, `PASS plaintext generated credentials removed`, and `PASS container volumes removed`.

The fresh run passed PostgreSQL migration/runtime/race coverage, n8n workflow import/activation/publication/export identity, connected HTTP paths, native UTC scheduler recovery, account enable/disable through the NULL-account operations webhook, durable pending-turn recovery, canonical consent validation, and multibyte provider-ID rejection. The harness refreshed the dynamically assigned n8n port after restart and drained bounded recoverable scheduler work before asserting the final token-free `authenticated_no_work` response.

All eight provider-free learning suites then passed again in separate Windows PowerShell processes. Final checks also passed for 19 JSON files, 25 PowerShell files, one Node script, `docker compose config`, release-manifest hashing, and `git diff --check`. The disposable runtime credential file was absent and its validated snapshot directory was removed after the run.

Executable snapshot SHA-256: `ccf2b3bc9cabaf23409c1508173fe764ed0927f1ff2f0013d575f2734571f716`. Activation manifest SHA-256: `b7a6474ac527f4784e181a3fa6531b0ab6ec54d7228f7e06b3ecb91a8bf739e0`. Release-set document SHA-256: `fd1600d18c860537cdc3d803706c76b3b4958325fbba9d357acccdf999292783`. `livePromotionAllowed=false` remains enforced.

This is synthetic-local evidence only. It does not prove production Meta delivery, a production LLM, CRM/Handoff-provider acknowledgement, managed PostgreSQL controls, deployment, activation, or production-owner approval. No commit or push was performed.

Final review closure: the independent adversarial reviewer rechecked the completed working-tree diff and returned `[]`. The earlier independent edge review cleared the implementation. Its final repeat could not execute because the reviewer workspace reported exhausted credits; it is not counted as a completed review. The primary agent locally traced the subsequent port-refresh and recovery-drain changes, including error, empty-result, loop-exhaustion, and replaced-assertion paths, and found no additional actionable regression.

### September 5 publication verification

A fresh `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run.ps1` run in the main checkout exited 0 with `PASS FULL PASS`, `PASS plaintext generated credentials removed`, and `PASS container volumes removed`. Native scheduler recovery, database concurrency, workflow identity, and HTTP regression checks passed. All eight `tests/learning/Test-*.ps1` suites passed in separate Windows PowerShell processes. JSON and PowerShell parsing, manifest hashing, diff integrity, and a changed-file credential-pattern scan also passed. No executable source changed after these checks; publication preparation only refreshed documentation. `livePromotionAllowed=false` remains enforced.
