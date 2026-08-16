# AI-Guided SalesFlow Tutoring Product Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a durable, interactive, milestone-gated tutoring product that guides a junior developer from a clean SalesFlow starter revision to the verified synthetic-local implementation without exposing direct solutions unless requested.

**Architecture:** A canonical Markdown tutor contract governs every AI client. JSON-compatible YAML files define the curriculum and checkpoints, a dependency-free PowerShell module owns local progress, and a thin `learn.ps1` CLI runs focused milestone validators. The completed solution and learner starter are published as immutable Git refs after the overlay and validators pass against the reference implementation.

**Tech Stack:** Windows PowerShell 5.1 or PowerShell 7, Git, Docker Compose, JSON-compatible YAML, Markdown, existing n8n/PostgreSQL artifacts

## Global Constraints

- Primary learner: junior developer with basic programming knowledge and little production PostgreSQL, Docker, n8n, or distributed-systems experience.
- Address only the active milestone and its immediate prerequisite.
- Begin with one mental model and no more than three new technical terms.
- Give one actionable step at a time and wait for learner evidence before advancing.
- Direct code, SQL, workflow, or command solutions require an explicit learner request.
- Hint use never lowers a score or blocks completion.
- A milestone requires both a behavior gate and an understanding gate.
- Production credentials and customer data never enter prompts, fixtures, progress, or test output.
- Use no new package manager or runtime dependency; the canonical learner path remains PowerShell plus Docker Desktop.
- Files named `.yaml` use the JSON-compatible subset of YAML 1.2 and are parsed with `ConvertFrom-Json`.
- Do not include existing unrelated `_bmad`, backup-file, Party memory, or visual-companion changes in implementation commits.
- Production adapter, retention, observability, rollback, and infrastructure hardening remain outside this plan except where a lesson describes their boundaries.

---

## Planned File Map

| File | Responsibility |
| --- | --- |
| `AGENTS.md` | Root pointer to the canonical tutoring protocol. |
| `.gitignore` | Ignore `.learning/` progress and `.superpowers/` visual-companion output. |
| `.gitattributes` | Enforce LF for manifest-hashed source artifacts on Windows checkouts. |
| `learning/README.md` | Learner entry point and command-oriented course map. |
| `learning/tutor-contract.md` | Canonical AI behavior, hint ladder, and direct-solution rules. |
| `learning/curriculum.yaml` | Ordered M00–M10 curriculum and immutable ref metadata. |
| `learning/progress-template.json` | Versioned schema/default state for `.learning/progress.json`. |
| `learning/journal.md` | Learner-owned explanation and reflection evidence. |
| `learning/milestones/Mxx-*/lesson.md` | Human-readable just-in-time milestone brief. |
| `learning/milestones/Mxx-*/checkpoint.yaml` | Machine-readable prerequisite, test, and gate contract. |
| `learning/milestones/Mxx-*/hints.md` | Five progressive hint levels without direct solutions. |
| `scripts/LearningState.psm1` | Progress, curriculum, lineage, and completion state operations. |
| `scripts/Invoke-LearningCheckpoint.ps1` | Safe focused-check dispatcher. |
| `scripts/learn.ps1` | Public `status/start/check/complete/resume/record-hint/request-solution` CLI. |
| `tests/learning/TestSupport.ps1` | Dependency-free assertions and fixture helpers. |
| `tests/learning/Test-*.ps1` | Contract, curriculum, state, CLI, and milestone validators. |
| `docs/development-guide.md` | Developer guidance for maintaining curriculum and refs. |

---

### Task 1: Establish the canonical tutor contract

**Files:**
- Create: `AGENTS.md`
- Create: `learning/tutor-contract.md`
- Create: `tests/learning/TestSupport.ps1`
- Create: `tests/learning/Test-TutorContract.ps1`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: approved design at `docs/superpowers/specs/2026-08-16-ai-guided-salesflow-tutoring-design.md`
- Produces: canonical protocol headings and the assertion helpers `Assert-True`, `Assert-Equal`, and `Assert-Match`

- [ ] **Step 1: Write the failing contract test**

```powershell
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$contract = Join-Path $root 'learning/tutor-contract.md'
$agents = Join-Path $root 'AGENTS.md'

Assert-True (Test-Path -LiteralPath $contract) 'canonical tutor contract exists'
Assert-True (Test-Path -LiteralPath $agents) 'root AI instructions exist'
$text = Get-Content -Raw -LiteralPath $contract
foreach ($heading in @(
  '## Session start',
  '## Just-in-time teaching limits',
  '## Hint ladder',
  '## Direct-solution mode',
  '## Completion gates',
  '## Failure classification',
  '## Session resume'
)) { Assert-Match $text ([regex]::Escape($heading)) "contract contains $heading" }
Assert-Match $text 'explicit learner request' 'direct solution requires explicit request'
Assert-Match (Get-Content -Raw -LiteralPath $agents) 'learning/tutor-contract\.md' 'AGENTS points to canonical contract'
Complete-TestFile
```

