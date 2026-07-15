---
title: 'Finish and test the N8N SalesFlow workflow'
type: 'feature'
created: '2026-07-15'
status: 'in-review'
baseline_revision: 'b7b55804600998482d72d3154488e5eaa2495fcd'
review_loop_iteration: 5
followup_review_recommended: false
context:
  - '{project-root}/docs/project-context.md'
warnings:
  - multiple-goals
  - oversized
---

<intent-contract>

## Intent

**Problem:** The repository defines a policy-bound WhatsApp sales assistant but contains no executable database, n8n workflows, runtime configuration, or test evidence. The full 19-story technical foundation must become reproducible without chat history or production credentials.

**Approach:** Build the canonical seven thin n8n workflows over a PostgreSQL-owned command/state model, run them in pinned containers, and prove all deterministic paths with sanitized fixtures and mock external results. Keep credentialed Meta, LLM, CRM, legal/privacy approval, and managed-infrastructure evidence as explicit production gates rather than fabricating proof.

## Boundaries & Constraints

**Always:** PostgreSQL owns business state and atomic transitions; n8n only orchestrates. Provider inbound IDs and logical action keys are unique. Only `active+ai` Conversations automate. Every customer send passes the same fail-closed final gate and short version-bound lease. Human-Owned blocks automation except one precommitted non-commercial Handoff acknowledgement, which opt-out can still suppress. Follow-Ups are durable UTC jobs. Model data/output is allowlisted, typed, untrusted, and unable to send or mutate. All identifiers are Contact-scoped and provenance/audit data is immutable. Secrets and customer data never enter exports, fixtures, logs, or source control.

**Block If:** A passing claim requires real Meta assets/credentials, a selected LLM/provider, the selected Handoff/CRM acknowledgement contract, managed PostgreSQL controls, approved policy/knowledge/legal/privacy wording, or production owner approval and those inputs are absent. Complete all synthetic/local work and record the precise missing live evidence before blocking.

**Never:** Add a custom UI, Redis, queue mode, workers, HA, vector retrieval, media, multi-tenancy, community nodes, command/file/Code nodes, arbitrary HTTP tools, extra runtime dependencies, per-lead Wait nodes, secrets, or invented executive/compliance decisions.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Trusted inbound | Valid configured-account event | One normalized inbound record and monotonic Conversation sequence | Duplicate returns existing record; no second action |
| Rejected inbound | Wrong account, malformed, oversized, unauthenticated evidence | No business side effect | Typed rejection and PII-minimized audit |
| Opt-out or human request | Eligible Conversation plus configured signal | Suppress pending work or atomically create/reuse Handoff and Human-Owned | Opt-out wins over every acknowledgement/send |
| Grounded response | Typed mock draft matching active knowledge/policy | One provenance-rich intent enters shared authorization | Invalid schema/source/offer/claim creates Handoff, never sends |
| Dispatch | Authorized current intent | One lease; injected provider result reconciles monotonically | Ambiguity becomes reconciliation-required, never blind retry |
| Follow-Up | Due eligible job | One bounded claim and shared authorized intent | Quiet hours, stale version, window/template, stop, reply, opt-out, or Human-Owned suppresses |
| Operations/data | Stop, replay, deletion, release, reconstruction | Audited control, scoped deletion tracking, reproducible evidence | Unauthorized/stale/cross-Contact operations fail closed |

</intent-contract>

## Code Map

