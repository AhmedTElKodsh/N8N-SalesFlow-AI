# SalesFlow local test evidence

Date: 2026-08-25
Runtime: n8n 2.30.4 and PostgreSQL 17.10, both digest-pinned in `compose.yaml`
Command: `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`

## Result

The synthetic-local run was re-executed after SP3-T2 duplicate-protected message sending and completed with `PASS FULL PASS` and exit code 0. The harness also reported that plaintext credentials and container volumes were removed. Before the canonical run, Docker client/server readiness and both digest-pinned PostgreSQL and n8n images were verified, and this repository's disposable Compose state was clean.

Verified evidence includes:

- clean and legacy migration idempotence, deterministic `processing_body` backfill, and a least-privilege n8n database role;
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
- strict integer/set configuration validation, audited immutable save/activation/rollback, bounded activation locking, incompatible-version rejection, account disablement, service-window policy, pre-call retry/lease recovery, deletion minimization of inbound, intent, and provider identity evidence, and single-active release rotation bound to release-v9;
- seven workflow imports, activations, publications, and real connected endpoint paths;
- automatic ingress-to-orchestrator-to-dispatch and ingress-to-Handoff completion, mixed Meta-envelope text preservation, explicit callback/operations HTTP error classes, operator publication through Workflow 07, propagated database failures, concurrent callback collapse, actual UTC Schedule Trigger recovery of expired outbound/Handoff claims, final pre-adapter authorization checks, and account-bound operations terminals;
- source versus imported/exported canonical workflow identity;
- approved native-node inventory and generated export secret scans;
- generated plaintext credential and Docker-volume cleanup.

## Scope boundary

This evidence proves the disposable synthetic-local implementation only. It does not prove production Meta delivery, a production LLM, a CRM/Handoff acknowledgement, managed PostgreSQL security/backup controls, approved customer sales and knowledge content, legal/privacy wording, or production-owner approval. `release/release-manifest.json` therefore keeps `livePromotionAllowed` set to `false`.
