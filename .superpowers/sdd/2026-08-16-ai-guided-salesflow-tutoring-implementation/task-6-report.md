# Task 6 implementation report

## Result

Implemented the safe learning checkpoint runner and JSON-only learning CLI.

## Files

- `scripts/Invoke-LearningCheckpoint.ps1`
- `scripts/learn.ps1`
- `tests/learning/Test-LearningCli.ps1`

## Behavior delivered

- Supports `status`, `start`, `check`, `complete`, `resume`, `record-hint`, and `request-solution`.
- Emits one compact JSON object on successful CLI operations; rejected operations write diagnostics to stderr and exit nonzero.
- Initializes M00 state, persists Task 5 state transitions, records hint/direct-solution metadata, rejects blank understanding evidence, and reports resume context.
- Resolves checkpoint scripts beneath `tests/learning/checkpoints` with canonical, case-insensitive, separator-aware containment.
- Rejects missing/non-file targets, sibling-prefix and traversal escapes, and reparse-point/junction paths.
- Executes checkpoint scripts in a separate Windows PowerShell process with `-NoProfile`, independently captures stdout and stderr, and requires exactly one valid JSON-array `LEARNING_EVIDENCE=` stdout line.
- Propagates the checkpoint child exit code. A valid nonzero checkpoint records the failed check and its evidence; protocol and boundary failures leave progress byte-for-byte unchanged.

## TDD and verification

1. Red: `Test-LearningCli.ps1` failed because the runner and CLI did not exist.
2. Green: focused Task 5 state and Task 6 CLI tests passed.
3. All learning tests passed:
   - `Test-Curriculum.ps1`
   - `Test-LearningCli.ps1`
   - `Test-LearningState.ps1`
   - `Test-MilestoneDocuments.ps1`
   - `Test-TutorContract.ps1`
4. The canonical full suite was run once. It passed preflight checks through `internal adapter outcomes`, then stopped at the known Task 8 CRLF portability defect: `manifest input .env.example`.

The Task 6 tests use disposable copied learning fixtures and real child processes. They cover JSON-only success output, call-operator error status, exact child exit-code propagation, stdout/stderr separation, evidence absence/duplication/malformed/type rejection, failed-check recording, no-mutation failures, traversal and sibling-prefix containment, and junction/reparse escape rejection.
