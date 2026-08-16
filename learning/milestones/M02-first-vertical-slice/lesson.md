# M02 — First vertical slice

## Outcome

A synthetic POST request reaches one safely bound database command and returns JSON with `accepted`: a Boolean and `eventId`: a string. In the accepted case, `accepted` is `true` and `eventId` is a non-empty synthetic identifier.

## Why now

One thin, observable path connects the healthy local stack to behavior before the project gains a larger domain model.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M01 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** A labeled envelope keeps its contents separate from the delivery instructions.

**New terms:**
- **Parameter:** an input value bound separately from database command text.

**One action:** State why the request value should enter the database command as a parameter.

**Wait:** Stop and inspect the prediction before locating the request entry point.

### Stage 2 — Entry point

**Mental model:** A webhook is the front door through which one outside event enters the workflow.

**New terms:**
- **Webhook:** an HTTP endpoint that receives an event.

**One action:** Identify the learner's inbound webhook workflow location.

**Wait:** Stop and inspect the location before asking for a change.

### Stage 3 — Parameter binding

**Mental model:** A sealed input slot prevents data from becoming part of the instruction label.

**New terms:** None.

**One action:** Make one change that binds the synthetic request value as a parameter.

**Wait:** Stop and inspect the working diff before discussing commit behavior.

### Stage 4 — Transaction boundary

**Mental model:** A transaction is one all-or-nothing envelope: its write and success claim leave together or neither leaves.

**New terms:**
- **Transaction:** a unit of database work that either commits completely or does not commit.

**One action:** Make one change that keeps the database command and accepted result in the same transaction.

**Wait:** Stop and inspect the diff before discussing response fields.

### Stage 5 — Typed terminal

**Mental model:** A typed terminal is a labeled exit whose fields have predictable kinds.

**New terms:**
- **Typed terminal:** a response with named values of defined kinds.

**One action:** Make one change that returns the typed terminal fields `accepted` as a Boolean and `eventId` as a string.

**Wait:** Stop and inspect the diff before requesting checkpoint evidence.

### Stage 6 — Terminal evidence

**Mental model:** A focused result is the receipt for the one path just built.

**New terms:** None.

**One action:** Run the focused M02 check.

**Wait:** Stop and inspect the result before advancing.

## Constraints

- Use one synthetic request and one database command only.
- Bind values as parameters; do not concatenate request data into command text.
- The response must not report acceptance for database work that did not commit.
- Do not introduce a multi-table domain model or concurrency behavior.
- Do not use production credentials, customer data, or runtime dependencies.

## Check

The M02 focused checkpoint proves the webhook path, parameterized command, transaction behavior, and typed terminal contract.

## Explain

Explain the request flow, why its value is parameterized, and one failure that the `accepted`/`eventId` response makes visible.

## Transfer

For a different synthetic input field, state where it crosses the request-to-database boundary and which typed response property would remain unchanged.
