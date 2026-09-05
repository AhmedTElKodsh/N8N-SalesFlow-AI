. "$PSScriptRoot/TestSupport.ps1"

$modulePath = Join-Path $PSScriptRoot '../../scripts/LearningState.psm1'
Import-Module $modulePath -Force -ErrorAction Stop

function Assert-Throws([scriptblock]$Action, [string]$Message) {
  $threw = $false
  try {
    & $Action
  } catch {
    $threw = $true
  }
  Assert-True $threw $Message
}

function Get-OperationFailure([scriptblock]$Action) {
  try {
    & $Action | Out-Null
    return $null
  } catch {
    return $_
  }
}

function Read-Progress($Context) {
  Get-Content -Raw -LiteralPath $Context.ProgressPath | ConvertFrom-Json
}

function Write-Progress($Context, $Progress) {
  [IO.File]::WriteAllText(
    $Context.ProgressPath,
    ($Progress | ConvertTo-Json -Depth 20),
    [Text.UTF8Encoding]::new($false)
  )
}

function New-LearningFixture([string]$Parent, [string]$Name) {
  $fixtureRoot = Join-Path $Parent $Name
  New-Item -Path $fixtureRoot -ItemType Directory -ErrorAction Stop | Out-Null
  Copy-Item -LiteralPath (Join-Path $script:root 'learning') -Destination $fixtureRoot -Recurse -ErrorAction Stop
  $fixtureContext = Get-LearningContext -RepositoryRoot $fixtureRoot
  $null = Initialize-LearningProgress -Context $fixtureContext
  $fixtureContext
}

function Assert-CorruptProgressRejected(
  [string]$Parent,
  [string]$Name,
  [scriptblock]$Corrupt,
  [scriptblock]$Operation
) {
  $fixtureContext = New-LearningFixture -Parent $Parent -Name $Name
  $progress = Read-Progress $fixtureContext
  & $Corrupt $progress
  Write-Progress -Context $fixtureContext -Progress $progress
  $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($fixtureContext.ProgressPath))
  $failure = Get-OperationFailure { & $Operation $fixtureContext }
  Assert-True ($null -ne $failure) "$Name corrupt progress rejected"
  $after = [Convert]::ToBase64String([IO.File]::ReadAllBytes($fixtureContext.ProgressPath))
  Assert-True ($after -ceq $before) "$Name corrupt progress remains byte-for-byte unchanged"
}

function Get-ExpectedLearningLockName([string]$ProgressPath) {
  $canonicalPath = [IO.Path]::GetFullPath($ProgressPath).ToUpperInvariant()
  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonicalPath))
  } finally {
    $sha256.Dispose()
  }
  $hex = -join @($hash | ForEach-Object { $_.ToString('x2') })
  "Local\SalesFlowLearningProgress-$hex"
}

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$temp = Join-Path ([IO.Path]::GetTempPath()) ("salesflow-learning-" + [guid]::NewGuid())
New-Item -Path $temp -ItemType Directory | Out-Null

