# M02 — First vertical slice

## Outcome

A synthetic POST webhook reaches one parameterized database command and returns a JSON typed terminal: `accepted`: a Boolean and `eventId`: a string. For the accepted first-slice case, `accepted` is `true` and `eventId` is a non-empty synthetic identifier.

## Why now

One thin, observable path connects the healthy local stack to behavior before the project gains a larger domain model.

## Mental model

A vertical slice is a sealed pipe: input enters at the webhook, crosses a safe database boundary, and exits as a predictable response.

## New terms

- **Webhook:** an HTTP endpoint that receives an event.
- **Parameter:** a separately bound input value.
- **Typed terminal:** a response with named values of defined kinds.

## Your task

M01 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.
At each stage, begin the teaching exchange with one mental model and at most three new terms.

### Stage 1 — Prediction

**One action:** State why a request value should be supplied separately from the database command text.

**Wait:** Stop and inspect the prediction before locating the workflow.

### Stage 2 — Entry point

**One action:** Identify the learner’s inbound webhook workflow location.

**Wait:** Stop and inspect the location before asking for a change.

### Stage 3 — One boundary

**One action:** Make one change that binds the synthetic request value as a parameter.

**Wait:** Stop and inspect the working diff before discussing the terminal response or transaction boundary.

### Stage 4 — Terminal evidence

**One action:** Run the focused M02 check after the terminal emits `accepted` and `eventId` with the stated types.

**Wait:** Stop and inspect the focused result before advancing.

## Constraints

- Use one synthetic request and one database command only.
- Bind values as parameters; do not concatenate request data into command text.
- Keep the command and terminal in one transaction boundary: the terminal must not report acceptance for database work that did not commit.
- Do not introduce a multi-table domain model or concurrency behavior.
- Do not use production credentials, customer data, or runtime dependencies.

## Check

The M02 focused checkpoint proves the webhook path, parameterized command, transaction boundary, and typed terminal contract.

## Explain

Explain the request flow, why its value is parameterized, and one failure that the `accepted`/`eventId` terminal contract makes visible.

## Transfer

For a different synthetic input field, state where it crosses the webhook-to-database boundary and which typed response property would remain unchanged.
