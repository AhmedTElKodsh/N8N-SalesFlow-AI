# PRD Quality Review — N8N SalesFlow AI

## Overall verdict

This is a disciplined, safety-conscious replacement for the executive concept note: the thesis is coherent, the MVP boundary is honest, and the numbered requirements are substantially more usable than the source. It is not yet a build-authorizing PRD, because the open questions still contain the pilot definition, commercial authority, operating ownership, compliance basis, and success decision rule; several requirements consequently depend on undefined policy terms and acceptance artifacts.

## Decision-readiness — thin

The PRD makes several real decisions clearly: the Assistant has no binding commercial authority (§1, FR-8), deterministic policy gates precede customer-facing side effects (FR-7), human ownership blocks automation (FR-12), and high-availability scaling is excluded from MVP (§5). The addendum also records why the executive proposals were restricted or replaced.

However, §11 leaves unresolved the product and operating decisions that determine what is actually being approved: pilot offer and market, permitted offer autonomy, systems of record, configuration approvers, Handoff destination and SLA, consent/template rules, provider terms, data obligations, success threshold, and release authority. These are not downstream implementation details; most are prerequisites for G0–G6.

### Findings

- **high** Phase-defining decisions are still open (§§10–11) — The twelve Open Questions include the pilot boundary, commercial authority, compliance basis, human coverage, data policy, and success criterion. Architecture and stories could be drafted around mutually incompatible answers. *Fix:* classify each question as launch-blocking or deferrable, assign an executive owner and decision date, and resolve all G0–G6 blockers before changing `status: review-required`.
- **medium** The approval object is unclear (§0, §9) — The document says it is the proposed requirements authority, while the gates say many core policies will be approved later. A reviewer cannot tell whether approval means “approve the guarded product direction” or “authorize implementation.” *Fix:* state the exact gate requested now and the next permitted downstream action if approved.

## Substance over theater — adequate

The journeys drive requirements, the glossary defines the domain, the NFRs are product-specific, and the non-goals remove the unsafe “AI closes deals” premise. There is little persona, innovation, or vision theater.

Some solution design is nevertheless presented as product requirement: “PostgreSQL owns durable business state” (§1), atomic scheduler claims (UJ-4, FR-14), an idempotent outbox (FR-16), and one-runtime/managed-PostgreSQL topology (§6). The addendum is the appropriate home for those mechanisms; the PRD should retain the externally verifiable capability unless the mechanism itself is an executive constraint.

### Findings

- **medium** Architecture choices leak into the requirements authority (§1; UJ-4; FR-14; FR-16; §6) — Database ownership, atomic-claim mechanics, an outbox, and deployment topology narrow architecture before the unresolved scale, RTO/RPO, CRM, and provider decisions are made. *Fix:* keep requirements such as durable state, single logical side effects, and race-safe eligibility checks in the PRD; keep PostgreSQL, outbox, scheduler, and topology decisions in the addendum/architecture unless explicitly approved constraints.

## Strategic coherence — adequate

The product has a clear thesis: improve consistency and sales-team focus by automating bounded work without delegating commercial authority. The MVP capabilities, non-goals, rollout gates, primary metrics, and counter-metrics generally follow that thesis.

The strategy remains weakly evidenced. The PRD does not describe the verified current funnel, response-delay problem, qualification burden, error rate, or representative workload. SM-1 says accepted qualified Handoffs “improves” but supplies no definition of eligible Conversation, baseline, target, measurement period, sample size, or control method, so it cannot yet validate the thesis or decide pilot continuation.

### Findings

- **high** The primary business outcome is not a decision rule (§7, SM-1; §11.9) — “Improves against the approved baseline/control” is directionally correct but cannot produce a go/no-go result without a denominator, baseline, materiality threshold, observation window, and attribution method. *Fix:* define eligible Conversation, accepted Handoff, exclusion rules, baseline/control design, minimum meaningful improvement, pilot duration, and required sample before G9.
- **medium** The problem thesis lacks current-state evidence (§1) — The PRD asserts response consistency and sales-team focus as the opportunity without source data or an explicit assumption tag. *Fix:* add a short evidence-backed current-state problem statement, or tag the unverified funnel and workload claims as assumptions to be tested during the pilot.

## Done-ness clarity — thin

All twenty FRs have a consequence, and many are directly testable: duplicate handling, Human-Owned lockout, fail-closed commercial validation, audit reconstruction, and follow-up eligibility are particularly clear. The rollout gates provide a useful cross-cutting acceptance frame.

