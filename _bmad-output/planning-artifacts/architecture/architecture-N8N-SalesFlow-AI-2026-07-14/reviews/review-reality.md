# Architecture Reality and Version Review

**Artifact reviewed:** `ARCHITECTURE-SPINE.md`  
**Review date:** 2026-07-14  
**Lens:** current vendor capability, version reality, licensing, operational enforceability, and unsafe assumptions  
**Original verdict (2026-07-14):** **CHANGES REQUIRED — the architecture pattern was credible, but the spine was not implementation-ready until the gates below were resolved.** See **Resolution after review** and **Final verdict** for current status.

## Executive finding

The pipes-and-filters design, PostgreSQL authority, deterministic policy gate, durable outbox, and single-runtime pilot boundary are defensible. PostgreSQL 17.10 is a real, current, supported release. n8n supports the Postgres, Schedule Trigger, queue/worker, webhook-processor, and multi-main capabilities named in the spine.

At the time of this review, the build was blocked by four reality gaps:

1. AD-9 treats the 24-hour window and template state as the WhatsApp eligibility gate but does not make recorded opt-in authority and atomic opt-out suppression part of that same gate.
2. n8n 2.25.7 exists, but it is no longer the current npm release; 2.30.4 is current at review time. The older pin has no recorded security/regression rationale, and the actual image digest is deferred.
3. AD-6 and AD-7 require transaction-scoped locking and atomic state-plus-outbox commits, but the spine does not constrain those operations to one database transaction boundary. Separate n8n Postgres nodes are not an architecture-level transaction.
4. “The LLM cannot call” dangerous capabilities is a workflow convention, not a deployment control. The spine does not yet require node exclusion, SSRF protection, egress controls, task-runner isolation, or a passing n8n security audit.

## Ranked findings

### R1 — Critical: WhatsApp eligibility is incomplete

**Where:** AD-9, AD-3, state diagram, outbox dispatcher.

WhatsApp's current Business Messaging Policy requires both the person's number and opt-in permission before the business contacts them, requires opt-out requests to be honored, permits free-form replies only within 24 hours of the last user message, and requires approved templates outside that window. AD-9 codifies only the last two conditions. An `opted_out` terminal state exists, but no invariant says a send intent is impossible without active, category-appropriate opt-in evidence or that a newly received opt-out invalidates an already-claimed outbox item.

That is not a documentation nit. A dispatcher can satisfy AD-9 and still send a policy-invalid marketing template to a number with no proven opt-in, or send after opt-out if the item was claimed before the state transition.

**Required change before build:** make one final send-eligibility decision authoritative and transactional. It must check active consent evidence and category, opt-out/suppression state, ownership, conversation version, quiet hours/frequency caps, 24-hour window state, active template ID/category/language, and campaign/kill-switch state immediately before changing the outbox item to sendable. Opt-out must atomically invalidate all pending automated sends.

**Acceptance evidence:** tests at 23:59 and 24:01, no-opt-in, wrong-category opt-in, consent withdrawal during dispatch, opt-out after claim, human takeover, disabled template, and campaign stop all produce zero unauthorized provider calls.