- `compose.yaml` -- pinned PostgreSQL 17.10 and n8n 2.30.4 local runtime.
- `.env.example` -- non-secret configuration contract.
- `database/001-initial.sql` -- canonical schema, constraints, atomic commands, fixtures entrypoints, and authorization gate.
- `workflows/01-whatsapp-ingress.json` through `workflows/07-error-and-operations.json` -- authenticated, complete native-node flows that consume, advance, and finalize persisted work; no claim-only dead ends.
- `config/*.json` -- typed synthetic Product Knowledge, Sales Policy, consent/template, qualification, model, retry, Handoff, retention, and Release Set contracts.
- `tests/pilot-scenarios.json` -- sanitized scenario inventory mapped to stories/gates.
- `tests/run.ps1` -- one-command static, migration, generated-credential, import, activation, real n8n execution, concurrency, scenario, secret, and release-evidence checks.
- `scripts/canonicalize-workflows.mjs` -- deterministic stdlib-only export hashing.
- `release/release-manifest.json` -- pinned versions, hashes, node inventory, and evidence references.
- `_bmad-output/implementation-artifacts/test-evidence.md` -- honest local results and unresolved credentialed gates.

## Tasks & Acceptance

**Execution:**
- [x] `compose.yaml`, `.env.example` -- define the digest-pinned UTC runtime, separate migration-owner and least-privilege n8n roles, disable execution payload persistence, mount source read-only, and keep generated credentials/state ignored and removable.
- [x] `database/001-initial.sql` -- implement account-scoped config/controls and composite ownership constraints, including Handoff conversation/source ownership; disable all tokens when their account is disabled; revoke bootstrap/evidence mutation from runtime; reject unknown config kinds and fully validate every consumed field/range; consume or explicitly evidence qualification and retention contracts; require explicit consent evidence and typed consent/operator inputs; use configured normalized signals, claims, timing, frequency, queue/deadline, retry durations/backoff/attempts; require valid Handoff config before human transfer and atomically create a durable Handoff on every grounding failure; make every claim denial typed, prevent terminal Handoff reclaim, and make every retryable failure reclaimable; bind finish commands to unexpired account-scoped lease/claim ownership; enforce monotonic provider transitions including delayed failures; compare conflicting concurrent replay payloads after uniqueness races; audit account-scoped safety transitions; execute and minimize deletion targets before declaring completion; rotate immutable release records without mutating prior evidence and bind activation to the exact reviewed repository release manifest. Enforce disabled-account checks for scheduler work; make recheck denials release/suppress leases; handle concurrent callback uniqueness and post-deletion callbacks deterministically; serialize a single active release pointer bound to the complete canonical repository manifest; reject same-version/different-body config publication; evaluate configured WhatsApp service-window/template timing; minimize consent evidence during completed deletion; consume qualification handoffScore.
- [x] `config/*.json` -- provide fully consumed, valid synthetic-local per-account contracts; production selection remains disabled without approval. Make account configuration drive test provisioning/evidence and keep every declared qualification/retention/release field behaviorally consumed.
- [x] `workflows/*.json` -- export seven authenticated branch-complete workflows: claim denials terminate cleanly; ingress rejection never orchestrates; dispatch/Handoff recheck immediately before internal adapter and finish with authenticated account context; Follow-Up has real UTC Schedule Trigger and test trigger feeding the same all-account claim path, then invokes shared dispatcher for every created intent; callbacks validate provider identity; operations is role-bound. Automatically chain ordinary reply intents and newly created Handoffs, add durable schedule-driven discovery for pending/retry outbound and Handoff work, and recheck Handoff authorization immediately before the adapter.
- [x] `tests/pilot-scenarios.json`, `tests/runtime.sql`, `tests/run.ps1` -- assert actual S01-S26 behavior before markers plus durable grounding Handoff creation, disabled-account denial, conflicting concurrent replay, expired dispatch/Handoff finish rejection, terminal Handoff non-reclaim, delayed failed-callback non-regression, malformed consent/operations input, second-release rotation tied to the exact repository manifest, completed deletion targets and minimized live data, all consumed config fields, exact config/workflow file sets, all advertised authorization reasons and policy/config consumption, retryable failure/backoff/exhaustion for outbound/Handoff/Follow-Up, cross-account internal command denial, schedule-produced dispatch, import/publish/export command exit codes, and worker native exits; generate database credentials from the disposable environment, poll readiness, and clean credentials/volumes in `finally`. Add assertions for automatic ordinary/retry work completion, disabled scheduler accounts, recheck denial cleanup, Handoff pre-adapter denial, callback races/post-deletion rejection, same-version config immutability, service-window behavior, one-active full-manifest release rotation, consent minimization, account config provisioning, and qualification threshold consumption.
- [x] `scripts/canonicalize-workflows.mjs`, `release/release-manifest.json` -- canonicalize inside the pinned container and hash every release-relevant runtime/config/schema/workflow/test input; reject extra config/workflow files, verify exported imported-workflow identity, and provide the exact canonical manifest payload/hash used by release activation. Bind release activation to the full canonical manifest digest while retaining exact artifact-set and imported/export identity proof.
- [x] `README.md`, `_bmad-output/implementation-artifacts/test-evidence.md` -- document the tested one-command/manual lifecycle including generated credential creation and cleanup, and retain honest external production blockers. Provide a migration-first manual lifecycle that can start a clean database before n8n connects.

