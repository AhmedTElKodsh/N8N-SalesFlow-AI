# M09 — Responsible operations

## Outcome

Synthetic operations can connect one request to its terminal facts, remove or reduce personal records under declared duties, prove that aged data is actually purged, keep sensitive configuration outside exported artifacts, identify the active release, return safely to a prior release, and surface conditions that require operator attention.

## Why now

M08 completes the local behavioral path. Before capstone acceptance, the system needs durable operational proof and controls for privacy, configuration, release change, and failure visibility.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M08 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** Audit evidence is a chain of durable facts that lets an operator explain what happened without reconstructing it from memory.

**New terms:**
- **Audit evidence:** durable, attributable facts proving an important action, decision, or state transition.

**One action:** State which terminal event you predict needs Audit evidence for an operator to diagnose it.

**Wait:** Stop and inspect the prediction before connecting events across the flow.

### Stage 2 — Correlation

**Mental model:** One baggage tag links every handoff in a journey without copying the bag's contents onto each receipt.

**New terms:**
- **Correlation identifier:** a non-secret value used to connect related evidence across components and stages.

**One action:** Make one change that carries a Correlation identifier from one synthetic request to its terminal evidence.

**Wait:** Stop and inspect the diff before reducing stored personal detail.

### Stage 3 — Minimization

**Mental model:** A receipt keeps only the fields needed for its declared purpose, not the customer's entire file.

**New terms:**
- **Minimization:** limiting collected and retained data to what a defined purpose requires.

**One action:** Identify one stored synthetic field that Minimization permits the operational record to omit.

**Wait:** Stop and inspect the classification before implementing erasure behavior.

### Stage 4 — Deletion

**Mental model:** An erasure request leaves a proof of completion without preserving the personal value that was removed.

**New terms:**
- **Deletion evidence:** durable non-sensitive proof that required removal or anonymization completed.

**One action:** Make one change that produces Deletion evidence while removing the targeted synthetic personal value.

**Wait:** Stop and inspect the diff before evaluating age-based duties.

### Stage 5 — Retention

**Mental model:** A calendar rule matters only when a janitor actually removes expired records and leaves a countable receipt.

**New terms:**
- **Enforced retention:** an age-based data duty implemented by executable purge behavior with observable results.

**One action:** Make one change that proves Enforced retention removes eligible synthetic records.

**Wait:** Stop and inspect the result before examining sensitive configuration boundaries.

### Stage 6 — Secret boundary

**Mental model:** A building plan names the locked cabinet but never prints the cabinet key into every copy of the plan.

**New terms:**
- **Secret boundary:** the separation that keeps sensitive runtime values out of source, fixtures, logs, and exported workflows.

**One action:** Inspect one exported artifact for compliance with the Secret boundary.

**Wait:** Stop and review the evidence before identifying the running release.

### Stage 7 — Release identity

**Mental model:** A deployment label ties the running configuration and workflow set to one reviewable version.

**New terms:**
- **Release identity:** a durable identifier for the exact approved artifact set selected to run.

**One action:** Make one change that exposes the active Release identity in synthetic operational evidence.

**Wait:** Stop and inspect the diff before testing a return to an earlier version.

### Stage 8 — Rollback

**Mental model:** Returning to an earlier route map changes future routing without pretending already delivered parcels never existed.

**New terms:**
- **Rollback behavior:** declared state and evidence rules for safely selecting a prior approved release.

**One action:** Make one change that verifies Rollback behavior preserves historical evidence while changing the active release.

**Wait:** Stop and inspect the result before defining operator attention.

### Stage 9 — Alerts

**Mental model:** A smoke alarm names the condition requiring attention; it does not merely produce more background noise.

**New terms:**
- **Operational alert:** an actionable signal with a defined condition, evidence location, and responsible response.

**One action:** Define one Operational alert for an unresolved local failure condition.

**Wait:** Stop and inspect whether the condition, evidence location, and expected response are observable.

### Stage 10 — Evidence

**Mental model:** A controlled operations drill proves each duty by its effect and receipt rather than by configuration labels alone.

**New terms:** None.

**One action:** Run the focused M09 check once with synthetic operational fixtures.

**Wait:** Stop and inspect whether the evidence covers traceability, privacy duties, actual purging, sensitive-value separation, release change, and actionable failures.

## Constraints

- Use synthetic records only; never place production credentials or customer data in prompts, fixtures, logs, or exports.
- Correlated evidence must be useful for diagnosis without copying unnecessary personal content.
- A configured retention value is not an enforced purge; completion requires observable removal behavior and durable non-sensitive results.
- Deletion and minimization preserve only the evidence necessary for declared operational or legal duties.
- Rollback changes the active approved release without rewriting historical evidence.
- Every alert has a condition, evidence location, and expected owner response.
- Real provider infrastructure remains an external production gate.

## Check

The M09 focused checkpoint verifies correlated audit facts, deletion and minimization outcomes, enforced age-based purging, sensitive-value boundaries, release identity, rollback behavior, and actionable alert requirements.

## Explain

Explain the operational-evidence flow, why configured policy is weaker than observed enforcement, and one realistic harm caused by leaking sensitive values into exports.

## Transfer

Given an expired synthetic record that remains present while its configured duration is correct, classify the failure and name the missing proof.