Primary source: [WhatsApp Business Messaging Policy](https://whatsappbusiness.com/policy/).

### R2 — High: the n8n pin is real but stale and not reproducible yet

**Where:** Stack; “Exact container digests ... pinned at implementation.”

n8n 2.25.7 is a real upstream release dated 2026-06-10. It is not the current package release on 2026-07-14: the npm registry reports 2.30.4. “Pinning” an older version can be correct, but only when the decision records compatibility and security evidence. The spine records neither. A mutable version tag without an image digest also does not reproduce the reviewed runtime.

This review does **not** recommend blindly changing the table to `latest`. It requires a fresh candidate selection, release-note/security review, regression run, and immutable digest. If 2.25.7 remains, record why it is accepted and how security fixes are monitored/backported.

**Required change before build:** select the candidate from a current supported release, record package version and official image digest, record Node.js/runtime requirements if not using the official image, generate/store an SBOM or equivalent dependency inventory, and define a patch cadence plus rollback. The digest must be the exact artifact used in test and production.

**Acceptance evidence:** deployed `/health` or runtime metadata, image digest, package version, SBOM, upgrade test result, and rollback exercise all agree.

Primary sources: [n8n 2.25.7 upstream release](https://github.com/n8n-io/n8n/releases/tag/n8n%402.25.7), [current n8n package metadata](https://registry.npmjs.org/n8n/latest).

### R3 — High: the transaction boundary is underspecified

**Where:** AD-6, AD-7, AD-8, “Conversation transaction + 06 dispatcher.”

PostgreSQL supports row locks and transaction-level advisory locks, and the n8n Postgres node supports parameterized queries and transaction batching. Those capabilities validate the design in principle. They do not make multiple workflow nodes atomic. A lock taken in one database session/node cannot safely protect a later node that may use another connection, and a failure between “change ownership” and “insert outbox/handoff” violates AD-7.

**Required change before build:** every state transition that must commit with an outbox, handoff, audit event, or follow-up mutation must run inside one database transaction, implemented as one parameterized SQL statement/CTE, one Postgres-node transaction batch, or one narrowly scoped stored function. Use transaction-level advisory locks only inside that same transaction; avoid session-level locks. Define deadlock/serialization retry behavior and a lock timeout.

**Acceptance evidence:** kill the n8n execution after every database statement and prove the database contains either the complete transition or none of it; concurrent duplicate/event tests prove one winner; deadlock/serialization failures retry safely.

Primary sources: [n8n Postgres node transaction and parameter support](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/), [PostgreSQL 17 explicit locking](https://www.postgresql.org/docs/17/explicit-locking.html).

### R4 — High: the “no arbitrary tool authority” rule is not enforced at the n8n instance boundary

**Where:** AD-2 and deployment topology.

AD-2 correctly denies the LLM direct WhatsApp, database mutation, CRM, URL-fetch, and arbitrary-tool authority. However, n8n itself ships nodes capable of command execution, file access, arbitrary HTTP requests, code execution, and credential-backed actions. n8n's own security audit identifies risky nodes, unprotected webhooks, community/custom nodes, unsafe query expressions, and missing settings. Current n8n also has explicit node blocking and SSRF-protection controls; SSRF protection must be enabled, and n8n says network controls remain the primary defense.

The spine currently states a logical rule without stating the controls that keep a workflow editor, imported workflow, compromised credential, or accidental node addition from bypassing it.

**Required change before build:** define an allowed node inventory; exclude command/file and all unneeded nodes with `NODES_EXCLUDE`; prohibit community/custom nodes for the pilot; enable SSRF protection; restrict egress to Meta, the selected LLM, managed PostgreSQL, and the approved handoff endpoint; isolate or exclude Code nodes; use least-privilege per-workflow credentials; protect production editing; run `n8n audit` as a release gate.

**Acceptance evidence:** a production workflow import containing excluded nodes fails; metadata/private-IP/DNS-rebinding probes fail; the security audit has no unapproved risky nodes or unprotected webhooks; production credentials cannot call unrelated APIs.

Primary sources: [n8n security audit](https://docs.n8n.io/hosting/securing/security-audit/), [block access to nodes](https://docs.n8n.io/hosting/securing/blocking-nodes/), [SSRF protection](https://docs.n8n.io/hosting/securing/ssrf-protection/), [task-runner hardening](https://docs.n8n.io/hosting/securing/hardening-task-runners/).

### R5 — High: Meta version and environment assumptions remain unverified

**Where:** AD-13; Stack; “supported WhatsApp Graph API version ... pinned at implementation.”

Deferring the Graph API version until the real Meta app and credentials exist is honest, but it must be an explicit build blocker. No supported version, retirement date, permission set, webhook subscription behavior, template inventory, throughput/quality limit, or test-number behavior is currently proven in this environment.

The sentence “WhatsApp's single-webhook-per-app behavior” is too absolute. This review could not verify that exact formulation in current public primary Meta documentation. Keep separate test and production apps/numbers because they isolate credentials, subscriptions, policy, templates, traffic, and enforcement blast radius; do not base the rule on an unverified platform slogan.

**Required change before build:** with the actual Meta assets, pin the supported Graph API version; record its retirement date and upgrade owner; prove webhook verification/subscription, duplicate and out-of-order event handling, template status lookup, and test/prod isolation. Replace the unverified rationale in AD-13 with the isolation rationale above.

**Acceptance evidence:** credentialed smoke test in both environments, captured app/WABA/phone-number IDs, callback configuration, template IDs/statuses, Graph version, version-retirement alert, and an upgrade smoke test.

Primary source for the currently verifiable policy boundary: [WhatsApp Business Messaging Policy](https://whatsappbusiness.com/policy/). Exact Cloud API capability remains **unverified until credentialed testing**.

### R6 — Medium: Schedule Trigger has deployment preconditions not stated in the spine

**Where:** AD-8 and `05-follow-up-scheduler.json`.

n8n's Schedule Trigger exists and supports fixed intervals and cron-like schedules. The workflow must be published, and execution uses the workflow timezone or instance timezone. Self-hosted n8n defaults to `America/New_York` when no timezone is set. The spine correctly stores business times in UTC, but it does not require the scheduler workflow to be published or the runtime/workflow timezone to be explicitly pinned.

The due-job design is still correct: after downtime, the next run can query all rows whose UTC due time has passed. That catch-up behavior must be in the SQL, not assumed from the scheduler.

**Required change before build:** explicitly publish the scheduler, set instance and workflow timezone, use a bounded `due_at <= now()` catch-up query, and define batch size/backlog alarms.

**Acceptance evidence:** downtime spanning multiple due times produces one eligible send per job after restart; DST/timezone changes do not change stored due times or quiet-hour decisions.

Primary source: [n8n Schedule Trigger documentation](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/).

### R7 — Medium: workflow provenance needs a concrete immutable identifier

**Where:** AD-10, which requires “workflow versions.”

n8n can retain and retry original execution workflows, but execution history is not the business audit authority and can be pruned or deleted with a workflow. n8n's execution-data documentation says pruning is enabled by default, normally after 14 days or above 10,000 executions. Recording only the current workflow name or mutable workflow ID would not satisfy AD-10.

**Required change before build:** define `workflow_release_id` as a Git commit plus canonical exported-workflow hash, or another immutable deployment identifier injected into every workflow. Store it in the business Audit Event, not only n8n execution data. Configure n8n execution retention as diagnostic data and keep business retention separate.

**Acceptance evidence:** an old message remains reconstructable after the n8n execution is pruned and after the workflow is republished.

Primary sources: [n8n execution data and default pruning](https://docs.n8n.io/hosting/scaling/execution-data/), [n8n execution retry behavior](https://docs.n8n.io/workflows/executions/all-executions/).

### R8 — Medium: managed PostgreSQL versioning and service properties are not selected

**Where:** Stack and topology.

PostgreSQL 17.10 is valid, current for major 17, and supported through 2029. PostgreSQL recommends running the current minor. That part of the stack passes.

The deployment says “managed PostgreSQL” without naming a provider or proving that the provider offers exact minor 17.10, permits required extensions/settings, exposes backup/restore, or lets the team control minor patch timing. Managed services commonly expose a major version contract and apply minor patches on their own schedule; this cannot be verified until the provider is chosen.

**Required change before build:** treat PostgreSQL **major 17** as the compatibility target and the provider's current patched minor as the deployment fact, unless the selected provider guarantees exact-minor control. Verify TLS, connection limits/pooling, backup/PITR, restore, maintenance windows, metrics, and regional/data-residency requirements.

**Acceptance evidence:** provider capability record and restore drill; application migrations/tests run against the actual provisioned version.

Primary sources: [PostgreSQL versioning policy](https://www.postgresql.org/support/versioning/), [PostgreSQL 17.10 release notes](https://www.postgresql.org/docs/17/release-17-10.html).

### R9 — Medium: scale-up capabilities are real, but one is license-bound

**Where:** AD-12 and Deferred.

The deferred n8n scale path is technically accurate: queue mode uses Redis as the broker, workers execute queued jobs, and optional webhook processors scale inbound requests. Multi-main provides main-process high availability but is documented as Self-hosted Enterprise functionality. All main and worker processes must run the same n8n version, share PostgreSQL/Redis, and share the encryption key.

The pilot is right not to add Redis or workers before evidence. The upgrade trigger must include license and budget, not only saturation/SLO evidence. Queue mode also adds webhook latency and another required service.

**Required change before scale-up:** record license eligibility, version-lock all components, protect/share the encryption key, load-test queue latency, and test Redis/database failure semantics.

Primary source: [n8n queue mode, workers, webhook processors, and multi-main](https://docs.n8n.io/hosting/scaling/queue-mode/).

## Capability and version verification matrix

| Named item or claim | Status on 2026-07-14 | Reality decision |
| --- | --- | --- |
| n8n 2.25.7 | **Verified release; not current** | Re-baseline and pin tested digest, or document explicit acceptance of the older version. |
| n8n current package | **Verified: 2.30.4** via npm registry | Candidate only; do not deploy `latest`. Test and pin an immutable image. |
| PostgreSQL 17.10 | **Verified current supported 17.x minor** | Sound feature baseline; managed-provider exact minor remains unverified. |
| PostgreSQL row/advisory locks | **Verified** | Use row locks or transaction-level advisory locks in one transaction; define retry/timeout. |
| PostgreSQL unique constraints, UUIDs, `timestamptz` | **Verified native capabilities** | Sound. Schema and migration tests still required. |
| n8n Postgres parameterized queries | **Verified** | Required for all untrusted values. Avoid expression-built SQL identifiers unless allowlisted. |
| n8n Postgres transaction batching | **Verified** | Atomic only within the actual node/query transaction; not across arbitrary workflow nodes. |
| n8n Schedule Trigger | **Verified** | Workflow must be published; pin timezone; SQL must catch up due rows. |
| Redis-backed queue mode and workers | **Verified** | Correctly deferred for pilot; adds latency and operating dependencies. |
| Webhook processors | **Verified optional scale capability** | Correctly deferred; require queue mode/Redis and load balancer. |
| n8n multi-main | **Verified; Enterprise-only** | Add license/budget gate and same-version/shared-key requirements. |
| n8n execution history as diagnostic only | **Verified and appropriate** | Keep AD-1. n8n prunes by default; business audit must remain in PostgreSQL. |
| WhatsApp 24-hour/template rule | **Verified current policy** | Keep AD-9, but add opt-in/opt-out and template-purpose eligibility. |
| “single webhook per Meta app” | **Unverified as written** | Preserve environment separation; replace the rationale. |
| Supported WhatsApp Graph API version | **Unverified/deferred** | Hard build gate before webhook/send implementation; add retirement monitoring. |
| Exact container digests | **Unverified/deferred** | Hard release gate; test and production must use the reviewed digest. |
| LLM provider/model/schema behavior | **Unverified/deferred** | Hard build gate for drafting workflow; benchmark structured output, latency, safety, retention, region, and failure behavior. |
| CRM/handoff API and acknowledgement | **Unverified/deferred** | Keep adapter deferred, but no production handoff claim until credentialed end-to-end proof. |
| Vector retrieval | **Not selected; not needed for pilot** | Correct YAGNI decision. |
| Attachments/voice | **Not selected** | Correctly excluded pending separate threat model. |

## Build-blocking acceptance gates

1. **Runtime gate:** selected n8n version, official image digest, dependency inventory, release/security review, regression result, and rollback proof are recorded.
2. **WhatsApp authority gate:** active opt-in evidence, opt-out suppression, 24-hour calculation, active template eligibility, ownership, and kill switch are one final transactional send gate.
3. **Database atomicity gate:** state/outbox/handoff/audit transitions execute in one PostgreSQL transaction and pass crash/concurrency/deadlock tests.
4. **n8n hardening gate:** allowed-node inventory, `NODES_EXCLUDE`, SSRF plus network egress controls, credential least privilege, protected production editing, and clean `n8n audit` evidence exist.
5. **Meta capability gate:** actual test and production assets prove webhook subscription/verification, supported Graph version, template state, duplicate/out-of-order callbacks, permissions, and environment isolation.
6. **Scheduler gate:** published workflow, explicit timezone, UTC due-query catch-up, backlog limits, and downtime/DST tests pass.
7. **Provenance gate:** immutable workflow release ID survives n8n pruning and reconstructs every outbound decision.
8. **Provider gates:** managed PostgreSQL backup/restore and selected LLM/CRM behavior are verified against their actual environments and contracts.

## Resolution after review

The spine was revised after this review: AD-14 now owns consent/opt-out final authorization; AD-6/AD-7 define one real PostgreSQL transaction; AD-17 enforces n8n hardening; AD-18 pins runtime/API release inputs; n8n was rebased to the verified 2.30.4 candidate; AD-8/AD-10 and Deferred now cover scheduler, provenance, managed PostgreSQL, licensing, and credentialed Meta verification. These changes still require implementation evidence before release.

## Final verdict

**CONDITIONALLY CONVERGED.** R1 through R5 have been converted into AD-14 and AD-17 through AD-23 or retained as explicit external blockers. The spine is adequate authority for independently approved, bounded implementation stories, but this is not production readiness: every applicable build gate still requires current implementation evidence, and Meta, managed PostgreSQL, LLM, Handoff, compliance, and ownership gates remain blocked until their real contracts and environments are approved.
