# M05 — Governed intelligence

## Outcome

A fixed synthetic response follows the accepting path only after every required supporting record validates; any failed validation follows a safe terminal. Local fixed examples prove this boundary, not real language-model behavior.

## Why now

Before considering external generative behavior, the system needs a deterministic boundary that rejects a response it cannot justify.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M04 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** An incomplete case file is sent to a person instead of being approved automatically.

**New terms:**
- **Handoff:** the safe terminal that transfers an unproven decision to human handling.

**One action:** State which missing supporting record you predict should force Handoff and why.

**Wait:** Stop and inspect the prediction before locating the decision interface.

### Stage 2 — Boundary

**Mental model:** An inspection desk is the one place where every supporting record must pass before approval.

**New terms:**
- **Decision boundary:** the interface that accepts or rejects a proposed response.

**One action:** Identify the synthetic decision boundary on the learner branch.

**Wait:** Stop and inspect the location before asking for a validation change.

### Stage 3 — Product Knowledge

**Mental model:** One approved product card must pass its shape check before it can support a response.

**New terms:**
- **Product Knowledge:** an approved versioned record of synthetic product facts.
- **Typed validation:** checking that required evidence has the expected shape and allowed values.

**One action:** Make one change that applies typed validation to Product Knowledge before acceptance.

**Wait:** Stop and inspect the diff before discussing policy.

### Stage 4 — Sales Policy

**Mental model:** A separate rule card constrains what the product card permits a response to say.

**New terms:**
- **Sales Policy:** an approved versioned record of synthetic sales rules.

**One action:** Make one change that applies typed validation to Sales Policy before acceptance.

**Wait:** Stop and inspect the diff before discussing configuration evidence.

### Stage 5 — Model

**Mental model:** A configuration label identifies the fixed decision setup without calling a real provider.

**New terms:**
- **Model record:** typed evidence naming the synthetic decision configuration.

**One action:** Make one change that applies typed validation to the Model record before acceptance.

**Wait:** Stop and inspect the diff before discussing the next rule record.

### Stage 6 — Qualification

**Mental model:** A qualification card records whether the fixed example meets one declared rule.

**New terms:**
- **Qualification:** typed evidence of the synthetic turn's rule outcome.

**One action:** Make one change that applies typed validation to Qualification before acceptance.

**Wait:** Stop and inspect the diff before discussing source evidence.

### Stage 7 — Provenance

**Mental model:** A citation label links the proposed response to the exact supporting card and version.

**New terms:**
- **Provenance:** typed evidence identifying the source record and version used by a decision.

**One action:** Make one change that validates Provenance against the selected Product Knowledge record and version.

**Wait:** Stop and inspect the diff before assembling the synthetic decision.

### Stage 8 — Synthetic decision

**Mental model:** A completed case file joins the separately checked records into one reviewable proposal.

**New terms:**
- **Synthetic turn decision:** a deterministic local proposal assembled without a real language model.

**One action:** Make one change that accepts a Synthetic turn decision only when every prior validation result succeeds.

**Wait:** Stop and inspect the diff before adding the failure path.

### Stage 9 — Handoff

**Mental model:** A safety gate stays closed whenever any required inspection fails.

**New terms:**
- **Fail-closed:** choosing the safe outcome whenever required evidence is absent or invalid.

**One action:** Make one change that applies Fail-closed behavior by routing every failed validation to Handoff.

**Wait:** Stop and inspect the diff before running the focused check.

### Stage 10 — Evidence

**Mental model:** A fixed test card proves the boundary rules while making no claim about real model quality.

**New terms:**
- **Deterministic fixture:** fixed synthetic input with a repeatable expected result.

**One action:** Run the focused M05 check once with its deterministic fixtures.

**Wait:** Stop and inspect the evidence that valid fixtures are accepted and each invalid-evidence case reaches Handoff.

## Constraints

- Use deterministic synthetic fixtures only; they do not represent real LLM behavior.
- Acceptance requires typed validation of Product Knowledge, Sales Policy, model, qualification, and provenance.
- Valid provenance identifies an allowed synthetic Product Knowledge record and matches the record version used by the decision.
- Any missing, malformed, unapproved, or version-mismatched evidence must fail closed to Handoff.
- Do not select a real model, tune prompts, or use production credentials or customer data.

## Check

The M05 focused checkpoint verifies typed knowledge, policy, model, and qualification independently; validated provenance; a synthetic turn decision; and invalid-evidence Handoff.

## Explain

Explain the decision flow, why fail-closed is the design, and one failure that Handoff prevents when evidence is invalid.

## Transfer

Given a synthetic decision with valid knowledge but missing provenance, predict Handoff and identify the failed validation.