- [ ] **Step 2: Run the contract test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-TutorContract.ps1`

Expected: FAIL because `AGENTS.md` and `learning/tutor-contract.md` do not exist.

- [ ] **Step 3: Implement dependency-free test helpers**

```powershell
$script:FailureCount = 0
function Assert-True([bool]$Condition, [string]$Message) {
  if (-not $Condition) { $script:FailureCount++; Write-Error "FAIL $Message" }
  else { Write-Host "PASS $Message" }
}
function Assert-Equal($Actual, $Expected, [string]$Message) {
  Assert-True ($Actual -eq $Expected) "$Message (actual=$Actual expected=$Expected)"
}
function Assert-Match([string]$Text, [string]$Pattern, [string]$Message) {
  Assert-True ($Text -match $Pattern) $Message
}
function Complete-TestFile {
  if ($script:FailureCount -gt 0) { throw "$script:FailureCount assertion(s) failed" }
}
```

- [ ] **Step 4: Write the canonical contract and root pointer**

`learning/tutor-contract.md` must state the exact M00–M10 protocol, one-step pacing, three-term teaching limit, five-level hint ladder, two completion gates, failure classes, direct-solution recording and reconstruction requirement, reference-access prohibition, and resume procedure from the approved design.

`AGENTS.md` must contain this binding pointer:

```markdown
# Project AI Instructions

When teaching or guiding work in this repository, read and follow `learning/tutor-contract.md` before acting. The learner owns implementation. Do not provide or apply direct solutions unless the learner explicitly requests one.
```

Append these exact ignore entries to `.gitignore`:

```gitignore
.learning/
.superpowers/
```

- [ ] **Step 5: Run the contract test and verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-TutorContract.ps1`

Expected: every assertion prints `PASS`; exit code 0.

- [ ] **Step 6: Commit the contract**

```powershell
git add AGENTS.md .gitignore learning/tutor-contract.md tests/learning/TestSupport.ps1 tests/learning/Test-TutorContract.ps1
git commit -m "feat: establish SalesFlow tutor contract"
```

---

### Task 2: Define curriculum and progress schemas

**Files:**
- Create: `learning/README.md`
- Create: `learning/curriculum.yaml`
- Create: `learning/progress-template.json`
- Create: `learning/journal.md`
- Create: `tests/learning/Test-Curriculum.ps1`

**Interfaces:**
- Consumes: canonical protocol from Task 1
- Produces: `curriculumVersion: 1`, milestone records with `id`, `directory`, `prerequisites`, and `title`; progress fields consumed by `LearningState.psm1`

- [ ] **Step 1: Write the failing curriculum/schema test**

```powershell
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$curriculum = Get-Content -Raw "$root/learning/curriculum.yaml" | ConvertFrom-Json
$template = Get-Content -Raw "$root/learning/progress-template.json" | ConvertFrom-Json

Assert-Equal $curriculum.curriculumVersion 1 'curriculum version'
Assert-Equal @($curriculum.milestones).Count 11 'M00-M10 count'
Assert-Equal (($curriculum.milestones.id) -join ',') ((0..10 | ForEach-Object { 'M{0:d2}' -f $_ }) -join ',') 'ordered milestone ids'
Assert-Equal @($curriculum.milestones[0].prerequisites).Count 0 'M00 has no prerequisites'
for ($i = 1; $i -le 10; $i++) {
  Assert-Equal $curriculum.milestones[$i].prerequisites[0] ('M{0:d2}' -f ($i - 1)) "M$i depends on predecessor"
}
Assert-Equal $template.schemaVersion 1 'progress schema version'
Assert-Equal $template.currentMilestone 'M00' 'initial milestone'
Assert-True ($null -ne $template.milestones.M00) 'M00 progress state exists'
Assert-Equal $template.milestones.M00.status 'available' 'M00 initially available'
Assert-Equal $template.milestones.M01.status 'locked' 'M01 initially locked'
Complete-TestFile
```

- [ ] **Step 2: Run the schema test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-Curriculum.ps1`

Expected: FAIL because the curriculum and progress schema do not exist.

- [ ] **Step 3: Write `curriculum.yaml` as JSON-compatible YAML**

Use this top-level shape and all eleven approved titles:

```json
{
  "curriculumVersion": 1,
  "starterRef": "starter/salesflow-guided-v1",
  "referenceRef": "reference/salesflow-complete-v1",
  "milestones": [
    {"id":"M00","directory":"M00-orientation","title":"Repository orientation","prerequisites":[]},
    {"id":"M01","directory":"M01-local-stack","title":"Smallest local stack","prerequisites":["M00"]},
    {"id":"M02","directory":"M02-first-vertical-slice","title":"First vertical slice","prerequisites":["M01"]},
    {"id":"M03","directory":"M03-durable-identity","title":"Durable identity","prerequisites":["M02"]},
    {"id":"M04","directory":"M04-safe-repetition","title":"Safe repetition","prerequisites":["M03"]},
    {"id":"M05","directory":"M05-governed-intelligence","title":"Governed intelligence","prerequisites":["M04"]},
    {"id":"M06","directory":"M06-authorized-side-effects","title":"Authorized side effects","prerequisites":["M05"]},
    {"id":"M07","directory":"M07-recovery-reconciliation","title":"Recovery and reconciliation","prerequisites":["M06"]},
    {"id":"M08","directory":"M08-time-human-ownership","title":"Time and human ownership","prerequisites":["M07"]},
    {"id":"M09","directory":"M09-responsible-operations","title":"Responsible operations","prerequisites":["M08"]},
    {"id":"M10","directory":"M10-capstone","title":"Capstone","prerequisites":["M09"]}
  ]
}
```

- [ ] **Step 4: Write the progress template**

Use these exact milestone-state properties for M00 through M10:

```json
{
  "status": "locked",
  "attempts": 0,
  "behaviorGate": false,
  "understandingGate": false,
  "highestHintLevel": 0,
  "directSolutionRequested": false,
  "lastCheckAt": null,
  "lastCheckResult": null,
  "explanation": null,
  "failureMode": null,
  "transferEvidence": null,
  "evidenceRevision": null,
  "resumeNote": null
}
```

Set M00 to `available`; set all others to `locked`. Add top-level `schemaVersion`, `curriculumVersion`, `currentMilestone`, `starterRevision`, and `referenceRevision`.

- [ ] **Step 5: Write the learner entry point and journal**

`learning/README.md` must explain the clean-starter model, `learn.ps1` commands, two completion gates, hint behavior, direct-solution rule, synthetic boundary, and safe resume.

`learning/journal.md` must contain one section per milestone with these prompts:

```markdown
### Data flow

