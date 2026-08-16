# M05 — Governed intelligence

## Outcome

A synthetic decision is accepted only when typed policy, product knowledge, and provenance are present; otherwise the result is Handoff.

## Why now

Before any real model behavior is considered, the system needs a deterministic boundary that rejects decisions it cannot justify.

## Mental model

Treat a proposed response like a claim in a case file: it may proceed only when its supporting records and rule checks are attached.

## New terms

- **Grounding:** support for a claim in approved knowledge.
- **Provenance:** where a piece of supporting information came from.
- **Fail-closed:** choose the safe fallback when required evidence is missing.

## Your task

Add one deterministic synthetic turn decision that is accepted only with typed Product Knowledge, Sales Policy, and provenance; otherwise route it to Handoff. Before editing, predict which missing evidence should force the safe fallback. Make one focused change, then stop and share the checkpoint evidence for review.

## Constraints

- M04 must be complete.
- Use deterministic synthetic fixtures only; they do not represent real LLM behavior.
- Require typed policy, knowledge, and provenance before accepting a decision.
- Route missing or invalid evidence to Handoff.
- Do not select a real model, tune prompts, or use production credentials or customer data.

## Check

Run the M05 focused checkpoint after both accepted and fail-closed synthetic cases have observable results. It verifies typed governance evidence, provenance, and Handoff behavior.

## Explain

Explain the decision flow, why fail-closed is the chosen design, and one failure mode that Handoff prevents when supporting evidence is absent.

## Transfer

Given a synthetic decision with valid knowledge but missing provenance, predict the terminal result and explain which required evidence caused it.