try {
  Copy-Item -LiteralPath (Join-Path $root 'learning') -Destination $temp -Recurse
  $ctx = Get-LearningContext -RepositoryRoot $temp

  Assert-Equal $ctx.RepositoryRoot ([IO.Path]::GetFullPath($temp).TrimEnd('\', '/')) 'context resolves repository root'
  Assert-Equal $ctx.CurriculumPath (Join-Path $ctx.RepositoryRoot 'learning/curriculum.yaml') 'context resolves curriculum path'
  Assert-Equal $ctx.TemplatePath (Join-Path $ctx.RepositoryRoot 'learning/progress-template.json') 'context resolves template path'
  Assert-Equal $ctx.ProgressPath (Join-Path $ctx.RepositoryRoot '.learning/progress.json') 'context resolves progress path'

  $driveRoot = [IO.Path]::GetPathRoot($ctx.RepositoryRoot)
  $driveContext = Get-LearningContext -RepositoryRoot $driveRoot
  Assert-Equal $driveContext.RepositoryRoot (Resolve-Path -LiteralPath $driveRoot).Path 'context preserves canonical drive root'

  $null = Initialize-LearningProgress -Context $ctx
  $p = Read-Progress $ctx
  $curriculum = Get-Content -Raw -LiteralPath $ctx.CurriculumPath | ConvertFrom-Json
  Assert-Equal $p.currentMilestone 'M00' 'initial milestone'
  Assert-Equal $p.curriculumVersion $curriculum.curriculumVersion 'initialization records curriculum version'
  Assert-Equal $p.starterRevision $curriculum.starterRef 'initialization records starter ref'
  Assert-Equal $p.referenceRevision $curriculum.referenceRef 'initialization records reference ref'
  Assert-True (-not (Test-Path -LiteralPath "$($ctx.ProgressPath).tmp")) 'initialization removes atomic temp file'
  $bytes = [IO.File]::ReadAllBytes($ctx.ProgressPath)
  $hasUtf8Bom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
  Assert-True (-not $hasUtf8Bom) 'progress is UTF-8 without BOM'

  $invalidProgressPath = Join-Path $temp '.learning/cannot-replace'
  New-Item -Path $invalidProgressPath -ItemType Directory | Out-Null
  $invalidContext = [pscustomobject]@{
    RepositoryRoot = $ctx.RepositoryRoot
    CurriculumPath = $ctx.CurriculumPath
    TemplatePath = $ctx.TemplatePath
    ProgressPath = $invalidProgressPath
  }
  $invalidFailure = Get-OperationFailure { Initialize-LearningProgress -Context $invalidContext }
  Assert-True ($null -ne $invalidFailure) 'atomic persistence rejects a directory destination'
  $invalidTemps = @(Get-ChildItem -LiteralPath (Split-Path -Parent $invalidProgressPath) -Filter 'cannot-replace.*.tmp' -File)
  Assert-Equal $invalidTemps.Count 1 'failed atomic persistence retains one unique diagnostic temp file'
  if ($invalidTemps.Count -eq 1) {
    Assert-Match $invalidTemps[0].Name '^cannot-replace\.[0-9a-f]{32}\.tmp$' 'failed persistence uses a GUID-unique temp path'
    Assert-Match $invalidFailure.Exception.Message ([regex]::Escape($invalidTemps[0].FullName)) 'persistence failure surfaces diagnostic temp path'
  }
  Assert-Equal @(Get-ChildItem -LiteralPath $invalidProgressPath -Force).Count 0 'failed atomic persistence leaves destination directory unchanged'
  if ($invalidTemps.Count -eq 1) {
    Remove-Item -LiteralPath $invalidTemps[0].FullName -Force -ErrorAction Stop
  }
  Remove-Item -LiteralPath $invalidProgressPath -Recurse -Force

  $beforeLockedMove = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ctx.ProgressPath))
  $progressLock = [IO.File]::Open($ctx.ProgressPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
  try {
    $lockedMoveFailure = Get-OperationFailure { Start-LearningMilestone -Context $ctx -MilestoneId M00 }
  } finally {
    $progressLock.Dispose()
  }
  Assert-True ($null -ne $lockedMoveFailure) 'real replacement failure terminates public mutation'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes($ctx.ProgressPath))) -ceq $beforeLockedMove) 'real replacement failure preserves final file byte-for-byte'
  $lockedMoveTemps = @(Get-ChildItem -LiteralPath (Split-Path -Parent $ctx.ProgressPath) -Filter 'progress.json.*.tmp' -File)
  Assert-Equal $lockedMoveTemps.Count 1 'real replacement failure retains one unique diagnostic temp file'
  if ($lockedMoveTemps.Count -eq 1) {
    Assert-Match $lockedMoveFailure.Exception.Message ([regex]::Escape($lockedMoveTemps[0].FullName)) 'real replacement failure surfaces diagnostic temp path'
    Remove-Item -LiteralPath $lockedMoveTemps[0].FullName -Force -ErrorAction Stop
  }

  Assert-CorruptProgressRejected -Parent $temp -Name 'wrong-behavior-boolean' -Corrupt {
    param($progress)
    $progress.milestones.M00.status = 'active'
    $progress.milestones.M00.attempts = 1
    $progress.milestones.M00.behaviorGate = 'false'
    $progress.milestones.M00.lastCheckResult = $true
  } -Operation {
    param($corruptContext)
    Complete-LearningMilestone -Context $corruptContext -MilestoneId M00 -Explanation 'x' -FailureMode 'y' -TransferEvidence 'z'
  }
  Assert-CorruptProgressRejected -Parent $temp -Name 'wrong-understanding-boolean' -Corrupt {
    param($progress)
    $progress.milestones.M00.understandingGate = 'false'
  } -Operation { param($corruptContext) Initialize-LearningProgress -Context $corruptContext }
  Assert-CorruptProgressRejected -Parent $temp -Name 'missing-schema-version' -Corrupt {
    param($progress)
    $progress.PSObject.Properties.Remove('schemaVersion')
  } -Operation { param($corruptContext) Initialize-LearningProgress -Context $corruptContext }
  Assert-CorruptProgressRejected -Parent $temp -Name 'unsupported-schema-version' -Corrupt {
    param($progress)
    $progress.schemaVersion = 99
  } -Operation { param($corruptContext) Initialize-LearningProgress -Context $corruptContext }
  Assert-CorruptProgressRejected -Parent $temp -Name 'invalid-status' -Corrupt {
    param($progress)
    $progress.milestones.M00.status = 'ready-ish'
  } -Operation { param($corruptContext) Initialize-LearningProgress -Context $corruptContext }
  Assert-CorruptProgressRejected -Parent $temp -Name 'invalid-current-milestone' -Corrupt {
    param($progress)
    $progress.currentMilestone = 'M99'
  } -Operation { param($corruptContext) Initialize-LearningProgress -Context $corruptContext }
  Assert-CorruptProgressRejected -Parent $temp -Name 'missing-milestone' -Corrupt {
    param($progress)
    $progress.milestones.PSObject.Properties.Remove('M10')
  } -Operation { param($corruptContext) Initialize-LearningProgress -Context $corruptContext }
  Assert-CorruptProgressRejected -Parent $temp -Name 'available-with-incomplete-prerequisite' -Corrupt {
    param($progress)
    $progress.milestones.M02.status = 'available'
  } -Operation { param($corruptContext) Initialize-LearningProgress -Context $corruptContext }

  $malformedContext = New-LearningFixture -Parent $temp -Name 'malformed-json'
  [IO.File]::WriteAllText($malformedContext.ProgressPath, '{not-json', [Text.UTF8Encoding]::new($false))
  $malformedBefore = [Convert]::ToBase64String([IO.File]::ReadAllBytes($malformedContext.ProgressPath))
  $malformedFailure = Get-OperationFailure { Initialize-LearningProgress -Context $malformedContext }
  Assert-True ($null -ne $malformedFailure) 'malformed JSON progress rejected'
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes($malformedContext.ProgressPath))) -ceq $malformedBefore) 'malformed JSON remains byte-for-byte unchanged'

  $contentionContext = New-LearningFixture -Parent $temp -Name 'lock-contention'
  $contentionBefore = [Convert]::ToBase64String([IO.File]::ReadAllBytes($contentionContext.ProgressPath))
  $mutex = [Threading.Mutex]::new($false, (Get-ExpectedLearningLockName -ProgressPath $contentionContext.ProgressPath))
  $mutexHeld = $false
  $job = $null
  try {
    $mutexHeld = $mutex.WaitOne(0)
    Assert-True $mutexHeld 'test acquires learning progress mutex'
    $job = Start-Job -ScriptBlock {
      param($modulePath, $repositoryRoot)
      Import-Module $modulePath -Force -ErrorAction Stop
      $jobContext = Get-LearningContext -RepositoryRoot $repositoryRoot
      $jobContext | Add-Member -NotePropertyName LockTimeoutMilliseconds -NotePropertyValue 250
      try {
        Start-LearningMilestone -Context $jobContext -MilestoneId M00 | Out-Null
        [pscustomobject]@{ Succeeded = $true; Message = '' }
      } catch {
        [pscustomobject]@{ Succeeded = $false; Message = $_.Exception.Message }
      }
    } -ArgumentList $modulePath, $contentionContext.RepositoryRoot
    $null = Wait-Job -Job $job -Timeout 15
    Assert-Equal $job.State 'Completed' 'contending mutation finishes within bounded time'
    $contentionResult = Receive-Job -Job $job
    Assert-True (-not $contentionResult.Succeeded) 'contending mutation fails instead of racing'
    Assert-Match $contentionResult.Message 'Timed out waiting for learning progress lock' 'contention reports bounded lock timeout'
  } finally {
    if ($mutexHeld) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
    if ($null -ne $job) { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue }
  }
  Assert-True (([Convert]::ToBase64String([IO.File]::ReadAllBytes($contentionContext.ProgressPath))) -ceq $contentionBefore) 'contending mutation leaves durable state unchanged'

  $beforeRejectedStart = Get-Content -Raw -LiteralPath $ctx.ProgressPath
  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M02 } 'locked milestone rejected'
  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M99 } 'unknown milestone rejected'
  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M02 -Level 1 } 'hint for inactive milestone rejected'
  Assert-Throws { Record-LearningCheck -Context $ctx -MilestoneId M02 -Passed $true -Evidence @('invalid') } 'check for inactive milestone rejected'
  Assert-Throws { Record-DirectSolutionRequest -Context $ctx -MilestoneId M02 } 'direct solution for inactive milestone rejected'
  Assert-True ((Get-Content -Raw -LiteralPath $ctx.ProgressPath) -ceq $beforeRejectedStart) 'rejected starts do not persist changes'
  Assert-True (-not (Test-Path -LiteralPath "$($ctx.ProgressPath).tmp")) 'rejected starts leave no atomic temp file'

  $null = Start-LearningMilestone -Context $ctx -MilestoneId M00
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'available milestone becomes active'
  Assert-Equal $p.milestones.M00.attempts 1 'first start increments attempts'

  $null = Start-LearningMilestone -Context $ctx -MilestoneId M00
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'starting same active milestone is idempotent'
  Assert-Equal $p.milestones.M00.attempts 1 'idempotent active start does not increment attempts'
  $null = Initialize-LearningProgress -Context $ctx
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'reinitialization preserves durable progress'
  Assert-Equal $p.milestones.M00.attempts 1 'reinitialization preserves attempt count'

  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M00 -Level 0 } 'hint level below one rejected'
  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M00 -Level 6 } 'hint level above five rejected'
  Assert-Throws { Record-LearningHint -Context $ctx -MilestoneId M00 -Level 1.5 } 'fractional hint level rejected'
  $null = Record-LearningHint -Context $ctx -MilestoneId M00 -Level 3
  $null = Record-LearningHint -Context $ctx -MilestoneId M00 -Level 1
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.highestHintLevel 3 'hint recording retains maximum level'

  $null = Record-LearningCheck -Context $ctx -MilestoneId M00 -Passed $false -Evidence @('orientation-failed')
  $p = Read-Progress $ctx
  Assert-True (-not $p.milestones.M00.behaviorGate) 'failed check does not pass behavior gate'
  Assert-True (-not $p.milestones.M00.understandingGate) 'failed check does not pass understanding gate'
  Assert-Equal $p.milestones.M00.lastCheckResult $false 'failed check result recorded'
  Assert-Equal (@($p.milestones.M00.evidenceRevision) -join ',') 'orientation-failed' 'failed check evidence recorded'
  Assert-True (-not [string]::IsNullOrWhiteSpace($p.milestones.M00.lastCheckAt)) 'failed check timestamp recorded'
  $validatedProgress = & (Get-Module LearningState) { param($context) Read-LearningProgress -Context $context } $ctx
  Assert-True ($validatedProgress.milestones.M00.lastCheckAt -is [string]) 'validated progress preserves timestamp as JSON string'
  Assert-Throws {
    Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation 'x' -FailureMode 'y' -TransferEvidence 'z'
  } 'completion rejects false behavior gate'

  $null = Record-DirectSolutionRequest -Context $ctx -MilestoneId M00
  $p = Read-Progress $ctx
  Assert-True $p.milestones.M00.directSolutionRequested 'direct-solution request recorded'
  Assert-Equal $p.milestones.M00.status 'active' 'direct-solution request does not complete milestone'
  Assert-True (-not $p.milestones.M00.behaviorGate) 'direct-solution request does not pass behavior gate'
  Assert-True (-not $p.milestones.M00.understandingGate) 'direct-solution request does not pass understanding gate'

  $null = Record-LearningCheck -Context $ctx -MilestoneId M00 -Passed $true -Evidence @('orientation-ok')
  $p = Read-Progress $ctx
  Assert-True $p.milestones.M00.behaviorGate 'passed check passes behavior gate'
  Assert-True (-not $p.milestones.M00.understandingGate) 'passed check does not pass understanding gate'
  Assert-Equal $p.milestones.M00.lastCheckResult $true 'passed check result recorded'
  Assert-Equal (@($p.milestones.M00.evidenceRevision) -join ',') 'orientation-ok' 'passed check evidence recorded'
  Assert-True (-not [string]::IsNullOrWhiteSpace($p.milestones.M00.lastCheckAt)) 'passed check timestamp recorded'

  $null = Record-LearningCheck -Context $ctx -MilestoneId M00 -Passed $false -Evidence @('later-failure')
  $p = Read-Progress $ctx
  Assert-True (-not $p.milestones.M00.behaviorGate) 'later failed check revokes behavior gate'
  Assert-Equal $p.milestones.M00.lastCheckResult $false 'later failed check becomes authoritative result'
  Assert-Throws {
    Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation 'x' -FailureMode 'y' -TransferEvidence 'z'
  } 'completion rejects pass-then-fail state'
  $null = Record-LearningCheck -Context $ctx -MilestoneId M00 -Passed $true -Evidence @('orientation-ok')

  foreach ($understanding in @(
    @{ Explanation = ' '; FailureMode = 'failure'; TransferEvidence = 'transfer'; Label = 'blank explanation' },
    @{ Explanation = 'explanation'; FailureMode = "`t"; TransferEvidence = 'transfer'; Label = 'blank failure mode' },
    @{ Explanation = 'explanation'; FailureMode = 'failure'; TransferEvidence = ''; Label = 'blank transfer evidence' }
  )) {
    Assert-Throws {
      Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation $understanding.Explanation -FailureMode $understanding.FailureMode -TransferEvidence $understanding.TransferEvidence
    } "completion rejects $($understanding.Label)"
  }
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'active' 'rejected completion leaves milestone active'
  Assert-Equal $p.milestones.M01.status 'locked' 'rejected completion does not unlock successor'

  $explanation = 'n8n routes;  PostgreSQL owns durable state'
  $failureMode = 'Workflow succeeds but persistence fails'
  $transferEvidence = 'Mapped a second webhook without rewriting the answer'
  $directSolutionTransferEvidence = 'Rebuilt the same behavior from a fresh scenario without copying the direct solution'
  $null = Complete-LearningMilestone -Context $ctx -MilestoneId M00 -Explanation $explanation -FailureMode $failureMode -TransferEvidence $transferEvidence -DirectSolutionTransferEvidence $directSolutionTransferEvidence
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M00.status 'completed' 'M00 completed'
  Assert-True $p.milestones.M00.understandingGate 'completion passes understanding gate'
  Assert-Equal $p.milestones.M00.highestHintLevel 3 'completion preserves highest hint'
  Assert-Equal $p.milestones.M00.explanation $explanation 'completion preserves learner explanation exactly'
  Assert-Equal $p.milestones.M00.failureMode $failureMode 'completion preserves learner failure mode exactly'
  Assert-Equal $p.milestones.M00.transferEvidence $transferEvidence 'completion preserves learner transfer evidence exactly'
  Assert-Equal $p.milestones.M00.directSolutionTransferEvidence $directSolutionTransferEvidence 'completion preserves post-solution transfer evidence exactly'
  Assert-Equal $p.currentMilestone 'M01' 'next milestone becomes current'
  Assert-Equal $p.milestones.M01.status 'available' 'immediate successor becomes available'
  Assert-Equal $p.milestones.M02.status 'locked' 'completion does not unlock later successors'
  Assert-True (-not (Test-Path -LiteralPath "$($ctx.ProgressPath).tmp")) 'completion removes atomic temp file'
  Assert-Equal @(Get-ChildItem -LiteralPath (Split-Path -Parent $ctx.ProgressPath) -Filter 'progress.json.*.tmp' -File).Count 0 'successful transitions leave no unique temp files'

  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M00 } 'completed milestone cannot restart'
  Assert-Throws { Start-LearningMilestone -Context $ctx -MilestoneId M02 } 'still-locked later milestone rejected'
  $null = Start-LearningMilestone -Context $ctx -MilestoneId M01
  $null = Start-LearningMilestone -Context $ctx -MilestoneId M01
  $p = Read-Progress $ctx
  Assert-Equal $p.milestones.M01.attempts 1 'successor active start remains idempotent'
} finally {
  Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Assert-True (-not (Test-Path -LiteralPath $temp)) 'temporary learning workspace removed'
Complete-TestFile