### Design decision

### Realistic failure mode

### Transfer exercise evidence
```

- [ ] **Step 6: Run the schema test and verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-Curriculum.ps1`

Expected: exit code 0 with eleven ordered milestone assertions.

- [ ] **Step 7: Commit schemas and entry documentation**

```powershell
git add learning/README.md learning/curriculum.yaml learning/progress-template.json learning/journal.md tests/learning/Test-Curriculum.ps1
git commit -m "feat: define SalesFlow learning curriculum"
```

---

### Task 3: Author milestone contracts M00–M05

**Files:**
- Create: `learning/milestones/M00-orientation/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M01-local-stack/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M02-first-vertical-slice/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M03-durable-identity/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M04-safe-repetition/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M05-governed-intelligence/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `tests/learning/Test-MilestoneDocuments.ps1`

**Interfaces:**
- Consumes: curriculum directory names from Task 2
- Produces: checkpoint properties `id`, `prerequisites`, `testScript`, `behaviorEvidence`, `understandingPrompts`, and `estimatedSeconds`

- [ ] **Step 1: Write the failing milestone-document test**

```powershell
param([ValidateSet('M05','M10')][string]$Through = 'M10')
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$curriculum = Get-Content -Raw "$root/learning/curriculum.yaml" | ConvertFrom-Json
$lastIndex = [int]$Through.Substring(1)
foreach ($m in @($curriculum.milestones)[0..$lastIndex]) {
  $dir = Join-Path $root "learning/milestones/$($m.directory)"
  foreach ($name in @('lesson.md','checkpoint.yaml','hints.md')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $dir $name)) "$($m.id) has $name"
  }
  if (Test-Path "$dir/checkpoint.yaml") {
    $checkpoint = Get-Content -Raw "$dir/checkpoint.yaml" | ConvertFrom-Json
    Assert-Equal $checkpoint.id $m.id "$($m.id) checkpoint identity"
    Assert-True ($checkpoint.testScript -match '^tests/learning/checkpoints/Test-M\d\d\.ps1$') "$($m.id) safe test path"
    Assert-True (@($checkpoint.understandingPrompts).Count -eq 3) "$($m.id) has three understanding prompts"
  }
  if (Test-Path "$dir/hints.md") {
    $hints = Get-Content -Raw "$dir/hints.md"
    foreach ($level in 1..5) { Assert-Match $hints "## Hint $level" "$($m.id) has hint $level" }
    Assert-True (-not ($hints -match 'Direct solution')) "$($m.id) hints do not contain direct solution"
  }
}
Complete-TestFile
```

- [ ] **Step 2: Run the test and verify M00–M10 documents fail**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-MilestoneDocuments.ps1 -Through M05`

Expected: FAIL for missing M00–M05 milestone artifacts.

- [ ] **Step 3: Author lessons M00–M05 with exact scope**

Use the approved curriculum scopes:

| ID | Visible deliverable | Concepts introduced now | Concepts explicitly deferred |
| --- | --- | --- | --- |
| M00 | Learner can map an inbound event to n8n and PostgreSQL responsibilities | repository, orchestrator, durable state | SQL syntax, retries, LLMs |
| M01 | PostgreSQL and n8n health checks pass locally | container, service, volume | workflow logic, schema design |
| M02 | POST webhook reaches one parameterized SQL command and returns a typed result | webhook, parameter, transaction | multi-table domain model, concurrency |
| M03 | Account-scoped contact/conversation/message records persist with foreign keys | primary key, foreign key, tenant scope | replay races, leases |
| M04 | Duplicate and concurrent inbound events produce one logical action or a typed conflict | idempotency, serialization, uniqueness | provider retry, callbacks |
| M05 | A synthetic decision is accepted only with typed policy/knowledge/provenance; otherwise Handoff | grounding, provenance, fail-closed | real model selection, prompt tuning |

Every `lesson.md` must include: `## Outcome`, `## Why now`, `## Mental model`, `## New terms`, `## Your task`, `## Constraints`, `## Check`, `## Explain`, and `## Transfer`.

