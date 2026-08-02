# Architecture Divergence Review — N8N SalesFlow AI

## Original verdict (superseded by resolution)

**Not convergent enough for independent downstream implementation at the time of review.** The deterministic lint passed, but two implementations could obey AD-1 through AD-18 and still disagree at shared database contracts, inbound ordering, send authorization concurrency, knowledge revocation, Handoff completion, and external retry exhaustion. See **Resolution after review** and **Gate result** for current status.

## Constructed downstream units

Both units below use PostgreSQL as authority, a stateless untrusted LLM, serialized state mutations, unique logical action keys, transactional outbox records, due-job Follow-Ups, the ordered AD-14 gate on every send/retry, Human-Owned transfer on model failure, separate environments, the single pilot topology, the AD-17 tool boundary, and pinned release inputs. Their differing choices are not forbidden by any AD Rule.

| Choice left by the spine | Unit A | Unit B |
| --- | --- | --- |
| Cross-workflow records | Each workflow owns direct SQL and writes a JSON payload to the shared outbox. | A database package owns mutations and exposes typed stored commands/views to workflows. |
| Inbound order | Serialize by database receipt sequence. | Serialize by provider timestamp plus message ID after a short reorder window. |
| Send linearization | Commit the AD-14 result and mark the intent `dispatching`, then call WhatsApp. | Acquire a short dispatch lease tied to Conversation version, then call WhatsApp. |
| Product Knowledge revocation | A turn's Product Knowledge snapshot remains usable until the turn finishes. | Dispatcher requires the snapshotted Product Knowledge version to remain non-revoked. |
| Handoff completion | Adapter HTTP `2xx` means the Handoff notification is complete. | Completion requires a Sales Representative acknowledgement; timeout requeues or escalates. |
| External retry exhaustion | Retry every `retryable` send indefinitely with bounded backoff. | Stop after a bounded attempt/age budget and move to operator reconciliation. |

Every row is a legitimate reading of the current spine. Unit A and Unit B therefore cannot be safely composed without decisions that the spine has not made.

## Findings

### 1. Shared record contracts and mutation ownership are not fixed — critical

**Hole:** AD-1 names PostgreSQL as authority, AD-7 constrains transaction shape, and AD-15 pins schema releases, but no AD owns each shared aggregate or defines the versioned contract between workflow writers and readers. “Exact schema columns and indexes” are deferred even though the Structural Seed splits ingress, orchestrator, outbox, status, Follow-Up, Handoff, and operations into independently buildable units.

**Compliant divergence:** Unit A's orchestrator can write an outbox row with `payload jsonb`, local status names, and direct Conversation updates. Unit B's dispatcher can expect typed recipient/template/body columns and status changes performed through stored commands. Both satisfy durability, idempotency, transactions, version pinning, and parameterized SQL, yet they do not interoperate.

**Required closure:** Add an AD assigning one owner to schema migrations and aggregate mutation contracts. Fix the minimum cross-unit contract—canonical record identifiers, required fields/statuses, writer ownership, and compatibility/versioning mechanism—without specifying incidental columns or indexes. Downstream workflows must consume that contract rather than invent table semantics.

### 2. The send-versus-suppression linearization point is undefined — high

**Hole:** AD-14 says the gate runs “immediately before” every provider call and that opt-out invalidates pending intents, but it does not define when an intent stops being pending, the linearization point for authorization, or the permitted result when opt-out/Human takeover races the external HTTP call. A database transaction cannot be atomic with WhatsApp.

**Compliant divergence:** Unit A commits `dispatching` after the gate and treats a later opt-out as too late. Unit B issues a short version-bound lease and lets a concurrent lifecycle mutation invalidate it until the provider request begins. Both gate before the call, record failures, and use the outbox; they disagree on whether the same raced message is sent.

**Required closure:** Define the dispatch state/lease protocol and exact authorization linearization point, state whether claimed work is still cancellable, forbid holding database locks across the network call, and explicitly document the unavoidable in-flight race plus its audit/reconciliation outcome.

