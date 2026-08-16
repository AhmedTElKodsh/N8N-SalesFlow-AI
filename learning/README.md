# SalesFlow guided learning

This learning track begins from the clean `starter/salesflow-guided-v1` branch. Keep your work on a learner branch based on that starter; `reference/salesflow-complete-v1` is an immutable completed reference, not a baseline for ordinary learning. The tutor exposes only the active milestone and its immediate prerequisite.

## Commands

Use PowerShell from the repository root:

```powershell
.\scripts\learn.ps1 status
.\scripts\learn.ps1 start M00
.\scripts\learn.ps1 check
.\scripts\learn.ps1 complete
.\scripts\learn.ps1 resume
```

`status` reports the active milestone, baseline state, and available action. `start` checks prerequisites and opens one attempt. `check` runs the focused behavior checkpoint. `complete` records completion only after both gates pass. `resume` rereads local progress, the journal, the working tree, and the narrowest useful check so a session can continue safely without chat history.

## Completion and help

Each milestone has two independent completion gates. The behavior gate is deterministic focused-check evidence. The understanding gate records your explanation of the data flow and a design decision, a realistic failure mode, and transfer-exercise evidence in the journal. A green test alone does not complete a milestone.

The tutor starts with one mental model, at most three new terms, and one learner action. Hints escalate only after your evidence, one level at a time; using a hint never lowers progress or assessment. A complete solution is available only after you explicitly request one for the named step. When direct-solution mode is active, reconstruct the behavior, explain it, and pass an additional transfer check before the milestone can complete.

## Local and safe work

Use PowerShell and Docker only. All fixtures and examples are deterministic synthetic data: never place production credentials or customer data in learning files, prompts, tests, or output. Do not delete local environments or volumes unless you explicitly use a reset operation within the validated project scope.

For a safe resume, first verify your learner branch still descends from the clean starter. Then use `resume` to inspect `.learning/progress.json`, `learning/journal.md`, uncommitted work, and focused-check evidence. Continue from the last incomplete behavior or understanding gate.
