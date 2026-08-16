# M05 — Governed intelligence

## Outcome

A deterministic synthetic turn decision is accepted only after typed validation of Product Knowledge, Sales Policy, model, qualification, and provenance. Missing, malformed, or mismatched evidence routes to Handoff. Deterministic fixtures test this boundary; they do not prove real LLM behavior.

## Why now

Before considering real model behavior, the system needs a deterministic boundary that rejects a decision it cannot justify.

## Mental model

A proposed response is a claim in a case file: it may proceed only when every required supporting record passes inspection.

## New terms

- **Typed validation:** checking that required evidence has the expected shape and values.
- **Provenance:** the recorded source of supporting information.
- **Fail-closed:** choose Handoff when required evidence is missing or invalid.

## Your task

M04 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.
At each stage, begin the teaching exchange with one mental model and at most three new terms.

### Stage 1 — Prediction

**One action:** State which missing or invalid supporting record should force Handoff and why.

**Wait:** Stop and inspect the prediction before locating the decision boundary.

### Stage 2 — Boundary

**One action:** Identify the synthetic turn-decision interface on the learner branch.

**Wait:** Stop and inspect the location before asking for a change.

### Stage 3 — Product Knowledge

**Mental model:** Knowledge is one approved record that can support a decision.

**One action:** Make one change that validates typed Product Knowledge before acceptance.

**Wait:** Stop and inspect the diff before discussing Sales Policy.

### Stage 4 — Sales Policy

**Mental model:** Policy is one separate record that constrains a decision.

**One action:** Make one change that validates typed Sales Policy before acceptance.

**Wait:** Stop and inspect the diff before discussing the model.

### Stage 5 — Model

**Mental model:** The model record names the synthetic decision configuration.

**One action:** Make one change that validates the typed model before acceptance.

**Wait:** Stop and inspect the diff before discussing qualification.

### Stage 6 — Qualification

**Mental model:** Qualification is a separate rule record for the synthetic turn.

**One action:** Make one change that validates typed qualification before acceptance.

**Wait:** Stop and inspect the diff before discussing provenance.

### Stage 7 — Provenance

**Mental model:** Provenance links a decision to the knowledge record that supports it.

**One action:** Make one change that validates provenance against the selected synthetic Product Knowledge record and version.

**Wait:** Stop and inspect the diff before discussing Handoff.

### Stage 8 — Handoff

**Mental model:** Fail-closed sends unproven decisions to the safe terminal.

**One action:** Make one change that routes invalid evidence to Handoff.

**Wait:** Stop and inspect the diff before running the focused check.

### Stage 9 — Evidence

**Mental model:** A focused check shows whether the boundary accepts only valid evidence.

**One action:** Run the M05 focused check with one fully valid fixture and one invalid-evidence fixture.

**Wait:** Stop and inspect that only valid evidence is accepted and invalid evidence reaches Handoff.

## Constraints

- Use deterministic synthetic fixtures only; they do not represent real LLM behavior.
- Acceptance requires typed validation of Product Knowledge, Sales Policy, model, qualification, and provenance.
- Valid provenance is typed, identifies an allowed synthetic Product Knowledge record, and matches the record version used by the decision.
- Any missing, malformed, unapproved, or version-mismatched evidence must fail closed to Handoff.
- Do not select a real model, tune prompts, or use production credentials or customer data.

## Check

The M05 focused checkpoint verifies typed knowledge, policy, model, and qualification; validated provenance; and invalid-evidence Handoff.

## Explain

Explain the decision flow, why fail-closed is the design, and one failure that Handoff prevents when evidence is invalid.

## Transfer

Given a synthetic decision with valid knowledge but missing provenance, predict Handoff and identify the failed validation.
