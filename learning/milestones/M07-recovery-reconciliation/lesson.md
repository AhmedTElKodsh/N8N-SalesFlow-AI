# M07 — Recovery and reconciliation

## Outcome

Temporary failures receive a finite, delayed sequence of attempts; remote notifications never move terminal progress backward; abandoned worker ownership becomes eligible again; and uncertain sends are resolved from durable external evidence.

## Why now

M06 makes one authorized attempt and preserves uncertainty. The next capability must recover safely without turning every timeout into another external effect.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M06 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** A Recovery policy is a written rule for which interrupted jobs may resume, when, and how often.

**New terms:**
- **Recovery policy:** deterministic limits and transitions for resuming interrupted work.

**One action:** Classify one M06 failure you predict the Recovery policy may retry safely.

**Wait:** Stop and inspect the classification before defining retry timing.

### Stage 2 — Retry

**Mental model:** A caller makes only a fixed number of later attempts, spacing them farther apart so a struggling service can recover.

**New terms:**
- **Bounded retry:** repeating eligible work no more than a declared maximum number of attempts.
- **Backoff:** increasing or scheduled delay before another eligible attempt.

**One action:** Make one change that applies Bounded retry with deterministic Backoff to eligible temporary failures.

**Wait:** Stop and inspect the diff before accepting remote notifications.

### Stage 3 — Callback

**Mental model:** A delivery desk sends a later receipt that refers to the original request number.

**New terms:**
- **Provider callback:** an asynchronous remote notification about a previously accepted request.

**One action:** Make one change that validates a synthetic Provider callback against its original persisted intent.

**Wait:** Stop and inspect the diff before protecting status direction.

### Stage 4 — Monotonic status

**Mental model:** A parcel cannot become merely packed after it has already been recorded as delivered.

**New terms:**
- **Monotonic state:** status that may advance through allowed transitions but cannot regress.

**One action:** Make one change that enforces Monotonic state for out-of-order callback updates.

**Wait:** Stop and inspect the diff before recovering abandoned worker ownership.

### Stage 5 — Expired claim

**Mental model:** An unattended claim ticket becomes available only after its printed time limit passes.

**New terms:**
- **Expired claim:** temporary ownership whose allowed time has elapsed without a valid finish.

**One action:** Make one change that returns an Expired claim to eligible recovery without stealing a live claim.

**Wait:** Stop and inspect the diff before resolving uncertain remote effects.

### Stage 6 — Ambiguous result

**Mental model:** When the local receipt is missing, a clerk compares the remote ledger using the original request identity.

**New terms:**
- **Reconciliation:** resolving uncertain local state by comparing it with authoritative external observations.

**One action:** Make one change that uses the stable remote request identity for Reconciliation of an uncertain result.

**Wait:** Stop and inspect the diff before collecting focused proof.

### Stage 7 — Evidence

**Mental model:** A recovery report records both the external observation and the deterministic local transition it justified.

**New terms:**
- **Reconciliation evidence:** durable facts showing what external observation resolved an uncertain local outcome.

**One action:** Run the focused M07 check once to collect Reconciliation evidence.

**Wait:** Stop and inspect whether the result covers limited retries, delayed timing, ordered callback state, abandoned claims, and uncertain outcomes.

## Constraints

- Use deterministic synthetic callbacks, clocks, and adapter observations only.
- Every bounded retry has an explicit attempt limit and deterministic backoff schedule.
- Duplicate or out-of-order callbacks preserve monotonic progress and one logical external effect.
- Recover only expired ownership; never take work from a live claimant.
- Reconciliation records the evidence used to resolve an ambiguous result instead of guessing from a timeout.
- Scheduling and human ownership remain deferred to M08.

## Check

The M07 focused checkpoint verifies bounded retry and backoff, monotonic provider callbacks, expired-claim recovery, and evidence-backed resolution of uncertain results.

## Explain

Explain the failure-to-recovery data flow, why progress cannot move backward, and one risk of retrying an uncertain external result blindly.

## Transfer

Given a delivered callback followed by a delayed sent callback, predict the stored status and identify the transition rule that protects it.
