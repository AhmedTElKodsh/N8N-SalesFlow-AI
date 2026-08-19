# M06 — Authorized side effects

## Outcome

An approved synthetic outbound request is stored before network work, temporarily owned by one worker, checked again immediately before sending, and finished with repeat-safe evidence. The learner also identifies the uncertainty created when the remote operation succeeds but its local completion record does not.

## Why now

M05 can justify a local decision. Before that decision may cause an external effect, the system must preserve authority and evidence across a database boundary and an unreliable network boundary.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M05 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** An Authorized side effect is like a stamped shipping order: approval must exist before a courier may act.

**New terms:**
- **Authorized side effect:** an external action that may occur only while its required business permission is valid.

**One action:** State where you predict the final permission check belongs for an Authorized side effect.

**Wait:** Stop and inspect the prediction before locating the permission record.

### Stage 2 — Consent

**Mental model:** A current permission slip allows one named activity but can be withdrawn before it occurs.

**New terms:**
- **Consent:** recorded permission for a defined communication purpose and scope.

**One action:** Identify the synthetic Consent evidence that should gate creation of the outbound request.

**Wait:** Stop and inspect the evidence location before asking for persistence work.

### Stage 3 — Persisted intent

**Mental model:** A clerk files the approved shipping order in the same ledger update that creates the business decision.

**New terms:**
- **Transactional outbox:** a pattern that stores business state and its intended external action in one database transaction.

**One action:** Make one change that persists the outbound intent through a Transactional outbox with the approving state.

**Wait:** Stop and inspect the diff before discussing worker ownership.

### Stage 4 — Claim

**Mental model:** A time-limited claim ticket lets one courier handle an order while allowing later recovery if the courier disappears.

**New terms:**
- **Lease:** temporary exclusive ownership that expires unless work finishes or renews it.

**One action:** Make one change that gives a single eligible worker a Lease on one persisted intent.

**Wait:** Stop and inspect the diff before checking authority at send time.

### Stage 5 — Authorization recheck

**Mental model:** The courier checks the permission slip at the door because approval may have changed after pickup.

**New terms:**
- **Authorization recheck:** a fresh evaluation of permission immediately before an external action.

**One action:** Make one change that performs the Authorization recheck immediately before the adapter call.

**Wait:** Stop and inspect the diff before discussing repeat-safe remote execution.

### Stage 6 — Dispatch

**Mental model:** The remote desk recognizes one stable request number even when the courier repeats the request after a timeout.

**New terms:**
- **Idempotency key:** a stable request identity a remote system can use to avoid repeating one logical effect.

**One action:** Make one change that derives a stable Idempotency key from the persisted intent for adapter execution.

**Wait:** Stop and inspect the diff before recording completion.

### Stage 7 — Finish

**Mental model:** A signed receipt records what the courier observed after attempting delivery.

**New terms:**
- **Dispatch result:** durable local evidence of the observed adapter outcome for one intent.

**One action:** Make one change that finishes the claim with a typed Dispatch result.

**Wait:** Stop and inspect the diff before testing the uncertain network boundary.

### Stage 8 — Ambiguity evidence

**Mental model:** A courier may return without a receipt even though the parcel reached the destination.

**New terms:**
- **Ambiguous outcome:** a result whose external effect cannot be inferred safely from local evidence alone.

**One action:** Run the focused M06 check once to expose the Ambiguous outcome fixture.

**Wait:** Stop and inspect whether the evidence covers permission, persistence, claim, recheck, repeat-safe execution, finish, and uncertainty.

## Constraints

- Use deterministic synthetic data and the local adapter only.
- The transactional outbox stores the approved intent with its business-state update before any remote work begins.
- Recheck every currently defined M06 authorization fact immediately before adapter execution.
- Repeated execution uses the same remote identity and cannot create a second logical send.
- Preserve the remote-success/local-persistence-failure ambiguity as explicit evidence; do not silently classify it as failure or success.
- Callbacks and retry recovery remain deferred to M07.

## Check

The M06 focused checkpoint verifies a consent-gated persisted intent, one-worker claim, immediate authority recheck, idempotent adapter execution, typed finish, and the uncertain remote-success fixture.

## Explain

Explain the intent-to-finish data flow, why permission is checked twice, and one realistic failure created by the network boundary.

## Transfer

Given a withdrawn permission after intent creation but before adapter execution, predict the terminal behavior and identify the evidence that proves no send occurred.
