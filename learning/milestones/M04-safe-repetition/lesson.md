# M04 — Safe repetition

## Outcome

Repeated and simultaneous deliveries of one synthetic inbound event leave one lasting change and preserve arrival order. A later attempt receives a predictable non-writing response based on whether its payload matches the first attempt.

## Why now

Networks can repeat requests and two requests can arrive together. The system needs one observable effect and a predictable response for every other attempt.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M03 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** A ticket number distinguishes a repeated scan from a different ticket.

**New terms:**
- **Event identity:** a stable value that distinguishes one inbound event from another.

**One action:** State the event identity you predict can distinguish a repeated inbound event from a different one.

**Wait:** Stop and inspect the prediction before locating the persistence boundary.

### Stage 2 — Boundary

**Mental model:** A turnstile is the single boundary where one admission can be counted.

**New terms:**
- **Durable effect:** the lasting state change caused by an accepted event.

**One action:** Identify the M03 persistence boundary where one durable effect can be enforced.

**Wait:** Stop and inspect the location before asking for a change.

### Stage 3 — One effect

**Mental model:** One ticket admits one entry because the gate enforces one unique ticket number.

**New terms:**
- **Idempotency:** repeated processing of the same request produces one logical effect.
- **Uniqueness:** a rule that allows only one stored instance of an identity.

**One action:** Make one change that combines idempotency with uniqueness to enforce exactly one durable logical effect.

**Wait:** Stop and inspect the diff before discussing repeat responses.

### Stage 4 — Replay result

**Mental model:** A second scan of the same ticket receives the original receipt instead of another admission.

**New terms:**
- **Replay result:** the deterministic response returned for the same identity and payload after the first effect.

**One action:** Make one change that returns the replay result for the same event identity and payload.

**Wait:** Stop and inspect the diff before discussing a changed payload.

### Stage 5 — Typed conflict

**Mental model:** A ticket number presented with different details is rejected with a named reason.

**New terms:**
- **Typed conflict:** a response with a defined shape for one identity paired with different content.

**One action:** Make one change that returns a typed conflict for the same identity with a different payload.

**Wait:** Stop and inspect the diff before discussing event order.

### Stage 6 — Ordering

**Mental model:** A single-file gate turns simultaneous arrivals into an observable sequence.

**New terms:**
- **Serialization:** arranging concurrent work into a safe order.

**One action:** Make one change that uses serialization to preserve observable inbound-event ordering.

**Wait:** Stop and inspect the diff before requesting concurrent evidence.

### Stage 7 — Race evidence

**Mental model:** A controlled simultaneous start tests the gate rather than trusting sequential examples.

**New terms:**
- **Race check:** a focused test that overlaps competing operations.

**One action:** Run the focused M04 race check.

**Wait:** Stop and inspect whether the result proves one effect, ordered events, and deterministic replay-or-conflict responses.

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