- [ ] **Step 4: Author JSON-compatible checkpoints M00–M05**

Use this exact shape, replacing values for each milestone:

```json
{
  "id": "M02",
  "prerequisites": ["M01"],
  "testScript": "tests/learning/checkpoints/Test-M02.ps1",
  "behaviorEvidence": ["webhook-path", "parameterized-query", "typed-terminal"],
  "understandingPrompts": ["dataFlow", "designDecision", "failureMode"],
  "estimatedSeconds": 20
}
```

Set estimates to M00=5, M01=15, M02=20, M03=20, M04=30, and M05=30 seconds.

- [ ] **Step 5: Author five-level hints M00–M05**

Each file follows this pattern and uses an unrelated miniature example at Hint 2:

```markdown
# M02 Hints

## Hint 1 — Diagnostic question

Which component should own the durable state after the webhook execution ends?

## Hint 2 — Concept

Explain parameter binding using a small inventory lookup, not SalesFlow code.

## Hint 3 — Location

Point to the learner's inbound workflow and first migration file.

## Hint 4 — Structure

Describe trigger → parameterized command → typed terminal without node values or SQL.

## Hint 5 — Pseudocode

Show incomplete pseudocode with named blanks; do not provide importable workflow JSON or executable SQL.
```

- [ ] **Step 6: Run the scoped document test and verify M00–M05 pass**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-MilestoneDocuments.ps1 -Through M05`

Expected: all scoped M00–M05 document, checkpoint, and hint assertions pass.

- [ ] **Step 7: Commit M00–M05**

```powershell
git add learning/milestones tests/learning/Test-MilestoneDocuments.ps1
git commit -m "feat: add foundational SalesFlow milestones"
```

---

### Task 4: Author milestone contracts M06–M10

**Files:**
- Create: `learning/milestones/M06-authorized-side-effects/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M07-recovery-reconciliation/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M08-time-human-ownership/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M09-responsible-operations/{lesson.md,checkpoint.yaml,hints.md}`
- Create: `learning/milestones/M10-capstone/{lesson.md,checkpoint.yaml,hints.md}`

**Interfaces:**
- Consumes: milestone document contract from Task 3
- Produces: complete M00–M10 curriculum artifact set

- [ ] **Step 1: Author lessons with exact scope**

| ID | Visible deliverable | Concepts introduced now | Concepts explicitly deferred |
| --- | --- | --- | --- |
| M06 | Consent-gated persisted intent is claimed, rechecked, dispatched, and finished | transactional outbox, lease, idempotency key | callbacks and retry recovery |
| M07 | Retry, monotonic callback, expired claim, and ambiguous result recover deterministically | backoff, reconciliation, monotonic state | scheduling and human ownership |
| M08 | UTC Follow-Ups and Handoffs honor service windows, opt-out, and Human-Owned lockout | UTC due work, template window, ownership | privacy deletion and releases |
| M09 | Operations expose correlated evidence, deletion/minimization, retention duties, and release identity | audit evidence, minimization, retention, rollback | real provider infrastructure |
| M10 | Complete suite passes and learner traces one scenario plus production gates | acceptance evidence, synthetic boundary, production gate | actual production promotion |

- [ ] **Step 2: Author checkpoints M06–M10**

Use the Task 3 checkpoint shape. Set estimates to M06=30, M07=30, M08=45, M09=30, and M10=240 seconds. M10's `testScript` is `tests/learning/checkpoints/Test-M10.ps1`, which delegates to the complete harness after preflight.

- [ ] **Step 3: Author five-level hints M06–M10**

Ensure M06 Hint 2 explicitly teaches why a database transaction cannot include a remote provider call, without describing SalesFlow's final implementation. Ensure M09 hints distinguish configured retention values from an enforced purge. Ensure M10 hints name production evidence categories but do not prescribe real provider credentials.

- [ ] **Step 4: Run the complete milestone-document test**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-MilestoneDocuments.ps1`

Expected: all M00–M10 document and hint assertions pass.

- [ ] **Step 5: Commit M06–M10**

```powershell
git add learning/milestones
git commit -m "feat: add advanced SalesFlow milestones"
```

---

### Task 5: Implement progress state with TDD

**Files:**
- Create: `scripts/LearningState.psm1`
- Create: `tests/learning/Test-LearningState.ps1`

**Interfaces:**
- Consumes: `learning/curriculum.yaml`, `learning/progress-template.json`, Git repository root
- Produces: `Get-LearningContext`, `Initialize-LearningProgress`, `Start-LearningMilestone`, `Record-LearningCheck`, `Record-LearningHint`, `Record-DirectSolutionRequest`, `Complete-LearningMilestone`

- [ ] **Step 1: Write failing state-transition tests in a temporary workspace**

