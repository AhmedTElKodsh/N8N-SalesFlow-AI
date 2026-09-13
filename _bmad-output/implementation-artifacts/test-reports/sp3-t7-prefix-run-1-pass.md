# SalesFlow one-click test report

- **Verdict:** PASS
- **Started (UTC):** 2026-09-13 12:45:24
- **Finished (UTC):** 2026-09-13 12:53:02
- **Results:** 36 passed, 0 failed, 0 not run
- **Scope:** Simulated local setup only: a synthetic WhatsApp adapter and a fixture AI model in disposable containers. A PASS is not evidence that live WhatsApp or AI providers work.
- **Order:** Scenarios are listed by ID but run in database order, so a not-run scenario can appear between passes.

| ID | Test | Result | Details |
|----|------|--------|---------|
| P01 | Prerequisites and clean-start check | pass |  |
| T04 | SP3-T4 automatic human hand-off suite | pass |  |
| T05 | SP3-T5 saved hand-off summary suite | pass |  |
| T06 | SP3-T6 activity log, emergency stop, and failure view suite | pass |  |
| R01 | Release, workflow, and database contract checks | pass |  |
| E01 | Clean environment, sample data, and database migrations | pass |  |
| S01 | A valid incoming message is accepted and linked to a customer conversation | pass |  |
| S02 | Messages with an invalid token or another account's token are rejected | pass |  |
| S03 | Oversized and future-dated messages are rejected | pass |  |
| S04 | A repeated message is recognized; a changed repeat is flagged as a conflict | pass |  |
| S05 | Messages in one conversation receive distinct, ordered sequence numbers | pass |  |
| S06 | A STOP reply opts the customer out and cancels pending sends, follow-ups, and hand-offs | pass |  |
| S07 | A request for a human creates a hand-off in the sales queue with a response deadline | pass |  |
| S08 | The conversation turn after a human request routes to the hand-off instead of replying | pass |  |
| S09 | A reply made stale by a newer customer message is not sent | pass |  |
| S10 | Hand-off notifications retry, reject stale claims, and stop once acknowledged | pass |  |
| S11 | A reply is drafted only after consent, with its sources recorded | pass |  |
| S12 | A reply the active model may not make goes to a human instead | pass |  |
| S13 | A reply containing an unsupported claim is blocked before sending | pass |  |
| S14 | Only one worker at a time can claim a reply for sending | pass |  |
| S15 | Retryable sends back off, and an uncertain send is flagged for reconciliation | pass |  |
| S16 | Delivery updates apply in time order, and malformed updates are rejected | pass |  |
| S17 | Due follow-ups are scheduled for every eligible account | pass |  |
| S18 | No reply is created when consent is missing | pass |  |
| S19 | A due follow-up is sent through the normal send path | pass |  |
| S20 | Only the current same-account claim can finish a send | pass |  |
| S21 | Deleting a customer erases their personal data from messages and delivery records | pass |  |
| S22 | Audit and delivery evidence cannot be edited or deleted | pass |  |
| S23 | The emergency stop blocks sending, including work already claimed | pass |  |
| S24 | A conversation stuck mid-processing is recovered and answered | pass |  |
| S25 | A send that has used every retry is not attempted again | pass |  |
| S26 | Releases rotate with recorded history and stay isolated per account | pass |  |
| R02 | Additional database regression checks | pass |  |
| C01 | Concurrency and race-condition checks | pass |  |
| W01 | Workflow publication and live endpoint checks | pass |  |
| X01 | Cleanup of containers, data, and generated credentials | pass | Containers, volumes, and generated credentials were removed. |