Done-ness still depends on policy words whose controlling artifacts do not yet exist. Examples include “configured opt-out signals” (FR-3), “approved qualification fields” (FR-5), “low confidence” and “approved fallback” (FR-6), “disallowed sensitive-topic handling” and “critical policy violation” (FR-9), “authorized explicit release” (FR-12), and “configured number” of Follow-Ups (FR-13). The NFR section likewise names controls without consistently giving bounds or test oracles.

### Findings

- **high** Core FR acceptance relies on undefined policy terms (FR-3, FR-5, FR-6, FR-9, FR-12, FR-13) — Engineers can implement different, apparently compliant behaviors because the thresholds, controlled vocabularies, fallback content, approver roles, and frequency limits are absent. *Fix:* define the minimum Sales Policy/Product Knowledge contracts and named acceptance artifacts, or explicitly make their approved versions prerequisites to story readiness.
- **medium** Several NFRs are controls rather than acceptance criteria (§6) — “No data loss,” “n8n security audit,” approved data minimization, and alerts for backlog/failure/unknown status lack test scope, thresholds, retention period, alert response expectation, or approved RTO/RPO. *Fix:* add measurable pilot bounds and validation evidence for each launch-blocking NFR; leave production SLOs open only with owner and revisit condition.

## Scope honesty — strong

The PRD is unusually candid about what the MVP will not do. §5 removes autonomous negotiation, legal deal closure, cold outbound, custom UI, multimodal handling, multi-tenant/multi-market expansion, premature retrieval infrastructure, and premature HA. Inline assumptions are visible, twelve open questions are explicit, and the addendum preserves the rationale behind rejected executive mechanisms.

The high open-item density is therefore not hidden scope; it is an implementation-readiness blocker already signaled by the document status. The main improvement is triage, not additional scope prose.

## Downstream usability — adequate

The glossary, contiguous FR/UJ/SM identifiers, named protagonists, requirement groupings, consequence blocks, non-goals, and rollout gates give UX, architecture, security, and story workflows strong extraction anchors. The addendum correctly carries model-selection, knowledge, follow-up, and scaling rationale.

The operational lifecycle is incomplete. UJ-2 assumes an “assigned” representative but no requirement assigns or queues one. FR-13 refers to `closed/lost` and “campaign stop,” although neither states nor campaign ownership are defined. The Handoff destination, acknowledgement SLA, after-hours path, notification failure operations, and authority to release Human-Owned conversations remain open (§11.5, §11.11). These gaps prevent one consistent state model and end-to-end Handoff story set.

### Findings

- **high** Conversation and Handoff lifecycle cannot yet be modeled consistently (UJ-2; FR-10–FR-13; §11.5, §11.11) — Assignment, acknowledgement timeout, after-hours behavior, notification escalation, `closed/lost`, campaign state, and release authority are either assumed or undefined. *Fix:* after the executive decisions, add the authoritative Conversation/Handoff states, permitted transitions, actor for each transition, timeout/failure outcomes, and the requirement that owns assignment.

## Shape fit — adequate

For a chain-top, multi-stakeholder B2B automation with commercial, privacy, messaging-policy, and operational risk, the journey-led capability shape is appropriate. Four journeys are load-bearing rather than decorative, and the separate governance, NFR, rollout, dependency, and open-question sections are justified by the stakes.

The document is slightly over-shaped toward architecture through mechanism-level FRs, but not bloated overall. Moving the few named mechanisms to the addendum would preserve its strong product shape while leaving architecture room to choose the smallest compliant design.

## Resolution after review

The PRD now states that approval permits technical epic planning, not implementation; defines the missing controlled terms; separates technical foundation stories from production-contract blockers; assigns technical-impact decisions to owners/gates; and narrows Handoff adapter work until its external acknowledgement contract exists. The business improvement threshold remains deliberately outside technical story readiness and belongs to G9 evaluation.

## Mechanical notes

- FR-1 through FR-20 and UJ-1 through UJ-4 are contiguous and unique. SM-1 through SM-7 and SM-C1 through SM-C4 are distinguishable and have no duplicate IDs.
- The four inline assumption groups round-trip to §12, but “Product brief source assumption” appears only in the index, contrary to §0’s statement that inline assumptions are indexed. Add the inline tag at the relevant thesis/current-state claim or remove the orphan index entry.
- `closed/lost`, campaign state, “eligible Conversation,” “release set,” “critical policy violation,” and “approved fallback” are used as controlled concepts but are not defined in §3.
- Cross-references from cited FRs to UJs and SMs resolve. Not every FR maps to a UJ or SM, which is acceptable here because the rollout gates cover operational and governance requirements.
- Each UJ has a named protagonist carrying role context inline.
- The addendum is consistent with the PRD’s rejection of direct model-to-WhatsApp sends, stale model examples, autonomous closure, phone-number-only identity, and premature queue-mode scaling.