**Acceptance Criteria:**
- Given a clean machine with Docker running, when `tests/run.ps1` executes, then PostgreSQL becomes healthy, the migration applies twice safely, generated local credentials import without entering source control, all seven workflows import and activate in n8n 2.30.4, every workflow executes at least one real connected path, no claimed work is stranded, and every synthetic scenario passes.
- Given concurrent/replayed inputs and callbacks, when repository checks execute, then one logical state/action survives and monotonic state never regresses.
- Given a missing account/policy/knowledge/retry/operations control, conflicting idempotency replay, expired claim/lease, future timestamp, or cross-account callback, when the shared command runs, then it fails closed or recovers deterministically without leaking identifiers or creating duplicate side effects.
- Given a new Contact without explicit consent evidence, an unselected production model, an unsupported offer/source/claim, or caller-supplied provider outcome, when automation is attempted, then no send or acknowledgement is recorded.
- Given a due Follow-Up or expired retry, when the UTC scheduler/worker runs, then the shared policy gate is re-evaluated from the published configuration, retry limits/backoff are enforced, and the persisted job reaches a terminal or recoverable state.
- Given multiple configured accounts, when policy, stop, scheduling, dispatch, callback, evidence, deletion, or release commands run, then the authenticated account cannot read or mutate another account and the real scheduler services every eligible account.
- Given the full test succeeds or fails, when cleanup runs, then plaintext generated credentials and container volumes are removed; imported exports are re-exported and matched to their canonical workflow identities.
- Given any suppression, ownership, consent, version, policy, knowledge, timing, or template failure, when final authorization executes, then no provider-call lease is issued and the typed reason is audited.
- Given the release artifacts, when canonicalization and scans run, then hashes reproduce, only approved nodes exist, and no secret/customer fixture is found.
- Given absent external approvals or credentials, when completion evidence is reviewed, then no production/live gate is reported as passed and every missing proof has an owner/input category.

## Spec Change Log

### 2026-07-15 — Review loop 1
- Trigger: imported two-node workflows stopped after database claims, while import-only tests reported the workflow as complete; reviewers also found unauthenticated triggers and database fail-open, recovery, and idempotency gaps.
- Amendment: workflow tasks now require authenticated end-to-end terminal paths and tests require activation plus real n8n invocation of every export. Database acceptance now names fail-closed configuration, account scoping, expired-claim recovery, conflict detection, finite retries, callback binding/order, immutable evidence, and complete deletion/Handoff records.
- Avoids: a green suite that proves SQL and importability while customer turns, Follow-Ups, dispatches, and Handoffs remain stranded or forgeable.
- KEEP: pinned n8n/PostgreSQL runtime; seven canonical exports; PostgreSQL-owned atomic commands; exact S01-S26 evidence mapping; concurrency checks; canonical hashes; native-node/secret scans; explicit separation of synthetic proof from external production gates.

