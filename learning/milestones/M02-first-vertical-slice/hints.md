# M02 Hints

## Hint 1 — Diagnostic question

Which value is currently crossing the webhook-to-database boundary without being bound as a parameter?

## Hint 2 — Concept

In an inventory lookup, a product code is supplied separately from the lookup instruction. Keeping the value separate lets the database distinguish data from the command shape.

## Hint 3 — Location

Point to the learner’s inbound workflow and the first migration or database setup file, then identify the terminal response configuration.

## Hint 4 — Structure

Arrange one trigger, one parameterized command boundary, and one typed terminal in that order. Decide the response property before filling any node values.

## Hint 5 — Pseudocode

Use an incomplete flow only:

```text
on POST [____]
  bind [request value] as [____]
  run [one database command]
  return { [typed property]: [____] }
```
