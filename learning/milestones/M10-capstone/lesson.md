# M10 — Capstone

## Outcome

The learner runs the full local verification, follows one synthetic inbound event through its terminal facts, explains critical ways the system can fail, and identifies the external proof still required before any real deployment decision.

## Why now

M00-M09 establish the complete synthetic-local capability. The capstone combines their independent proof without turning local success into a production claim.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M09 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** Acceptance evidence is a signed inspection pack: every required result must be attributable, reproducible, and interpreted within its scope.

**New terms:**
- **Acceptance evidence:** reproducible results showing that declared requirements and invariants passed their required checks.

**One action:** State which Acceptance evidence you predict the full local run must preserve.

**Wait:** Stop and inspect the prediction before reviewing the local-only scope.

### Stage 2 — Preflight

**Mental model:** A wind-tunnel test can validate an aircraft model while still leaving real-flight approval unanswered.

**New terms:**
- **Synthetic boundary:** the explicit limit separating deterministic local substitutes from claims about real external systems.

**One action:** Classify the current repository evidence on each side of the Synthetic boundary.

**Wait:** Stop and inspect the classification before starting the costly full check.

### Stage 3 — Complete suite

**Mental model:** A release inspection runs the whole route under one controlled setup because isolated checks cannot prove the assembled path.

**New terms:** None.

**One action:** Run `powershell -ExecutionPolicy Bypass -File .\tests\learning\checkpoints\Test-M10.ps1` once.

**Wait:** Wait for the complete output and inspect its exit, full-pass marker, and cleanup evidence; do not advance to the next stage unless all three succeed.

### Stage 4 — Scenario trace

**Mental model:** A parcel trace connects each custody event from intake to its final receipt using durable identities.

**New terms:**
- **Scenario trace:** an evidence-backed account of one event's ordered path through state, decisions, side effects, and terminal records.

**One action:** Trace one synthetic inbound event to terminal evidence using a Scenario trace.

**Wait:** Stop and inspect whether every transition has an identity, observed value, and diagnostic location.

### Stage 5 — Failure analysis

**Mental model:** A safety review explains how a protection can fail, what evidence reveals it, and which control limits the damage.

**New terms:**
- **Failure mode:** a specific way a component or interaction can violate an expected invariant.

**One action:** Explain one critical Failure mode from the traced scenario.

**Wait:** Stop and review whether the explanation names the violated invariant, evidence, and protective behavior.

### Stage 6 — Production gates

**Mental model:** A local certificate opens the laboratory exit, while separate authorities still control admission to real operation.

**New terms:**
- **Production gate:** external evidence or approval required before a capability may be promoted to real operation.

**One action:** Identify every unresolved Production gate for the synthetic-local release.

**Wait:** Stop and inspect the list against the declared external evidence categories before considering completion.

## Constraints

- State the roughly 240-second expected cost before running the complete release harness; container startup or rebuild can make the wall time longer.
- Use only the repository's deterministic synthetic fixtures and disposable local environment.
- Preserve the final exit result and focused diagnostic location for any failure.
- Trace one event through intake, durable state, governed decision, authorized external intent, recovery or scheduling when applicable, and terminal operational evidence.
- A green local run proves only the declared synthetic implementation and invariants.
- The external-gate inventory must cover provider delivery, model behavior, Handoff integration, managed database controls, approved Sales Policy content, approved Product Knowledge content, legal approval, privacy approval, commercial approval, external integration proof, pilot proof, and production-owner approval.
- Actual production promotion remains outside this synthetic capstone.

## Check

The M10 checkpoint performs preflight and delegates to the complete release harness. Its behavior gate passes only when that harness exits 0, emits the expected full-pass marker, and records successful cleanup evidence. A nonzero exit blocks M10 completion. Likewise, a missing full-pass marker blocks M10 completion, and missing cleanup evidence blocks M10 completion. After that behavior gate passes, completion still requires the learner's data-flow explanation, design decision, realistic failure analysis, transfer evidence, and complete external-gate inventory.

## Explain

Explain the end-to-end data flow, one design decision that protects an invariant, and one critical failure with its diagnostic evidence.

## Transfer

Given a clean local result but no evidence from the selected external provider, explain what is proven, what remains unproven, and why promotion is blocked.
