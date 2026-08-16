# AI-Guided SalesFlow Tutoring Product Design

**Date:** 2026-08-16

**Status:** Approved design

**Primary learner:** Junior developer with basic programming knowledge and little production PostgreSQL, Docker, n8n, or distributed-systems experience

## Purpose

Turn the existing conversational teaching promise into a durable tutoring product that guides a junior learner through building N8N SalesFlow from a clean starter state to a verified synthetic-local implementation.

The product uses repository-native lessons, checkpoints, progress evidence, and an interactive AI tutor. The AI adapts explanations and hints to the learner's current obstacle but does not provide a direct solution unless the learner explicitly requests one.

## Problem

The current teaching contract exists only in Party Mode memory. The repository has no project-specific curriculum, learning objectives, milestone checkpoints, hint protocol, mastery rules, or portable progress record. A new AI session cannot reproduce the intended teaching behavior without chat history.

The completed implementation is also too dense to serve directly as a junior learning workspace. The learner would face n8n, PostgreSQL, Docker, concurrency, authorization, privacy, and distributed side effects simultaneously. The canonical test harness provides strong release evidence but is too broad and slow to be the only feedback mechanism during learning.

## Goals

- Guide the learner interactively from project start to completion.
- Introduce each technical concept only when the next project step requires it.
- Preserve learner agency through attempts, questions, and progressively stronger hints.
- Keep the completed implementation separate from the learner workspace.
- Make tutoring behavior and progress reproducible without chat history.
- Require both correct behavior and demonstrated understanding before progression.
- Use focused checks during milestones and the complete release suite at the capstone.
- Distinguish learner mistakes from environment, tooling, and curriculum defects.

## Non-goals

- A general-purpose programming curriculum.
- A browser learning-management system or custom dashboard.
- Automatic production deployment.
- Replacing the synthetic model, Meta, or Handoff adapters during the tutoring-product implementation.
- Solving every existing production-readiness gap in the first implementation plan.
- Scoring learners competitively or penalizing them for requesting hints.

## Teaching approach

The curriculum uses a milestone-gated vertical-build spiral. The learner creates a small working end-to-end path early, then revisits that path to add identity, persistence, authorization, idempotency, ordering, governed decisions, retries, reconciliation, scheduling, privacy, observability, and release proof.

Each teaching exchange follows three just-in-time limits:

1. Address only the active milestone and its immediate prerequisite.
2. Begin with one mental model and no more than three new technical terms.
3. Expand only when the learner's attempt, question, or evidence shows that more explanation is necessary.

The tutor gives one actionable step at a time and waits for the learner's attempt or evidence before advancing.

## Workspace and branch model

The completed implementation and the learning workspace are separate:

- `reference/salesflow-complete-v1` identifies the immutable completed reference.
- `starter/salesflow-guided-v1` identifies the immutable clean starter.
- Each learner works on a branch created from the starter revision.
- Product `main` evolves independently and is not silently used as either teaching baseline.
- `learning/curriculum.yaml` records the exact starter and reference revisions.

The starter retains project context, architecture boundaries, configuration contracts appropriate to the current milestone, and learning infrastructure. It does not expose completed workflow or SQL solutions.

Ordinary tutoring may inspect the learner branch, milestone contract, relevant documentation, focused test output, and learner progress. It may not inspect or copy the completed reference implementation. Reference access is allowed only for curriculum maintenance, checkpoint verification, or after an explicit direct-solution request.

## Repository structure

```text
learning/
├── README.md
├── tutor-contract.md
├── curriculum.yaml
├── progress-template.json
├── journal.md
└── milestones/
    ├── M00-orientation/
    │   ├── lesson.md
    │   ├── checkpoint.yaml
    │   └── hints.md
    └── M01...M10/

scripts/
└── learn.ps1

tests/
└── learning/
    └── milestone-specific checks
```

The root AI instructions point supported development clients to `learning/tutor-contract.md`. Client-specific wrappers may locate the canonical contract but may not redefine it.

`.learning/progress.json` stores local machine-readable progress and is ignored by Git. `learning/journal.md` and learner implementation commits store durable learning evidence. Progress can be reconstructed by rerunning completed milestone checks if the local progress file is lost.

## Milestone contract

Every milestone defines:

- Purpose and visible SalesFlow capability.
- Prerequisites limited to completed milestones.
- The minimum just-in-time concepts required.
- A learner task expressed as observable behavior rather than implementation steps.
- Architectural and safety constraints.
- One focused deterministic checkpoint command.
- A progressive hint ladder.
- An explanation question covering data flow and a design decision.
- A realistic failure-mode question.
- A small transfer exercise.
- Machine-readable completion evidence.

