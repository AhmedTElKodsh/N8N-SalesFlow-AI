# M08 — Time and human ownership

## Outcome

Synthetic Follow-Ups become eligible from one universal clock, send only during allowed local hours with an eligible approved message, and remain suppressed after a person opts out or a human takes control. Human transfer work and interrupted scheduler work also recover deterministically.

## Why now

M07 can recover an existing outbound attempt. The system can now decide when later work becomes eligible and when automation must yield to current permission or human control.

## Mental model

Each stage contains exactly one mental model for that teaching exchange.

## New terms

New terms are defined in the stage that first uses them.

## Your task

M07 is the immediate prerequisite. The tutor reveals only Stage 1 initially. Do not reveal a later stage until the learner supplies evidence from this stage.

### Stage 1 — Prediction

**Mental model:** UTC due work is one universal appointment timestamp that each account interprets through its own local rules.

**New terms:**
- **UTC due work:** scheduled work whose eligibility time is stored in Coordinated Universal Time.

**One action:** State why you predict UTC due work should be stored independently of local display time.

**Wait:** Stop and inspect the prediction before applying allowed-hours rules.

### Stage 2 — Service window

**Mental model:** A universal appointment may be ready but still waits outside the recipient's permitted local hours.

**New terms:**
- **Service window:** the approved local-time interval during which an automated communication may occur.

**One action:** Make one change that admits due work only inside the account's Service window.

**Wait:** Stop and inspect the diff before checking message eligibility.

### Stage 3 — Template

**Mental model:** An approved message pass has its own validity period in addition to the appointment time.

**New terms:**
- **Template window:** the period in which a specific approved outbound message form is eligible for use.

**One action:** Make one change that requires an eligible Template window for a Follow-Up candidate.

**Wait:** Stop and inspect the diff before considering withdrawn permission.

### Stage 4 — Opt-out

**Mental model:** A stop instruction overrides an earlier reminder appointment, even when every timing rule passes.

**New terms:**
- **Opt-out precedence:** the rule that a current stop request overrides automated-send eligibility.

**One action:** Make one change that applies Opt-out precedence immediately before creating outbound work.

**Wait:** Stop and inspect the diff before considering human control.

### Stage 5 — Ownership

**Mental model:** When a human agent takes the conversation file, the automation desk closes its action slot.

**New terms:**
- **Human-Owned lockout:** suppression of automated communication while a human owns the conversation.

**One action:** Make one change that enforces Human-Owned lockout for every automated outbound candidate.

**Wait:** Stop and inspect the diff before handling transfer work.

### Stage 6 — Handoff

**Mental model:** A transfer ticket is separate due work that delivers the conversation context to the human queue.

**New terms:**
- **Handoff dispatch:** persisted delivery of an eligible transfer request to the approved human-work adapter.

**One action:** Make one change that claims one eligible Handoff dispatch for the synthetic human queue.

**Wait:** Stop and inspect the diff before recovering interrupted scheduler work.

### Stage 7 — Scheduler recovery

**Mental model:** A missed alarm does not erase an appointment; the next scan finds still-due work and rechecks every current rule.

**New terms:**
- **Scheduler recovery:** deterministic rediscovery of eligible due work after an interrupted or missed scheduler run.

**One action:** Make one change that applies Scheduler recovery without bypassing current timing, permission, template, or ownership checks.

**Wait:** Stop and inspect the diff before running focused evidence.

### Stage 8 — Evidence

**Mental model:** A test clock can cross a time boundary and prove both suppression and later eligibility without waiting in real time.

**New terms:** None.

**One action:** Run the focused M08 check once with its deterministic clock.

**Wait:** Stop and inspect whether the evidence covers due timing, allowed hours, approved messages, stop requests, human control, transfers, and missed-run recovery.

## Constraints

- Use deterministic synthetic accounts, messages, queues, and clock values only.
- Store UTC Follow-Ups independently of account-local service-window evaluation.
- Apply opt-out precedence and Human-Owned lockout immediately before any automated outbound intent is created.
- Human ownership blocks automation except an approved fixed non-commercial transfer acknowledgement; current opt-out still suppresses that acknowledgement.
- Handoff work uses persisted intent, claim, recovery, and evidence rules from M06-M07.
- Privacy deletion and releases remain deferred to M09.

## Check

The M08 focused checkpoint may take about 45 seconds. It verifies deterministic UTC eligibility, allowed local hours, approved-message timing, stop and ownership suppression, human transfer delivery, and missed-scheduler recovery.

## Explain

Explain the due-work data flow, why current stop and ownership state overrides prior scheduling, and one failure caused by confusing universal time with account-local rules.

## Transfer

Given overdue synthetic work for a human-controlled conversation after a missed scheduler run, predict the result and identify every rule that is reevaluated.
