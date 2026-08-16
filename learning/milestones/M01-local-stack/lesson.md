# M01 — Smallest local stack

## Outcome

PostgreSQL and n8n health checks pass on your machine using a local, synthetic-only stack.

## Why now

A small healthy stack gives later work a dependable place to run, without asking you to design workflows or data models yet.

## Mental model

Containers are labeled local boxes: each service has one job, and the health check is the box’s ready signal.

## New terms

- **Container:** an isolated local process package.
- **Service:** a container’s named responsibility.
- **Volume:** storage that survives a container restart.

## Your task

From the M01 starter configuration, start the two local services with PowerShell and Docker, then capture the health output for PostgreSQL and n8n. Before you run the command, predict which result would show that the database is ready. Stop after the health evidence and share it for review.

## Constraints

- M00 must be complete before beginning.
- Use PowerShell and Docker only; do not add a runtime dependency.
- Use local synthetic settings only; no production credentials or data.
- Do not implement workflow logic or schema design in this milestone.
- Do not remove containers or volumes unless an explicit project-scoped reset is requested.

## Check

Run the M01 focused checkpoint once both services report healthy. It verifies the smallest local stack behavior.

## Explain

Explain the startup flow, why each service is separate, and one failure mode a health check can reveal before you build on the stack.

## Transfer

Suppose n8n is running but PostgreSQL is not ready. Describe the next observation you would collect and why, without changing workflow logic.
