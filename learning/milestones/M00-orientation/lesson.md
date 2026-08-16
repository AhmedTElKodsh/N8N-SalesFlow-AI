# M00 — Repository orientation

## Outcome

You can work safely on the learner branch, map a synthetic inbound event, distinguish n8n orchestration from PostgreSQL durable state, and explain why synthetic-local success is not production proof.

## Why now

A safe map prevents accidental work on the wrong baseline and prevents an automation tool from becoming the record of customer history.

## Mental model

n8n is a conductor that coordinates an event; PostgreSQL is the ledger that remembers facts after the conductor stops.

## New terms

- **Repository:** the versioned project folder.
- **Orchestrator:** a component that coordinates steps.
- **Durable state:** facts that remain after a process ends.

## Your task

The tutor reveals only Stage 1 at the start of a session. Do not reveal a later stage until the learner supplies evidence from this stage.
At each stage, begin the teaching exchange with one mental model and at most three new terms.

### Stage 1 — Prediction

**One action:** State which component you predict retains a synthetic inbound event after an n8n execution ends.

**Wait:** Stop and wait for that prediction; inspect it before discussing files or commands.

### Stage 2 — Branch identity

**One action:** Run `git branch --show-current`.

**Wait:** Stop and confirm the reported branch is the learner branch before checking its ancestry.

### Stage 3 — Starter ancestry

**Mental model:** An ancestry check is a receipt: record its result so another person can review it.

**One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; Write-Output "starter-ancestry-exit=$LASTEXITCODE"`.

**Wait:** Stop and inspect the printed `starter-ancestry-exit` evidence before checking the worktree.

### Stage 4 — Clean state

**One action:** Run `git status --short`.

**Wait:** Stop and inspect the output before mapping anything; preserve any learner work rather than changing it.

### Stage 5 — Map

**One action:** Name the repository entry point for one synthetic inbound event.

**Wait:** Stop and inspect the named location before asking for the n8n or database boundary.

### Stage 6 — Boundaries

**One action:** State which component coordinates the event and which component owns its durable fact.

**Wait:** Stop and classify any misunderstanding before continuing.

## Constraints

- Use the learner branch descended from `starter/salesflow-guided-v1`; do not use the completed reference as a baseline.
- Git/worktree safety requires the expected branch, successful starter ancestry check, and reviewed working-tree state.
- Use synthetic local examples only; never add credentials or customer data.
- Do not write SQL, configure retries, or investigate LLM behavior here.
- Make no implementation changes while M00 orientation and safety evidence are incomplete.
- A synthetic-local check is useful evidence, not production proof: production credentials, customer data, and external-provider behavior remain outside it.

## Check

Run the M00 focused checkpoint only after the branch-safety evidence and event map are reviewed.

## Explain

Explain the event flow, why PostgreSQL rather than n8n owns the remembered fact, and one failure that would follow if the workflow were the ledger. Also explain why a local synthetic result cannot prove production readiness.

## Transfer

For a second synthetic inbound event, identify its transient coordinator and durable owner without opening a later milestone.
