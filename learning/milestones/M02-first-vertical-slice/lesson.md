# M02 — First vertical slice

## Outcome

A synthetic POST webhook reaches one parameterized database command and returns a typed result.

## Why now

One thin, observable path connects the local stack to real behavior before the project gains a larger domain model.

## Mental model

A vertical slice is a single sealed pipe: input enters at the webhook, passes through a safe database boundary, and leaves as a predictable response.

## New terms

- **Webhook:** an HTTP endpoint that receives an event.
- **Parameter:** a separately bound input value.
- **Transaction:** a unit of database work that succeeds or fails together.

## Your task

Implement one synthetic POST path that invokes one parameterized SQL command and ends at a typed terminal response. Before editing, predict what makes the database input safe to bind separately from the command text. Make one change toward the path, then stop and share the resulting focused evidence for review.

## Constraints

- M01 must be complete and the local stack healthy.
- Use one synthetic request and one database command only.
- Keep values bound as parameters; do not concatenate request data into command text.
- Do not introduce a multi-table domain model or concurrency behavior.
- Do not use production credentials, customer data, or runtime dependencies.

## Check

Run the M02 focused checkpoint when the request produces the typed terminal result. It checks the webhook path, parameterized command boundary, and terminal shape.

## Explain

Explain the request’s data flow, why its value is bound as a parameter, and one failure that a typed terminal makes easier to detect.

## Transfer

For a different synthetic field, state where it would cross the webhook-to-database boundary and what response property would prove it was handled.