### 2026-07-15 — Review loop 2
- Trigger: the re-derived workflows executed, but Follow-Ups were webhook-only, dispatcher/Handoff outcomes remained caller-controlled, rejected ingress flowed into orchestration, consent defaulted true, configuration was partly decorative, and several scenario markers followed weaker assertions than their advertised behavior.
- Amendment: tasks now prescribe a real UTC Schedule Trigger, internal deterministic synthetic adapters, rejection branches, explicit consent/configured opt-out, synthetic-local model selection, provider-bound callbacks, composite account constraints, audited transitions, container-only hashing, environment-derived credentials, and assertion-before-marker proof for each scenario.
- Avoids: an executable demo whose callers can forge sends/acknowledgements or whose tests label partial SQL state as end-to-end safety evidence.
- KEEP: loop 1's disposable credential import, workflow publication and authenticated webhook invocation, connected ingress-to-orchestrator path, clean-volume runtime, exact digest pins, and concurrent same-message/distinct-message checks.

### 2026-07-15 — Review loop 3
- Trigger: retryable dispatch/Handoff failures were terminal, Follow-Up completion could strand a pending intent, config/controls were global and partly unused, denial branches still reached adapter nodes, callbacks/releases/deletion were under-validated, and successful tests could leave credentials/volumes behind.
- Amendment: runtime tasks now require account-scoped config/controls, least-privilege roles, fully consumed validated contracts, reclaimable finite retries/backoff, all-account scheduler-to-dispatch chaining, typed denial branches, account-bound finish/callback commands, correct deletion targets/minimization, immutable release validation, imported-workflow export identity, exit-code checks, bounded readiness polling, and unconditional cleanup.
- Avoids: a green synthetic run that cannot retry real failures, silently ignores non-test accounts, or leaves sensitive local state after failure.
- KEEP: loop 2's internal adapter outcomes, explicit consent, rejection branch, real Schedule Trigger topology, S01-S26 exact markers, container hashing, env-derived credentials, parallel replay/sequence/lease/opt-out workers, and all seven live endpoints.

### 2026-07-15 — Review loop 4
- Trigger: the green live suite still allowed expired dispatch/Handoff completion, terminal Handoff reclaim, delayed failure regression, disabled-account use, conflicting concurrent replay acceptance, non-durable grounding Handoffs, false deletion completion, and an unrotatable release record unrelated to the repository manifest.
- Amendment: database and test tasks now explicitly require unexpired ownership at finish, terminal-state guards, failed-callback monotonicity, account-enabled authentication, post-race replay comparison, durable grounding Handoffs, typed malformed input, complete/minimized deletion, exact-manifest release rotation, full config field validation/consumption, composite Handoff ownership, exact config sets, and environment-derived database credentials.
- Avoids: a passing local suite that can duplicate or regress external actions, report deletion/release success without performing it, or remain operational after account disablement.
- KEEP: digest-pinned disposable runtime; least-privilege n8n role; PostgreSQL-owned state machine; seven native workflows; authenticated live endpoints; ingress rejection branching; passthrough sub-workflow triggers; field-preserving internal adapters; S01-S26 assertions; concurrency workers; canonical import/export identity; secret scans; and unconditional generated-credential/volume cleanup.

### 2026-07-15 — Review loop 5
- Trigger: repaired commands still relied on external callers to discover normal replies, Handoffs, and retryable work; scheduler disablement, recheck linearization, callback races, single-active release binding, immutable config, service-window policy, consent deletion, account provisioning, qualification thresholds, and the documented manual bootstrap were incomplete.
- Amendment: tasks now require durable all-account workers for pending/retry outbound and Handoff work, automatic chaining of newly created work, final Handoff recheck, scheduler account-enabled filtering, typed recheck suppression, callback race handling, immutable same-version config, actual service-window evaluation, exact full-manifest release binding with one active pointer, consent minimization, consumed account/qualification config, and a working migration-first manual lifecycle.
- Avoids: green endpoint demos that strand normal/retry work, send after account disablement or changed authorization, or activate/minimize evidence inconsistently.
- KEEP: every loop-4 repair; full clean-run proof; exact file sets; conflicting replay workers; environment-derived credentials; loopback binding; digest pins; least privilege; seven native workflows; import/export identity; live endpoint paths; and unconditional cleanup.

