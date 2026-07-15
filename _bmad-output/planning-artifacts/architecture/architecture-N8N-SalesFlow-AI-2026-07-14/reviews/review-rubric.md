# Architecture Spine Reviewer Gate — Rubric Walker

**Reviewed:** `../ARCHITECTURE-SPINE.md`  
**Date:** 2026-07-14  
**Intent:** Validate only; the spine was not edited.  
**Verdict:** **CHANGES REQUIRED** — mechanically sound and directionally strong, but not yet a safe build substrate because independently built dispatchers can disagree about whether sending is permitted, ownership and lifecycle state have conflicting representations, and provider-status concurrency is underspecified.

## Deterministic lint

`lint_spine.py` passed with **0 findings**. AD IDs are unique, all ADs contain Binds/Prevents/Rule, no placeholders remain, and stack versions are pinned.

## Good-spine checklist

| Check | Result | Review |
| --- | --- | --- |
| Fixes the real divergence points one level down | **Fail** | A shared pre-send authorization invariant is missing; reactive replies, Follow-Ups, retries, and dispatcher paths can enforce different eligibility sets. |
| Every AD Rule is enforceable and prevents its stated divergence | **Partial** | Most rules are testable. AD-3 conflicts with the state diagram, AD-8 relies on undefined “all eligibility conditions,” and AD-7 permits provider status regression. |
| Deferred contains no item that can cause incompatible units | **Partial** | Infrastructure and adapter deferrals are sound. Invalid/low-confidence model behavior and policy-version race behavior are neither decided nor explicitly deferred. |
| Named technology is verified-current | **Pass** | n8n 2.25.7 is the current signed release shown by the official project; PostgreSQL 17.10 is the current supported 17.x minor. PostgreSQL 17 remains supported through 2029. |
| Ratifies rather than contradicts brownfield reality | **Pass / greenfield** | No application implementation or `project-context.md` exists to contradict. The spine correctly treats the installed BMAD scaffold as planning infrastructure, not product architecture. |
| Covers the driving PRD capabilities | **Fail** | FR-3 and FR-19 precedence across every outbound path, FR-17 monotonic status reconciliation, and important FR-20 lifecycle/restore responsibilities are not fixed as invariants. |
| Preserves inherited parent invariants | **N/A** | No parent spine is declared. |
| Every owned dimension is decided, deferred, or open | **Fail** | The deployment topology is present, but operational authority, backup/restore ownership, data-deletion completion, and model failure/fallback behavior remain silent. |

## Findings

### Critical — C1: There is no single authoritative send-authorization gate

**Evidence:** AD-3 blocks automation for Human-Owned Conversations; AD-4 validates commercial policy; AD-8 rechecks unspecified “all eligibility conditions” only for Follow-Ups; AD-9 gates the WhatsApp window. No rule binds **every** outbound customer-message path immediately before dispatch to the same precedence order. FR-3 requires opt-out to suppress all pending outbound work, while FR-19 requires a global stop and per-Conversation disable.

**Failure construction:** The reactive-reply dispatcher obeys AD-3, AD-4, AD-7, and AD-9 but does not check the global kill switch because only the Follow-Up scheduler interprets it as an eligibility condition. A retrying outbox dispatcher sends an already-created intent after an opt-out because it considers the intent previously authorized. Both units obey every current AD yet violate FR-3/FR-19.

**Treatment:** **Autofix.** Add one AD requiring a single deterministic authorization decision immediately before every external customer send, including retries. Enumerate precedence at minimum: global stop, Contact/Conversation disable, opt-out/consent, ownership/lifecycle, stale version, policy validation, window/template, quiet hours/frequency/campaign eligibility. A failed check must atomically suppress or cancel the intent and audit the reason.

### High — H1: Ownership and lifecycle state are modeled incompatibly

**Evidence:** AD-3 says a Conversation is “exactly AI-Owned or Human-Owned.” The state diagram instead presents `ai_owned`, `human_owned`, `opted_out`, and `closed` as mutually exclusive states. Units can therefore implement one four-value enum or separate ownership and lifecycle fields.

**Failure construction:** One workflow transitions `human_owned → closed` and loses the last owner; another keeps `owner=human` with `lifecycle=closed`. Authorization, release, audit, and reporting then disagree while both implementations conform to different spine sections.

**Treatment:** **Autofix.** Define orthogonal dimensions, for example `automation_owner = ai|human` and `lifecycle = active|opted_out|closed`, with precedence rules; or explicitly expand AD-3 to one canonical state machine. Make release legal only for the intended lifecycle states.