```powershell
. "$PSScriptRoot/TestSupport.ps1"
Import-Module "$PSScriptRoot/../../scripts/LearningState.psm1" -Force
$temp = Join-Path ([IO.Path]::GetTempPath()) ("salesflow-learning-" + [guid]::NewGuid())
New-Item $temp -ItemType Directory | Out-Null
try {
  Copy-Item "$PSScriptRoot/../../learning" $temp -Recurse
  $ctx = Get-LearningContext -RepositoryRoot $temp
  Initialize-LearningProgress -Context $ctx
  $p = Get-Content -Raw $ctx.ProgressPath | ConvertFrom-Json
  Assert-Equal $p.currentMilestone 'M00' 'initial milestone'

  Start-LearningMilestone -Context $ctx -MilestoneId M00
  Record-LearningHint -Context $ctx -MilestoneId M00 -Level 3
  Record-LearningCheck -Context $ctx -MilestoneId M00 -Passed $true -Evidence @('orientation-ok')
  Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation 'n8n routes; PostgreSQL owns durable state' -FailureMode 'workflow succeeds but persistence fails' -TransferEvidence 'mapped a second webhook'
  $p = Get-Content -Raw $ctx.ProgressPath | ConvertFrom-Json
  Assert-Equal $p.milestones.M00.status 'completed' 'M00 completed'
  Assert-Equal $p.milestones.M00.highestHintLevel 3 'highest hint recorded'
  Assert-Equal $p.currentMilestone 'M01' 'next milestone unlocked'
  Assert-Equal $p.milestones.M01.status 'available' 'M01 available'

  $threw = $false
  try { Start-LearningMilestone -Context $ctx -MilestoneId M02 } catch { $threw = $true }
  Assert-True $threw 'locked milestone rejected'
  Complete-TestFile
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
```

- [ ] **Step 2: Run the state test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-LearningState.ps1`

Expected: FAIL because `LearningState.psm1` does not exist.

- [ ] **Step 3: Implement context and atomic persistence**

```powershell
function Get-LearningContext([string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)) {
  $root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
  [pscustomobject]@{
    RepositoryRoot = $root
    CurriculumPath = Join-Path $root 'learning/curriculum.yaml'
    TemplatePath = Join-Path $root 'learning/progress-template.json'
    ProgressPath = Join-Path $root '.learning/progress.json'
  }
}

