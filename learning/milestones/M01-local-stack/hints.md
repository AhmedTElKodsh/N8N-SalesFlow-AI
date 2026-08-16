# M01 Hints

## Hint 1 — Diagnostic question

What evidence distinguishes a container that merely started from a service that is ready to accept its work?

## Hint 2 — Concept

For a home oven, a lit display is different from reaching the chosen temperature. A readiness check answers the second question.

## Hint 3 — Location

Look at the learner branch’s Docker Compose file or local stack documentation, then inspect the Docker service status for PostgreSQL and n8n.

## Hint 4 — Structure

Bring up the named local services, observe each status independently, and keep the two health observations as evidence before advancing.

## Hint 5 — Pseudocode

Use this command-shaped outline and fill it from local documentation:

```text
PowerShell: [start local stack command]
observe: [PostgreSQL health signal: ____]
observe: [n8n health signal: ____]
```