## Review Triage Log

### 2026-07-15 — Review pass
- intent_gap: 0
- bad_spec: 12: (high 12, medium 0, low 0)
- patch: 17: (high 12, medium 5, low 0)
- defer: 0
- reject: 5: (high 0, medium 3, low 2)
- addressed_findings:
  - `[high]` `[bad_spec]` Required complete ingress-to-orchestrator, dispatch-result, Follow-Up-intent, and Handoff-result paths instead of claim-only workflow endings.
  - `[high]` `[bad_spec]` Required authenticated ingress, status, and operations triggers with actor identity bound to authentication context.
  - `[high]` `[bad_spec]` Required real n8n activation and invocation evidence for every workflow instead of CLI import-only proof.
  - `[high]` `[bad_spec]` Required runtime policy to consume published typed configuration rather than contradictory hard-coded gates.
  - `[high]` `[bad_spec]` Required source, offer, confidence, and provenance validation to produce one grounded intent or fail into Handoff.
  - `[high]` `[bad_spec]` Required safe Handoff creation without active commercial configuration and actionable Handoff provenance, assignment, and deadline fields.
  - `[high]` `[bad_spec]` Required recoverable claims, finite retries, idempotency conflict detection, and callback identity and ordering checks.
  - `[high]` `[bad_spec]` Required account-scoped Contact identity and replay behavior without cross-contact identifier disclosure.
  - `[high]` `[bad_spec]` Required fail-closed missing controls/configuration and serialized single-active policy/knowledge publication.
  - `[high]` `[bad_spec]` Required immutable audit/provider evidence and deletion target tracking that suppresses every pending external action.
  - `[high]` `[bad_spec]` Required image digests in Compose, not only in the manifest.
  - `[high]` `[bad_spec]` Required each S01-S26 marker to follow assertions that prove its advertised behavior.

### 2026-07-15 — Review pass 2
- intent_gap: 0
- bad_spec: 11: (high 11, medium 0, low 0)
- patch: 18: (high 11, medium 7, low 0)
- defer: 0
- reject: 4: (high 0, medium 2, low 2)
- addressed_findings:
  - `[high]` `[bad_spec]` Required real UTC scheduling and completed Follow-Up work instead of webhook-only polling.
  - `[high]` `[bad_spec]` Moved synthetic provider/Handoff outcomes inside workflows so authenticated callers cannot forge terminal success.
  - `[high]` `[bad_spec]` Required rejection branching before orchestration and account-scoped internal workflow commands.
  - `[high]` `[bad_spec]` Required execution payload pruning and broader generated/exported secret scans.
  - `[high]` `[bad_spec]` Required explicit consent evidence, configured normalized opt-out, and synthetic-local model selection with typed grounding checks.
  - `[high]` `[bad_spec]` Required the shared Follow-Up gate to enforce consent, stop, timing, template, campaign, offer, source, and retry policy.
  - `[high]` `[bad_spec]` Required live-lease preservation, finite adapter retries, configuration-driven claim durations, and provider-time monotonic callbacks.
  - `[high]` `[bad_spec]` Required composite account ownership constraints and auditing of every safety-critical transition.
  - `[high]` `[bad_spec]` Required release activation to validate pinned manifest hashes and single-active serialization.
  - `[high]` `[bad_spec]` Required S06, S11, S14, S18, and S20 to execute their advertised race, grounding, lease, gate, and isolation behaviors.
  - `[high]` `[bad_spec]` Required worker exit-code checks, manifest/file-set equality, environment-derived credentials, and Docker-only canonicalization.

