# M00 — Repository orientation

## Outcome

You can point to the path of one synthetic inbound event and name which part of the project orchestrates it and which part keeps durable state.

## Why now

Before changing anything, you need a safe map. It prevents an automation tool from quietly becoming the system that owns customer history.

## Mental model

Treat n8n as a conductor that coordinates a request; PostgreSQL is the ledger that remembers facts after the conductor stops.

## New terms

- **Repository:** the versioned project folder.
- **Orchestrator:** a component that coordinates steps.
- **Durable state:** facts that remain after a process ends.

## Your task

Starting from the learner branch, trace one *synthetic* inbound event in the repository and write a short map: its entry point, its n8n handoff, and its PostgreSQL ownership boundary. Before you inspect files, predict which component should retain the event after the workflow ends. Then stop and share the prediction plus your map for review.

## Constraints

- Work only on the learner branch that descends from `starter/salesflow-guided-v1`.
- Use synthetic local examples only; never add credentials or customer data.
- Do not write SQL, configure retries, or investigate LLM behavior in this milestone.
- Make no implementation changes while mapping the project.

## Check

Run the M00 focused checkpoint after the map is reviewed. It verifies the orientation artifacts expected for this milestone.

## Explain

Explain the data flow in your own words, why PostgreSQL rather than n8n owns the remembered event, and one failure that would result if the workflow alone were treated as the ledger.

## Transfer

Given a second synthetic inbound event, identify where its transient coordination would belong and where its durable evidence would belong without opening later-milestone material.