The `checkpoint.yaml` file identifies prerequisites, allowed files, focused commands, expected evidence, and completion gates. It contains no solution source or source-equality assertion.

## Interactive tutor protocol

For each milestone, the AI tutor must:

1. Verify the expected learner branch and starter lineage.
2. Read the curriculum, current milestone, local progress, journal, and working diff.
3. Orient the learner to the next visible capability and explain why it matters.
4. Ask for a prediction or proposed approach before implementation.
5. Allow the learner to attempt the work.
6. Inspect the learner's code, output, and reasoning.
7. Classify the current obstacle before teaching or suggesting changes.
8. Explain only the concept blocking the current step.
9. Escalate through the hint ladder one level at a time.
10. Run or interpret the focused checkpoint.
11. Require the learner's explanation, failure analysis, and transfer exercise.
12. Record completion evidence and unlock the next milestone only when both gates pass.

The tutor must not perform the learner's implementation, silently patch files, reveal reference code, or jump ahead during ordinary guidance.

## Hint and solution disclosure policy

Hints escalate in this order:

1. Restate the goal or ask a diagnostic question.
2. Explain the blocking concept with a small unrelated example.
3. Point to the relevant interface, file, node, table, or function.
4. Describe the required structure or data flow without exact implementation.
5. Provide pseudocode or an incomplete skeleton.

A complete code, SQL, workflow, or command solution requires an explicit learner request. When requested, the tutor must:

- State that it is switching to direct-solution mode for the named step.
- Limit the solution to that step.
- Record that direct help was requested.
- Require the learner to remove or close the solution view, reconstruct the behavior, explain it, and complete an additional transfer check.

Hint use never lowers a score or blocks completion by itself.

## Curriculum

### M00 — Repository orientation

Map the project, establish Git/worktree safety, distinguish n8n orchestration from PostgreSQL state ownership, and explain the synthetic-local versus production boundary.

### M01 — Smallest local stack

Start PostgreSQL and n8n safely. Introduce containers, services, ports, environment variables, health checks, volumes, and cleanup only as required to reach a healthy local state.

### M02 — First vertical slice

Build a webhook-to-database-to-typed-response path. Introduce n8n triggers, nodes, expressions, query parameters, transactions, and typed terminals through one working behavior.

### M03 — Durable identity

Add accounts, contacts, conversations, inbound messages, and migrations. Introduce primary keys, composite account scope, foreign keys, and immutable inbound evidence.

### M04 — Safe repetition

Handle replay, conflict, ordering, and concurrent messages. Introduce uniqueness, idempotency, serialization, deterministic conflicts, and focused race tests.

### M05 — Governed intelligence

Add typed Product Knowledge, Sales Policy, model, qualification, provenance, synthetic turn decisions, and fail-closed Handoff. Explicitly distinguish deterministic fixtures from real LLM behavior.

### M06 — Authorized side effects

Add consent, persisted outbound intent, claim, immediate authorization recheck, adapter execution, and finish. Introduce the transactional outbox, leases, remote idempotency keys, and the remote-success/local-persistence-failure ambiguity.

### M07 — Recovery and reconciliation

Add bounded retry, backoff, provider callbacks, monotonic status, expired-claim recovery, ambiguous outcomes, and reconciliation evidence.

### M08 — Time and human ownership

Add UTC Follow-Ups, service windows, templates, opt-out precedence, Human-Owned lockout, Handoff dispatch, and scheduler recovery.

### M09 — Responsible operations

Add correlation and evidence, deletion and minimization, enforceable retention, secret boundaries, release identity, rollback behavior, and operational alert requirements.

### M10 — Capstone

Run the complete suite, trace a scenario from inbound event to terminal evidence, explain critical failure modes, and identify every external production gate the synthetic implementation cannot prove.

## Progress and assessment

The progress record contains:

- Curriculum and starter version.
- Current milestone and status.
- Attempt count and focused-check results.
- Highest hint level used.
- Learner explanation and identified failure mode.
- Transfer-exercise evidence.
- Evidence commit or working-tree identity.
- Direct-solution request state.
- Resume notes.

Every milestone has two independent completion gates:

1. **Behavior gate:** deterministic checks prove the implementation satisfies the milestone contract.
2. **Understanding gate:** the learner explains the data flow, one design decision, and one realistic failure mode, then passes the transfer exercise.

