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

### Stage 3 — Validation

**One action:** Make one change that validates one required typed evidence record before a synthetic decision is accepted.

**Wait:** Stop and inspect the diff before discussing any other record or terminal.

### Stage 4 — Evidence

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