### High — H2: Provider delivery status can regress under concurrency

**Evidence:** AD-7 lets the dispatcher update provider status on the outbox row, while the status-callback workflow also updates it. No transition order or compare rule is defined.

**Failure construction:** WhatsApp’s `delivered` callback commits before the original dispatcher records `sent`; the dispatcher then overwrites `delivered` with `sent`. Another unit stores every callback append-only and derives the current status. Both obey AD-7/FR-17 but expose incompatible truth.

**Treatment:** **Autofix.** Define an append-only provider-status event ledger or a monotonic transition rule with allowed transitions and terminal-state protection. Unknown/out-of-order callbacks must remain auditable without downgrading derived current status.

### High — H3: The operational and data-lifecycle envelope is incomplete

**Evidence:** AD-12 chooses pilot topology but does not assign runtime configuration/secrets, backup, restore, migration, recovery, monitoring/alert ownership, or deletion completion. AD-11 covers scoped queries and model minimization but not retention/deletion propagation or backup expiry. The PRD makes kill-switch drills, backup/restore, retention, and deletion launch gates.

**Failure construction:** Database migrations and workflow imports can be deployed in either order with no compatibility rule. One deletion workflow deletes live rows but not backups or execution data; another waits for backup expiry and reports completion differently. Both can claim compliance with the current spine.

**Treatment:** **Discuss, then autofix the settled minimum.** Add an operations invariant covering deployment ordering/rollback, secret ownership, backup/restore authority, and observability ownership. Add a data-lifecycle invariant naming the authoritative deletion record, affected stores, completion semantics, and backup-retention treatment. Leave numeric RTO/RPO and retention periods open if executives have not approved them.

### High — H4: Invalid or low-confidence model output has two permitted outcomes

**Evidence:** AD-2 requires a schema-valid draft but does not state the action when validation fails, sources conflict, confidence is low, or the provider is unavailable. The PRD permits “Handoff or approved fallback,” which is a deliberate product fork, not one deterministic outcome. It is absent from Deferred.

**Failure construction:** One orchestrator sends a canned fallback and retains AI ownership; another atomically hands off and locks automation. Each obeys AD-2 but produces incompatible customer and ownership behavior.

**Treatment:** **Discuss.** Choose one default per failure category, or add an explicit typed policy mapping whose published version deterministically selects fallback versus Handoff. Until chosen, add it as an open item/Deferred blocker.

### Medium — M1: `generation` is part of idempotency but has no canonical allocation rule

**Evidence:** AD-5’s unique action key includes `generation`; AD-8 mentions Follow-Up generation but does not define when it increments or whether a retry reuses it.

**Risk:** A unit that increments generation on execution retry defeats deduplication, while another increments only when a new logical job is committed.

**Treatment:** **Autofix.** State that generation is allocated once when a new logical turn/follow-up is committed; delivery/workflow retries reuse it, and only an explicit superseding action increments it.

### Medium — M2: Policy publication racing an in-flight turn is unresolved

**Evidence:** AD-4 validates against one published version and AD-10 records versions, but neither states whether a turn binds the version at intake, at draft, at send-intent creation, or revalidates against the latest version immediately before send.

**Risk:** Two orchestrators can legally validate the same in-flight draft against different policy versions.

**Treatment:** **Discuss.** Fix a policy: snapshot at turn creation and honor through send, or require latest-policy revalidation before intent/dispatch. Define what happens when the selected version is revoked for safety.

## What already holds

- The named pipes-and-filters paradigm, PostgreSQL authority, stateless LLM boundary, deterministic commercial gate, serialized turns, durable outbox, and due-job scheduler form a coherent core.
- The structural seed is small, the dependency direction is explicit, and infrastructure scale is correctly deferred behind evidence.
- Test/production Meta separation directly addresses n8n’s documented one-webhook-per-app behavior.
- Technology verification: [n8n official releases](https://github.com/n8n-io/n8n/releases), [PostgreSQL 17.10 release](https://www.postgresql.org/docs/release/17.10/), and [PostgreSQL versioning policy](https://www.postgresql.org/support/versioning/).

## Gate decision

Do not finalize the spine until C1 and H1–H2 are corrected. H3–H4 require explicit decisions or bounded open/deferred items with revisit conditions. M1 is a safe mechanical clarification; M2 requires a policy choice.
