# M00 — Repository orientation

## Outcome

You can prove you are on the expected learner line of work, map one synthetic inbound event, assign coordination to n8n and remembered facts to PostgreSQL, and explain why local success is not production proof.

## Why now

A verified starting point and a small project map prevent accidental work on the wrong baseline or in the wrong component.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

The tutor reveals only Stage 1 at the start of a session. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** A conductor coordinates a performance; a ledger keeps its lasting record.

**New terms:**
- **Durable state:** facts that remain after a process ends.

**One action:** State which component you predict owns the durable state after an n8n execution ends.

**Wait:** Stop and inspect the prediction before discussing files or commands.

### Stage 2 — Branch identity

**Mental model:** A labeled trail tells you which line of work your next step will extend.

**New terms:**
- **Branch:** the current line of project work that a commit extends.

**One action:** Run `git branch --show-current`.

**Wait:** Stop and confirm the reported branch is the expected learner branch before checking its starting point.

### Stage 3 — Starter ancestry

**Mental model:** Starter ancestry is a receipt that proves the current work began from the approved starting point.

**New terms:**
- **Starter ancestry:** the condition that the approved starter commit is an ancestor of the current commit.

**One action:** Run `git merge-base --is-ancestor starter/salesflow-guided-v1 HEAD; $ancestryExit = $LASTEXITCODE; Write-Output "starter-ancestry-exit=$ancestryExit"; if ($ancestryExit -ne 0) { throw "starter ancestry failed" }`.

**Wait:** Stop and inspect the printed `starter-ancestry-exit=0` result before reviewing pending file changes.

### Stage 4 — Clean state

**Mental model:** A workbench inventory distinguishes existing learner work from changes made during this session.

**New terms:**
- **Working tree:** tracked and untracked files outside the current commit.

**One action:** Run `git status --short`.

**Wait:** Stop and inspect the working tree output before mapping anything; preserve existing learner work.

### Stage 5 — Map

**Mental model:** A building map starts at one door instead of cataloguing every room.

**New terms:**
- **Repository:** the versioned project folder.
- **Entry point:** the first project location that receives an event.

**One action:** Identify one repository entry point for a synthetic inbound event.

**Wait:** Stop and inspect the named entry point before asking about component boundaries.

### Stage 6 — Boundaries

**Mental model:** A dispatcher coordinates a delivery, while a records office keeps the lasting fact.

**New terms:**
- **Orchestrator:** a component that coordinates steps without owning the lasting record.
- **Synthetic-local boundary:** the limit beyond which local invented data cannot prove production behavior.

**One action:** Write one boundary statement naming the orchestrator, the owner of durable state, and the synthetic-local boundary.

**Wait:** Stop and inspect the boundary statement before running the focused check.

## Constraints

- Use the learner branch descended from `starter/salesflow-guided-v1`; do not use the completed reference as a baseline.
- Git working-tree safety requires the expected branch, a successful starter ancestry check, and a reviewed working tree.
- Use synthetic local examples only; never add credentials or customer data.
- Do not write SQL, configure retries, or investigate LLM behavior here.
- Make no implementation changes while M00 orientation and safety evidence are incomplete.
- A synthetic-local success is not production proof: production credentials, customer data, and external-provider behavior remain outside it.

## Check

Run the M00 focused checkpoint only after the branch-safety evidence, project map, and component boundary have been reviewed.

## Explain

Explain the event flow, why PostgreSQL rather than n8n owns the remembered fact, and one failure that would follow if the workflow were the ledger. Also explain why a local synthetic result cannot prove production readiness.

## Transfer

For a second synthetic inbound event, identify its transient coordinator and lasting owner without opening a later milestone.
