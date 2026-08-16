# M01 — Smallest local stack

## Outcome

PostgreSQL and n8n readiness checks pass locally using a synthetic-only stack.

## Why now

A small healthy stack gives later work a dependable place to run, without designing workflows or schema yet.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M00 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** A ready light answers one narrow question before anyone uses the machine.

**New terms:**
- **Health check:** a focused readiness signal from a running component.

**One action:** State what health check result you predict would prove PostgreSQL is ready for later work.

**Wait:** Stop and inspect the prediction before selecting a local command.

### Stage 2 — Start

**Mental model:** Each container is a labeled room, each service is the job performed there, and a volume is its project-owned cupboard.

**New terms:**
- **Container:** an isolated local process package.
- **Service:** a container's named responsibility.
- **Volume:** project-scoped storage that can outlive a container process.

**One action:** Start the documented local container services with the project's PowerShell and Docker command while retaining the project volume.

**Wait:** Stop and inspect the startup output before requesting health evidence.

### Stage 3 — PostgreSQL evidence

**Mental model:** Check one instrument before depending on the whole panel.

**New terms:** None.

**One action:** Collect the PostgreSQL health check result.

**Wait:** Stop and classify an unhealthy result before looking at n8n.

### Stage 4 — n8n evidence

**Mental model:** A second ready light must be checked independently of the first.

**New terms:** None.

**One action:** Collect the n8n health check result.

**Wait:** Stop and inspect the result before running the focused checkpoint.

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
