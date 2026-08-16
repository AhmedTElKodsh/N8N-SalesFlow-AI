# M01 — Smallest local stack

## Outcome

PostgreSQL and n8n health checks pass locally using a synthetic-only stack.

## Why now

A small healthy stack gives later work a dependable place to run, without designing workflows or schema yet.

## Mental model

Containers are labeled local boxes: each service has one job, and a health check is its ready signal.

## New terms

- **Container:** an isolated local process package.
- **Service:** a container’s named responsibility.
- **Health check:** a readiness signal from a service.

## Your task

M00 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.
At each stage, begin the teaching exchange with one mental model and at most three new terms.

### Stage 1 — Prediction

**One action:** State what result you predict would prove PostgreSQL is ready for later work.

**Wait:** Stop and inspect the prediction before selecting a local command.

### Stage 2 — Start

**One action:** Start the named local stack using the project’s documented PowerShell and Docker command.

**Wait:** Stop and inspect the command output before requesting any health evidence.

### Stage 3 — PostgreSQL evidence

**One action:** Collect the PostgreSQL health result.

**Wait:** Stop and classify an unhealthy result before looking at n8n.

### Stage 4 — n8n evidence

**One action:** Collect the n8n health result.

**Wait:** Stop and inspect it before running the focused checkpoint.

## Constraints

- Use PowerShell and Docker only; do not add a runtime dependency.
- Use local synthetic settings only; no production credentials or data.
- Do not implement workflow logic or schema design.
- Do not remove containers or volumes unless an explicit project-scoped reset is requested.

## Check

Run the M01 focused checkpoint only after both reviewed health results pass.

## Explain

Explain the startup flow, why the services are separate, and one failure mode a health check reveals before implementation begins.

## Transfer

If n8n is running but PostgreSQL is not ready, name the next observation you would collect and why, without changing workflow logic.