### 2026-07-15 — Review pass 3
- intent_gap: 0
- bad_spec: 10: (high 10, medium 0, low 0)
- patch: 19: (high 10, medium 9, low 0)
- defer: 0
- reject: 5: (high 0, medium 3, low 2)
- addressed_findings:
  - `[high]` `[bad_spec]` Required retryable outbound and Handoff failures plus Follow-Up claims to use configured backoff, limits, and recoverable states.
  - `[high]` `[bad_spec]` Required the scheduler to service all accounts and dispatch every created Follow-Up intent rather than mark it complete while pending.
  - `[high]` `[bad_spec]` Required config and controls to be account-scoped, validated, and actually consumed by authorization/Handoff/opt-out/model paths.
  - `[high]` `[bad_spec]` Required body claims and callback transitions/required fields to be validated, not only identifiers and timestamps.
  - `[high]` `[bad_spec]` Required replay conflicts and workflow claim denials to return typed terminal results with no fall-through.
  - `[high]` `[bad_spec]` Required finish and evidence commands to authenticate account scope and recheck suppression before adapter linearization.
  - `[high]` `[bad_spec]` Required correct deletion target identifiers/minimization and release activation tied to immutable reviewed manifest evidence.
  - `[high]` `[bad_spec]` Required a least-privilege runtime role unable to mint auth tokens or rewrite append-only evidence.
  - `[high]` `[bad_spec]` Required tests to exercise real retry/schedule/cross-account paths and assert every external command exit.
  - `[high]` `[bad_spec]` Required unconditional credential/volume cleanup and imported-workflow export identity verification.

### 2026-07-15 — Review pass 4
- intent_gap: 0
- bad_spec: 18: (high 18, medium 0, low 0)
- patch: 0
- defer: 0
- reject: 2: (high 0, medium 1, low 1)
- addressed_findings:
  - `[high]` `[bad_spec]` Required invalid grounding to atomically complete the turn and create a durable dispatchable Handoff.
  - `[high]` `[bad_spec]` Required dispatch and Handoff finish commands to reject expired lease/claim ownership.
  - `[high]` `[bad_spec]` Required terminal Handoffs to be non-reclaimable and expired claims to be explicitly recoverable.
  - `[high]` `[bad_spec]` Required delayed failed callbacks to preserve delivered/read monotonicity.
  - `[high]` `[bad_spec]` Required immutable release rotation without updating prior evidence and exact binding to the reviewed repository manifest.
  - `[high]` `[bad_spec]` Required deletion to complete/minimize tracked targets before returning a completed terminal.
  - `[high]` `[bad_spec]` Required disabled accounts to invalidate previously issued runtime/operator tokens.
  - `[high]` `[bad_spec]` Required retry and Handoff config validation for every consumed timing, queue, and backoff field.
  - `[high]` `[bad_spec]` Required qualification and retention contracts to be consumed or evidenced rather than accepted decoratively.
  - `[high]` `[bad_spec]` Required conflicting concurrent replay payloads to remain conflicts after uniqueness races.
  - `[high]` `[bad_spec]` Required missing Handoff configuration and malformed consent/operator input to return typed fail-closed results.
  - `[high]` `[bad_spec]` Required environment-derived disposable database credentials and loopback-only local n8n exposure.
  - `[high]` `[bad_spec]` Required account-scoped Handoff conversation/source ownership constraints.
  - `[high]` `[bad_spec]` Required exact manifest config/workflow sets so unreviewed artifacts cannot enter runtime evidence.

