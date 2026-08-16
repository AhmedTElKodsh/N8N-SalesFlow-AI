# M04 — Safe repetition

## Outcome

For each stable synthetic inbound-event identity, duplicate and concurrent deliveries create exactly one durable logical effect and preserve ordered inbound events. A later attempt returns a deterministic replay result for the same payload, or a typed conflict for a different payload; neither creates another effect.

## Why now

Networks can repeat requests and two requests can arrive together. The system needs one observable effect and a predictable response for every other attempt.

## Mental model

One ticket admits one entry: multiple scanners may see it, but the gate records one admission and gives every later scan a defined result.

## New terms

- **Idempotency:** repeating the same request has one logical effect.
- **Uniqueness:** a rule that rejects a duplicate identity.
- **Serialization:** arranging concurrent work into a safe order.

## Your task

M03 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.
At each stage, begin the teaching exchange with one mental model and at most three new terms.

### Stage 1 — Prediction

**One action:** State the stable identity you predict can distinguish the same inbound event from a different one.

**Wait:** Stop and inspect the prediction before locating the durable boundary.

### Stage 2 — Boundary

**One action:** Identify the M03 persistence boundary where one durable logical effect can be enforced.

**Wait:** Stop and inspect the location before asking for a change.

### Stage 3 — One effect

**One action:** Make one change that enforces exactly one durable logical effect for the stable event identity.

**Wait:** Stop and inspect the diff before discussing replay results.

### Stage 4 — Replay result

**One action:** Make one change that returns the deterministic replay result for the same event identity and payload.

**Wait:** Stop and inspect the diff before discussing conflicting payloads.

### Stage 5 — Typed conflict

**One action:** Make one change that returns a typed conflict for the same identity with a different payload.

**Wait:** Stop and inspect the diff before discussing ordering.

### Stage 6 — Ordering

**One action:** Make one change that preserves observable inbound-event ordering.

**Wait:** Stop and inspect the diff before running a race check.

### Stage 7 — Race evidence

**One action:** Run the focused M04 race check with duplicate and concurrent synthetic deliveries.

**Wait:** Stop and inspect whether it proves one effect, ordered events, and deterministic replay-or-conflict results.

## Constraints

- Use deterministic synthetic events and focused race tests.
- Preserve the original inbound evidence and its order.
- For the same event identity and payload, a second caller receives the defined replay result; for the same identity with a different payload, it receives a typed conflict.
- Both replay and conflict paths leave the durable-effect count at exactly one.
- Do not add provider retries, callbacks, or lease behavior.

## Check

The M04 focused checkpoint verifies ordered inbound events, exactly one durable logical effect, and deterministic replay-or-conflict behavior.

## Explain

Explain the event flow, the rule that limits the durable effect to one, and one realistic race failure it addresses.

## Transfer

Describe the expected result when a client repeats the same event after a timeout, without adding provider retry logic.