function Save-LearningProgress($Context, $Progress) {
  $dir = Split-Path -Parent $Context.ProgressPath
  New-Item $dir -ItemType Directory -Force | Out-Null
  $temp = "$($Context.ProgressPath).tmp"
  [IO.File]::WriteAllText($temp, ($Progress | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temp -Destination $Context.ProgressPath -Force
}
```

Implement the produced functions with these invariants:

- initialization copies the template and records curriculum/starter/reference refs;
- `start` accepts only `available` or the same `active` milestone;
- attempts increment only when transitioning into `active`;
- hint levels must be integers 1–5 and retain the maximum;
- a passed check sets only `behaviorGate` and stores evidence/timestamp;
- completion rejects a false behavior gate or blank explanation/failure/transfer fields;
- completion unlocks only the immediate successor;
- direct-solution request sets the flag but does not mark either gate complete.

- [ ] **Step 4: Run the state test and verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-LearningState.ps1`

Expected: exit code 0; temp workspace removed in `finally`.

- [ ] **Step 5: Commit the state engine**

```powershell
git add scripts/LearningState.psm1 tests/learning/Test-LearningState.ps1
git commit -m "feat: add durable learning progress state"
```

---

### Task 6: Implement the safe checkpoint runner and CLI

**Files:**
- Create: `scripts/Invoke-LearningCheckpoint.ps1`
- Create: `scripts/learn.ps1`
- Create: `tests/learning/Test-LearningCli.ps1`

**Interfaces:**
- Consumes: Task 5 state functions and checkpoint `testScript`
- Produces: CLI commands `status`, `start`, `check`, `complete`, `resume`, `record-hint`, `request-solution`

- [ ] **Step 1: Write the failing CLI test**

The test invokes the CLI with `-RepositoryRoot` pointing to a disposable fixture and asserts:

```powershell
$status = & $cli status -RepositoryRoot $temp | ConvertFrom-Json
Assert-Equal $status.currentMilestone 'M00' 'status initializes M00'
& $cli start -Milestone M00 -RepositoryRoot $temp | Out-Null
& $cli record-hint -Milestone M00 -Level 2 -RepositoryRoot $temp | Out-Null
& $cli request-solution -Milestone M00 -RepositoryRoot $temp | Out-Null
$status = & $cli status -RepositoryRoot $temp | ConvertFrom-Json
Assert-Equal $status.highestHintLevel 2 'CLI records hint'
Assert-True $status.directSolutionRequested 'CLI records direct solution request'
```

Add a fixture checkpoint whose test script exits 0 and writes `LEARNING_EVIDENCE=["fixture-pass"]`. Assert `check` records the behavior gate. Assert `complete` rejects blank understanding fields and accepts three nonblank fields.

- [ ] **Step 2: Run the CLI test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-LearningCli.ps1`

Expected: FAIL because the runner and CLI do not exist.

- [ ] **Step 3: Implement the checkpoint runner path boundary**

```powershell
$testsRoot = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'tests/learning/checkpoints'))
$scriptPath = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $Checkpoint.testScript))
if (-not $scriptPath.StartsWith($testsRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Checkpoint testScript escapes tests/learning/checkpoints.'
}
if (-not (Test-Path -LiteralPath $scriptPath)) { throw "Checkpoint script missing: $scriptPath" }
& powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -RepositoryRoot $RepositoryRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The runner captures the single `LEARNING_EVIDENCE=<json-array>` line and returns a JSON result with `passed`, `milestone`, `evidence`, and `durationMs`.

- [ ] **Step 4: Implement CLI dispatch**

Use this parameter contract:

```powershell
param(
  [Parameter(Position=0)][ValidateSet('status','start','check','complete','resume','record-hint','request-solution')][string]$Command = 'status',
  [string]$Milestone,
  [ValidateRange(1,5)][int]$Level,
  [string]$Explanation,
  [string]$FailureMode,
  [string]$TransferEvidence,
  [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)
```

Every successful command emits one JSON object. Errors go to the error stream and return nonzero. `resume` reports branch, current milestone, working-tree state, behavior gate, hint level, direct-solution state, and resume note; it does not mutate implementation files.

- [ ] **Step 5: Run the CLI test and verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-LearningCli.ps1`

Expected: all state, path-boundary, and completion-gate assertions pass.

- [ ] **Step 6: Commit runner and CLI**

```powershell
git add scripts/Invoke-LearningCheckpoint.ps1 scripts/learn.ps1 tests/learning/Test-LearningCli.ps1
git commit -m "feat: add SalesFlow learning CLI"
```

---

### Task 7: Add focused M00–M10 checkpoint validators

**Files:**
- Create: `tests/learning/checkpoints/Test-M00.ps1` through `Test-M10.ps1`
- Create: `tests/learning/Test-CheckpointSuite.ps1`

**Interfaces:**
- Consumes: `-RepositoryRoot`, current repository artifacts, Task 1 assertion helpers
- Produces: exit 0 plus exactly one `LEARNING_EVIDENCE=<json-array>` line on success

- [ ] **Step 1: Write the checkpoint-suite meta-test**

```powershell
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
foreach ($i in 0..10) {
  $id = 'M{0:d2}' -f $i
  $path = Join-Path $root "tests/learning/checkpoints/Test-$id.ps1"
  Assert-True (Test-Path -LiteralPath $path) "$id checkpoint exists"
  if (Test-Path $path) {
    $text = Get-Content -Raw $path
    Assert-Match $text '(?s)param\(.*\$RepositoryRoot' "$id accepts RepositoryRoot"
    Assert-Match $text 'LEARNING_EVIDENCE=' "$id emits evidence"
    Assert-True (-not ($text -match 'git\s+(show|checkout).*reference/')) "$id does not read reference solution"
  }
}
Complete-TestFile
```

- [ ] **Step 2: Run the suite test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-CheckpointSuite.ps1`

Expected: FAIL for eleven missing scripts.

- [ ] **Step 3: Implement checkpoint behavior contracts**

Each script parses structured artifacts where possible and emits these evidence keys:

| ID | Required focused evidence |
| --- | --- |
| M00 | Git repository, learning contract readable, learner journal contains M00 prompts |
| M01 | Docker daemon reachable, Compose config valid, n8n published only on `127.0.0.1`, PostgreSQL healthcheck present |
| M02 | Workflow 01 JSON parses; webhook, PostgreSQL, conditional/terminal nodes form a connected path; query uses replacements rather than interpolated body SQL |
| M03 | Migration declares account/contact/conversation/inbound-message ownership keys and cross-account foreign-key boundaries |
| M04 | Migration and tests contain provider replay uniqueness, monotonic sequence, typed idempotency conflict, and a concurrent replay assertion |
| M05 | All typed config files parse; turn completion records policy, knowledge, claims, source IDs, confidence, and fail-closed Handoff behavior |
| M06 | Intent is persisted before adapter; workflow order is claim → recheck → adapter → finish; consent and final authorization denial paths exist |
| M07 | Retry budget, backoff, expired claim recovery, ambiguous result, callback idempotency, and monotonic status assertions exist |
| M08 | UTC schedule trigger routes both outbound and Handoff work; opt-out suppresses work; Human-Owned prevents automation |
| M09 | Audit immutability, deletion/minimization evidence, retention configuration boundary, release manifest binding, and production gates are documented and asserted |
| M10 | Preflight verifies M00–M09; then invokes `tests/run.ps1`; success requires `PASS FULL PASS` and cleanup evidence |

Use `ConvertFrom-Json` for workflow/config parsing. SQL checks assert behavioral constructs and corresponding test evidence markers, not full function text or hashes. M10 must explain its expected runtime before invoking the full suite.

- [ ] **Step 4: Run M00–M09 against the completed reference worktree**

Run:

```powershell
0..9 | ForEach-Object {
  $id = 'M{0:d2}' -f $_
  powershell -ExecutionPolicy Bypass -File ".\tests\learning\checkpoints\Test-$id.ps1" -RepositoryRoot (Get-Location)
  if ($LASTEXITCODE -ne 0) { throw "$id failed" }
}
```

Expected: every script exits 0 and emits one evidence array. Do not run M10 yet because Task 8 fixes Windows manifest hashing first.

- [ ] **Step 5: Run the checkpoint-suite meta-test**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-CheckpointSuite.ps1`

Expected: eleven checkpoint interface and anti-reference-leak assertions pass.

- [ ] **Step 6: Commit checkpoint validators**

```powershell
git add tests/learning/checkpoints tests/learning/Test-CheckpointSuite.ps1
git commit -m "test: add focused SalesFlow learning checkpoints"
```

---

### Task 8: Make manifest verification stable on Windows checkouts

**Files:**
- Create: `.gitattributes`
- Create: `tests/learning/Test-ManifestHashing.ps1`

**Interfaces:**
- Consumes: `release/release-manifest.json.inputHashes`
- Produces: enforced LF working-tree bytes for every manifest-hashed text format, allowing the existing raw `Get-FileHash` contract to remain unchanged

- [ ] **Step 1: Write a failing line-ending policy and raw-hash test**

```powershell
. "$PSScriptRoot/TestSupport.ps1"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$manifest = Get-Content -Raw "$root/release/release-manifest.json" | ConvertFrom-Json

foreach ($sample in @('tests/run.ps1','tests/runtime.sql','workflows/01-whatsapp-ingress.json','learning/curriculum.yaml')) {
  $attribute = git -C $root check-attr eol -- $sample
  Assert-Match ($attribute -join "`n") 'eol: lf$' "$sample is forced to LF"
}

foreach ($property in $manifest.inputHashes.psobject.Properties) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root $property.Name)).Hash.ToLowerInvariant()
  Assert-Equal $actual $property.Value "raw manifest hash $($property.Name)"
}
Complete-TestFile
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-ManifestHashing.ps1`

Expected: FAIL because no repository LF policy exists and raw hashes differ in a CRLF Windows checkout.

- [ ] **Step 3: Add the repository line-ending policy**

Create `.gitattributes`:

```gitattributes
* text=auto
*.env text eol=lf
*.example text eol=lf
*.json text eol=lf
*.sql text eol=lf
*.mjs text eol=lf
*.yaml text eol=lf
*.md text eol=lf
*.ps1 text eol=lf
*.psm1 text eol=lf
```

- [ ] **Step 4: Normalize the isolated implementation worktree without changing Git content**

Normalize only the manifest-declared text inputs:

```powershell
$manifest = Get-Content -Raw release/release-manifest.json | ConvertFrom-Json
foreach ($property in $manifest.inputHashes.psobject.Properties) {
  $path = (Resolve-Path -LiteralPath $property.Name).Path
  $text = [IO.File]::ReadAllText($path).Replace("`r`n", "`n").Replace("`r", "`n")
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}
```

Run `git status --short` and verify normalization did not create content changes to manifest inputs. `.gitattributes` and the new test should be the only Task 8 changes.

- [ ] **Step 5: Run hashing and existing static preflight**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-ManifestHashing.ps1`