### 2026-07-15 — Review pass 5
- intent_gap: 0
- bad_spec: 17: (high 17, medium 0, low 0)
- patch: 0
- defer: 0
- reject: 0
- addressed_findings:
  - `[high]` `[bad_spec]` Required scheduler and scheduler-authorized claims to reject disabled accounts.
  - `[high]` `[bad_spec]` Required failed immediate rechecks to suppress/release work with typed evidence rather than leave leases stranded.
  - `[high]` `[bad_spec]` Required Handoff authorization recheck immediately before the internal adapter.
  - `[high]` `[bad_spec]` Required durable autonomous discovery for normal replies, due Follow-Ups, retryable outbound intents, new Handoffs, and retryable Handoffs.
  - `[high]` `[bad_spec]` Required callback uniqueness races and post-deletion callbacks to return deterministic typed terminals.
  - `[high]` `[bad_spec]` Required one active release pointer, serialized rotation, and activation bound to the full repository manifest rather than three version strings.
  - `[high]` `[bad_spec]` Required published config versions to be immutable on same-version/different-body replay.
  - `[high]` `[bad_spec]` Required final authorization to evaluate the configured WhatsApp service window/template contract.
  - `[high]` `[bad_spec]` Required completed deletion to minimize consent evidence and reject later identifier-bearing callbacks.
  - `[high]` `[bad_spec]` Required account configuration to drive provisioning/evidence and qualification `handoffScore` to affect runtime decisions.
  - `[high]` `[bad_spec]` Required the documented manual lifecycle to apply migrations before n8n connects.

### 2026-07-15 — Review pass 6
- intent_gap: 0
- bad_spec: 0
- patch: 16: (high 12, medium 4, low 0)
- defer: 0
- reject: 5 duplicate reports
- addressed_findings:
  - Recovered expired outbound leases and Handoff claims through the native UTC scheduler and proved both terminal paths.
  - Chained human-request Handoffs directly from ingress through workflow 06.
  - Made opt-out precedence explicit and atomically suppressed pending intents, Follow-Ups, and Handoffs.
  - Bounded expired turn recovery with the configured retry limit.
  - Enforced per-template timing and fully typed configuration arrays, including rejecting overlapping opt-out/human signals.
  - Serialized first publication of an account/config kind and retained immutable same-version behavior.
  - Minimized provider identifiers through an operator-authorized deletion tombstone while preserving append-only protection otherwise.
  - Added final-gate denial cleanup assertions, concurrent callback proof, actual Schedule Trigger execution, and autonomous retry recovery evidence.
  - Removed diagnostic environment preservation so failure cleanup cannot retain generated plaintext credentials or volumes.

## Design Notes

The shortest safe design places complexity in PostgreSQL functions because n8n nodes cannot make a multi-node transaction atomic. Workflows remain trigger → shape → one command → branch/native side effect → persisted result. Synthetic dispatch injects provider outcomes after the lease boundary, exercising the same state machine without pretending to test Meta or CRM.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` -- expected: all static, migration, import, SQL scenario, concurrency, and evidence checks pass.
- `docker compose exec -T n8n n8n export:workflow --all --separate --output=/tmp/exported` -- expected: seven workflows export and canonical hashes match.
- `git diff --check` -- expected: no whitespace errors.
- `git status --short` -- expected: only intentional implementation artifacts before commit.

## Auto Run Result

- Result: `PASS FULL PASS`, exit code 0, 145.1 seconds.
- Review: two independent pass-6 reviewers found no intent gap or specification defect; all 16 unique patch findings were fixed and retested.
- Verified: migration idempotence; least-privilege roles; S01-S26; replay, sequence, and callback concurrency; exact manifest binding; seven import/activate/publish/export identities; real endpoint paths; actual UTC schedule recovery; automatic reply and Handoff chaining; secret scans; unconditional plaintext/volume cleanup.
- Residual production gates: customer Meta credentials/assets, approved production LLM and content, real CRM/Handoff acknowledgement, managed PostgreSQL controls, legal/privacy approval, and named production-owner approval. Local promotion remains disabled.