### 3. Serialization does not define canonical inbound order — high

**Hole:** AD-5 deduplicates and AD-6 serializes, while AD-13 only asks smoke tests to observe duplicate/out-of-order behavior. No Rule chooses the order key, tie-break, late-event behavior, or rapid-message coalescing window.

**Compliant divergence:** Unit A processes `received_at` sequence. Unit B waits briefly and orders by provider timestamp/message ID. If a customer's “yes” and later “no” arrive out of order, both produce a single serialized history but can send different replies or create different Handoffs.

**Required closure:** Add the canonical ordering key and deterministic tie-break, define what happens to an event older than the committed turn, and decide whether rapid consecutive customer messages are coalesced before drafting.

### 4. Product Knowledge has provenance but no safety-revocation semantics — high

**Hole:** AD-10 snapshots Product Knowledge, but AD-4 and AD-14 revalidate only Sales Policy and messaging controls. No invariant says whether a Product Knowledge correction or safety withdrawal cancels already-created intents.

**Compliant divergence:** Unit A sends using the approved Product Knowledge snapshot selected at turn creation. Unit B suppresses when that version has since been safety-revoked. Both preserve immutable provenance and use approved bounded context, but one can send a fact that operations has withdrawn.

**Required closure:** Define ordinary replacement versus safety revocation for Product Knowledge and require the authorization gate to reject a safety-revoked knowledge version before send. State whether the result is recompute, approved fallback, or Handoff.

### 5. Handoff delivery and acknowledgement remain a build-time fork — high

**Hole:** AD-3 and AD-16 correctly transfer ownership before notification, but neither defines notification success, assignment, acknowledgement, timeout, or permanent-failure escalation. The CRM/Handoff adapter and acknowledgement SLA are Deferred while `06-handoff-dispatcher.json` remains in the build seed.

**Compliant divergence:** Unit A treats adapter `2xx` as complete and leaves the Conversation Human-Owned. Unit B requires representative acknowledgement and requeues/reassigns on timeout. Both create one Handoff transactionally and never restore AI ownership; only one guarantees that a human actually accepted the customer.

**Required closure:** Either mark every Handoff-dispatcher story blocked until the executive decision, or add the selected delivery/acknowledgement state machine, owner, timeout, permanent-failure path, and customer/operations behavior as an AD.

### 6. External retry exhaustion is not shared — medium

**Hole:** The Error convention supplies a typed category and `retryable` flag, AD-14 re-gates retries, and AD-6 bounds only lock/serialization retries. There is no common attempt budget, maximum age, backoff/jitter envelope, terminal state, or reconciliation rule for WhatsApp, CRM, and LLM/provider failures.

**Compliant divergence:** Unit A retries a retryable outbox record indefinitely; Unit B stops after an attempt/age budget and exposes it for operator action. Both are idempotent and re-authorize each attempt, but they produce incompatible backlog, alert, and recovery semantics.

**Required closure:** Define one retry envelope contract with per-action overrides: attempt and age limits, backoff/jitter, terminal status, alert threshold, and the only allowed operator replay path using the original logical action key.

## Resolution after review

AD-19 closes shared schema/mutation ownership; AD-20 defines canonical inbound order; AD-21 defines the dispatch lease and external linearization boundary; AD-22 defines Product Knowledge safety revocation; AD-23 centralizes finite retry exhaustion. Handoff acknowledgement remains intentionally blocked until the selected external adapter and operating SLA define a real technical contract.

## Gate result

- Deterministic lint: pass, zero findings.
- Findings 1–4 and 6: closed by AD-19 through AD-23.
- Finding 5: intentionally blocked until the Handoff adapter and operating SLA become an approved contract.
- Handoff recommendation: bounded stories that do not depend on Finding 5 may proceed only after story-level approval; Handoff delivery/acknowledgement remains blocked.