Expected: every sampled Git attribute reports `eol: lf`; all existing raw manifest hashes pass unchanged.

- [ ] **Step 6: Run M10 in a clean disposable environment**

Before running, confirm there is no retained `.env` or project-labeled volume. Do not delete either without explicit authorization. When clean, run:

`powershell -ExecutionPolicy Bypass -File .\tests\learning\checkpoints\Test-M10.ps1 -RepositoryRoot (Get-Location)`

Expected: `PASS FULL PASS`, M10 evidence, generated plaintext removed, and disposable volumes removed.

- [ ] **Step 7: Commit reproducibility policy**

```powershell
git add .gitattributes tests/learning/Test-ManifestHashing.ps1
git commit -m "fix: stabilize manifest checks across line endings"
```

---

### Task 9: Verify resume, no-solution leakage, and complete learning acceptance

**Files:**
- Create: `tests/learning/Test-TutoringAcceptance.ps1`
- Modify: `docs/development-guide.md`

**Interfaces:**
- Consumes: all Phase 1 tutoring artifacts
- Produces: one acceptance command proving clean initialization, progression rules, resume, checkpoint dispatch, and reference isolation

- [ ] **Step 1: Write the failing acceptance test**

The test creates a disposable repository fixture, initializes progress, completes M00 with both gates, verifies M01 unlocks, simulates a new process by re-invoking `learn.ps1 resume`, and scans learner-facing files for forbidden solution access:

```powershell
$forbidden = @('git show reference/', 'git checkout reference/', 'reference/salesflow-complete-v1:database', 'reference/salesflow-complete-v1:workflows')
$learnerText = (Get-ChildItem "$root/learning","$root/scripts" -File -Recurse | Get-Content -Raw) -join "`n"
foreach ($pattern in $forbidden) {
  Assert-True (-not $learnerText.Contains($pattern)) "learner path omits $pattern"
}
```

It also asserts every checkpoint path stays within `tests/learning/checkpoints`, every lesson has at most three entries under `## New terms`, and each M00–M10 lesson links to only its immediate prerequisite.

