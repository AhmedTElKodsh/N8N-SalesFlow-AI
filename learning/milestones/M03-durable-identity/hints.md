# M03 Hints

## Hint 1 — Diagnostic question

What database relationship should make it impossible to store a conversation for an account that is absent?

## Hint 2 — Concept

A library loan card can name a book and a member, but the system should reject a loan whose member card is missing. A checked reference protects that link.

## Hint 3 — Location

Locate the learner’s migration directory and the path that receives the synthetic inbound event from M02.

## Hint 4 — Structure

Model the account as the scope, connect contact and conversation within that scope, then attach the immutable inbound message to its conversation. Keep the migration and persistence path aligned.

## Hint 5 — Pseudocode

Use an incomplete relationship sketch:

```text
[account] <- [contact scoped by ____]
[account] <- [conversation scoped by ____]
[conversation] <- [inbound evidence: ____]
```