A green test alone never unlocks the next milestone. The tutor records the learner's explanation without rewriting it into an idealized answer.

## Validation layers

- `learn.ps1 status` reports the current milestone, branch/baseline state, and available action.
- `learn.ps1 start <milestone>` verifies prerequisites and initializes the milestone attempt.
- `learn.ps1 check` runs the current focused checkpoint.
- `learn.ps1 complete` verifies both gates and records evidence.
- `learn.ps1 resume` reconstructs context from progress, Git state, and checkpoint evidence.

Focused checks validate behavior and invariants, never textual similarity to the completed solution. Database and workflow integration checks appear only after their prerequisites exist. Major curriculum gates run the relevant subsystem suites. M10 runs the complete release harness.

Focused checks should normally complete within 30 seconds. Checks requiring a container rebuild or the full release environment must state that cost before execution.

## Failure classification and recovery

Before explaining a failure, the tutor classifies it as one of:

- Environment or tooling failure.
- Syntax or integration failure.
- Behavioral checkpoint failure.
- Conceptual misunderstanding.
- Curriculum or checkpoint defect.

Environment failures do not count as learner mistakes. The tutor repairs or guides repair of the environment, reruns the same checkpoint, and preserves the learner's current implementation.

Checkpoint output names the violated invariant, relevant observed value, and diagnostic location. It does not display a reference diff or completed implementation.

On resume, the tutor verifies the branch and starter lineage, reads local progress and the learner journal, inspects uncommitted work, reruns the narrowest useful check, and continues from the last incomplete gate.

## Security and privacy boundaries

- Production credentials and customer data never enter tutor prompts, lesson fixtures, progress files, or test output.
- Lessons use deterministic synthetic accounts and data.
- Direct-solution records contain only milestone metadata, not private conversation transcripts.
- The reference solution remains read-only during curriculum validation.
- Learner scripts do not delete local environments or volumes without an explicit reset flag and a validated project scope.

## Implementation phases

### Phase 1 — Tutoring product

Create the canonical tutor contract, curriculum, M00–M10 milestone artifacts, progress schema, learner journal, `learn.ps1`, focused checkpoint framework, starter/reference lineage checks, and AI-client pointers.

### Phase 2 — Reproducible learning environment

Define repository line endings, make manifest verification platform-stable, add focused test selection, improve diagnostic output, and ensure clean starter setup and recovery.

### Phase 3 — Educational source presentation

Provide readable, modular educational SQL and workflow sources while generating or validating canonical runtime artifacts. Remove superseded definitions from the learner-facing path without losing migration history.

### Phase 4 — Reliability hardening

Implement and teach provider idempotency/reconciliation for remote-success/local-failure ambiguity, then add enforceable retention and stronger operational evidence.

### Phase 5 — Production-facing hardening

Address real webhook authentication, secrets isolation, adapter contracts, observability, rollback, backup/restore, and production acceptance evidence only after external owners and providers are selected.

Each phase after Phase 1 receives its own implementation specification and plan. Phase 1 must not silently absorb production-adapter work.

## Success criteria

- A new AI session can resume tutoring from repository and progress artifacts without prior chat history.
- A junior learner can identify the active milestone and next action without reading the completed implementation.
- The tutor introduces no future milestone concepts unless required to resolve an active blocker.
- The tutor does not reveal a direct solution without an explicit request.
- Every milestone has a focused behavior check and an understanding gate.
- The reference solution remains separate and is not required in the learner worktree.
- Focused checks provide actionable invariant-level feedback.
- The complete synthetic-local implementation and full release evidence remain the M10 destination.
- Production limitations remain explicit throughout the curriculum.

## Risks and mitigations

- **AI over-explains or solves the task:** canonical tutor protocol, one-step exchanges, disclosure ladder, and direct-solution logging.
- **Curriculum becomes stale as `main` evolves:** immutable starter/reference revisions and explicit curriculum versioning.
- **Tests reward copying rather than understanding:** behavior-based checks plus explanation and transfer gates.
- **Learner is blocked by infrastructure:** failure classification, focused diagnostics, safe resume, and environment errors excluded from learner assessment.
- **Too many concepts arrive at once:** vertical slice followed by one-concern hardening milestones and the just-in-time concept limits.
- **Progress file is lost:** reconstruct state from checks, journal, and Git evidence.
- **The first implementation expands into production work:** phase boundary and separate specifications for later hardening.