- [ ] **Step 2: Run acceptance and verify initial failure**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-TutoringAcceptance.ps1`

Expected: FAIL on any missing integration or documentation rule.

- [ ] **Step 3: Fix only acceptance defects**

Correct mismatched field names, missing lesson sections, over-budget term lists, unsafe paths, or resume output. Do not weaken assertions and do not add production work.

- [ ] **Step 4: Document maintainer workflow**

Add to `docs/development-guide.md`:

- how to change curriculum and checkpoints;
- JSON-compatible YAML rule;
- commands for contract, curriculum, state, CLI, milestone, hash, and acceptance tests;
- rule that reference code is unavailable to ordinary tutoring;
- requirement to update starter/reference revisions deliberately;
- warning that learner-facing hints may not contain completed code.

- [ ] **Step 5: Run the complete tutoring test set**

```powershell
Get-ChildItem .\tests\learning\Test-*.ps1 | Sort-Object Name | ForEach-Object {
  powershell -NoProfile -ExecutionPolicy Bypass -File $_.FullName
  if ($LASTEXITCODE -ne 0) { throw "$($_.Name) failed" }
}
```

Expected: all tutoring tests pass.

- [ ] **Step 6: Commit acceptance and maintenance documentation**

```powershell
git add tests/learning/Test-TutoringAcceptance.ps1 docs/development-guide.md
git commit -m "test: verify SalesFlow tutoring journey"
```

---

### Task 10: Publish immutable reference and clean starter revisions

**Files:**
- Modify on starter branch: `README.md`
- Delete on starter branch: completed `database/001-initial.sql`, `workflows/*.json`, production-shaped `config/*.json`, `release/release-manifest.json`, `tests/runtime.sql`, and `tests/pilot-scenarios.json`
- Preserve on starter branch: `learning/**`, `scripts/learn.ps1`, `scripts/LearningState.psm1`, `scripts/Invoke-LearningCheckpoint.ps1`, `tests/learning/**`, project requirements/design boundaries, `.env.example`, and `compose.yaml`

**Interfaces:**
- Consumes: fully passing tutoring overlay on the complete implementation
- Produces: immutable `reference/salesflow-complete-v1`, immutable `starter/salesflow-guided-v1`, and a learner branch that contains no completed implementation

- [ ] **Step 1: Verify the reference candidate is clean and passing**

Run the complete tutoring tests and `git status --short`. The implementation worktree must contain only intentional committed changes; existing unrelated workspace changes must remain outside the isolated implementation worktree.

- [ ] **Step 2: Create the immutable reference tag**

```powershell
git tag -a reference/salesflow-complete-v1 -m "Verified SalesFlow tutoring reference v1"
```

Verify: `git rev-parse reference/salesflow-complete-v1^{commit}` equals `HEAD`.

- [ ] **Step 3: Create an isolated starter worktree**

```powershell
$starterPath = Join-Path (Split-Path -Parent (Get-Location)) 'N8N-SalesFlow-AI-starter-build'
git worktree add -b codex/build-learning-starter $starterPath HEAD
```

Verify the resolved path is outside but adjacent to the reference worktree and does not already contain user data before creation.

- [ ] **Step 4: Remove completed solutions from the starter worktree**

Use `git rm` with the exact starter deletion list above. Add minimal empty directories only where a milestone requires the learner to create an artifact. Do not retain source snippets from the completed SQL or workflow exports.

Rewrite root `README.md` to point to `learning/README.md` and state:

````markdown
This is the clean SalesFlow guided-build starter. Begin with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\learn.ps1 status
```

The completed implementation is intentionally absent from this branch.
````

- [ ] **Step 5: Add a starter-surface test before committing**

Create `tests/learning/Test-StarterSurface.ps1` on the starter branch. It must assert that completed workflow exports, final migration, runtime scenario SQL, release manifest, and synthetic production-shaped configs are absent while learning files and CLI remain present.

Run: `powershell -ExecutionPolicy Bypass -File .\tests\learning\Test-StarterSurface.ps1`

Expected: PASS.

- [ ] **Step 6: Commit and tag the starter**

```powershell
git add -A
git commit -m "feat: publish clean SalesFlow learning starter"
git tag -a starter/salesflow-guided-v1 -m "Clean SalesFlow guided-build starter v1"
```

- [ ] **Step 7: Validate separation**

```powershell
git diff --name-status starter/salesflow-guided-v1..reference/salesflow-complete-v1
git grep -n "Synthetic Plan includes one service" starter/salesflow-guided-v1 -- database workflows config
```

Expected: the diff shows completed implementation artifacts only in the reference; `git grep` returns no starter matches.

- [ ] **Step 8: Remove the temporary starter worktree after verification**

First confirm it is clean with `git -C $starterPath status --short`. Then run:

```powershell
git worktree remove $starterPath
```

Do not force removal and do not delete the branch or tags.

---

## Final Verification

- [ ] Run `git diff --check`.
- [ ] Run every `tests/learning/Test-*.ps1` file in a fresh PowerShell process.
- [ ] Run M00–M09 focused checkpoints against `reference/salesflow-complete-v1`.
- [ ] Run M10 only in a clean disposable Docker state and confirm `PASS FULL PASS` plus cleanup evidence.
- [ ] Verify `starter/salesflow-guided-v1` passes `Test-StarterSurface.ps1` and does not contain completed solution artifacts.
- [ ] Verify a new process can run `learn.ps1 resume` from a fixture progress file without chat history.
- [ ] Verify only intended implementation commits exist; unrelated workspace changes remain untouched.
- [ ] Verify `learning/curriculum.yaml` names exactly `starter/salesflow-guided-v1` and `reference/salesflow-complete-v1`, then record their resolved object IDs in the release evidence without creating a self-referential curriculum commit.
